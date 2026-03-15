import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({required SharedPreferences prefs})
    : _prefs = prefs,
      _isDarkMode = prefs.getBool(_prefKey) ?? false;

  static const String _prefKey = 'isDarkModeEnabled';
  final SharedPreferences _prefs;
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_prefKey, _isDarkMode);
    notifyListeners();
  }
}
