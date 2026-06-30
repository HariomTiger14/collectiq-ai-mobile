import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/domain/services/smart_collector_insights_service.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/portfolio_history_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
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
    final performance = ref.watch(
      portfolioPerformanceProvider(portfolio.items),
    );
    final alertSummary = ref.watch(priceAlertSummaryProvider(portfolio.items));
    final recentItems = orderedItems.take(3).toList();
    final insights = const CollectorDashboardAnalyticsService().build(
      orderedItems,
    );
    final smartIntelligence = const SmartCollectorInsightsService().build(
      insights,
    );
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
                    _PortfolioPerformanceSection(performance: performance),
                    const SizedBox(height: AppSpacing.xxl),
                    _PriceAlertSummarySection(summary: alertSummary),
                    const SizedBox(height: AppSpacing.xxl),
                    _CategoryBreakdownSection(insights: insights),
                    const SizedBox(height: AppSpacing.xxl),
                    _CollectionHealthSection(insights: insights),
                    const SizedBox(height: AppSpacing.xxl),
                    _CollectionScoreSection(intelligence: smartIntelligence),
                    const SizedBox(height: AppSpacing.xxl),
                    _SmartCollectorInsightsSection(
                      intelligence: smartIntelligence,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _AiCollectorRecommendationsSection(
                      intelligence: smartIntelligence,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _WishlistGoalsSection(intelligence: smartIntelligence),
                    const SizedBox(height: AppSpacing.xxl),
                    _AchievementsSection(intelligence: smartIntelligence),
                    const SizedBox(height: AppSpacing.xxl),
                    _PortfolioAnalyticsSection(
                      insights: insights,
                      onOpenItem: (item) =>
                          _openCollectibleDetail(context, item),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _InsightsSection(insights: insights),
                    const SizedBox(height: AppSpacing.xxl),
                    _RecommendationsSection(insights: insights),
                    const SizedBox(height: AppSpacing.xxl),
                    _TrendFoundationSection(insights: insights),
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

  final CollectorDashboardAnalytics insights;

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

  final CollectorDashboardAnalytics insights;

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

class _PortfolioPerformanceSection extends StatelessWidget {
  const _PortfolioPerformanceSection({required this.performance});

  final AsyncValue<PortfolioPerformance> performance;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 140),
      child: AppInfoSection(
        title: 'Portfolio Performance',
        child: performance.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppResponsiveMetricGroup(
                metrics: [
                  AppMetricData(
                    label: "Today's Change",
                    value: _formatChange(data.todayChange),
                    icon: Icons.today_outlined,
                  ),
                  AppMetricData(
                    label: 'Weekly Change',
                    value: _formatChange(data.weeklyChange),
                    icon: Icons.date_range_outlined,
                  ),
                  AppMetricData(
                    label: 'Monthly Change',
                    value: _formatChange(data.monthlyChange),
                    icon: Icons.calendar_month_outlined,
                  ),
                  AppMetricData(
                    label: 'Overall Gain/Loss',
                    value: _formatChange(data.overallChange),
                    icon: Icons.query_stats_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _MoverSummary(performance: data),
              const SizedBox(height: AppSpacing.lg),
              for (final recommendation in data.recommendations) ...[
                _PerformanceRecommendation(message: recommendation),
                if (recommendation != data.recommendations.last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(
            'Portfolio performance history will update after the next portfolio refresh.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoverSummary extends StatelessWidget {
  const _MoverSummary({required this.performance});

  final PortfolioPerformance performance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MoverRow(
          label: 'Top Gainer',
          mover: performance.topGainer,
          positive: true,
        ),
        const SizedBox(height: AppSpacing.md),
        _MoverRow(
          label: 'Top Loser',
          mover: performance.topLoser,
          positive: false,
        ),
      ],
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({
    required this.label,
    required this.mover,
    required this.positive,
  });

  final String label;
  final PortfolioValueMover? mover;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = positive ? AppColors.success : const Color(0xFFD97706);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.trending_up_outlined
                : Icons.trending_down_outlined,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  mover?.title ?? 'No movement yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            mover == null ? 'AUD 0' : _formatSignedAud(mover!.absoluteChange),
            style: textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRecommendation extends StatelessWidget {
  const _PerformanceRecommendation({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.insights_outlined, size: 18, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceAlertSummarySection extends StatelessWidget {
  const _PriceAlertSummarySection({required this.summary});

  final AsyncValue<PriceAlertSummary> summary;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 150),
      child: AppInfoSection(
        title: 'Price Alerts',
        child: summary.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppResponsiveMetricGroup(
                metrics: [
                  AppMetricData(
                    label: 'Active Alerts',
                    value: data.activeCount.toString(),
                    icon: Icons.notifications_active_outlined,
                  ),
                  AppMetricData(
                    label: 'Triggered Alerts',
                    value: data.triggeredCount.toString(),
                    icon: Icons.price_change_outlined,
                  ),
                  AppMetricData(
                    label: 'Tracked Items',
                    value: data.totalCount.toString(),
                    icon: Icons.bookmark_added_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _AlertSummaryMessage(summary: data),
            ],
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(
            'Price alerts are stored locally and will retry on the next refresh.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertSummaryMessage extends StatelessWidget {
  const _AlertSummaryMessage({required this.summary});

  final PriceAlertSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasTriggered = summary.messages.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasTriggered
            ? AppColors.success.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasTriggered
              ? AppColors.success.withValues(alpha: 0.18)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasTriggered
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
            color: hasTriggered ? AppColors.success : colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              hasTriggered
                  ? summary.messages.first
                  : 'Create alerts from a collectible detail page to track value changes.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 160),
      child: AppInfoSection(
        title: 'Category Breakdown',
        child: Column(
          children: [
            for (final category in CollectorCategory.values) ...[
              _CategoryBreakdownBar(
                label: category.label,
                count: insights.categoryDistribution[category] ?? 0,
                total: insights.itemCount,
              ),
              if (category != CollectorCategory.values.last)
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

class _CollectionHealthSection extends StatelessWidget {
  const _CollectionHealthSection({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    final health = insights.collectionHealth;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _FadeSlideIn(
      delay: const Duration(milliseconds: 180),
      child: AppInfoSection(
        title: 'Collection Health',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${health.score}',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        health.label,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Based on confidence, metadata, pricing freshness, duplicates, and image quality.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppResponsiveMetricGroup(
              metrics: [
                AppMetricData(
                  label: 'Confidence',
                  value: '${health.confidenceScore}',
                  icon: Icons.verified_outlined,
                ),
                AppMetricData(
                  label: 'Data Quality',
                  value: '${health.metadataScore}',
                  icon: Icons.fact_check_outlined,
                ),
                AppMetricData(
                  label: 'Pricing Freshness',
                  value: '${health.pricingFreshnessScore}',
                  icon: Icons.schedule_outlined,
                ),
                AppMetricData(
                  label: 'Duplicates',
                  value: '${health.duplicateScore}',
                  icon: Icons.control_point_duplicate_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionScoreSection extends StatelessWidget {
  const _CollectionScoreSection({required this.intelligence});

  final SmartCollectorIntelligence intelligence;

  @override
  Widget build(BuildContext context) {
    final score = intelligence.collectionScore;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _FadeSlideIn(
      delay: const Duration(milliseconds: 195),
      child: AppInfoSection(
        title: 'Collection Score',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppElevation.accentGlow,
                    ),
                    child: Text(
                      '${score.score}',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${score.label} collector profile',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Scored from rarity, completeness, confidence, value, diversity, duplicates, image quality, and pricing freshness.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final factor in CollectionScoreFactor.values) ...[
              _CollectionScoreFactorRow(
                label: factor.label,
                value: score.factorScores[factor] ?? 0,
              ),
              if (factor != CollectionScoreFactor.values.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectionScoreFactorRow extends StatelessWidget {
  const _CollectionScoreFactorRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fraction = (value / 100).clamp(0.0, 1.0);

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
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$value',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 8,
            width: double.infinity,
            color: colorScheme.surfaceContainerHighest,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(color: colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmartCollectorInsightsSection extends StatelessWidget {
  const _SmartCollectorInsightsSection({required this.intelligence});

  final SmartCollectorIntelligence intelligence;

  @override
  Widget build(BuildContext context) {
    final visibleInsights = intelligence.insights.take(5).toList();

    return _FadeSlideIn(
      delay: const Duration(milliseconds: 205),
      child: AppInfoSection(
        title: 'Smart Collector Insights',
        child: Column(
          children: [
            for (final insight in visibleInsights) ...[
              _SmartCollectorInsightCard(insight: insight),
              if (insight != visibleInsights.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmartCollectorInsightCard extends StatelessWidget {
  const _SmartCollectorInsightCard({required this.insight});

  final SmartCollectorInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = _smartInsightColor(
      insight.type,
      Theme.of(context).colorScheme,
    );
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(_smartInsightIcon(insight.type), color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(insight.message, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCollectorRecommendationsSection extends StatelessWidget {
  const _AiCollectorRecommendationsSection({required this.intelligence});

  final SmartCollectorIntelligence intelligence;

  @override
  Widget build(BuildContext context) {
    final recommendations = intelligence.recommendations.take(5).toList();

    return _FadeSlideIn(
      delay: const Duration(milliseconds: 215),
      child: AppInfoSection(
        title: 'AI Collector Recommendations',
        child: Column(
          children: [
            for (final recommendation in recommendations) ...[
              _AiCollectorRecommendationRow(recommendation: recommendation),
              if (recommendation != recommendations.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiCollectorRecommendationRow extends StatelessWidget {
  const _AiCollectorRecommendationRow({required this.recommendation});

  final AiCollectorRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            _aiRecommendationIcon(recommendation.type),
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                recommendation.message,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WishlistGoalsSection extends StatelessWidget {
  const _WishlistGoalsSection({required this.intelligence});

  final SmartCollectorIntelligence intelligence;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 225),
      child: AppInfoSection(
        title: 'Wishlist & Goals',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppResponsiveMetricGroup(
              metrics: [
                AppMetricData(
                  label: 'Owned',
                  value:
                      '${intelligence.wishlistStatusCounts[WishlistStatus.owned] ?? 0}',
                  icon: Icons.check_circle_outline,
                ),
                AppMetricData(
                  label: 'Wanted',
                  value:
                      '${intelligence.wishlistStatusCounts[WishlistStatus.wanted] ?? 0}',
                  icon: Icons.bookmark_add_outlined,
                ),
                AppMetricData(
                  label: 'Missing',
                  value:
                      '${intelligence.wishlistStatusCounts[WishlistStatus.missing] ?? 0}',
                  icon: Icons.playlist_add_check_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final goal in intelligence.goals) ...[
              _CollectionGoalRow(goal: goal),
              if (goal != intelligence.goals.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectionGoalRow extends StatelessWidget {
  const _CollectionGoalRow({required this.goal});

  final CollectionGoal goal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                goal.progressLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            goal.description,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: goal.progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({required this.intelligence});

  final SmartCollectorIntelligence intelligence;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 235),
      child: AppInfoSection(
        title: 'Achievements',
        child: Column(
          children: [
            for (final achievement in intelligence.achievements) ...[
              _AchievementRow(achievement: achievement),
              if (achievement != intelligence.achievements.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement});

  final CollectorAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = achievement.isUnlocked
        ? AppColors.success
        : colorScheme.outline;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(_achievementIcon(achievement.type), color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                achievement.description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                minHeight: 4,
                value: achievement.progress.clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PortfolioAnalyticsSection extends StatelessWidget {
  const _PortfolioAnalyticsSection({
    required this.insights,
    required this.onOpenItem,
  });

  final CollectorDashboardAnalytics insights;
  final ValueChanged<CollectibleItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 210),
      child: AppInfoSection(
        title: 'Portfolio Analytics',
        child: Column(
          children: [
            _AnalyticsMiniList(
              title: 'Top 5 Highest Value',
              items: insights.topHighestValue,
              valueFor: (item) => _formatAud(item.estimatedValue),
              onOpenItem: onOpenItem,
            ),
            const SizedBox(height: AppSpacing.lg),
            _AnalyticsMiniList(
              title: 'Top 5 Lowest Confidence',
              items: insights.topLowestConfidence,
              valueFor: (item) => _formatPercent(item.confidence),
              onOpenItem: onOpenItem,
            ),
            const SizedBox(height: AppSpacing.lg),
            _AnalyticsMiniList(
              title: 'Newest Additions',
              items: insights.newestAdditions,
              valueFor: (item) => _formatDate(item.createdAt),
              onOpenItem: onOpenItem,
            ),
            const SizedBox(height: AppSpacing.lg),
            _LargestCategoryTile(insights: insights),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsMiniList extends StatelessWidget {
  const _AnalyticsMiniList({
    required this.title,
    required this.items,
    required this.valueFor,
    required this.onOpenItem,
  });

  final String title;
  final List<CollectibleItem> items;
  final String Function(CollectibleItem item) valueFor;
  final ValueChanged<CollectibleItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in items) ...[
          _CompactAnalyticsRow(
            item: item,
            value: valueFor(item),
            onTap: () => onOpenItem(item),
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _CompactAnalyticsRow extends StatelessWidget {
  const _CompactAnalyticsRow({
    required this.item,
    required this.value,
    required this.onTap,
  });

  final CollectibleItem item;
  final String value;
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
              PortfolioThumbnail(imagePath: item.imagePath, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.category,
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
                value,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargestCategoryTile extends StatelessWidget {
  const _LargestCategoryTile({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    final category = insights.largestCategory;
    final count = category == null
        ? 0
        : insights.categoryDistribution[category] ?? 0;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Largest Category',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            category == null ? 'None' : '${category.label} ($count)',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 230),
      child: AppInfoSection(
        title: 'Collector Insights',
        child: Column(
          children: [
            for (final insight in insights.insights.take(5)) ...[
              _InsightCard(insight: insight),
              if (insight != insights.insights.take(5).last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final CollectionInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = _insightColor(insight.type, Theme.of(context).colorScheme);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(_insightIcon(insight.type), color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(insight.message, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  const _RecommendationsSection({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 250),
      child: AppInfoSection(
        title: 'Recommendations',
        child: Column(
          children: [
            for (final recommendation in insights.recommendations) ...[
              _RecommendationRow(recommendation: recommendation),
              if (recommendation != insights.recommendations.last)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({required this.recommendation});

  final CollectionRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            _recommendationIcon(recommendation.type),
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                recommendation.message,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendFoundationSection extends StatelessWidget {
  const _TrendFoundationSection({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    return _FadeSlideIn(
      delay: const Duration(milliseconds: 270),
      child: AppInfoSection(
        title: 'Portfolio Trends',
        child: AppResponsiveMetricGroup(
          metrics: [
            AppMetricData(
              label: 'Daily Snapshots',
              value: insights.dailySnapshots.length.toString(),
              icon: Icons.today_outlined,
            ),
            AppMetricData(
              label: 'Weekly Snapshots',
              value: insights.weeklySnapshots.length.toString(),
              icon: Icons.date_range_outlined,
            ),
            AppMetricData(
              label: 'Monthly Snapshots',
              value: insights.monthlySnapshots.length.toString(),
              icon: Icons.calendar_month_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioHighlights extends StatelessWidget {
  const _PortfolioHighlights({
    required this.insights,
    required this.onOpenItem,
  });

  final CollectorDashboardAnalytics insights;
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

Color _insightColor(CollectionInsightType type, ColorScheme colorScheme) {
  switch (type) {
    case CollectionInsightType.positive:
      return AppColors.success;
    case CollectionInsightType.warning:
      return const Color(0xFFD97706);
    case CollectionInsightType.review:
      return AppColors.accent;
    case CollectionInsightType.highlight:
      return colorScheme.primary;
  }
}

IconData _insightIcon(CollectionInsightType type) {
  switch (type) {
    case CollectionInsightType.positive:
      return Icons.trending_up_outlined;
    case CollectionInsightType.warning:
      return Icons.warning_amber_outlined;
    case CollectionInsightType.review:
      return Icons.rate_review_outlined;
    case CollectionInsightType.highlight:
      return Icons.workspace_premium_outlined;
  }
}

IconData _recommendationIcon(CollectionRecommendationType type) {
  switch (type) {
    case CollectionRecommendationType.scanAgain:
      return Icons.document_scanner_outlined;
    case CollectionRecommendationType.improvePhoto:
      return Icons.photo_camera_outlined;
    case CollectionRecommendationType.upgradePlan:
      return Icons.workspace_premium_outlined;
    case CollectionRecommendationType.reviewLowConfidence:
      return Icons.fact_check_outlined;
    case CollectionRecommendationType.addMoreCollectibles:
      return Icons.add_circle_outline;
  }
}

Color _smartInsightColor(
  SmartCollectorInsightType type,
  ColorScheme colorScheme,
) {
  switch (type) {
    case SmartCollectorInsightType.opportunity:
      return colorScheme.primary;
    case SmartCollectorInsightType.warning:
      return const Color(0xFFD97706);
    case SmartCollectorInsightType.highlight:
      return AppColors.success;
    case SmartCollectorInsightType.trend:
      return AppColors.secondaryAccent;
  }
}

IconData _smartInsightIcon(SmartCollectorInsightType type) {
  switch (type) {
    case SmartCollectorInsightType.opportunity:
      return Icons.auto_awesome_outlined;
    case SmartCollectorInsightType.warning:
      return Icons.warning_amber_outlined;
    case SmartCollectorInsightType.highlight:
      return Icons.workspace_premium_outlined;
    case SmartCollectorInsightType.trend:
      return Icons.trending_up_outlined;
  }
}

IconData _aiRecommendationIcon(AiCollectorRecommendationType type) {
  switch (type) {
    case AiCollectorRecommendationType.scanBetterPhotos:
      return Icons.photo_camera_outlined;
    case AiCollectorRecommendationType.upgradeGrading:
      return Icons.workspace_premium_outlined;
    case AiCollectorRecommendationType.sellNow:
      return Icons.sell_outlined;
    case AiCollectorRecommendationType.hold:
      return Icons.lock_clock_outlined;
    case AiCollectorRecommendationType.watchPrice:
      return Icons.query_stats_outlined;
    case AiCollectorRecommendationType.addMissingCards:
      return Icons.playlist_add_outlined;
  }
}

IconData _achievementIcon(AchievementType type) {
  switch (type) {
    case AchievementType.firstScan:
      return Icons.looks_one_outlined;
    case AchievementType.hundredScans:
      return Icons.collections_bookmark_outlined;
    case AchievementType.rareCollector:
      return Icons.diamond_outlined;
    case AchievementType.coinExpert:
      return Icons.paid_outlined;
    case AchievementType.completionist:
      return Icons.emoji_events_outlined;
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

String _formatSignedAud(double value) {
  final prefix = value > 0
      ? '+'
      : value < 0
      ? '-'
      : '';
  return '$prefix${_formatAud(value.abs())}';
}

String _formatChange(PortfolioValueChange change) {
  return '${_formatSignedAud(change.absoluteChange)} (${_formatPercent(change.percentageChange.abs())})';
}

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(0)}%';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
