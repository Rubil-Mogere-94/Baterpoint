// frontend/lib/services/quest_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quest.dart';
import '../models/reward.dart';
import 'environment_config.dart';
import 'auth_service.dart';

class QuestService {
  final AuthService _authService = AuthService();

  Future<List<UserQuest>> fetchQuests() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/users/me/quests'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<UserQuest>.from(l.map((model) => UserQuest.fromJson(model)));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load quests');
    }
  }

  Future<Map<String, dynamic>> claimReward(int userQuestId) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${EnvironmentConfig.apiUrl}/users/me/quests/$userQuestId/claim'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to claim reward');
    }
  }

  Future<List<Reward>> fetchRewards() async {
    final response = await http.get(Uri.parse('${EnvironmentConfig.apiUrl}/rewards/'));
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Reward>.from(l.map((model) => Reward.fromJson(model)));
    } else {
      throw Exception('Failed to load rewards');
    }
  }

  Future<UserReward> redeemReward(int rewardId) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${EnvironmentConfig.apiUrl}/rewards/$rewardId/redeem'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return UserReward.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to redeem reward');
    }
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/users/me/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<AppNotification>.from(l.map((model) => AppNotification.fromJson(model)));
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}

class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
