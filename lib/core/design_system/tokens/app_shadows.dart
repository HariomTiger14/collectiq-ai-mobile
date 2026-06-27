import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static const List<BoxShadow> large = [
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 36, offset: Offset(0, 20)),
  ];

  static const List<BoxShadow> focus = [
    BoxShadow(color: Color(0x33047857), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

class AppElevation {
  const AppElevation._();

  static const List<BoxShadow> level1 = AppShadows.subtle;
  static const List<BoxShadow> level2 = AppShadows.medium;
  static const List<BoxShadow> level3 = AppShadows.large;
  static const List<BoxShadow> accentGlow = AppShadows.focus;
}
