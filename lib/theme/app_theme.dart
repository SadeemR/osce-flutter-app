import 'package:flutter/material.dart';

class AppColors {
  static const cyan = Color(0xFF29E7F5);
  static const mint = Color(0xFF25FCC3);
  static const lime = Color(0xFFC3FC25);
  static const purple = Color(0xFF7C1D93);

  // Light cyan + mint backgrounds
  static const purpleDeep = Color(0xFFCFFAF5);
  static const purpleDark = Color(0xFFB2F5EC);
  static const purpleMid = Color(0xFF9B35B0);

  // Aliases
  static const burgundy = purple;
  static const burgundyLight = Color(0xFF9B35B0);
  static const burgundyMid = mint;
  static const apricot = cyan;
  static const apricotLight = mint;
  static const apricotPale = Color(0xFFD0FAF8);

  static const brandPrimary = purple;
  static const brandAccent = cyan;
  static const brandSurface = purpleDark;

  static const burgundyBackground = purpleDeep;
  static const offWhiteCream = purpleDeep;
  static const cardCream = purpleDark;

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4A0A6B),
      Color(0xFF7C1D93),
      Color(0xFF29B8C5),
      Color(0xFF29E7F5),
      Color(0xFF25FCC3),
    ],
  );

  static const ratingGreen = mint;
  static const ratingBlue = cyan;
  static const ratingOrange = lime;
  static const ratingRed = Color(0xFFFF2D6B);
}
