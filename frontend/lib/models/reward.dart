class Reward {
  final int id;
  final String title;
  final String description;
  final int pointsCost;
  final String rewardType;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.rewardType,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pointsCost: json['points_cost'],
      rewardType: json['reward_type'],
    );
  }
}

class UserReward {
  final int id;
  final int rewardId;
  final DateTime redeemedAt;
  final Reward reward;

  UserReward({
    required this.id,
    required this.rewardId,
    required this.redeemedAt,
    required this.reward,
  });

  factory UserReward.fromJson(Map<String, dynamic> json) {
    return UserReward(
      id: json['id'],
      rewardId: json['reward_id'],
      redeemedAt: DateTime.parse(json['redeemed_at']),
      reward: Reward.fromJson(json['reward']),
    );
  }
}
