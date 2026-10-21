import 'package:flutter/material.dart';

class Product {
  final String image, title, description;
  final int price, id;
  final int size;
  final Color color;
  final bool acceptsBarter;
  final bool acceptsCurrency;
  final String? barterPreference;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String? condition;

  Product({
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.size,
    required this.id,
    required this.color,
    this.acceptsBarter = false,
    this.acceptsCurrency = true,
    this.barterPreference,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.inStock = true,
    this.condition,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['product_id'] ?? 0;
    final int id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final String title = json['title'] ?? json['name'] ?? 'Item #$id';
    final String description = json['description'] ?? '';

    final num rawPrice = json['cashPrice'] ?? json['price'] ?? 0.0;
    final int price = rawPrice.round();

    final String tradeType =
        json['tradeType'] ?? _inferTradeType(id, title, json);
    final String? barterPref =
        json['exchangeItem'] ??
        json['exchange_item'] ??
        _inferBarterPreference(title, category: json['category']?.toString());

    final rawImage = json['imageUrl'] ??
        json['image_url'] ??
        json['thumbnail'] ??
        (json['images'] is List && (json['images'] as List).isNotEmpty
            ? json['images'][0]
            : json['image']) ??
        '';
    final String image = _resolveImage(title, rawImage.toString());

    final num rawRating = json['rating'] is Map
        ? (json['rating']['rate'] ?? 0.0)
        : (json['rating'] ?? 0.0);
    final int reviewCount =
        json['reviewCount'] ??
        (json['reviews'] is List ? (json['reviews'] as List).length : 0);

    final bool inStock = json['inStock'] ??
        json['availability'] ??
        (json['stock'] != null ? ((json['stock'] as num) > 0) : true);

    return Product(
      id: id,
      title: title,
      description: description,
      price: price,
      size: 10,
      image: image,
      color: _getColorForId(id),
      acceptsBarter: tradeType == 'Barter' || tradeType == 'Both',
      acceptsCurrency: tradeType == 'Sale' || tradeType == 'Both',
      barterPreference: barterPref,
      rating: rawRating.toDouble(),
      reviewCount: reviewCount,
      inStock: inStock,
      condition: json['condition'],
    );
  }

  static String _inferTradeType(
    int id,
    String title,
    Map<String, dynamic> json,
  ) {
    final lower = title.toLowerCase();
    if (lower.contains('headphone') || lower.contains('camera')) {
      return 'Barter';
    }
    if (lower.contains('tv') || lower.contains('refrigerator')) {
      return 'Sale';
    }
    return 'Both'; // Mixed trade default
  }

  static String? _inferBarterPreference(String title, {String? category}) {
    final lower = title.toLowerCase();
    if (lower.contains('smartphone')) {
      return 'Tablet or DSLR Camera + KSh 5,000';
    }
    if (lower.contains('laptop')) {
      return 'High-end Gaming PC or iPad Pro';
    }
    if (lower.contains('headphone')) {
      return 'Smartwatch or Mechanical Keyboard';
    }
    if (lower.contains('smartwatch')) {
      return 'Fitness tracker or AirPods + cash';
    }
    if (lower.contains('camera')) {
      return 'Drone or iPhone 13';
    }
    if (lower.contains('tablet')) {
      return 'Nintendo Switch or Kindle Oasis';
    }
    if (lower.contains('console')) {
      return 'Gaming Laptop or VR Headset';
    }
    if (category == 'Electronics') {
      return 'Equivalent electronics or camera gear';
    }
    return null;
  }

  static String _resolveImage(String title, String raw) {
    if (raw.isNotEmpty &&
        !raw.contains('example.com') &&
        !raw.startsWith('http://localhost') &&
        (raw.startsWith('http://') || raw.startsWith('https://'))) {
      return raw;
    }

    final lower = title.toLowerCase();
    if (lower.contains('smart phone') || lower.contains('smartphone')) {
      return 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80';
    }
    if (lower.contains('laptop')) {
      return 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80';
    }
    if (lower.contains('headphone')) {
      return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=800&q=80';
    }
    if (lower.contains('smartwatch')) {
      return 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80';
    }
    if (lower.contains('camera')) {
      return 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80';
    }
    if (lower.contains('tv')) {
      return 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?auto=format&fit=crop&w=800&q=80';
    }
    if (lower.contains('tablet')) {
      return 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?auto=format&fit=crop&w=800&q=80';
    }
    if (lower.contains('console') || lower.contains('gaming')) {
      return 'https://images.unsplash.com/photo-1486401899868-0e435ed85128?auto=format&fit=crop&w=800&q=80';
    }
    if (lower.contains('refrigerator')) {
      return 'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?auto=format&fit=crop&w=800&q=80';
    }
    return raw.isNotEmpty ? raw : 'assets/images/placeholder.png';
  }

  static Color _getColorForId(int id) {
    final colors = [
      const Color(0xFF3D82AE),
      const Color(0xFFD3A984),
      const Color(0xFF989493),
      const Color(0xFFE6B398),
      const Color(0xFFFB7883),
      const Color(0xFFAEAEAE),
    ];
    return colors[id % colors.length];
  }
}