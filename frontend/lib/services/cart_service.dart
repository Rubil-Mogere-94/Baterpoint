import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart.dart';
import '../models/order.dart' as model;
import 'environment_config.dart';
import 'auth_service.dart';

class CartService {
  final AuthService _authService = AuthService();

  Future<Cart> fetchMyCart() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/cart/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load cart');
    }
  }

  Future<Cart> addToCart(int listingId, {int quantity = 1}) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${EnvironmentConfig.apiUrl}/cart/items'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'listing_id': listingId,
        'quantity': quantity,
      }),
    );
    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to add item to cart');
    }
  }

  Future<Cart> removeFromCart(int itemId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('${EnvironmentConfig.apiUrl}/cart/items/$itemId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to remove item');
    }
  }

  Future<Cart> updateQuantity(int itemId, int quantity) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('${EnvironmentConfig.apiUrl}/cart/items/$itemId?quantity=$quantity'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update quantity');
    }
  }
}

class OrderService {
  final AuthService _authService = AuthService();

  Future<void> createOrder(String shippingAddress, {String? couponCode}) async {
    final token = await _authService.getToken();
    final body = {
      'shipping_address': shippingAddress,
    };
    if (couponCode != null && couponCode.isNotEmpty) {
      body['coupon_code'] = couponCode;
    }
    
    final response = await http.post(
      Uri.parse('${EnvironmentConfig.apiUrl}/orders/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create order');
    }
  }

  Future<List<model.Order>> fetchMyOrders() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/orders/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<model.Order>.from(l.map((m) => model.Order.fromJson(m)));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load orders');
    }
  }
}
