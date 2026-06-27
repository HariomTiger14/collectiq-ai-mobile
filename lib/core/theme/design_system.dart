import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

class AppElevation {
  const AppElevation._();

  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x100F172A), blurRadius: 28, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> accentGlow = [
    BoxShadow(color: Color(0x332563EB), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

class AppTextStyles {
  const AppTextStyles._();

  static const h1 = TextStyle(
    fontSize: 32,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const h2 = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const caption = TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
}

class AppColors {
  const AppColors._();

  static const ink = Color(0xFF111827);
  static const mutedInk = Color(0xFF6B7280);
  static const canvas = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F3F5);
  static const border = Color(0xFFE5E7EB);
  static const accent = Color(0xFF2563EB);
  static const accentDeep = Color(0xFF1D4ED8);
  static const secondaryAccent = Color(0xFF14B8A6);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
}

class AppGradients {
  const AppGradients._();

  static const primary = LinearGradient(
    colors: [AppColors.accent, Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const premium = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF1E1B4B), AppColors.accentDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
