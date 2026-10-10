import 'package:flutter/material.dart';

/// Mirrors the react-native-app's `constants/Colors.ts` light/dark palette:
/// tint `#0a7ea4` in light mode, white in dark mode.
class AppTheme {
  static const _lightTint = Color(0xFF0A7EA4);
  static const _darkTint = Color(0xFFFFFFFF);
  static const addToCartGreen = Color(0xFF2E7D32);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: _lightTint,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: _darkTint,
        scaffoldBackgroundColor: const Color(0xFF151718),
      );
}
