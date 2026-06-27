import 'package:collectiq_ai/core/design_system/tokens/tokens.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.shadows = AppShadows.subtle,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: borderColor ?? colorScheme.outlineVariant,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.action,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      shadows: AppShadows.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
