import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/offer.dart';
import 'auth_service.dart';

class OfferService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Offer> makeOffer(int listingId, {double? offeredPrice, String? offeredItem}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/listings/$listingId/offers'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (offeredPrice != null) 'offered_price': offeredPrice,
        if (offeredItem != null) 'offered_item': offeredItem,
      }),
    );

    if (response.statusCode == 200) {
      return Offer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to make offer: ${response.body}');
    }
  }

  Future<List<Offer>> getMyOffers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/offers'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Offer.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load my offers: ${response.body}');
    }
  }

  Future<List<Offer>> getReceivedOffers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/received_offers'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Offer.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load received offers: ${response.body}');
    }
  }

  Future<Offer> updateOfferStatus(int offerId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/offers/$offerId'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return Offer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update offer: ${response.body}');
    }
  }
}
