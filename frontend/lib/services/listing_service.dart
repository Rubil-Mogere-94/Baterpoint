// frontend/lib/services/listing_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/listing.dart';
import '../models/deal.dart';
import '../models/match.dart';
import 'environment_config.dart';
import 'auth_service.dart';

class ListingService {
  final AuthService _authService = AuthService();

  Future<List<Listing>> fetchListings({
    String? search,
    String? category,
    String? tradeType,
    String? sortBy,
    String? order,
    String? tag,
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
    if (tag != null) queryParams['tag'] = tag;

    final uri = Uri.parse('${EnvironmentConfig.apiUrl}/listings/').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load listings');
    }
  }

  Future<bool> toggleFavorite(int listingId) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${EnvironmentConfig.apiUrl}/listings/$listingId/favorite'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'favorited';
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to toggle favorite');
    }
  }

  Future<List<Listing>> fetchFavorites() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/users/me/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load favorites');
    }
  }

  Future<Listing> fetchListingById(int id) async {
    final response = await http.get(Uri.parse('${EnvironmentConfig.apiUrl}/listings/$id'));
    if (response.statusCode == 200) {
      return Listing.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Listing not found');
    }
  }

  Future<List<Listing>> fetchMyListings() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/users/me/listings'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load your listings');
    }
  }

  Future<List<Listing>> fetchMyChats() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/users/me/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load your chats');
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
    List<String> sustainabilityTags = const [],
  }) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('${EnvironmentConfig.apiUrl}/listings/'));
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['cashPrice'] = cashPrice.toString();
    request.fields['exchangeItem'] = exchangeItem;
    request.fields['tradeType'] = tradeType;
    request.fields['category'] = category;
    request.fields['sustainability_tags'] = jsonEncode(sustainabilityTags);
    
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
    List<String>? sustainabilityTags,
  }) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('${EnvironmentConfig.apiUrl}/listings/$listingId'),
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
        if (sustainabilityTags != null) 'sustainability_tags': sustainabilityTags,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update listing: ${response.body}');
    }
  }

  Future<List<Match>> fetchSmartMatches({int limit = 10}) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/listings/matches?limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Match>.from(l.map((model) => Match.fromJson(model)));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load smart matches');
    }
  }

  Future<void> deleteListing(int listingId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('${EnvironmentConfig.apiUrl}/listings/$listingId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete listing');
    }
  }

  Future<List<Listing>> fetchRecommendations({int limit = 10}) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${EnvironmentConfig.apiUrl}/listings/recommendations?limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Listing>.from(l.map((model) => Listing.fromJson(model)));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load recommendations');
    }
  }

  Future<Deal> fetchDealOfTheHour() async {
    final response = await http.get(Uri.parse('${EnvironmentConfig.apiUrl}/listings/deal-of-the-hour'));
    if (response.statusCode == 200) {
      return Deal.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load deal of the hour');
    }
  }

  Future<void> addReview({required int listingId, required int rating, String? comment}) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${EnvironmentConfig.apiUrl}/users/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'listing_id': listingId,
        'rating': rating,
        'comment': comment,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to add review');
    }
  }
}
