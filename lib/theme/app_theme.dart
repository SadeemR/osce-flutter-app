import 'package:flutter/material.dart';

class AppColors {
  static const burgundy = Color(0xFFCC0033);
  static const burgundyLight = Color(0xFFEE1144);
  static const burgundyMid = Color(0xFFFF3355);
  static const apricot = Color(0xFFFF6600);
  static const apricotLight = Color(0xFFFF8833);
  static const apricotPale = Color(0xFFFF4400);

  static const brandPrimary = burgundy;
  static const brandAccent = apricot;
  static const brandSurface = Color(0xFF2A0A12);

  // Dark backgrounds111
  static const burgundyBackground = Color(0xFF120308);
  static const offWhiteCream = Color(0xFF1A0510);
  static const cardCream = Color(0xFF2A0A18);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0205),
      Color(0xFF3D0815),
      Color(0xFF7A0F28),
      Color(0xFFBB2020),
      Color(0xFFFF6600),
    ],
  );

  static const ratingGreen = Color(0xFF00DD66);
  static const ratingBlue = brandPrimary;
  static const ratingOrange = apricot;
  static const ratingRed = Color(0xFFFF2200);
}
