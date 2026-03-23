import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  Map<String, dynamic>? _data;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnalytics({int days = 30}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _analyticsService.fetchSellerAnalytics(days: days);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
