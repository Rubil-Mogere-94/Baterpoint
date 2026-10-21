import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../constants.dart';

class ApiService {
  static const String _baseUrl = kBaseUrl;
  static const String _v1 = kApiV1;
  static const String _tokenKey = 'baterpoint_access_token';

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return <String, String>{};
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final detail = decoded['detail'] ?? decoded['message'];
        if (detail != null) return detail.toString();
      }
    } catch (_) {
      // The server may return plain text for an unexpected response.
    }
    return 'The request could not be completed. Please try again.';
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  Future<List<Product>> getListings({
    String? category,
    String? search,
    String? tradeType,
  }) async {
    final query = <String, String>{};
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      query['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (tradeType != null && tradeType.trim().isNotEmpty) {
      query['tradeType'] = tradeType;
    }

    try {
      final uri = Uri.parse('$_baseUrl$_v1/listings/').replace(
        queryParameters: query.isEmpty ? null : query,
      );
      final response = await http
          .get(uri, headers: await _authHeaders())
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .map(
                (item) => Product.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        }
      }
    } catch (_) {
      // Backend unavailable; automatically use the configured Beeceptor Mock Store.
    }

    // Direct integration with https://fake-store-api.mock.beeceptor.com
    return getMockStoreProducts(
      category: category,
      search: search,
      tradeType: tradeType,
    );
  }

  /// Fetches products directly from the Beeceptor Fake Store API.
  Future<List<Product>> getMockStoreProducts({
    String? category,
    String? search,
    String? tradeType,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$kMockStoreUrl/api/products'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          var products = decoded
              .map(
                (item) => Product.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();

          if (category != null &&
              category.trim().isNotEmpty &&
              category != 'All') {
            products = products
                .where(
                  (p) =>
                      p.description.toLowerCase().contains(
                            category.toLowerCase(),
                          ) ||
                      p.title.toLowerCase().contains(category.toLowerCase()),
                )
                .toList();
          }

          if (search != null && search.trim().isNotEmpty) {
            final q = search.trim().toLowerCase();
            products = products
                .where(
                  (p) =>
                      p.title.toLowerCase().contains(q) ||
                      p.description.toLowerCase().contains(q),
                )
                .toList();
          }

          if (tradeType != null && tradeType.trim().isNotEmpty) {
            if (tradeType == 'Barter') {
              products = products.where((p) => p.acceptsBarter).toList();
            } else if (tradeType == 'Sale') {
              products = products.where((p) => p.acceptsCurrency).toList();
            }
          }

          return products;
        }
      }
    } catch (_) {
      // Return empty list if external mock store also unreachable
    }
    return <Product>[];
  }

  Future<Product> getListing(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl$_v1/listings/$id'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return Product.fromJson(_asMap(jsonDecode(response.body)));
      }
    } catch (_) {
      // Fallback to mock store
    }

    final mockProducts = await getMockStoreProducts();
    final match = mockProducts.where((p) => p.id == id).firstOrNull;
    if (match != null) return match;

    throw Exception('Listing not found');
  }

  Future<Product> createListing({
    required String title,
    required String description,
    required String category,
    required String tradeType,
    required XFile image,
    String? cashPrice,
    String? exchangeItem,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$_v1/listings/'),
    );
    request.headers.addAll(await _authHeaders());
    request.fields.addAll({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'tradeType': tradeType,
    });
    if (cashPrice != null && cashPrice.trim().isNotEmpty) {
      request.fields['cashPrice'] = cashPrice.trim();
    }
    if (exchangeItem != null && exchangeItem.trim().isNotEmpty) {
      request.fields['exchangeItem'] = exchangeItem.trim();
    }
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      await image.readAsBytes(),
      filename: image.name,
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(_asMap(jsonDecode(response.body)));
    }
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> evaluateItem({
    required String itemName,
    String description = '',
  }) async {
    // The current backend mounts the AI router under /api/v1/ai/ai.
    final uri = Uri.parse('$_baseUrl$_v1/ai/ai/evaluate').replace(
      queryParameters: {
        'item_name': itemName.trim(),
        'description': description.trim(),
      },
    );
    final response = await http.post(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return _asMap(jsonDecode(response.body));
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/users/me'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) return _asMap(jsonDecode(response.body));
    throw Exception(_errorMessage(response.body));
  }

  Future<List<Product>> getMyListings() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/users/me/listings'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception(_errorMessage(response.body));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <Product>[];
    return decoded
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getInbox() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/chat/inbox'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception(_errorMessage(response.body));
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse('$_baseUrl$_v1/cart/'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) return _asMap(jsonDecode(response.body));
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> addToCart(int listingId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/cart/items'),
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'listing_id': listingId, 'quantity': 1}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> removeCartItem(int itemId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$_v1/cart/items/$itemId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) return _asMap(jsonDecode(response.body));
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> createOffer(
    int listingId, {
    String? offeredItem,
    double? offeredPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/offers/$listingId'),
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (offeredItem != null && offeredItem.trim().isNotEmpty)
          'offered_item': offeredItem.trim(),
        if (offeredPrice != null) 'offered_price': offeredPrice,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response.body));
  }

  Future<Map<String, dynamic>> createOrder() async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_v1/orders/'),
      headers: {
        ...await _authHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _asMap(jsonDecode(response.body));
    }
    throw Exception(_errorMessage(response.body));
  }
}
