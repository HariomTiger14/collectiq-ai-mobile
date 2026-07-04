import 'package:collectiq_ai/core/theme/design_system.dart';
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
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.24 : 0.16,
                ),
                blurRadius: isDark ? 28 : 42,
                offset: const Offset(0, -14),
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 34,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: RepaintBoundary(
            child: Container(
              height: 78,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.86,
                      )
                    : colorScheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.58),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.06 : 0.24),
                    colorScheme.primary.withValues(alpha: 0.04),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: _hovered
                ? colors.last.withValues(alpha: isDark ? 0.14 : 0.10)
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
                            width: widget.isActive ? 50 : 0,
                            height: 34,
                            duration: navSpringDuration,
                            curve: PackLoxMotionTheme.navSpringCurve,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: widget.isActive
                                  ? Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                    )
                                  : null,
                              boxShadow: widget.isActive
                                  ? [
                                      BoxShadow(
                                        color: colors.last.withValues(
                                          alpha: isDark ? 0.22 : 0.28,
                                        ),
                                        blurRadius: 22,
                                        offset: const Offset(0, 10),
                                      ),
                                    ]
                                  : const [],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: const SizedBox.expand(),
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
                            size: widget.isActive
                                ? AppIconSizes.md
                                : AppIconSizes.md,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedDefaultTextStyle(
                    duration: PackLoxMotionTheme.medium,
                    curve: PackLoxMotionTheme.hoverCurve,
                    style:
                        textTheme.labelSmall?.copyWith(
                          color: widget.isActive
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontWeight: widget.isActive
                              ? FontWeight.w800
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
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                colors.last.withValues(alpha: 0.85),
                colors.first.withValues(alpha: 0),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
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
