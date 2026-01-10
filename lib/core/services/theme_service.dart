import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  /// Kaydedilmiş tema modunu yükle
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(StorageKeys.themeMode);

    if (savedMode == 'light') {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  /// Temayı değiştir ve kaydet
  Future<void> toggleTheme() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    // Storage'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.themeMode,
      _mode == ThemeMode.light ? 'light' : 'dark',
    );
  }
}
