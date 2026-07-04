import 'dart:ui';

import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MotionReveal(
      offset: 16,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
                blurRadius: isDark ? 22 : 34,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 74,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.48,
                        )
                      : colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(
                        alpha: isDark ? 0.20 : 0.36,
                      ),
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    for (var index = 0; index < items.length; index++)
                      Expanded(
                        child: NavBarItem(
                          key: items[index].key,
                          icon: items[index].icon,
                          label: items[index].label,
                          isActive: currentIndex == index,
                          gradientStyle: items[index].gradientStyle,
                          onTap: () => onTap(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavBarItem extends StatefulWidget {
  const NavBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    this.gradientStyle = GradientStyle.blueIndigo,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final GradientStyle gradientStyle;
  final VoidCallback? onTap;

  @override
  State<NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<NavBarItem> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) {
      return;
    }
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colorsFor(context, widget.gradientStyle);
    final foreground = widget.isActive
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: 0.68);
    final navSpringDuration = PackLoxMotionTheme.isTestMode
        ? Duration.zero
        : PackLoxMotionTheme.navSpringDuration;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: MotionTapScale(
        onTap: widget.onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: PackLoxMotionTheme.medium,
          curve: PackLoxMotionTheme.hoverCurve,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _hovered
                ? colors.last.withValues(alpha: isDark ? 0.10 : 0.08)
                : Colors.transparent,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              NavBarBackgroundGlow(
                isActive: widget.isActive,
                colors: colors,
                isDark: isDark,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 52,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedScale(
                          scale: widget.isActive ? 1.04 : 1,
                          duration: navSpringDuration,
                          curve: PackLoxMotionTheme.navSpringCurve,
                          child: AnimatedContainer(
                            width: widget.isActive ? 48 : 0,
                            height: 32,
                            duration: navSpringDuration,
                            curve: PackLoxMotionTheme.navSpringCurve,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: widget.isActive
                                  ? [
                                      BoxShadow(
                                        color: colors.last.withValues(
                                          alpha: isDark ? 0.22 : 0.28,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : const [],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: MotionAmbientGradient(
                              gradientBuilder: _ambientGradientFor(
                                widget.gradientStyle,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: navSpringDuration,
                          switchInCurve: PackLoxMotionTheme.navSpringCurve,
                          switchOutCurve: PackLoxMotionTheme.navSpringCurve,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.82, end: 1)
                                    .animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve:
                                            PackLoxMotionTheme.navSpringCurve,
                                      ),
                                    ),
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            widget.icon,
                            key: ValueKey('${widget.label}-${widget.isActive}'),
                            size: widget.isActive ? 20 : 22,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: PackLoxMotionTheme.medium,
                    curve: PackLoxMotionTheme.hoverCurve,
                    style:
                        textTheme.labelSmall?.copyWith(
                          color: widget.isActive
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontWeight: widget.isActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          letterSpacing: 0,
                        ) ??
                        TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavBarBackgroundGlow extends StatelessWidget {
  const NavBarBackgroundGlow({
    super.key,
    required this.isActive,
    required this.colors,
    required this.isDark,
  });

  final bool isActive;
  final List<Color> colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: isActive ? (isDark ? 0.18 : 0.12) : 0,
        duration: PackLoxMotionTheme.slow,
        curve: PackLoxMotionTheme.revealCurve,
        child: Container(
          width: 64,
          height: 44,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                colors.last.withValues(alpha: 0.85),
                colors.first.withValues(alpha: 0),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
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
          ? const [Color(0xFF6D28D9), Color(0xFF1E3A8A)]
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
