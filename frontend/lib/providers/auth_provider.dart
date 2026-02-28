import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

import '../services/listing_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  
  User? _user;
  bool _isLoading = false;
  Set<int> _favoriteIds = {};

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  Set<int> get favoriteIds => _favoriteIds;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _fetchFavorites() async {
    if (!isAuthenticated) return;
    try {
      final favs = await _listingService.fetchFavorites();
      _favoriteIds = favs.map((l) => l.id).toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite(int listingId) async {
    try {
      HapticFeedback.lightImpact();
      final isFav = await _listingService.toggleFavorite(listingId);
      if (isFav) {
        _favoriteIds.add(listingId);
      } else {
        _favoriteIds.remove(listingId);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _checkAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.getCurrentUser();
      if (_user != null) {
        await _fetchFavorites();
      }
    } catch (e) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      _user = await _authService.getCurrentUser();
      if (_user != null) {
        await _fetchFavorites();
      }
      notifyListeners();
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _authService.login(username, password);
      if (token != null) {
        _user = await _authService.getCurrentUser();
        if (_user != null) {
          await _fetchFavorites();
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(username, email, password);
      await login(username, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _favoriteIds.clear();
    notifyListeners();
  }
}

