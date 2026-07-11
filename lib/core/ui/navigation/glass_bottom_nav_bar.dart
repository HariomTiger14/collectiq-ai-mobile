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
    final navChild = Row(
      children: [
        for (var index = 0; index < items.length; index++)
          Expanded(
            child: NavBarItem(
              key: ValueKey('${items[index].label}-${currentIndex == index}'),
              icon: items[index].icon,
              label: items[index].label,
              isActive: currentIndex == index,
              gradientStyle: items[index].gradientStyle,
              onTap: () => onTap(index),
            ),
          ),
      ],
    );

    final outerSurface = isDark
        ? colorScheme.surface
        : Theme.of(context).scaffoldBackgroundColor;
    return ColoredBox(
      key: const ValueKey('bottom-navigation-safe-area-surface'),
      color: outerSurface,
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
                  alpha: isDark ? 0.18 : 0.12,
                ),
                blurRadius: isDark ? 22 : 32,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.92)
                  : colorScheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.56),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: navChild,
          ),
        ),
      ),
    );
  }
}

class NavBarItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colorsFor(context, gradientStyle);
    final foreground = isActive
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: 0.68);
    final content = Container(
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: isActive
            ? colors.last.withValues(alpha: isDark ? 0.18 : 0.10)
            : Colors.transparent,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  gradient: isActive
                      ? LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive
                      ? null
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: isDark ? 0.34 : 0.0,
                        ),
                ),
                child: Icon(icon, color: foreground, size: AppIconSizes.md),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0,
                    ) ??
                    TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      excludeSemantics: true,
      child: MotionTapScale(
        onTap: onTap,
        scale: 0.97,
        child: AnimatedContainer(
          duration: PackLoxMotionTheme.fast,
          curve: PackLoxMotionTheme.navStateCurve,
          child: AnimatedSwitcher(
            duration: PackLoxMotionTheme.fast,
            switchInCurve: PackLoxMotionTheme.navStateCurve,
            switchOutCurve: PackLoxMotionTheme.navStateCurve,
            child: KeyedSubtree(key: ValueKey<bool>(isActive), child: content),
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
