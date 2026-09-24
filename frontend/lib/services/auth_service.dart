import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AuthException implements Exception {
  final String message;
  final int statusCode;
  AuthException(this.message, this.statusCode);
  @override
  String toString() => 'AuthException($statusCode): $message';
}

class AuthService {
  static const String _baseUrl = kBaseUrl;
  static const String _v1 = kApiV1;

  static String _extractError(dynamic data) {
    if (data is Map) {
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
      }
    }
    return 'Authentication failed';
  }

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    }
    final body = jsonDecode(response.body);
    throw AuthException(_extractError(body), response.statusCode);
  }

  static Future<String> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    }
    final body = jsonDecode(response.body);
    throw AuthException(_extractError(body), response.statusCode);
  }

  static void logout() {}
}