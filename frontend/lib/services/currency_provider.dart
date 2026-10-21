import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final int decimalPlaces;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.decimalPlaces = 2,
  });
}

class CurrencyProvider extends ChangeNotifier {
  static const String _prefKey = 'baterpoint_selected_currency';

  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh', flag: '🇰🇪', decimalPlaces: 0),
    CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸', decimalPlaces: 2),
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺', decimalPlaces: 2),
    CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧', decimalPlaces: 2),
    CurrencyInfo(code: 'UGX', name: 'Ugandan Shilling', symbol: 'USh', flag: '🇺🇬', decimalPlaces: 0),
    CurrencyInfo(code: 'TZS', name: 'Tanzanian Shilling', symbol: 'TSh', flag: '🇹🇿', decimalPlaces: 0),
  ];

  String _currentCurrency = 'KES';
  bool _isLoading = false;
  Map<String, double> _rates = {
    'KES': 1.0,
    'USD': 0.0077,
    'EUR': 0.0072,
    'GBP': 0.0061,
    'UGX': 28.5,
    'TZS': 20.0,
  };

  CurrencyProvider() {
    _init();
  }

  String get currentCurrency => _currentCurrency;
  bool get isLoading => _isLoading;
  Map<String, double> get rates => _rates;

  CurrencyInfo get currentInfo =>
      supportedCurrencies.firstWhere(
        (c) => c.code == _currentCurrency,
        orElse: () => supportedCurrencies.first,
      );

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && supportedCurrencies.any((c) => c.code == saved)) {
        _currentCurrency = saved;
        notifyListeners();
      }
    } catch (_) {}

    await fetchRates();
  }

  /// Fetches live exchange rates using the free open.er-api.com API.
  Future<void> fetchRates() async {
    _isLoading = true;
    try {
      final response = await http
          .get(Uri.parse(kExchangeRateUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['rates'] is Map) {
          final liveRates = decoded['rates'] as Map;
          final updated = Map<String, double>.from(_rates);
          for (final c in supportedCurrencies) {
            if (liveRates.containsKey(c.code)) {
              final raw = liveRates[c.code];
              if (raw is num) {
                updated[c.code] = raw.toDouble();
              }
            }
          }
          _rates = updated;
        }
      }
    } catch (_) {
      // Gracefully maintain offline fallback rates
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets user preferred currency and persists selection.
  Future<void> setCurrency(String code) async {
    if (_currentCurrency == code) return;
    _currentCurrency = code;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }

  /// Converts a KES amount to the currently selected currency.
  double convert(num amountInKes) {
    if (_currentCurrency == 'KES') return amountInKes.toDouble();
    final rate = _rates[_currentCurrency] ?? 1.0;
    return amountInKes.toDouble() * rate;
  }

  /// Formats a base KES price into the selected currency.
  String formatPrice(num amountInKes) {
    if (_currentCurrency == 'KES') {
      return formatKes(amountInKes);
    }

    final info = currentInfo;
    final converted = convert(amountInKes);

    final pattern = info.decimalPlaces > 0 ? '#,##0.00' : '#,##0';
    final formatted = NumberFormat(pattern, 'en_US').format(converted);
    return '${info.symbol} $formatted';
  }

  /// Alias for formatPrice to format KES values with selected currency
  String formatKesEquivalent(num amountInKes) => formatPrice(amountInKes);
}
