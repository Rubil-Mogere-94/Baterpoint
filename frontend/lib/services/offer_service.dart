import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/offer.dart';
import '../constants.dart';
import 'auth_service.dart';

class OfferService {
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
      Uri.parse('$apiUrl/listings/$listingId/offers'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (offeredPrice != null) 'offered_price': offeredPrice,
        if (offeredItem != null) 'offered_item': offeredItem,
      }),
    );

    if (response.statusCode == 200) {
      return Offer.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to make offer');
    }
  }

  Future<List<Offer>> getMyOffers() async {
    final response = await http.get(
      Uri.parse('$apiUrl/users/me/offers'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Offer.fromJson(e)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load my offers');
    }
  }

  Future<List<Offer>> getReceivedOffers() async {
    final response = await http.get(
      Uri.parse('$apiUrl/users/me/received_offers'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Offer.fromJson(e)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load received offers');
    }
  }

  Future<Offer> updateOfferStatus(int offerId, String status) async {
    final response = await http.put(
      Uri.parse('$apiUrl/offers/$offerId'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return Offer.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update offer');
    }
  }

  Future<Offer> confirmTrade(int offerId) async {
    final response = await http.post(
      Uri.parse('$apiUrl/offers/$offerId/confirm'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Offer.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to confirm trade');
    }
  }
}
