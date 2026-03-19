import 'package:flutter/material.dart';
import '../services/listing_service.dart';
import '../models/listing.dart';

class RecommendationsProvider extends ChangeNotifier {
  final ListingService _listingService = ListingService();
  
  List<Listing> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  List<Listing> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRecommendations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _recommendations = await _listingService.fetchAIRecommendations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Listing>> getSimilarListings(int listingId) async {
    try {
      return await _listingService.fetchSimilarListings(listingId);
    } catch (e) {
      debugPrint('Error fetching similar listings: $e');
      return [];
    }
  }
}
