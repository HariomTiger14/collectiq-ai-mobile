import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 28,
    height: 1.16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    height: 1.24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.48,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 1.36,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  // Backwards-compatible aliases for existing screens.
  static const TextStyle h1 = display;
  static const TextStyle h2 = title;
}
