import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:flutter/material.dart';

/// Frosted container used for modern settings surfaces.
class GlassCard extends StatefulWidget {
  /// Creates a glass-style card.
  const GlassCard({super.key, required this.child, this.enablePress = true});

  /// Card content.
  final Widget child;

  /// Whether the card should run its built-in pressed visual state.
  final bool enablePress;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: widget.enablePress ? (_) => _setPressed(true) : null,
        onTapCancel: widget.enablePress ? () => _setPressed(false) : null,
        onTapUp: widget.enablePress ? (_) => _setPressed(false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: _pressed
                      ? (isDark ? 0.20 : 0.08)
                      : (isDark ? 0.28 : 0.12),
                ),
                blurRadius: _pressed ? 24 : 42,
                offset: Offset(0, _pressed ? 12 : 24),
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: _pressed ? 0.04 : 0.08,
                ),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.62)
                  : colorScheme.surface.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.52),
              ),
              backgroundBlendMode: BlendMode.softLight,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.06 : 0.30),
                  colorScheme.primary.withValues(alpha: isDark ? 0.04 : 0.03),
                ],
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
