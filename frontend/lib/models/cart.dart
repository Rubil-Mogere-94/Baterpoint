import 'listing.dart';

class CartItem {
  final int id;
  final int cartId;
  final int listingId;
  final int quantity;
  final Listing listing;

  CartItem({
    required this.id,
    required this.cartId,
    required this.listingId,
    required this.quantity,
    required this.listing,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      cartId: json['cart_id'],
      listingId: json['listing_id'],
      quantity: json['quantity'],
      listing: Listing.fromJson(json['listing']),
    );
  }
}

class Cart {
  final int id;
  final int userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      userId: json['user_id'],
      items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + ((item.listing.cashPrice ?? 0) * item.quantity));
  }
}
