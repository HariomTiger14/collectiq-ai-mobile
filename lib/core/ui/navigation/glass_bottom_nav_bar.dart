import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(1);
    final navHeight = textScale >= 1.6 ? 88.0 : 76.0;

    return ColoredBox(
      key: const ValueKey('bottom-navigation-safe-area-surface'),
      color: PackLoxTokens.background,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: 'Primary navigation',
          child: Container(
            constraints: BoxConstraints(minHeight: navHeight),
            decoration: BoxDecoration(
              color: PackLoxTokens.surface.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: PackLoxTokens.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 22,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: NavBarItem(
                      key:
                          items[index].key ??
                          ValueKey(
                            '${items[index].label}-${currentIndex == index}',
                          ),
                      icon: items[index].icon,
                      selectedIcon: items[index].selectedIcon,
                      iconAsset: items[index].iconAsset,
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
    );
  }
}

class NavBarItem extends StatelessWidget {
  const NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.selectedIcon,
    this.iconAsset,
    this.gradientStyle = GradientStyle.blueIndigo,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String? iconAsset;
  final String label;
  final bool isActive;
  final GradientStyle gradientStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    final duration = reduceMotion ? Duration.zero : PackLoxMotionTheme.fast;
    final foreground = isActive
        ? PackLoxTokens.textPrimary
        : PackLoxTokens.textSecondary;
    final borderColor = isActive
        ? PackLoxTokens.cyan.withValues(alpha: 0.72)
        : Colors.transparent;
    final fillColor = isActive
        ? PackLoxTokens.blue.withValues(alpha: 0.28)
        : Colors.transparent;
    final effectiveIcon = isActive ? selectedIcon ?? icon : icon;

    final content = AnimatedContainer(
      duration: duration,
      curve: PackLoxMotionTheme.navStateCurve,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: iconAsset == null
                ? Icon(effectiveIcon, color: foreground, size: 23)
                : SvgPicture.asset(
                    iconAsset!,
                    width: 23,
                    height: 23,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  height: 1.08,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      excludeSemantics: true,
      child: MotionTapScale(
        onTap: onTap,
        scale: reduceMotion ? 1 : PackLoxMotionTheme.tapScale,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: content,
        ),
      ),
    );
  }
}
