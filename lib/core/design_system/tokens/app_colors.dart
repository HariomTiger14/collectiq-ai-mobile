import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF047857);
  static const Color primaryDark = Color(0xFF065F46);
  static const Color primaryLight = Color(0xFFD1FAE5);

  static const Color secondary = Color(0xFF0F172A);
  static const Color secondaryMuted = Color(0xFF334155);
  static const Color secondaryLight = Color(0xFFE2E8F0);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color estimatedValueGold = Color(0xFFD97706);
  static const Color confidenceBlue = Color(0xFF2563EB);

  static const Color overlay = Color(0x660F172A);
  static const Color shadow = Color(0x1A0F172A);

  // Backwards-compatible aliases for the pre-sprint token names.
  static const Color ink = textPrimary;
  static const Color mutedInk = textSecondary;
  static const Color canvas = background;
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color accent = primary;
  static const Color accentDeep = primaryDark;
  static const Color secondaryAccent = Color(0xFF14B8A6);
  static const Color danger = error;
}

class AppGradients {
  const AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premium = LinearGradient(
    colors: [AppColors.secondary, Color(0xFF12372F), AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
