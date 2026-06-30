import 'package:flutter/material.dart';

class AppColors {
  // اللوحة الأساسية
  static const burgundy = Color(0xFF7B0D2A);
  static const burgundyLight = Color(0xFFA01535);
  static const burgundyMid = Color(0xFFD42B4A);
  static const apricot = Color(0xFFFF6B2B);
  static const apricotLight = Color(0xFFFF9A55);
  static const apricotPale = Color(0xFFFFCC99);

  static const brandPrimary = burgundy;
  static const brandAccent = apricot;
  static const brandSurface = apricotPale;

  // خلفيات
  static const burgundyBackground = Color(0xFFFFCCD8);
  static const offWhiteCream = Color(0xFFFFE8CC);
  static const cardCream = Color(0xFFFFD4A0);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D0510),
      Color(0xFF7B0D2A),
      Color(0xFFB01F3A),
      Color(0xFFD94030),
      Color(0xFFFF6B2B),
    ],
  );

  static const ratingGreen = Color(0xFF1E8C4A);
  static const ratingBlue = brandPrimary;
  static const ratingOrange = apricot;
  static const ratingRed = Color(0xFFCC1A1A);
}
