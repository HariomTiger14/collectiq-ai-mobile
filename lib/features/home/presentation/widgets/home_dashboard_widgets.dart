import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Evening, Harry',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Welcome back to CollectIQ AI',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class CollectionValueHero extends StatelessWidget {
  const CollectionValueHero({required this.totalValue, super.key});

  final double totalValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      shadows: AppShadows.medium,
      backgroundColor: colorScheme.primary,
      borderColor: colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Collection Value',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            formatDashboardCurrency(totalValue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Estimated market value',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class HomeQuickStats extends StatelessWidget {
  const HomeQuickStats({
    required this.itemCount,
    required this.averageConfidence,
    required this.lastScan,
    super.key,
  });

  final int itemCount;
  final String averageConfidence;
  final String lastScan;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = [
          MetricTile(
            label: 'Collectibles',
            value: itemCount.toString(),
            icon: Icons.inventory_2_outlined,
          ),
          MetricTile(
            label: 'Average Confidence',
            value: averageConfidence,
            icon: Icons.verified_outlined,
            valueColor: AppColors.confidenceBlue,
          ),
          MetricTile(
            label: 'Last Scan',
            value: lastScan,
            icon: Icons.history_outlined,
          ),
        ];

        if (constraints.maxWidth < AppBreakpoints.tablet) {
          return AppResponsiveColumn(spacing: AppSpacing.md, children: metrics);
        }

        return Row(
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              Expanded(child: metrics[index]),
              if (index != metrics.length - 1)
                const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({required this.items, super.key});

  final List<CollectibleItem> items;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveColumn(
      spacing: AppSpacing.md,
      children: [
        for (var index = 0; index < items.length; index++)
          DashboardFadeSlide(
            delay: Duration(milliseconds: 40 * index),
            child: _RecentActivityCard(item: items[index]),
          ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortfolioThumbnail(
            size: 72,
            child: _thumbnailForPath(item.imagePath),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.category} / ${formatDashboardDate(item.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  formatDashboardCurrency(item.estimatedValue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.estimatedValueGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _thumbnailForPath(String imagePath) {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty || normalizedPath.startsWith('sample://')) {
      return null;
    }

    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return Image.network(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    if (normalizedPath.startsWith('assets/')) {
      return Image.asset(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    return buildLocalPortfolioImage(
      imagePath: normalizedPath,
      fit: BoxFit.cover,
      placeholderBuilder: () => const SizedBox.shrink(),
    );
  }
}

class DashboardFadeSlide extends StatelessWidget {
  const DashboardFadeSlide({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slideDuration + delay,
      curve: AppMotion.standardCurve,
      builder: (context, value, child) {
        final delayedProgress = delay == Duration.zero
            ? value
            : (value - 0.16).clamp(0.0, 1.0);

        return Opacity(
          opacity: delayedProgress,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - delayedProgress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

String formatDashboardCurrency(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

String formatDashboardDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final itemDay = DateTime(date.year, date.month, date.day);
  final difference = today.difference(itemDay).inDays;

  if (difference == 0) {
    return 'Today';
  }
  if (difference == 1) {
    return 'Yesterday';
  }

  final month = _monthLabels[date.month - 1];
  return '$month ${date.day}';
}

const _monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
