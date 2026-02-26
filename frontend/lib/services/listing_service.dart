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
  }) async {
    final queryParams = <String, String>{};
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
}
