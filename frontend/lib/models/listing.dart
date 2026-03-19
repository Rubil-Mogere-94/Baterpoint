class Review {
  final int id;
  final int userId;
  final int listingId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? username;

  Review({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.username,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      listingId: json['listing_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      username: json['username'],
    );
  }
}

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
  final double averageRating;
  final List<Review> reviews;
  final List<String> sustainabilityTags;

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
    this.averageRating = 0.0,
    this.reviews = const [],
    this.sustainabilityTags = const [],
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
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      reviews: json['reviews'] != null 
          ? (json['reviews'] as List).map((r) => Review.fromJson(r)).toList()
          : [],
      sustainabilityTags: json['sustainability_tags'] != null
          ? List<String>.from(json['sustainability_tags'])
          : [],
    );
  }

  factory Listing.skeleton() {
    return Listing(
      id: 0,
      title: 'Loading listing title...',
      description: 'Loading description of the listing item goes here...',
      category: 'CATEGORY',
      userId: 0,
      viewCount: 0,
      ownerUsername: 'Username',
      tradeType: 'TRADE',
      cashPrice: 0.0,
      exchangeItem: 'Exchange item',
    );
  }
}
