import 'package:flutter/material.dart';

/// لوحة ألوان Apricot & Burgundy — محوّلة حرفيًا من AppTheme.swift
class AppColors {
  // اللوحة الأساسية
  static const burgundy = Color(0xFF6B1230); // 0.42, 0.10, 0.19
  static const burgundyLight = Color(0xFF8C2040); // 0.55, 0.13, 0.25
  static const burgundyMid = Color(0xFFBF384F); // 0.75, 0.22, 0.31
  static const apricot = Color(0xFFE88459); // 0.91, 0.52, 0.35
  static const apricotLight = Color(0xFFFDD6BF); // 0.99, 0.84, 0.75
  static const apricotPale = Color(0xFFFFF3E8); // 1.00, 0.95, 0.91

  static const brandPrimary = burgundy;
  static const brandAccent = apricot;
  static const brandSurface = apricotPale;

  // خلفيات
  static const burgundyBackground = Color(0xFFF7EEF0); // 0.97, 0.93, 0.94
  static const offWhiteCream = Color(0xFFFDF9F4); // 0.99, 0.98, 0.96
  static const cardCream = Color(0xFFFFF5E6); // 1.00, 0.96, 0.90

  // تدرّج الـ Hero (5 ألوان من CaseInputView)
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3D0D1A), // 0.24, 0.05, 0.10
      Color(0xFF6B1226), // 0.42, 0.07, 0.15
      Color(0xFF922140), // 0.57, 0.13, 0.25
      Color(0xFFC75747), // 0.78, 0.34, 0.28
      Color(0xFFE88459), // 0.91, 0.52, 0.35
    ],
  );

  // ألوان دلالية للتقييم
  static const ratingGreen = Color(0xFF2E9E5B);
  static const ratingBlue = brandPrimary;
  static const ratingOrange = apricot;
  static const ratingRed = Color(0xFFC0392B);
}
