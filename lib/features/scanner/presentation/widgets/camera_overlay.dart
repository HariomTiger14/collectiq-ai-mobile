import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class CameraFocusRing extends StatelessWidget {
  const CameraFocusRing({required this.position, super.key});

  final Offset position;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('scan-focus-ring'),
      left: position.dx - 34,
      top: position.dy - 34,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.82, end: 1),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: IgnorePointer(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.22),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CameraGridOverlay extends StatelessWidget {
  const CameraGridOverlay({required this.visible, super.key});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        key: const ValueKey('scan-camera-grid'),
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: CustomPaint(painter: _CameraGridPainter()),
      ),
    );
  }
}

class AutoDetectOverlay extends StatelessWidget {
  const AutoDetectOverlay({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: DecoratedBox(
        key: ValueKey('scan-auto-detect-$label'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.50),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.34),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            key: const ValueKey('scan-auto-detect-label'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class CaptureFlashOverlay extends StatelessWidget {
  const CaptureFlashOverlay({required this.visible, super.key});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        key: const ValueKey('scan-capture-flash'),
        opacity: visible ? 0.40 : 0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: const ColoredBox(color: Colors.white),
      ),
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 1;
    for (final fraction in const [1 / 3, 2 / 3]) {
      final dx = size.width * fraction;
      final dy = size.height * fraction;
      canvas
        ..drawLine(Offset(dx, 0), Offset(dx, size.height), paint)
        ..drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CameraGridPainter oldDelegate) => false;
}
