import 'package:flutter/material.dart';

class AppColors {
  static const cyan = Color(0xFF29E7F5);
  static const mint = Color(0xFF25FCC3);
  static const lime = Color(0xFFC3FC25);
  static const purple = Color(0xFF7C1D93);

  // Derived
  static const purpleDark = Color(0xFF3D0A52);
  static const purpleDeep = Color(0xFF1A0530);
  static const purpleMid = Color(0xFF9B35B0);

  // Aliases used across the app
  static const burgundy = cyan;
  static const burgundyLight = mint;
  static const burgundyMid = mint;
  static const apricot = cyan;
  static const apricotLight = mint;
  static const apricotPale = lime;

  static const brandPrimary = purple;
  static const brandAccent = cyan;
  static const brandSurface = purpleDark;

  // Backgrounds (dark purple theme)
  static const burgundyBackground = purpleDeep;
  static const offWhiteCream = purpleDeep;
  static const cardCream = purpleDark;

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D0218),
      Color(0xFF3D0A52),
      Color(0xFF7C1D93),
      Color(0xFF29B8C5),
      Color(0xFF29E7F5),
    ],
  );

  static const ratingGreen = mint;
  static const ratingBlue = cyan;
  static const ratingOrange = lime;
  static const ratingRed = Color(0xFFFF2D6B);
}
