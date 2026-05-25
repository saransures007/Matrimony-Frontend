import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

export 'light_theme.dart';
export 'dark_theme.dart';

// ======================================
// ✅ THEME PROVIDER & EXPORTER
// ======================================

/// ✅ Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// ✅ App Theme Export
class AppTheme {
  static ThemeData get light => getLightTheme();
  static ThemeData get dark => getDarkTheme();
}