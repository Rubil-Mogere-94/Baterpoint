import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static String get apiUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000';
  
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }
}
