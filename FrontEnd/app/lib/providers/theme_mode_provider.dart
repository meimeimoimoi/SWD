import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists [ThemeMode] for the whole app (system / light / dark).
class ThemeModeProvider extends ChangeNotifier {
  ThemeModeProvider() {
    _load();
  }

  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get themeMode => _mode;

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_key);
      if (v == 'light') {
        _mode = ThemeMode.light;
      } else if (v == 'dark') {
        _mode = ThemeMode.dark;
      } else {
        _mode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {
      // keep default
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      final s = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await p.setString(_key, s);
    } catch (_) {}
  }
}
