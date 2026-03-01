import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // In a real app we might check the platform brightness, 
      // but for simplicity we'll treat system as not dark unless explicit
      return false; 
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme([bool? isDark]) {
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }
}
