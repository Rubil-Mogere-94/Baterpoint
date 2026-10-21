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

    // Direct integration with external mock APIs (Beeceptor + DummyJSON)
    return getUnifiedExternalProducts(
      category: category,
      search: search,
      tradeType: tradeType,
    );
  }

  /// Fetches products from DummyJSON API (https://dummyjson.com/products).
  Future<List<Product>> getDummyJsonProducts({
    String? category,
    String? search,
    String? tradeType,
  }) async {
    try {
      Uri uri;
      if (search != null && search.trim().isNotEmpty) {
        uri = Uri.parse('$kDummyJsonUrl/products/search').replace(
          queryParameters: {'q': search.trim(), 'limit': '30'},
        );
      } else if (category != null &&
          category.trim().isNotEmpty &&
          category != 'All') {
        final catSlug = category.trim().toLowerCase().replaceAll(' ', '-');
        uri = Uri.parse('$kDummyJsonUrl/products/category/$catSlug');
      } else {
        uri = Uri.parse('$kDummyJsonUrl/products?limit=30');
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded is Map && decoded['products'] is List
            ? decoded['products'] as List
            : (decoded is List ? decoded : []);

        var products = list
            .map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        if (tradeType != null && tradeType.trim().isNotEmpty) {
          if (tradeType == 'Barter') {
            products = products.where((p) => p.acceptsBarter).toList();
          } else if (tradeType == 'Sale') {
            products = products.where((p) => p.acceptsCurrency).toList();
          }
        }
        return products;
      }
    } catch (_) {
      // Fall through on network failure
    }
    return <Product>[];
  }

  /// Fetches products directly from the Beeceptor Fake Store API.
  Future<List<Product>> getBeeceptorProducts({
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

  /// Fetches products from Platzi Fake Store API (https://api.escuelajs.co/api/v1/products).
  Future<List<Product>> getPlatziProducts({
    String? category,
    String? search,
    String? tradeType,
  }) async {
    try {
      final uri = Uri.parse('$kPlatziStoreUrl/products?offset=0&limit=25');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
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
            final cat = category.toLowerCase();
            products = products
                .where(
                  (p) =>
                      p.description.toLowerCase().contains(cat) ||
                      p.title.toLowerCase().contains(cat),
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
      // Fall through on network failure
    }
    return <Product>[];
  }

  /// Combines products from Beeceptor, DummyJSON, and Platzi into a unified catalog.
  Future<List<Product>> getUnifiedExternalProducts({
    String? category,
    String? search,
    String? tradeType,
  }) async {
    final results = await Future.wait([
      getBeeceptorProducts(
        category: category,
        search: search,
        tradeType: tradeType,
      ),
      getDummyJsonProducts(
        category: category,
        search: search,
        tradeType: tradeType,
      ),
      getPlatziProducts(
        category: category,
        search: search,
        tradeType: tradeType,
      ),
    ]);

    final beeceptorItems = results[0];
    final dummyJsonItems = results[1];
    final platziItems = results[2];

    final combined = <Product>[];
    final seenTitles = <String>{};

    for (final p in beeceptorItems) {
      if (seenTitles.add(p.title.toLowerCase())) {
        combined.add(p);
      }
    }
    for (final p in dummyJsonItems) {
      if (seenTitles.add(p.title.toLowerCase())) {
        combined.add(p);
      }
    }
    for (final p in platziItems) {
      if (seenTitles.add(p.title.toLowerCase())) {
        combined.add(p);
      }
    }
    return combined;
  }

  /// Backward compatibility alias
  Future<List<Product>> getMockStoreProducts({
    String? category,
    String? search,
    String? tradeType,
  }) => getUnifiedExternalProducts(
        category: category,
        search: search,
        tradeType: tradeType,
      );

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
      // Fallback to unified external mock store
    }

    final mockProducts = await getUnifiedExternalProducts();
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

  Future<List<Map<String, dynamic>>> getConversation(int otherUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_v1/chat/conversation/$otherUserId'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> sendChatMessage({
    required int recipientId,
    required String messageContent,
    int? listingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_v1/chat/send'),
        headers: {
          ...await _authHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recipient_id': recipientId,
          'message_content': messageContent,
          if (listingId != null) 'listing_id': listingId,
        }),
      );
      if (response.statusCode == 200) {
        return _asMap(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  /// Reviews and approves or rejects a trade as a verified Barterpoint Official.
  Future<Map<String, dynamic>?> reviewTradeAsOfficial(
    int offerId, {
    required bool approved,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_v1/offers/$offerId/official-review'),
        headers: {
          ...await _authHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': approved ? 'approved' : 'rejected',
          if (notes != null) 'official_notes': notes,
        }),
      );
      if (response.statusCode == 200) {
        return _asMap(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
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
