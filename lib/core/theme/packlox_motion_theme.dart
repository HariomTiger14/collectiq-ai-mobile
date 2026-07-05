import 'package:flutter/material.dart';

class PackLoxMotionTheme {
  const PackLoxMotionTheme._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration navSpringDuration = Duration(milliseconds: 260);

  static const Curve tapCurve = Curves.easeOutCubic;
  static const Curve revealCurve = Curves.easeOutCubic;
  static const Curve transitionCurve = Curves.easeInOutCubic;
  static const Curve hoverCurve = Curves.easeOutQuad;
  static const Curve navStateCurve = Curves.easeOutCubic;
  static Curve get navSpringCurve => Curves.easeOutBack;

  static const double tapScale = 0.96;

  static const double hoverOpacity = 0.08;
  static const double hoverBlurRadius = 14.0;

  static const double heroParallaxDepth = 18.0;
  static const double cardParallaxDepth = 6.0;

  static const Duration revealStagger = Duration(milliseconds: 60);

  static const Duration pulseDuration = Duration(milliseconds: 1800);
  static const Duration waveDuration = Duration(milliseconds: 2600);

  static Gradient ambientBlueIndigo(double t) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(Colors.indigo.shade400, Colors.blue.shade300, t)!,
        Color.lerp(Colors.blue.shade600, Colors.indigo.shade700, 1 - t)!,
      ],
    );
  }

  static Gradient ambientPurpleDeepBlue(double t) {
    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color.lerp(Colors.deepPurple.shade400, Colors.blue.shade300, t)!,
        Color.lerp(Colors.blue.shade700, Colors.deepPurple.shade600, 1 - t)!,
      ],
    );
  }

  static bool get isTestMode {
    var isWidgetTest = false;
    assert(() {
      isWidgetTest = WidgetsBinding.instance.runtimeType
          .toString()
          .toLowerCase()
          .contains('test');
      return true;
    }());
    return isWidgetTest;
  }

  static bool get ambientMotionEnabled => !isTestMode;
}
