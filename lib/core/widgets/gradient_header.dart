import 'dart:ui';

import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:flutter/material.dart';

/// Available gradient treatments for settings section headers.
enum GradientStyle {
  /// Blue to indigo.
  blueIndigo,

  /// Purple to deep blue.
  purpleDeepBlue,

  /// Teal to emerald.
  tealEmerald,
}

class PackLoxGradients {
  const PackLoxGradients._();

  static List<Color> build(GradientStyle style, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (style) {
      GradientStyle.blueIndigo =>
        isDark
            ? const [Color(0xFF07111F), Color(0xFF1E40AF), Color(0xFF5E5CE6)]
            : const [Color(0xFF0A84FF), Color(0xFF1456D9), Color(0xFF5E5CE6)],
      GradientStyle.purpleDeepBlue =>
        isDark
            ? const [Color(0xFF1A103D), Color(0xFF5B21B6), Color(0xFF1E40AF)]
            : const [Color(0xFF8B5CF6), Color(0xFF5E5CE6), Color(0xFF0A84FF)],
      GradientStyle.tealEmerald =>
        isDark
            ? const [Color(0xFF062D35), Color(0xFF0F766E), Color(0xFF047857)]
            : const [Color(0xFF0A84FF), Color(0xFF14B8A6), Color(0xFF10B981)],
    };
  }
}

class HeroDecorativeCircle extends StatelessWidget {
  const HeroDecorativeCircle({
    required this.diameter,
    required this.strokeWidth,
    required this.opacity,
    super.key,
  });

  final double diameter;
  final double strokeWidth;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: opacity),
          width: strokeWidth,
        ),
      ),
    );
  }
}

class HeroSurfaceContainerHighest extends StatelessWidget {
  const HeroSurfaceContainerHighest({
    required this.height,
    required this.padding,
    required this.gradientStyle,
    required this.child,
    this.decorativeChildren = const [],
    super.key,
  });

  final double height;
  final EdgeInsetsGeometry padding;
  final GradientStyle gradientStyle;
  final Widget child;
  final List<Widget> decorativeChildren;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = PackLoxGradients.build(gradientStyle, context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xxl),
      ),
      child: Container(
        height: height,
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.xxl),
          ),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(
                alpha: isDark ? 0.20 : 0.26,
              ),
              blurRadius: 36,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(children: [...decorativeChildren, child]),
      ),
    );
  }
}

/// Compact rounded gradient header for settings sections.
class GradientHeader extends StatefulWidget {
  /// Creates a gradient header.
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.gradientStyle = GradientStyle.blueIndigo,
  });

  /// Header title.
  final String title;

  /// Optional supporting copy.
  final String? subtitle;

  /// Gradient color family.
  final GradientStyle gradientStyle;

  @override
  State<GradientHeader> createState() => _GradientHeaderState();
}

class _GradientHeaderState extends State<GradientHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = _colorsFor(context, widget.gradientStyle);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shift = _controller.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 92),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(colors.first, colors[1], shift * 0.16)!,
                    Color.lerp(colors[1], colors.last, shift * 0.10)!,
                    colors.last,
                  ],
                  begin: Alignment(-1 + shift * 0.26, -1),
                  end: Alignment(1 - shift * 0.20, 1),
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha: 0.24 + shift * 0.06),
                    blurRadius: 38,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -28,
                    top: -44,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 18,
                        ),
                      ),
                    ),
                  ),
                  DefaultTextStyle(
                    style: TextStyle(color: colorScheme.onPrimary),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.80,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _colorsFor(BuildContext context, GradientStyle style) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (style) {
      GradientStyle.blueIndigo =>
        isDark
            ? const [Color(0xFF07111F), Color(0xFF1E40AF), Color(0xFF5E5CE6)]
            : const [Color(0xFF0A84FF), Color(0xFF1456D9), Color(0xFF5E5CE6)],
      GradientStyle.purpleDeepBlue =>
        isDark
            ? const [Color(0xFF1A103D), Color(0xFF5B21B6), Color(0xFF1E40AF)]
            : const [Color(0xFF8B5CF6), Color(0xFF5E5CE6), Color(0xFF0A84FF)],
      GradientStyle.tealEmerald =>
        isDark
            ? const [Color(0xFF062D35), Color(0xFF0F766E), Color(0xFF047857)]
            : const [Color(0xFF0A84FF), Color(0xFF14B8A6), Color(0xFF10B981)],
    };
  }
}
