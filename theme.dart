import 'package:flutter/material.dart';

/// START HERE to restyle the app: colours, fonts, corner radius.
/// Individual screens are in lib/pages/ (layout and widgets only, no logic).
class AppColors {
  static const seed = Color(0xFFB71C1C); // main brand colour
  static const sosButton = Color(0xFFC62828); // big SOS circle
  static const warningBg = Color(0xFFFFECB3); // yellow info cards
  static const infoBg = Color(0xFFECEFF1); // grey info cards
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.seed,
    // fontFamily: 'YourFont',   // add the font in pubspec.yaml first
  );
}
