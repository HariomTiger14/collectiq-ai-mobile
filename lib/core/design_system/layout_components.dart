import 'dart:ui';

import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:flutter/material.dart';

class AppTwoLineTitle extends StatelessWidget {
  const AppTwoLineTitle(this.text, {this.style, this.textAlign, super.key});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: style,
    );
  }
}

class AppLabelValueRow extends StatelessWidget {
  const AppLabelValueRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.forceVertical = false,
    super.key,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool forceVertical;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack =
            forceVertical || constraints.maxWidth < 340 || value.length > 24;

        final labelWidget = Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        );
        final valueWidget = Text(
          value,
          maxLines: shouldStack ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: shouldStack ? TextAlign.start : TextAlign.end,
          style:
              valueStyle ??
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        );

        if (shouldStack) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: AppSpacing.xs),
                valueWidget,
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: labelWidget),
              const SizedBox(width: AppSpacing.md),
              Flexible(child: valueWidget),
            ],
          ),
        );
      },
    );
  }
}

class AppMetadataItem {
  const AppMetadataItem({required this.label, required this.value});

  final String label;
  final String value;
}

class AppMetadataList extends StatelessWidget {
  const AppMetadataList({required this.items, super.key});

  final List<AppMetadataItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          AppLabelValueRow(label: item.label, value: item.value),
      ],
    );
  }
}

class AppInfoSection extends StatelessWidget {
  const AppInfoSection({
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    super.key,
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
                : colorScheme.surface.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
            ),
            boxShadow: AppElevation.level2,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.05 : 0.28),
                colorScheme.primary.withValues(alpha: 0.025),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTwoLineTitle(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

enum PremiumBadgeTone { primary, secondary, tertiary, success, neutral }

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    required this.label,
    this.icon,
    this.tone = PremiumBadgeTone.primary,
    this.compact = false,
    this.maxWidth = 128,
    super.key,
  });

  const PremiumBadge.confidence({
    required this.label,
    this.icon = Icons.verified_outlined,
    this.compact = false,
    this.maxWidth = 128,
    super.key,
  }) : tone = PremiumBadgeTone.primary;

  const PremiumBadge.trend({
    required this.label,
    this.icon = Icons.trending_up,
    this.compact = false,
    this.maxWidth = 128,
    super.key,
  }) : tone = PremiumBadgeTone.tertiary;

  const PremiumBadge.wishlist({
    required this.label,
    this.icon = Icons.bookmark_border_outlined,
    this.compact = false,
    this.maxWidth = 128,
    super.key,
  }) : tone = PremiumBadgeTone.success;

  const PremiumBadge.category({
    required this.label,
    this.icon = Icons.category_outlined,
    this.compact = false,
    this.maxWidth = 128,
    super.key,
  }) : tone = PremiumBadgeTone.secondary;

  final String label;
  final IconData? icon;
  final PremiumBadgeTone tone;
  final bool compact;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = _PremiumBadgeColors.from(colorScheme, tone);

    return Container(
      key: ValueKey('premium-badge-$label'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 12, color: colors.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBadgeColors {
  const _PremiumBadgeColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  factory _PremiumBadgeColors.from(
    ColorScheme colorScheme,
    PremiumBadgeTone tone,
  ) {
    return switch (tone) {
      PremiumBadgeTone.primary => _PremiumBadgeColors(
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
      PremiumBadgeTone.secondary => _PremiumBadgeColors(
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
      ),
      PremiumBadgeTone.tertiary => _PremiumBadgeColors(
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      ),
      PremiumBadgeTone.success => _PremiumBadgeColors(
        background: AppColors.success.withValues(alpha: 0.14),
        foreground: AppColors.success,
      ),
      PremiumBadgeTone.neutral => _PremiumBadgeColors(
        background: colorScheme.surfaceContainerHighest,
        foreground: colorScheme.onSurfaceVariant,
      ),
    };
  }
}

class AppMetricData {
  const AppMetricData({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;
}

class AppResponsiveMetricGroup extends StatelessWidget {
  const AppResponsiveMetricGroup({required this.metrics, super.key});

  final List<AppMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRows = constraints.maxWidth >= 620;
        if (useRows) {
          return Row(
            children: [
              for (final metric in metrics) ...[
                Expanded(child: _MetricCell(metric: metric)),
                if (metric != metrics.last)
                  const SizedBox(width: AppSpacing.md),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (final metric in metrics) ...[
              _MetricCell(metric: metric),
              if (metric != metrics.last) const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});

  final AppMetricData metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
        boxShadow: AppElevation.level1,
      ),
      child: Row(
        children: [
          if (metric.icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                metric.icon,
                color: colorScheme.primary,
                size: AppIconSizes.md,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppSegmentOption<T> {
  const AppSegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AppStableSegmentedSelector<T> extends StatelessWidget {
  const AppStableSegmentedSelector({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    super.key,
  });

  final List<AppSegmentOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final option in options) ...[
            Expanded(
              child: _StableSegment(
                label: option.label,
                isSelected: option.value == selectedValue,
                onPressed: () => onChanged(option.value),
              ),
            ),
            if (option != options.last) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class AppPriceHero extends StatelessWidget {
  const AppPriceHero({
    required this.label,
    required this.value,
    this.subtitle,
    super.key,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.premium,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppElevation.level3,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppProfileSection extends StatelessWidget {
  const AppProfileSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 360
        ? AppSpacing.md
        : width < 600
        ? AppSpacing.lg
        : AppSpacing.xl;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.60),
        ),
        boxShadow: AppElevation.level2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTwoLineTitle(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class AppCompactMetadata extends StatelessWidget {
  const AppCompactMetadata({required this.items, super.key});

  final List<AppMetadataItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          AppLabelValueRow(label: item.label, value: item.value),
      ],
    );
  }
}

class AppDangerAction extends StatelessWidget {
  const AppDangerAction({
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: colorScheme.error),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.48)),
        ),
      ),
    );
  }
}

class _StableSegment extends StatelessWidget {
  const _StableSegment({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : Colors.transparent,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
