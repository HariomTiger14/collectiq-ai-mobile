import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/home_dashboard_providers.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/portfolio_history_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    this.onScanPressed,
    this.onImportPhotoPressed,
    this.onPortfolioPressed,
    super.key,
  });

  final VoidCallback? onScanPressed;
  final VoidCallback? onImportPhotoPressed;
  final VoidCallback? onPortfolioPressed;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioControllerProvider);
    final items = portfolio.orderedItems;
    // Use the controller's stored list (a stable reference across rebuilds) as
    // the family argument so the async providers cache correctly instead of
    // refetching on every build.
    final stableItems = portfolio.items;
    final insights = const CollectorDashboardAnalyticsService().build(items);
    final performance = ref
        .watch(portfolioPerformanceProvider(stableItems))
        .asData
        ?.value;
    final triggeredAlertCount =
        ref.watch(homeTriggeredAlertCountProvider).asData?.value ?? 0;
    final homeData = _HomeViewData.fromInsights(
      insights,
      valueTrend: _dailyTrendFromSnapshots(performance?.dailySnapshots),
      triggeredAlertCount: triggeredAlertCount,
      topGainer: performance?.topGainer,
      topLoser: performance?.topLoser,
    );
    final recentItems = homeData.recentItems.take(4).toList(growable: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth <= 360
                ? AppSpacing.md
                : AppSpacing.lg;

            return CustomScrollView(
              key: const PageStorageKey<String>('home-scroll-position'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.md,
                    child: _CompactHomeHero(
                      scrollController: _scrollController,
                      data: homeData,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.lg,
                    child: _CollectionSnapshotSection(
                      data: homeData,
                      dailySnapshots: homeData.dailySnapshots,
                      onScanPressed: widget.onScanPressed,
                      onReviewPressed: widget.onPortfolioPressed,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.md,
                    child: _PrimaryScanCta(onPressed: widget.onScanPressed),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.md,
                    child: _SecondaryActions(
                      onImportPhotoPressed:
                          widget.onImportPhotoPressed ?? widget.onScanPressed,
                      onPortfolioPressed: widget.onPortfolioPressed,
                    ),
                  ),
                ),
                if (homeData.showAttention)
                  SliverToBoxAdapter(
                    child: _HomeFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.lg,
                      child: _AttentionSection(
                        data: homeData,
                        onPressed: widget.onPortfolioPressed,
                      ),
                    ),
                  ),
                if (homeData.itemCount > 0)
                  SliverToBoxAdapter(
                    child: _HomeFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.lg,
                      child: _HealthCategorySection(data: homeData),
                    ),
                  ),
                if (homeData.hasMovers)
                  SliverToBoxAdapter(
                    child: _HomeFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.lg,
                      child: _MoversSection(data: homeData),
                    ),
                  ),
                if (recentItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _HomeFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.lg,
                      bottomPadding: AppSpacing.xxl,
                      child: _RecentCollectiblesSection(
                        items: recentItems,
                        hasMore: homeData.itemCount > recentItems.length,
                        onViewAll: widget.onPortfolioPressed,
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeViewData {
  const _HomeViewData({
    required this.items,
    required this.itemCount,
    required this.totalValuedAmount,
    required this.valuedItemCount,
    required this.unvaluedCount,
    required this.categoryCount,
    required this.lastScanAt,
    required this.topCollectible,
    required this.recentItems,
    required this.dailySnapshots,
    required this.triggeredAlertCount,
    required this.collectionHealth,
    required this.categoryDistribution,
    this.topGainer,
    this.topLoser,
  });

  final List<CollectibleItem> items;
  final int itemCount;
  final double totalValuedAmount;
  final int valuedItemCount;
  final int unvaluedCount;
  final int categoryCount;
  final DateTime? lastScanAt;
  final CollectibleItem? topCollectible;
  final List<CollectibleItem> recentItems;
  final List<TrendSnapshot> dailySnapshots;
  final int triggeredAlertCount;
  final CollectionHealthScore collectionHealth;
  final Map<CollectorCategory, int> categoryDistribution;
  final PortfolioValueMover? topGainer;
  final PortfolioValueMover? topLoser;

  bool get isEmpty => itemCount == 0;
  bool get hasValuedItems => valuedItemCount > 0;

  int get trustedPricingCount => items.where(_hasTrustedPricing).length;

  int get needsReviewCount => itemCount - trustedPricingCount;

  bool get showAttention =>
      itemCount > 0 && (unvaluedCount > 0 || triggeredAlertCount > 0);

  bool get hasMovers => topGainer != null || topLoser != null;

  List<_CategoryShare> topCategoryShares(int limit) {
    final entries =
        categoryDistribution.entries
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    if (total == 0) {
      return const <_CategoryShare>[];
    }
    return [
      for (final entry in entries.take(limit))
        _CategoryShare(label: entry.key.label, fraction: entry.value / total),
    ];
  }

  String get heroSupport {
    if (isEmpty) {
      return 'Scan your first collectible and start building your collection.';
    }
    final categoryText = categoryCount > 0
        ? ' across $categoryCount ${categoryCount == 1 ? 'category' : 'categories'}'
        : '';
    return 'You have $_itemCountLabel$categoryText.';
  }

  String get _itemCountLabel =>
      '$itemCount ${itemCount == 1 ? 'collectible' : 'collectibles'}';

  String get snapshotValue => hasValuedItems
      ? '${_formatCurrency(totalValuedAmount)} estimated value'
      : 'Value unavailable';

  String get itemMetric =>
      '$itemCount ${itemCount == 1 ? 'collectible' : 'collectibles'}';

  String? get categoryMetric {
    if (categoryCount <= 0) {
      return null;
    }
    return '$categoryCount ${categoryCount == 1 ? 'category' : 'categories'}';
  }

  String? get lastScanMetric => lastScanAt == null
      ? null
      : 'Last scan ${_formatRelativeTime(lastScanAt!)}';

  factory _HomeViewData.fromInsights(
    CollectorDashboardAnalytics insights, {
    required List<TrendSnapshot> valueTrend,
    required int triggeredAlertCount,
    PortfolioValueMover? topGainer,
    PortfolioValueMover? topLoser,
  }) {
    final items = insights.items;
    final valuedItems = items.where(_hasDisplayValue).toList(growable: false);
    final totalValuedAmount = valuedItems.fold<double>(
      0,
      (sum, item) => sum + item.estimatedValue,
    );
    final topCollectible = valuedItems.isNotEmpty
        ? valuedItems.reduce(
            (best, item) =>
                item.estimatedValue > best.estimatedValue ? item : best,
          )
        : (items.isEmpty ? null : items.first);

    return _HomeViewData(
      items: items,
      itemCount: items.length,
      totalValuedAmount: totalValuedAmount,
      valuedItemCount: valuedItems.length,
      unvaluedCount: items.length - valuedItems.length,
      categoryCount: _categoryCount(insights),
      lastScanAt: insights.mostRecentItem?.createdAt,
      topCollectible: topCollectible,
      recentItems: items,
      dailySnapshots: valueTrend,
      triggeredAlertCount: triggeredAlertCount,
      collectionHealth: insights.collectionHealth,
      categoryDistribution: insights.categoryDistribution,
      topGainer: topGainer,
      topLoser: topLoser,
    );
  }
}

class _HomeFrame extends StatelessWidget {
  const _HomeFrame({
    required this.child,
    required this.horizontalPadding,
    this.topPadding = AppSpacing.lg,
    this.bottomPadding = 0,
  });

  final Widget child;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class _CompactHomeHero extends StatelessWidget {
  const _CompactHomeHero({required this.scrollController, required this.data});

  final ScrollController scrollController;
  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        return MotionElasticHero(
          key: const ValueKey('home-hero-motion'),
          baseHeight: 156,
          maxOverscroll: 40,
          scrollOffset: scrollOffset,
          child: MotionParallax(
            scrollOffset: scrollOffset,
            depth: 8,
            child: Container(
              key: const ValueKey('home-hero-container'),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 156),
              decoration: BoxDecoration(
                gradient: AppGradients.premiumHeroGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppElevation.level2,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: MotionReveal(
                  offset: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _timeAwareGreeting(),
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Ready to grow your collection?',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        data.heroSupport,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600,
                          height: 1.22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrimaryScanCta extends StatelessWidget {
  const _PrimaryScanCta({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Scan a collectible',
      hint: 'Starts a new collectible scan',
      child: Tooltip(
        message: 'Start a new scan',
        child: MotionTapScale(
          key: const ValueKey('home-primary-scan-cta'),
          onTap: onPressed,
          enabled: onPressed != null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppGradients.premium,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppElevation.level2,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan a collectible',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Identify, value, and save an item',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActions extends StatelessWidget {
  const _SecondaryActions({this.onImportPhotoPressed, this.onPortfolioPressed});

  final VoidCallback? onImportPhotoPressed;
  final VoidCallback? onPortfolioPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryActionCard(
            key: const ValueKey('home-secondary-import'),
            icon: Icons.photo_library_outlined,
            label: 'Import photo',
            subtitle: 'Use gallery',
            onTap: onImportPhotoPressed,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SecondaryActionCard(
            key: const ValueKey('home-secondary-portfolio'),
            icon: Icons.inventory_2_outlined,
            label: 'Open portfolio',
            subtitle: 'View saved',
            onTap: onPortfolioPressed,
          ),
        ),
      ],
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  const _SecondaryActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MotionTapScale(
      onTap: onTap,
      enabled: onTap != null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.56),
          ),
          boxShadow: AppElevation.level1,
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionSnapshotSection extends StatelessWidget {
  const _CollectionSnapshotSection({
    required this.data,
    required this.dailySnapshots,
    this.onScanPressed,
    this.onReviewPressed,
  });

  final _HomeViewData data;
  final List<TrendSnapshot> dailySnapshots;
  final VoidCallback? onScanPressed;
  final VoidCallback? onReviewPressed;

  @override
  Widget build(BuildContext context) {
    return data.isEmpty
        ? _SectionSurface(
            title: 'Collection snapshot',
            child: _EmptySnapshot(onScanPressed: onScanPressed),
          )
        : _PortfolioValuationCard(
            data: data,
            dailySnapshots: dailySnapshots,
            onReviewPressed: onReviewPressed,
          );
  }
}

class _PortfolioValuationCard extends StatelessWidget {
  const _PortfolioValuationCard({
    required this.data,
    required this.dailySnapshots,
    this.onReviewPressed,
  });

  final _HomeViewData data;
  final List<TrendSnapshot> dailySnapshots;
  final VoidCallback? onReviewPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final trustedCount = data.trustedPricingCount;
    final reviewCount = data.needsReviewCount;
    final totalCount = data.itemCount;
    final delta = _portfolioThirtyDayDelta(dailySnapshots);
    final deltaColor = delta == null
        ? colorScheme.onSurfaceVariant
        : delta.absoluteChange >= 0
        ? AppColors.success
        : AppColors.danger;

    return MotionReveal(
      child: Container(
        key: const ValueKey('home-portfolio-valuation-card'),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.52),
          ),
          boxShadow: AppElevation.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Portfolio value',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _TrustedPricingBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  data.hasValuedItems
                      ? _formatCurrency(data.totalValuedAmount)
                      : 'Value unavailable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineMedium?.copyWith(
                    color: data.hasValuedItems
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                Text(
                  data.hasValuedItems
                      ? (delta == null
                            ? 'History building'
                            : _formatDelta(delta))
                      : 'Review needed',
                  style: textTheme.titleSmall?.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              delta == null
                  ? '30-day trend starts after enough daily snapshots'
                  : 'past 30 days',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PortfolioValueSparkline(snapshots: dailySnapshots),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$trustedCount of $totalCount items trusted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$reviewCount need review',
                  style: textTheme.labelMedium?.copyWith(
                    color: _warningAmber,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _TrustSegmentBar(
              trustedCount: trustedCount,
              reviewCount: reviewCount,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: reviewCount == 0 ? null : onReviewPressed,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(
                  'Review $reviewCount ${reviewCount == 1 ? 'item' : 'items'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustedPricingBadge extends StatelessWidget {
  const _TrustedPricingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            'Trusted pricing',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioValueSparkline extends StatelessWidget {
  const _PortfolioValueSparkline({required this.snapshots});

  final List<TrendSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ordered = [...snapshots]..sort((a, b) => a.date.compareTo(b.date));
    final values = ordered
        .map((snapshot) => snapshot.totalValue)
        .toList(growable: false);

    return Container(
      height: 104,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: values.length < 2
          ? Center(
              child: Text(
                'No value history yet',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : CustomPaint(
              painter: _HomeSparklinePainter(
                values: values,
                color: colorScheme.primary,
              ),
            ),
    );
  }
}

class _TrustSegmentBar extends StatelessWidget {
  const _TrustSegmentBar({
    required this.trustedCount,
    required this.reviewCount,
  });

  final int trustedCount;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = trustedCount + reviewCount;
    final trustedFlex = total == 0 ? 1 : trustedCount.clamp(0, total);
    final reviewFlex = total == 0 ? 1 : reviewCount.clamp(0, total);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 12,
        color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        child: Row(
          children: [
            if (trustedFlex > 0)
              Expanded(
                flex: trustedFlex,
                child: Container(color: AppColors.success),
              ),
            if (reviewFlex > 0)
              Expanded(
                flex: reviewFlex,
                child: Container(color: _warningAmber),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeSparklinePainter extends CustomPainter {
  const _HomeSparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final span = maxValue - minValue;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final normalized = span == 0 ? 0.5 : (values[index] - minValue) / span;
      final y = size.height - (size.height * normalized);
      points.add(Offset(x, y.clamp(6, size.height - 6)));
    }

    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.12));

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(points.last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HomeSparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _ThirtyDayDelta {
  const _ThirtyDayDelta({
    required this.absoluteChange,
    required this.percentageChange,
  });

  final double absoluteChange;
  final double percentageChange;
}

class _EmptySnapshot extends StatelessWidget {
  const _EmptySnapshot({this.onScanPressed});

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No collectibles saved yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Scan your first item to start tracking value, condition, and saved history.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: onScanPressed,
          icon: const Icon(Icons.document_scanner_outlined),
          label: const Text('Scan first collectible'),
        ),
      ],
    );
  }
}

class _RecentCollectiblesSection extends StatelessWidget {
  const _RecentCollectiblesSection({
    required this.items,
    required this.hasMore,
    this.onViewAll,
  });

  final List<CollectibleItem> items;
  final bool hasMore;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      title: 'Recent collectibles',
      trailing: hasMore
          ? TextButton(onPressed: onViewAll, child: const Text('View all'))
          : null,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            MotionReveal(
              delay: Duration(milliseconds: i * 30),
              child: _RecentCollectibleTile(item: items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentCollectibleTile extends StatelessWidget {
  const _RecentCollectibleTile({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detail = [
      item.category,
      if (item.condition.trim().isNotEmpty) item.condition,
    ].join(' • ');

    return MotionTapScale(
      onTap: () => _openCollectibleDetail(context, item),
      child: Container(
        key: ValueKey('home-recent-${item.id}'),
        constraints: const BoxConstraints(minHeight: 86),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.44),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: PortfolioThumbnail(imagePath: item.imagePath, size: 64),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Added ${_formatRelativeTime(item.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 74,
              child: Text(
                _formatItemValue(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: textTheme.labelLarge?.copyWith(
                  color: _hasDisplayValue(item)
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryShare {
  const _CategoryShare({required this.label, required this.fraction});

  final String label;
  final double fraction;
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({required this.data, this.onPressed});

  final _HomeViewData data;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final alertCount = data.triggeredAlertCount;
    final unvalued = data.unvaluedCount;
    final accent = alertCount > 0 ? AppColors.danger : _warningAmber;

    final alertLine = alertCount > 0
        ? '$alertCount price ${alertCount == 1 ? 'alert' : 'alerts'} triggered'
        : null;
    final valuationLine = unvalued > 0
        ? '$unvalued ${unvalued == 1 ? 'collectible needs' : 'collectibles need'} a valuation'
        : null;
    final primaryLine = alertLine ?? valuationLine!;
    final secondaryLine = alertLine != null ? valuationLine : null;

    return MotionReveal(
      child: MotionTapScale(
        onTap: onPressed,
        enabled: onPressed != null,
        child: Container(
          key: const ValueKey('home-attention-card'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: accent.withValues(alpha: 0.32)),
            boxShadow: AppElevation.level1,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  alertCount > 0
                      ? Icons.notifications_active_outlined
                      : Icons.error_outline,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (secondaryLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthCategorySection extends StatelessWidget {
  const _HealthCategorySection({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    return MotionReveal(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _HealthCard(data: data)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _CategoryMixCard(data: data)),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final score = data.collectionHealth.score.clamp(0, 100);
    final color = score >= 70
        ? AppColors.success
        : score >= 50
        ? _warningAmber
        : AppColors.danger;

    return _MiniCard(
      key: const ValueKey('home-health-card'),
      title: 'Collection health',
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 5,
                    backgroundColor: colorScheme.outlineVariant.withValues(
                      alpha: 0.32,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '$score',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              data.collectionHealth.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryMixCard extends StatelessWidget {
  const _CategoryMixCard({required this.data});

  final _HomeViewData data;

  static const List<Color> _barColors = [
    AppColors.accent,
    AppColors.secondaryAccent,
    AppColors.violet,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shares = data.topCategoryShares(3);

    return _MiniCard(
      key: const ValueKey('home-category-mix-card'),
      title: 'Category mix',
      child: shares.isEmpty
          ? Text(
              'No categories yet',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < shares.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _CategoryBar(
                    share: shares[i],
                    color: _barColors[i % _barColors.length],
                  ),
                ],
              ],
            ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.share, required this.color});

  final _CategoryShare share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                share.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(share.fraction * 100).round()}%',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            height: 6,
            color: colorScheme.outlineVariant.withValues(alpha: 0.32),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: share.fraction.clamp(0.03, 1.0),
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoversSection extends StatelessWidget {
  const _MoversSection({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final gainer = data.topGainer;
    final loser = data.topLoser;

    return MotionReveal(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (gainer != null)
              Expanded(child: _MoverCard(mover: gainer, positive: true)),
            if (gainer != null && loser != null)
              const SizedBox(width: AppSpacing.md),
            if (loser != null)
              Expanded(child: _MoverCard(mover: loser, positive: false)),
          ],
        ),
      ),
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({required this.mover, required this.positive});

  final PortfolioValueMover mover;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = positive ? AppColors.success : AppColors.danger;

    return _MiniCard(
      key: ValueKey(positive ? 'home-mover-gainer' : 'home-mover-loser'),
      title: positive ? 'Top gainer' : 'Top loser',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                positive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  mover.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatSignedCurrency(mover.absoluteChange),
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

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.52),
        ),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotionReveal(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.52),
          ),
          boxShadow: AppElevation.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

List<TrendSnapshot> _dailyTrendFromSnapshots(
  List<PortfolioSnapshot>? snapshots,
) {
  if (snapshots == null || snapshots.isEmpty) {
    return const <TrendSnapshot>[];
  }
  return [
    for (final snapshot in snapshots)
      TrendSnapshot(
        period: TrendSnapshotPeriod.daily,
        date: snapshot.periodStart,
        totalValue: snapshot.totalPortfolioValue,
        itemCount: snapshot.totalItems,
        averageConfidence: 0,
      ),
  ];
}

_ThirtyDayDelta? _portfolioThirtyDayDelta(List<TrendSnapshot> snapshots) {
  if (snapshots.length < 2) {
    return null;
  }
  final ordered = [...snapshots]..sort((a, b) => a.date.compareTo(b.date));
  final latest = ordered.last;
  final cutoff = latest.date.subtract(const Duration(days: 30));
  TrendSnapshot? baseline;
  for (final snapshot in ordered) {
    if (!snapshot.date.isAfter(cutoff)) {
      baseline = snapshot;
    }
  }
  baseline ??= ordered.first;
  if (baseline.date == latest.date) {
    return null;
  }
  final previousValue = baseline.totalValue;
  final absoluteChange = latest.totalValue - previousValue;
  final percentageChange = previousValue == 0
      ? (latest.totalValue == 0 ? 0.0 : 1.0)
      : absoluteChange / previousValue;
  return _ThirtyDayDelta(
    absoluteChange: absoluteChange,
    percentageChange: percentageChange,
  );
}

String _formatDelta(_ThirtyDayDelta delta) {
  final percent = (delta.percentageChange.abs() * 100).toStringAsFixed(1);
  return '${_formatSignedCurrency(delta.absoluteChange)} · $percent%';
}

String _formatSignedCurrency(double value) {
  if (value == 0) {
    return '\$0';
  }
  final prefix = value > 0 ? '+' : '-';
  return '$prefix${_formatCurrency(value.abs())}';
}

bool _hasTrustedPricing(CollectibleItem item) {
  return item.valuationStatus == ValuationStatus.marketEstimated &&
      item.estimatedValue > 0;
}

const _warningAmber = Color(0xFFF59E0B);

void _openCollectibleDetail(BuildContext context, CollectibleItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CollectibleDetailPage(item: item)));
}

bool _hasDisplayValue(CollectibleItem item) {
  return item.estimatedValue > 0 ||
      item.valuationStatus == ValuationStatus.marketEstimated ||
      item.valuationStatus == ValuationStatus.aiEstimated;
}

String _formatItemValue(CollectibleItem item) {
  if (!_hasDisplayValue(item)) {
    return 'Value unavailable';
  }
  return _formatCurrency(item.estimatedValue);
}

String _formatCurrency(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

int _categoryCount(CollectorDashboardAnalytics insights) {
  return insights.categoryDistribution.values
      .where((count) => count > 0)
      .length;
}

String _timeAwareGreeting({DateTime? now}) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) {
    return 'Good morning';
  }
  if (hour < 17) {
    return 'Good afternoon';
  }
  return 'Good evening';
}

String _formatRelativeTime(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(date);
  if (difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (_isSameDay(date, reference)) {
    return 'today';
  }
  if (_isSameDay(date, reference.subtract(const Duration(days: 1)))) {
    return 'yesterday';
  }
  return '${difference.inDays}d ago';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
