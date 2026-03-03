// frontend/lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'environment_config.dart';
import 'auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();
  final String apiUrl = EnvironmentConfig.apiUrl;

  Future<void> registerDeviceToken(String token) async {
    final authToken = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$apiUrl/users/me/device-token'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'device_token': token}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register device token');
    }
  }

  // Placeholder for FCM initialization
  Future<void> initializeNotifications() async {
    // In a real app, you would get the FCM token here
    // String? token = await FirebaseMessaging.instance.getToken();
    String mockToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
    await registerDeviceToken(mockToken);
  }
}
