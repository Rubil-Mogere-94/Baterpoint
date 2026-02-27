// frontend/lib/services/listing_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/listing.dart';
import '../constants.dart';
import 'auth_service.dart';

class ListingService {
  final AuthService _authService = AuthService();

  Future<List<Listing>> fetchListings({
    String? search,
    String? category,
    String? tradeType,
    String? sortBy,
    String? order,
    int skip = 0,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category != 'All') queryParams['category'] = category;
    if (tradeType != null) queryParams['tradeType'] = tradeType;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (order != null) queryParams['order'] = order;

    final uri = Uri.parse('$apiUrl/listings/').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      throw Exception('Failed to load listings');
    }
  }

  Future<bool> toggleFavorite(int listingId) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$apiUrl/listings/$listingId/favorite'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'favorited';
    } else {
      throw Exception('Failed to toggle favorite');
    }
  }

  Future<List<Listing>> fetchFavorites() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/users/me/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  Future<Listing> fetchListingById(int id) async {
    final response = await http.get(Uri.parse('$apiUrl/listings/$id'));
    if (response.statusCode == 200) {
      return Listing.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Listing not found');
    }
  }

  Future<List<Listing>> fetchMyListings() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/users/me/listings'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      throw Exception('Failed to load your listings');
    }
  }

  Future<List<Listing>> fetchMyChats() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/users/me/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      throw Exception('Failed to load your chats');
    }
  }

  Future<void> createListing({
    required String title,
    required String description,
    required double cashPrice,
    required String exchangeItem,
    required String tradeType,
    required String category,
    required File image,
  }) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/listings/'));
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['cashPrice'] = cashPrice.toString();
    request.fields['exchangeItem'] = exchangeItem;
    request.fields['tradeType'] = tradeType;
    request.fields['category'] = category;
    
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    final response = await request.send();
    if (response.statusCode != 201) {
      final body = await response.stream.bytesToString();
      throw Exception('Failed to create listing: $body');
    }
  }

  Future<void> updateListing(int listingId, {
    String? title,
    String? description,
    double? cashPrice,
    String? exchangeItem,
    String? tradeType,
    String? category,
  }) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$apiUrl/listings/$listingId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (cashPrice != null) 'cashPrice': cashPrice,
        if (exchangeItem != null) 'exchangeItem': exchangeItem,
        if (tradeType != null) 'tradeType': tradeType,
        if (category != null) 'category': category,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update listing: ${response.body}');
    }
  }

  Future<void> deleteListing(int listingId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('$apiUrl/listings/$listingId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete listing');
    }
  }

  Future<List<Listing>> fetchRecommendations({int limit = 10}) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$apiUrl/listings/recommendations?limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      throw Exception('Failed to load recommendations');
    }
  }
}
