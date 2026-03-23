import 'package:flutter/material.dart';

class Product {
  final String image, title, description;
  final int price, size, id;
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
}

List<Product> products = [
  Product(
      id: 1,
      title: "Vintage Camera",
      price: 150,
      size: 12,
      description: dummyText,
      image: "assets/images/bag_1.png",
      color: const Color(0xFF3D82AE),
      acceptsBarter: true,
      acceptsCurrency: true,
      barterPreference: "Looking for an acoustic guitar"),
  Product(
      id: 2,
      title: "Guitar Amp",
      price: 80,
      size: 8,
      description: dummyText,
      image: "assets/images/bag_2.png",
      color: const Color(0xFFD3A984),
      acceptsBarter: true,
      acceptsCurrency: false,
      barterPreference: "Trading for a solid state drive"),
  Product(
      id: 3,
      title: "Leather Jacket",
      price: 120,
      size: 10,
      description: dummyText,
      image: "assets/images/bag_3.png",
      color: const Color(0xFF989493),
      acceptsBarter: false,
      acceptsCurrency: true),
  Product(
      id: 4,
      title: "Smart Watch",
      price: 200,
      size: 11,
      description: dummyText,
      image: "assets/images/bag_4.png",
      color: const Color(0xFFE6B398),
      acceptsBarter: true,
      acceptsCurrency: true,
      barterPreference: "Open to tech trades"),
  Product(
      id: 5,
      title: "Mountain Bike",
      price: 450,
      size: 12,
      description: dummyText,
      image: "assets/images/bag_5.png",
      color: const Color(0xFFFB7883),
      acceptsBarter: true,
      acceptsCurrency: true,
      barterPreference: "Any Apple product"),
  Product(
    id: 6,
    title: "DJI Drone",
    price: 350,
    size: 12,
    description: dummyText,
    image: "assets/images/bag_6.png",
    color: const Color(0xFFAEAEAE),
    acceptsBarter: false,
    acceptsCurrency: true,
  ),
];

String dummyText =
    "This item is available for trade on Baterpoint. Check the seller's preferences to see if they accept direct barter or currency equivalent.";
