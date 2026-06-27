import 'package:flutter/animation.dart';

class AppMotion {
  const AppMotion._();

  static const Duration fadeDuration = Duration(milliseconds: 180);
  static const Duration slideDuration = Duration(milliseconds: 240);
  static const Duration scaleDuration = Duration(milliseconds: 220);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve fastCurve = Curves.easeOut;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
}
