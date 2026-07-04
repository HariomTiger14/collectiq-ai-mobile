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
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72, maxHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(colors.first, colors.last, shift * 0.16)!,
                Color.lerp(colors.last, colors.first, shift * 0.10)!,
              ],
              begin: Alignment(-1 + shift * 0.26, -1),
              end: Alignment(1 - shift * 0.20, 1),
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.22 + shift * 0.06),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: DefaultTextStyle(
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.subtitle != null &&
                    widget.subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ],
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
            ? const [Color(0xFF1E40AF), Color(0xFF3730A3)]
            : const [Color(0xFF2563EB), Color(0xFF4F46E5)],
      GradientStyle.purpleDeepBlue =>
        isDark
            ? const [Color(0xFF6D28D9), Color(0xFF1E3A8A)]
            : const [Color(0xFF8B5CF6), Color(0xFF1D4ED8)],
      GradientStyle.tealEmerald =>
        isDark
            ? const [Color(0xFF0F766E), Color(0xFF047857)]
            : const [Color(0xFF14B8A6), Color(0xFF10B981)],
    };
  }
}
