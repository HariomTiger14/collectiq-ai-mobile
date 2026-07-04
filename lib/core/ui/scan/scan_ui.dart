import 'dart:ui';

import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class ScanHeroHeader extends StatelessWidget {
  const ScanHeroHeader({
    super.key,
    required this.scrollController,
    this.gradientStyle = GradientStyle.tealEmerald,
  });

  final ScrollController scrollController;
  final GradientStyle gradientStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colorsFor(context, gradientStyle);

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        final parallax = scrollOffset.clamp(0, 120).toDouble();

        return MotionElasticHero(
          baseHeight: 168,
          scrollOffset: scrollOffset,
          child: MotionParallax(
            scrollOffset: scrollOffset,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: MotionAmbientGradient(
                gradientBuilder: _ambientGradientFor(gradientStyle),
                child: Container(
                  height: 168,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withValues(
                          alpha: isDark ? 0.18 : 0.26,
                        ),
                        blurRadius: isDark ? 24 : 34,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -18 + parallax * 0.08,
                        top: -34,
                        child: _HeaderOrb(color: colorScheme.onPrimary),
                      ),
                      Positioned(
                        right: 62 - parallax * 0.04,
                        bottom: -52,
                        child: _HeaderOrb(
                          color: colorScheme.onPrimary,
                          size: 120,
                          opacity: 0.06,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: Offset(0, parallax * 0.04),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Scan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.04,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Powered by PackLox Intelligence',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.82,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ScanPreviewGlassFrame extends StatefulWidget {
  const ScanPreviewGlassFrame({
    super.key,
    required this.child,
    this.isAnalyzing = false,
  });

  final Widget child;
  final bool isAnalyzing;

  @override
  State<ScanPreviewGlassFrame> createState() => _ScanPreviewGlassFrameState();
}

class _ScanPreviewGlassFrameState extends State<ScanPreviewGlassFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.pulseDuration * 2,
    );
    if (_scanMotionEnabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _FadeSlideUp(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = Curves.easeInOut.transform(_controller.value);
          final glowAlpha = widget.isAnalyzing ? 0.22 : 0.10 + pulse * 0.06;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: isDark ? 0.18 : 0.10,
                  ),
                  blurRadius: isDark ? 22 : 34,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: glowAlpha),
                  blurRadius: 24 + pulse * 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          )
                        : colorScheme.surface.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.primary.withValues(
                        alpha: 0.14 + pulse * 0.08,
                      ),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      child!,
                      if (widget.isAnalyzing)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.10),
                                    Colors.transparent,
                                    colorScheme.tertiary.withValues(
                                      alpha: 0.08,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class ScanWaveAnimation extends StatefulWidget {
  const ScanWaveAnimation({super.key, this.height = 82});

  final double height;

  @override
  State<ScanWaveAnimation> createState() => _ScanWaveAnimationState();
}

class _ScanWaveAnimationState extends State<ScanWaveAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.waveDuration * 3,
    );
    if (_scanMotionEnabled) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _FadeSlideUp(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ScanWavePainter(
                progress: _controller.value,
                color: colorScheme.primary,
                opacity: isDark ? 0.16 : 0.22,
              ),
            );
          },
        ),
      ),
    );
  }
}

class ScanStatusBar extends StatelessWidget {
  const ScanStatusBar({
    super.key,
    required this.status,
    this.confidence,
    this.detectedCategory,
  });

  final String status;
  final double? confidence;
  final String? detectedCategory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidenceLabel = confidence == null
        ? null
        : 'AI Confidence: ${(confidence! * 100).toStringAsFixed(0)}%';
    final categoryLabel =
        detectedCategory == null || detectedCategory!.trim().isEmpty
        ? null
        : 'Detected Category: $detectedCategory';

    return _FadeSlideUp(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                  : colorScheme.surface.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: isDark ? 0.12 : 0.07,
                  ),
                  blurRadius: isDark ? 20 : 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: PackLoxMotionTheme.medium,
                  switchInCurve: PackLoxMotionTheme.revealCurve,
                  switchOutCurve: PackLoxMotionTheme.transitionCurve,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.18),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey('$status-$confidenceLabel-$categoryLabel'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MotionStagger(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  confidenceLabel != null ||
                                      categoryLabel != null
                                  ? 8
                                  : 0,
                            ),
                            child: Text(
                              status,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          if (confidenceLabel != null)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: categoryLabel != null ? 4 : 0,
                              ),
                              child: Text(
                                confidenceLabel,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          if (categoryLabel != null)
                            Text(
                              categoryLabel,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 3,
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.tertiary.withValues(alpha: 0.78),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScanActionButtons extends StatelessWidget {
  const ScanActionButtons({
    super.key,
    required this.onStart,
    required this.onRetake,
    required this.onSave,
    this.onCamera,
    this.onGallery,
    this.onSample,
    this.isBusy = false,
    this.canRetake = false,
    this.canSave = false,
    this.isSaved = false,
  });

  final VoidCallback? onStart;
  final VoidCallback? onRetake;
  final VoidCallback? onSave;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onSample;
  final bool isBusy;
  final bool canRetake;
  final bool canSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideUp(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final startLabel = canRetake && !canSave && !isSaved
                  ? 'Analyze with AI'
                  : 'Start Scan';
              final buttons = [
                _ScanGradientButton(
                  label: isBusy ? 'Analyzing...' : startLabel,
                  icon: isBusy
                      ? Icons.hourglass_top_outlined
                      : Icons.document_scanner_outlined,
                  onPressed: isBusy ? null : onStart,
                ),
                _ScanGradientButton(
                  label: 'Retake',
                  icon: Icons.replay_outlined,
                  onPressed: canRetake && !isBusy ? onRetake : null,
                  muted: true,
                ),
                _ScanGradientButton(
                  label: 'Save Item',
                  icon: isSaved
                      ? Icons.check_circle_outline
                      : Icons.add_circle_outline,
                  onPressed: canSave && !isBusy && !isSaved ? onSave : null,
                  muted: true,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    for (var index = 0; index < buttons.length; index++) ...[
                      Expanded(child: buttons[index]),
                      if (index != buttons.length - 1)
                        const SizedBox(width: 16),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < buttons.length; index++) ...[
                    buttons[index],
                    if (index != buttons.length - 1) const SizedBox(height: 16),
                  ],
                ],
              );
            },
          ),
          if (onCamera != null || onGallery != null || onSample != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (onCamera != null)
                  _ScanSecondaryButton(
                    icon: Icons.photo_camera_outlined,
                    label: 'Scan with Camera',
                    onPressed: isBusy ? null : onCamera,
                  ),
                if (onGallery != null)
                  _ScanSecondaryButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Choose from Gallery',
                    onPressed: isBusy ? null : onGallery,
                  ),
                if (onSample != null)
                  _ScanSecondaryButton(
                    icon: Icons.science_outlined,
                    label: 'Use Sample Scan',
                    onPressed: isBusy ? null : onSample,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderOrb extends StatelessWidget {
  const _HeaderOrb({required this.color, this.size = 148, this.opacity = 0.08});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

class _ScanGradientButton extends StatefulWidget {
  const _ScanGradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool muted;

  @override
  State<_ScanGradientButton> createState() => _ScanGradientButtonState();
}

class _ScanGradientButtonState extends State<_ScanGradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: MotionTapScale(
        onTap: widget.onPressed,
        enabled: enabled,
        scale: 0.97,
        child: AnimatedContainer(
          duration: PackLoxMotionTheme.medium,
          curve: PackLoxMotionTheme.hoverCurve,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.muted
                  ? [
                      colorScheme.primary.withValues(
                        alpha: enabled ? 0.18 : 0.08,
                      ),
                      colorScheme.tertiary.withValues(
                        alpha: enabled ? 0.14 : 0.06,
                      ),
                    ]
                  : [
                      colorScheme.primary.withValues(
                        alpha: enabled ? 0.96 : 0.30,
                      ),
                      colorScheme.tertiary.withValues(
                        alpha: enabled ? 0.86 : 0.22,
                      ),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.primary.withValues(
                alpha: _hovered && enabled ? 0.28 : 0.12,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: _hovered && enabled
                      ? PackLoxMotionTheme.hoverOpacity
                      : 0.04,
                ),
                blurRadius: _hovered && enabled
                    ? PackLoxMotionTheme.hoverBlurRadius
                    : 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.muted
                      ? colorScheme.primary.withValues(
                          alpha: enabled ? 1 : 0.42,
                        )
                      : colorScheme.onPrimary.withValues(
                          alpha: enabled ? 1 : 0.56,
                        ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: widget.muted
                          ? colorScheme.onSurface.withValues(
                              alpha: enabled ? 1 : 0.44,
                            )
                          : colorScheme.onPrimary.withValues(
                              alpha: enabled ? 1 : 0.56,
                            ),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanSecondaryButton extends StatelessWidget {
  const _ScanSecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        minimumSize: const Size(128, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
    );
  }
}

class _FadeSlideUp extends StatelessWidget {
  const _FadeSlideUp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MotionReveal(child: child);
  }
}

class _ScanWavePainter extends CustomPainter {
  const _ScanWavePainter({
    required this.progress,
    required this.color,
    required this.opacity,
  });

  final double progress;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: opacity * 0.55),
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.45),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    for (var wave = 0; wave < 3; wave++) {
      final path = Path();
      final vertical = size.height * (0.30 + wave * 0.22);
      final amplitude = 10.0 + wave * 3;
      final phase = progress * size.width * 1.4 + wave * 52;
      path.moveTo(0, vertical);

      for (var x = 0.0; x <= size.width; x += 8) {
        final y =
            vertical + amplitude * (0.5 - ((x + phase) % 96) / 96).abs() * 2;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity;
  }
}

List<Color> _colorsFor(BuildContext context, GradientStyle style) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (style) {
    GradientStyle.blueIndigo =>
      isDark
          ? const [Color(0xFF1E40AF), Color(0xFF3730A3)]
          : const [Color(0xFF2563EB), Color(0xFF4F46E5)],
    GradientStyle.purpleDeepBlue =>
      isDark
          ? const [Color(0xFF5B21B6), Color(0xFF1E3A8A)]
          : const [Color(0xFF8B5CF6), Color(0xFF1D4ED8)],
    GradientStyle.tealEmerald =>
      isDark
          ? const [Color(0xFF0F766E), Color(0xFF047857)]
          : const [Color(0xFF14B8A6), Color(0xFF10B981)],
  };
}

Gradient Function(double) _ambientGradientFor(GradientStyle style) {
  return switch (style) {
    GradientStyle.purpleDeepBlue => PackLoxMotionTheme.ambientPurpleDeepBlue,
    GradientStyle.blueIndigo ||
    GradientStyle.tealEmerald => PackLoxMotionTheme.ambientBlueIndigo,
  };
}

bool get _scanMotionEnabled {
  var isWidgetTest = false;
  assert(() {
    isWidgetTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
    return true;
  }());

  return !isWidgetTest && PackLoxMotionTheme.ambientMotionEnabled;
}
