import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({this.onScanPressed, super.key});

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final portfolio = ref.watch(portfolioControllerProvider);
    final orderedItems = portfolio.orderedItems;
    final recentItems = orderedItems.take(3).toList();
    final insights = _HomeInsights.fromItems(orderedItems);
    _logHomeOrder(recentItems);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FadeSlideIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Evening, Harry',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.12,
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (orderedItems.isEmpty)
                    _EmptyDashboardHero(onScanPressed: onScanPressed)
                  else
                    _CollectionHero(insights: insights),
                  const SizedBox(height: AppSpacing.xl),
                  _PrimaryScanButton(onPressed: onScanPressed),
                  if (orderedItems.isEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _HomeEmptyState(onScanPressed: onScanPressed),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _DashboardInsights(insights: insights),
                    const SizedBox(height: AppSpacing.xxl),
                    _CategoryBreakdownSection(insights: insights),
                    const SizedBox(height: AppSpacing.xxl),
                    _PortfolioHighlights(
                      insights: insights,
                      onOpenItem: (item) =>
                          _openCollectibleDetail(context, item),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _SectionHeader(
                      title: 'Recent Activity',
                      subtitle:
                          'Latest saved collectibles from your collection.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RecentActivityList(
                      items: recentItems,
                      onOpenItem: (item) =>
                          _openCollectibleDetail(context, item),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _openCollectibleDetail(BuildContext context, CollectibleItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CollectibleDetailPage(item: item)));
}

void _logHomeOrder(List<CollectibleItem> items) {
  debugPrint(
    '[Home] Recent Activity final order: '
    '${items.map((item) => '${item.id}@${collectibleDisplayTimestamp(item).toIso8601String()}').join(' > ')}',
  );
  for (final item in items) {
    debugPrint(
      '[Home] Recent Activity item '
      'id=${item.id} '
      'title="${item.title}" '
      'imageSource=${_imageSourceFor(item.imagePath)} '
      'createdAt=${item.createdAt.toIso8601String()} '
      'savedAt=${item.createdAt.toIso8601String()} '
      'updatedAt=not-tracked '
      'displayTimestamp='
      '${collectibleDisplayTimestamp(item).toIso8601String()}',
    );
  }
}

String _imageSourceFor(String imagePath) {
  final normalizedPath = imagePath.trim();
  if (normalizedPath.startsWith('sample://')) {
    return 'sample';
  }
  if (normalizedPath.startsWith('http://') ||
      normalizedPath.startsWith('https://')) {
    return 'network';
  }
  if (normalizedPath.startsWith('assets/')) {
    return 'asset';
  }
  if (normalizedPath.isEmpty) {
    return 'missing';
  }

  return 'local';
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({required this.insights});

  final _HomeInsights insights;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _FadeSlideIn(
      delay: const Duration(milliseconds: 80),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppElevation.accentGlow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collection Value',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _formatAud(insights.totalValue),
              style: textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Estimated market value across ${insights.itemCount} collectibles',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Text(
                'Top asset: ${insights.highestValueItem?.title ?? 'None yet'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboardHero extends StatelessWidget {
  const _EmptyDashboardHero({required this.onScanPressed});

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 80),
      child: AppInfoSection(
        title: 'Build your collection dashboard',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan your first collectible to unlock portfolio value, category insights, highlights, and recent activity.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onScanPressed,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Start First Scan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryScanButton extends StatelessWidget {
  const _PrimaryScanButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan Collectible'),
      ),
    );
  }
}

class _DashboardInsights extends StatelessWidget {
  const _DashboardInsights({required this.insights});

  final _HomeInsights insights;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 120),
      child: AppInfoSection(
        title: 'Dashboard Insights',
        child: AppResponsiveMetricGroup(
          metrics: [
            AppMetricData(
              label: 'Total Collectibles',
              value: insights.itemCount.toString(),
              icon: Icons.inventory_2_outlined,
            ),
            AppMetricData(
              label: 'Average Item Value',
              value: _formatAud(insights.averageItemValue),
              icon: Icons.payments_outlined,
            ),
            AppMetricData(
              label: 'Recently Added',
              value: insights.recentlyAddedCount.toString(),
              icon: Icons.fiber_new_outlined,
            ),
            AppMetricData(
              label: 'Average Confidence',
              value: _formatPercent(insights.averageConfidence),
              icon: Icons.verified_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({required this.insights});

  final _HomeInsights insights;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 160),
      child: AppInfoSection(
        title: 'Category Breakdown',
        child: Column(
          children: [
            for (final category in _DashboardCategory.values) ...[
              _CategoryBreakdownBar(
                label: category.label,
                count: insights.categoryCounts[category] ?? 0,
                total: insights.itemCount,
              ),
              if (category != _DashboardCategory.values.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdownBar extends StatelessWidget {
  const _CategoryBreakdownBar({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fraction = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$count',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 9,
            width: double.infinity,
            color: colorScheme.surface,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PortfolioHighlights extends StatelessWidget {
  const _PortfolioHighlights({
    required this.insights,
    required this.onOpenItem,
  });

  final _HomeInsights insights;
  final ValueChanged<CollectibleItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 200),
      child: AppInfoSection(
        title: 'Portfolio Highlights',
        child: Column(
          children: [
            if (insights.highestValueItem != null)
              _HighlightRow(
                label: 'Highest Value Collectible',
                item: insights.highestValueItem!,
                value: _formatAud(insights.highestValueItem!.estimatedValue),
                icon: Icons.workspace_premium_outlined,
                onTap: () => onOpenItem(insights.highestValueItem!),
              ),
            if (insights.mostRecentItem != null) ...[
              const SizedBox(height: AppSpacing.md),
              _HighlightRow(
                label: 'Most Recent Collectible',
                item: insights.mostRecentItem!,
                value: _formatDate(insights.mostRecentItem!.createdAt),
                icon: Icons.history_outlined,
                onTap: () => onOpenItem(insights.mostRecentItem!),
              ),
            ],
            if (insights.strongestConfidenceItem != null) ...[
              const SizedBox(height: AppSpacing.md),
              _HighlightRow(
                label: 'Strongest Confidence Item',
                item: insights.strongestConfidenceItem!,
                value: _formatPercent(
                  insights.strongestConfidenceItem!.confidence,
                ),
                icon: Icons.verified_outlined,
                onTap: () => onOpenItem(insights.strongestConfidenceItem!),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _ReviewInsightRow(count: insights.lowConfidenceItems.length),
          ],
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.label,
    required this.item,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final CollectibleItem item;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTwoLineTitle(
                      item.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewInsightRow extends StatelessWidget {
  const _ReviewInsightRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final needsReview = count > 0;
    const warningColor = Color(0xFFD97706);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: needsReview
            ? warningColor.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: needsReview
              ? warningColor.withValues(alpha: 0.24)
              : AppColors.success.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            needsReview
                ? Icons.priority_high_outlined
                : Icons.check_circle_outline,
            color: needsReview ? warningColor : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items Needing Review',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  needsReview
                      ? '$count low-confidence items may need a closer look.'
                      : 'No low-confidence items right now.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$count',
            style: textTheme.titleMedium?.copyWith(
              color: needsReview ? warningColor : AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.onScanPressed});

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: colorScheme.primary,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No collectibles scanned yet.',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Start with a camera scan or gallery upload.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onScanPressed,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Start Scanning'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.items, required this.onOpenItem});

  final List<CollectibleItem> items;
  final ValueChanged<CollectibleItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _FadeSlideIn(
            delay: Duration(milliseconds: 120 + items.indexOf(item) * 40),
            child: _RecentActivityItem(
              item: item,
              onTap: () => onOpenItem(item),
            ),
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  const _RecentActivityItem({required this.item, required this.onTap});

  final CollectibleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      key: ValueKey('home-recent-${item.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: AppElevation.level1,
          ),
          child: Row(
            children: [
              PortfolioThumbnail(imagePath: item.imagePath, size: 64),
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
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _ActivityBadge(label: item.category),
                        _ActivityBadge(label: item.condition),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Saved ${_formatDate(item.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAud(item.estimatedValue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.marketSummary?.trendLabel ?? 'Stable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.secondaryAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
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

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final eased = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

String _formatAud(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return 'AUD $withCommas';
}

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(0)}%';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

enum _DashboardCategory {
  cards(label: 'Cards'),
  coins(label: 'Coins'),
  comics(label: 'Comics'),
  memorabilia(label: 'Memorabilia'),
  other(label: 'Other');

  const _DashboardCategory({required this.label});

  final String label;
}

class _HomeInsights {
  const _HomeInsights({
    required this.items,
    required this.totalValue,
    required this.itemCount,
    required this.averageItemValue,
    required this.averageConfidence,
    required this.recentlyAddedCount,
    required this.categoryCounts,
    required this.lowConfidenceItems,
    this.highestValueItem,
    this.mostRecentItem,
    this.strongestConfidenceItem,
  });

  final List<CollectibleItem> items;
  final double totalValue;
  final int itemCount;
  final double averageItemValue;
  final double averageConfidence;
  final int recentlyAddedCount;
  final Map<_DashboardCategory, int> categoryCounts;
  final List<CollectibleItem> lowConfidenceItems;
  final CollectibleItem? highestValueItem;
  final CollectibleItem? mostRecentItem;
  final CollectibleItem? strongestConfidenceItem;

  factory _HomeInsights.fromItems(List<CollectibleItem> orderedItems) {
    final items = List<CollectibleItem>.unmodifiable(orderedItems);
    final itemCount = items.length;
    final totalValue = items.fold<double>(
      0,
      (sum, item) => sum + item.estimatedValue,
    );
    final totalConfidence = items.fold<double>(
      0,
      (sum, item) => sum + item.confidence,
    );
    final categoryCounts = {
      for (final category in _DashboardCategory.values) category: 0,
    };
    for (final item in items) {
      final category = _categoryFor(item.category);
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final highestValueItem = _maxBy(items, (item) => item.estimatedValue);
    final strongestConfidenceItem = _maxBy(items, (item) => item.confidence);
    final mostRecentItem = items.isEmpty ? null : items.first;
    final newestTimestamp = items
        .map(collectibleDisplayTimestamp)
        .fold<DateTime?>(
          null,
          (latest, timestamp) =>
              latest == null || timestamp.isAfter(latest) ? timestamp : latest,
        );
    final recentCutoff = newestTimestamp?.subtract(const Duration(days: 7));
    final recentlyAddedCount = recentCutoff == null
        ? 0
        : items
              .where(
                (item) =>
                    !collectibleDisplayTimestamp(item).isBefore(recentCutoff),
              )
              .length;

    return _HomeInsights(
      items: items,
      totalValue: totalValue,
      itemCount: itemCount,
      averageItemValue: itemCount == 0 ? 0 : totalValue / itemCount,
      averageConfidence: itemCount == 0 ? 0 : totalConfidence / itemCount,
      recentlyAddedCount: recentlyAddedCount,
      categoryCounts: categoryCounts,
      highestValueItem: highestValueItem,
      mostRecentItem: mostRecentItem,
      strongestConfidenceItem: strongestConfidenceItem,
      lowConfidenceItems: items
          .where((item) => item.confidence < 0.75)
          .toList(growable: false),
    );
  }
}

CollectibleItem? _maxBy(
  List<CollectibleItem> items,
  double Function(CollectibleItem item) valueFor,
) {
  CollectibleItem? best;
  for (final item in items) {
    if (best == null || valueFor(item) > valueFor(best)) {
      best = item;
    }
  }

  return best;
}

_DashboardCategory _categoryFor(String category) {
  final value = category.toLowerCase();
  if (value.contains('card') || value.contains('tcg')) {
    return _DashboardCategory.cards;
  }
  if (value.contains('coin')) {
    return _DashboardCategory.coins;
  }
  if (value.contains('comic')) {
    return _DashboardCategory.comics;
  }
  if (value.contains('memorabilia') ||
      value.contains('sports') ||
      value.contains('autograph') ||
      value.contains('jersey')) {
    return _DashboardCategory.memorabilia;
  }

  return _DashboardCategory.other;
}
