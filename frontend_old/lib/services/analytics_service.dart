// frontend/lib/services/analytics_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'environment_config.dart';
import 'auth_service.dart';

class AnalyticsService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> fetchSellerAnalytics({int days = 30}) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/analytics/seller?days=$days'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load analytics');
    }
  }
}
