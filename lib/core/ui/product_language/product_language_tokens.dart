import 'package:flutter/material.dart';

/// Frozen visual contract for PackLox Product Language PLX-PL-1.0.
abstract final class PackLoxTokens {
  static const background = Color(0xFF0B0F17);
  static const surface = Color(0xFF111827);
  static const surfaceRaised = Color(0xFF1A2233);
  static const border = Color(0xFF334155);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const blue = Color(0xFF2563EB);
  static const cyan = Color(0xFF22D3EE);
  static const amber = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF123C8F), Color(0xFF082C67)],
  );
}
