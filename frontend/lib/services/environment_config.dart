import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000';
  static String get apiPrefix => '/api/v1';
  static String get apiUrl => '$baseUrl$apiPrefix';
  
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }
}
