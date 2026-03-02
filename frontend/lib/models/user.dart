// frontend/lib/models/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? subscriptionStatus;
  final double overallRating;
  final int totalReviews;
  final int loyaltyPoints;
  final int successfulTrades;
  final double tradeReputation;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.subscriptionStatus,
    this.overallRating = 0.0,
    this.totalReviews = 0,
    this.loyaltyPoints = 0,
    this.successfulTrades = 0,
    this.tradeReputation = 5.0,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      subscriptionStatus: json['subscription_status'],
      overallRating: (json['overall_rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      loyaltyPoints: json['loyalty_points'] ?? 0,
      successfulTrades: json['successful_trades'] ?? 0,
      tradeReputation: (json['trade_reputation'] ?? 5.0).toDouble(),
      avatarUrl: json['avatar_url'],
    );
  }
}
