import 'package:flutter/material.dart';

class ErrorProvider with ChangeNotifier {
  String? _errorMessage;
  bool _hasError = false;

  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;

  void setError(String message) {
    _errorMessage = message;
    _hasError = true;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _hasError = false;
    notifyListeners();
  }

  void showSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
