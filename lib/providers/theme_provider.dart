import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccentColorType { yellow, blue }

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  AccentColorType _accentColorType = AccentColorType.yellow;

  bool get isDarkMode => _isDarkMode;
  AccentColorType get accentColorType => _accentColorType;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    final savedAccent = prefs.getString('accent_color');
    if (savedAccent == 'blue') {
      _accentColorType = AccentColorType.blue;
    } else {
      _accentColorType = AccentColorType.yellow;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  Future<void> toggleAccentColor() async {
    if (_accentColorType == AccentColorType.yellow) {
      _accentColorType = AccentColorType.blue;
    } else {
      _accentColorType = AccentColorType.yellow;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accent_color', _accentColorType.name);
  }
}
