// frontend/lib/services/quest_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quest.dart';
import '../constants.dart';
import 'auth_service.dart';

class QuestService {
  final AuthService _authService = AuthService();

  Future<List<UserQuest>> fetchQuests() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/users/me/quests'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<UserQuest>.from(l.map((model) => UserQuest.fromJson(model)));
    } else {
      throw Exception('Failed to load quests');
    }
  }

  Future<Map<String, dynamic>> claimReward(int userQuestId) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$apiUrl/users/me/quests/$userQuestId/claim'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to claim reward');
    }
  }
}
