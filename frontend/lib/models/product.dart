import 'package:flutter/material.dart';

class Product {
  final String image, title, description;
  final int price, id;
  final int size; // Keeping size metadata
  final Color color;
  final bool acceptsBarter;
  final bool acceptsCurrency;
  final String? barterPreference;

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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String tradeType = json['tradeType'] ?? 'Both';
    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      price: (json['cashPrice'] ?? 0.0).round(),
      size: 10, // Default metadata
      image: json['imageUrl'] ?? 'assets/images/bag_1.png',
      color: _getColorForId(json['id']),
      acceptsBarter: tradeType == 'Barter' || tradeType == 'Both',
      acceptsCurrency: tradeType == 'Sale' || tradeType == 'Both',
      barterPreference: json['exchangeItem'],
    );
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

// Keeping this for accidental falls back but ideally we use the API
List<Product> products = [];

String dummyText =
    "This item is available for trade on Baterpoint. Check the seller's preferences to see if they accept direct barter or currency equivalent.";
