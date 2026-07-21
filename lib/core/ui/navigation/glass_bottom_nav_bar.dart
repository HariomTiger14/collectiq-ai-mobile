import 'dart:ui';

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

  static const compactHeight = 68.0;
  static const largeTextHeight = 78.0;
  static const bottomBreathingGap = 16.0;

  static double heightFor(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaler.scale(1);
    return textScale >= 1.6 ? largeTextHeight : compactHeight;
  }

  static double scrollContentClearance(BuildContext context) {
    return heightFor(context) + AppSpacing.xs + bottomBreathingGap;
  }

  static double bodyContentInset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return heightFor(context) + mediaQuery.padding.bottom + AppSpacing.xs;
  }

  @override
  Widget build(BuildContext context) {
    final navHeight = heightFor(context);

    return SafeArea(
      key: const ValueKey('bottom-navigation-safe-area-surface'),
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Primary navigation',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              constraints: BoxConstraints(minHeight: navHeight),
              decoration: BoxDecoration(
                color: PackLoxTokens.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: PackLoxTokens.cyan.withValues(alpha: 0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: PackLoxTokens.cyan.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
    final isScanAction = label == 'Scan';
    final foreground = isScanAction
        ? isActive
              ? PackLoxTokens.textPrimary
              : PackLoxTokens.cyan
        : isActive
        ? PackLoxTokens.textPrimary
        : PackLoxTokens.textSecondary;
    final borderColor = isScanAction
        ? PackLoxTokens.cyan.withValues(alpha: isActive ? 0.58 : 0.24)
        : isActive
        ? PackLoxTokens.cyan.withValues(alpha: 0.38)
        : Colors.transparent;
    final fillColor = isScanAction
        ? PackLoxTokens.blue.withValues(alpha: isActive ? 0.72 : 0.12)
        : isActive
        ? PackLoxTokens.cyan.withValues(alpha: 0.12)
        : Colors.transparent;
    final effectiveIcon = isActive ? selectedIcon ?? icon : icon;

    final content = AnimatedContainer(
      duration: duration,
      curve: PackLoxMotionTheme.navStateCurve,
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(
        horizontal: isScanAction ? 8 : 6,
        vertical: isScanAction ? 7 : 5,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(
          isScanAction ? AppRadius.xl : AppRadius.lg,
        ),
        border: Border.all(color: borderColor),
        boxShadow: isScanAction && isActive
            ? [
                BoxShadow(
                  color: PackLoxTokens.blue.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: iconAsset == null
                ? Icon(
                    effectiveIcon,
                    color: foreground,
                    size: isScanAction ? 23 : 21,
                  )
                : SvgPicture.asset(
                    iconAsset!,
                    width: isScanAction ? 23 : 21,
                    height: isScanAction ? 23 : 21,
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
                  fontSize: isScanAction ? 12.5 : 12,
                  height: 1.08,
                  fontWeight: isScanAction || isActive
                      ? FontWeight.w800
                      : FontWeight.w700,
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
