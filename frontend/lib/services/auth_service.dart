import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AuthException implements Exception {
  final String message;
  final int statusCode;
  final String error;
  AuthException(this.message, this.statusCode, {this.error = ''});
  @override
  String toString() => 'AuthException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

class AuthService {
  static const String _baseUrl = kBaseUrl;
  static const String _v1 = kApiV1;
  static const int _timeoutMs = 15000;

  static String _extractError(dynamic data) {
    if (data is Map) {
      if (data['message'] is String) return data['message'];
      if (data['detail'] is String) return data['detail'];
      if (data['detail'] is List) {
        final details = data['detail'] as List;
        if (details.isNotEmpty && details.first is Map) {
          final loc = details.first['loc'];
          final msg = details.first['msg'];
          if (loc is List && loc.length > 1) {
            final field = loc.last;
            return '$field: $msg';
          }
          return msg.toString();
        }
        return details.first.toString();
      }
    }
    return 'Authentication failed';
  }

  static Future<http.Response> _post(Uri uri, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(milliseconds: _timeoutMs));
      return response;
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out. Check your connection.');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Unexpected error: $e');
    }
  }

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      Uri.parse('$_baseUrl$_v1/token'),
      {'username': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      if (token is String && token.isNotEmpty) return token;
      throw AuthException('Invalid response from server', response.statusCode);
    }
    final body = jsonDecode(response.body);
    throw AuthException(_extractError(body), response.statusCode);
  }

  static Future<String> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _post(
      Uri.parse('$_baseUrl$_v1/register/'),
      {'username': username, 'email': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      if (token is String && token.isNotEmpty) return token;
      throw AuthException('Invalid response from server', response.statusCode);
    }
    final body = jsonDecode(response.body);
    throw AuthException(_extractError(body), response.statusCode);
  }

  static Future<String> refreshToken(String refreshToken) async {
    final response = await _post(
      Uri.parse('$_baseUrl$_v1/refresh'),
      {},
    );
    response.headers['Authorization'] = 'Bearer $refreshToken';
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      if (token is String && token.isNotEmpty) return token;
      throw AuthException('Invalid response from server', response.statusCode);
    }
    final body = jsonDecode(response.body);
    throw AuthException(_extractError(body), response.statusCode);
  }

  static Future<void> forgotPassword(String email) async {
    final response = await _post(
      Uri.parse('$_baseUrl$_v1/forgot'),
      {'email': email},
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw AuthException(_extractError(body), response.statusCode);
    }
  }

  static Future<void> resetPassword(String token, String password) async {
    final response = await _post(
      Uri.parse('$_baseUrl$_v1/reset'),
      {'token': token, 'password': password},
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw AuthException(_extractError(body), response.statusCode);
    }
  }

  static void logout() {}
}