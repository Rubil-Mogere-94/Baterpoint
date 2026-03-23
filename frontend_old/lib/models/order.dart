import 'listing.dart';

class OrderItem {
  final int id;
  final int listingId;
  final int quantity;
  final double priceAtPurchase;
  final Listing listing;

  OrderItem({
    required this.id,
    required this.listingId,
    required this.quantity,
    required this.priceAtPurchase,
    required this.listing,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      listingId: json['listing_id'],
      quantity: json['quantity'],
      priceAtPurchase: (json['price_at_purchase'] as num).toDouble(),
      listing: Listing.fromJson(json['listing']),
    );
  }
}

class Order {
  final int id;
  final int userId;
  final String status;
  final double totalAmount;
  final String? shippingAddress;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    this.shippingAddress,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      shippingAddress: json['shipping_address'],
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
    );
  }
}
