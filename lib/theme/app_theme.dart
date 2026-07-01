import 'package:flutter/material.dart';

class AppColors {
  static const burgundy = Color(0xFFF3295C);
  static const burgundyLight = Color(0xFFF3295C);
  static const burgundyMid = Color.fromARGB(255, 238, 53, 84);
  static const apricot = Color(0xFFFFAA00);
  static const apricotLight = Color.from(alpha: 1, red: 0.996, green: 0.651, blue: 0.4);
  static const apricotPale = Color.fromARGB(255, 246, 212, 61);

  static const brandPrimary = Color.fromARGB(255, 254, 38, 92);
  static const brandAccent = Color(0xFFFFAA00);
  static const brandSurface = Color(0xFFFF537E);

  // Dark backgrounds
  static const burgundyBackground = Color.fromARGB(255, 172, 8, 63);
  static const offWhiteCream = Color.fromARGB(255, 170, 16, 67);
  static const cardCream = Color.fromARGB(255, 237, 20, 93);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(255, 245, 36, 106),
      Color.fromARGB(255, 230, 46, 92),
      Color.fromARGB(255, 209, 42, 81),
      Color(0xFFBB2020),
      Color.fromARGB(255, 255, 145, 0),
    ],
  );

  static const ratingGreen = Color.fromARGB(255, 3, 255, 120);
  static const ratingBlue = Color.fromARGB(255, 255, 34, 89);
  static const ratingOrange = apricot;
  static const ratingRed = Color.fromARGB(255, 255, 33, 70);
}
