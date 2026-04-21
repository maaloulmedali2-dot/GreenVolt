import 'package:flutter/material.dart';
import 'package:greenvolt/theme/app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeNotifier() {
    AppTheme.setDark(true);
  }

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    AppTheme.setDark(isDark);
    notifyListeners();
  }
}
