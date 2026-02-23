// frontend/lib/models/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? subscriptionStatus;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.subscriptionStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      subscriptionStatus: json['subscription_status'],
    );
  }
}
