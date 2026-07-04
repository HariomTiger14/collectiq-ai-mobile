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
  static const double xl = 24;
  static const double xxl = 32;
  static const double pill = 999;
}

class AppElevation {
  const AppElevation._();

  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 22, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x160F172A), blurRadius: 34, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x0AFFFFFF), blurRadius: 1, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 46, offset: Offset(0, 24)),
    BoxShadow(color: Color(0x0FFFFFFF), blurRadius: 1, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> accentGlow = [
    BoxShadow(color: Color(0x332563EB), blurRadius: 34, offset: Offset(0, 16)),
  ];
}

class AppTextStyles {
  const AppTextStyles._();

  static const h1 = TextStyle(
    fontSize: 34,
    height: 1.06,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const h2 = TextStyle(
    fontSize: 24,
    height: 1.14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const h3 = TextStyle(
    fontSize: 18,
    height: 1.22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
}

class AppColors {
  const AppColors._();

  static const ink = Color(0xFF111827);
  static const mutedInk = Color(0xFF6B7280);
  static const canvas = Color(0xFFF6F8FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEFF4FA);
  static const border = Color(0xFFDDE5EF);
  static const accent = Color(0xFF0A84FF);
  static const accentDeep = Color(0xFF1456D9);
  static const secondaryAccent = Color(0xFF14B8A6);
  static const violet = Color(0xFF7C3AED);
  static const glass = Color(0xBFFFFFFF);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
}

class AppGradients {
  const AppGradients._();

  static const primary = LinearGradient(
    colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const premium = LinearGradient(
    colors: [
      Color(0xFF07111F),
      Color(0xFF163A77),
      Color(0xFF5E5CE6),
      Color(0xFF14B8A6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppIconSizes {
  const AppIconSizes._();

  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;
  static const double xl = 34;
}
