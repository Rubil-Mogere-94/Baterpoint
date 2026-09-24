import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AuthService {
  static const String _baseUrl = kBaseUrl;
  static const String _v1 = kApiV1;

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/token'),
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      return token;
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  static Future<String> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/register/'),
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      return token;
    } else {
      throw Exception('Registration failed: ${response.statusCode}');
    }
  }

  static void logout() {
    // Clear any stored tokens or user data
  }
}