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

  static const compactHeight = 60.0;
  static const largeTextHeight = 68.0;
  static const bottomBreathingGap = 14.0;

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
      minimum: const EdgeInsets.fromLTRB(30, 0, 30, 12),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Primary navigation',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: navHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF334155).withValues(alpha: 0.86),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: PackLoxTokens.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -1),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
    final foreground = isActive
        ? PackLoxTokens.textPrimary
        : const Color(0xFF94A3B8);
    final borderColor = isScanAction
        ? const Color(0xFF63B3FF).withValues(alpha: isActive ? 0.42 : 0.0)
        : isActive
        ? const Color(0xFF63B3FF).withValues(alpha: 0.34)
        : Colors.transparent;
    final fillColor = isScanAction
        ? const Color(0xFF0A84FF).withValues(alpha: isActive ? 1.0 : 0.0)
        : isActive
        ? const Color(0xFF0A84FF)
        : Colors.transparent;
    final effectiveIcon = isActive ? selectedIcon ?? icon : icon;

    final content = AnimatedContainer(
      duration: duration,
      curve: PackLoxMotionTheme.navStateCurve,
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      padding: EdgeInsets.symmetric(
        horizontal: isScanAction ? 8 : 7,
        vertical: isScanAction ? 8 : 7,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(
          isScanAction || isActive ? 999 : AppRadius.lg,
        ),
        border: Border.all(color: borderColor),
        boxShadow: isScanAction && isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: ExcludeSemantics(
          child: iconAsset == null
              ? Icon(
                  effectiveIcon,
                  color: foreground,
                  size: isScanAction ? 24 : 22,
                )
              : SvgPicture.asset(
                  iconAsset!,
                  width: isScanAction ? 24 : 22,
                  height: isScanAction ? 24 : 22,
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
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
        scale: reduceMotion ? 1 : PackLoxMotionTheme.tapScale,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: content,
        ),
      ),
    );
  }
}
