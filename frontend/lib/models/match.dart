import 'listing.dart';

class UserBasic {
  final int id;
  final String email;
  final String username;
  final String? avatarUrl;

  UserBasic({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
  });

  factory UserBasic.fromJson(Map<String, dynamic> json) {
    return UserBasic(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
    );
  }
}

class Match {
  final int matchScore;
  final Listing userItem;
  final Listing targetItem;
  final UserBasic partner;
  final String reason;

  Match({
    required this.matchScore,
    required this.userItem,
    required this.targetItem,
    required this.partner,
    required this.reason,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      matchScore: json['match_score'],
      userItem: Listing.fromJson(json['user_item']),
      targetItem: Listing.fromJson(json['target_item']),
      partner: UserBasic.fromJson(json['partner']),
      reason: json['reason'],
    );
  }
}
