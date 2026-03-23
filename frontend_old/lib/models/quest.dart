// frontend/lib/models/quest.dart
class Quest {
  final int id;
  final String title;
  final String description;
  final String goalType;
  final int goalValue;
  final int pointsReward;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.goalType,
    required this.goalValue,
    required this.pointsReward,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      goalType: json['goal_type'],
      goalValue: json['goal_value'],
      pointsReward: json['points_reward'],
    );
  }
}

class UserQuest {
  final int id;
  final int questId;
  final int progress;
  final bool completed;
  final Quest quest;

  UserQuest({
    required this.id,
    required this.questId,
    required this.progress,
    required this.completed,
    required this.quest,
  });

  factory UserQuest.fromJson(Map<String, dynamic> json) {
    return UserQuest(
      id: json['id'],
      questId: json['quest_id'],
      progress: json['progress'],
      completed: json['completed'],
      quest: Quest.fromJson(json['quest']),
    );
  }
}
