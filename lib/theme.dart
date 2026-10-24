import 'package:flutter/material.dart';

/// START HERE to restyle the app: colours, fonts, corner radius.
/// Baby pink and brown, soft and warm.
/// Individual screens are in lib/pages/ (layout and widgets only, no logic).
class AppColors {
  static const seed = Color(0xFFF4B6C8); // baby pink, base of the palette
  static const brown = Color(0xFF6B4A3F); // main buttons and icons
  static const darkBrown = Color(0xFF3E2A25); // text
  static const pinkBg = Color(0xFFFFF3F6); // screen background
  static const babyPink = Color(0xFFF8D4DF); // highlights
  static const sosButton = Color(0xFF8D5B4C); // big SOS circle
  static const warningBg = Color(0xFFFFE3EA); // pink info cards
  static const infoBg = Color(0xFFF7EAE6); // beige info cards
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.brown,
    onPrimary: Colors.white,
    primaryContainer: AppColors.babyPink,
    onPrimaryContainer: AppColors.darkBrown,
    secondary: AppColors.sosButton,
    onSecondary: Colors.white,
    surface: AppColors.pinkBg,
    onSurface: AppColors.darkBrown,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.pinkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.pinkBg,
      foregroundColor: AppColors.darkBrown,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFFBE3EA),
      indicatorColor: AppColors.seed,
    ),
    // fontFamily: 'YourFont',   // add the font in pubspec.yaml first
  );
}
