import 'dart:io';
import 'dart:ui';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class AnalyzeAnimationOverlay extends StatefulWidget {
  const AnalyzeAnimationOverlay({
    required this.imagePath,
    this.qaProgress,
    super.key,
  });

  final String imagePath;
  final double? qaProgress;

  @override
  State<AnalyzeAnimationOverlay> createState() =>
      _AnalyzeAnimationOverlayState();
}

class _AnalyzeAnimationOverlayState extends State<AnalyzeAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final qaProgress = widget.qaProgress;
    if (qaProgress == null) {
      _controller.forward();
    } else {
      _controller.value = qaProgress.clamp(0, 1).toDouble();
    }
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.125, curve: Curves.easeOut),
    ).drive(Tween<double>(begin: 0.9, end: 1));
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          key: const ValueKey('analyze-blur-overlay'),
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.18),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scale,
                    builder: (context, child) {
                      return Transform.scale(scale: _scale.value, child: child);
                    },
                    child: Opacity(
                      opacity: 0.30,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: SizedBox.square(
                          key: const ValueKey('analyze-silhouette'),
                          dimension: 210,
                          child: _AnalyzeImage(path: widget.imagePath),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      final colorScheme = Theme.of(context).colorScheme;
                      final percent = (_progress.value * 100).round();
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            key: const ValueKey('analyze-progress-ring'),
                            size: const Size.square(252),
                            painter: _AnalyzeRingPainter(
                              progress: _progress.value,
                              color: colorScheme.primary,
                            ),
                          ),
                          DecoratedBox(
                            key: const ValueKey('analyze-progress-center'),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.56),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$percent%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                  Text(
                                    'Analyzing',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.78,
                                          ),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyzeImage extends StatelessWidget {
  const _AnalyzeImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('sample://')) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.style_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 72,
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return const ColoredBox(
      color: Color(0xFFE5E7EB),
      child: Icon(Icons.broken_image_outlined, size: 48),
    );
  }
}

class _AnalyzeRingPainter extends CustomPainter {
  const _AnalyzeRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 18) / 2;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.20), color, const Color(0xFF14B8A6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * progress,
      false,
      glowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalyzeRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
