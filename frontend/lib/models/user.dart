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

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.subscriptionStatus,
    this.overallRating = 0.0,
    this.totalReviews = 0,
    this.loyaltyPoints = 0,
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
    );
  }
}
