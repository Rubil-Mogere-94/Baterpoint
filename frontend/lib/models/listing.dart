// frontend/lib/models/listing.dart
class Listing {
  final int id;
  final String title;
  final String? description;
  final double? cashPrice;
  final String? exchangeItem;
  final String? tradeType;
  final String category;
  final String? imageUrl;
  final int userId;
  final int viewCount;
  final String? ownerUsername;
  final double ownerRating;
  final int ownerReviews;
  final String? ownerAvatar;

  Listing({
    required this.id,
    required this.title,
    this.description,
    this.cashPrice,
    this.exchangeItem,
    this.tradeType,
    required this.category,
    this.imageUrl,
    required this.userId,
    required this.viewCount,
    this.ownerUsername,
    this.ownerRating = 0.0,
    this.ownerReviews = 0,
    this.ownerAvatar,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      cashPrice: json['cashPrice'] != null ? (json['cashPrice'] as num).toDouble() : null,
      exchangeItem: json['exchangeItem'],
      tradeType: json['tradeType'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      userId: json['user_id'],
      viewCount: json['view_count'] ?? 0,
      ownerUsername: json['owner_username'],
      ownerRating: (json['owner_rating'] ?? 0.0).toDouble(),
      ownerReviews: json['owner_reviews'] ?? 0,
      ownerAvatar: json['owner_avatar'],
    );
  }
}
