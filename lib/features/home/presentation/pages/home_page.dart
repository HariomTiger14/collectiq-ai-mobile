import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
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
  bool _scanRequestPending = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScanPressed() {
    if (_scanRequestPending) {
      return;
    }
    _scanRequestPending = true;
    widget.onScanPressed?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scanRequestPending = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioControllerProvider);
    final items = portfolio.orderedItems;
    final insights = const CollectorDashboardAnalyticsService().build(items);
    final homeData = _HomeViewData.fromInsights(insights);
    final recentItems = homeData.recentItems.take(3).toList(growable: false);

    // Home follows the approved dark authority independent of system brightness.
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: HomeTokens.background,
        body: SafeArea(
          child: HomeStateContainer(
            controller: _scrollController,
            bottomClearance: 104,
            sections: [
              const HomeSection(
                topPadding: AppSpacing.xs,
                child: HomeAppBar(
                  firstName: '',
                  fallbackName: 'Collector',
                  greetingText: 'Your collection',
                  onNotifications: null,
                ),
              ),
              if (homeData.isEmpty)
                HomeSection(
                  topPadding: AppSpacing.xs,
                  child: _EmptyCollectionCard(
                    onScanPressed: widget.onScanPressed == null
                        ? null
                        : _handleScanPressed,
                  ),
                ),
              HomeSection(
                topPadding: AppSpacing.sm,
                child: _CollectionSnapshotSection(data: homeData),
              ),
              HomeSection(
                topPadding: AppSpacing.sm,
                child: homeData.isEmpty
                    ? const _PopularCategoriesSection()
                    : _CompactQuickActions(
                        onScanPressed: widget.onScanPressed == null
                            ? null
                            : _handleScanPressed,
                        onImportPhotoPressed:
                            widget.onImportPhotoPressed ?? widget.onScanPressed,
                        onPortfolioPressed: widget.onPortfolioPressed,
                      ),
              ),
              if (homeData.isEmpty)
                HomeSection(
                  topPadding: AppSpacing.sm,
                  child: _CompactQuickActions(
                    onScanPressed: widget.onScanPressed == null
                        ? null
                        : _handleScanPressed,
                    onImportPhotoPressed:
                        widget.onImportPhotoPressed ?? widget.onScanPressed,
                    onPortfolioPressed: widget.onPortfolioPressed,
                  ),
                ),
              if (recentItems.isNotEmpty)
                HomeSection(
                  topPadding: AppSpacing.lg,
                  child: _RecentCollectiblesSection(
                    items: recentItems,
                    hasMore: homeData.itemCount > recentItems.length,
                    onViewAll: widget.onPortfolioPressed,
                  ),
                ),
              if (homeData.unvaluedCount > 0 && homeData.itemCount > 0)
                HomeSection(
                  topPadding: AppSpacing.lg,
                  bottomPadding: AppSpacing.xxl,
                  child: _GroundedInsightCard(data: homeData),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactQuickActions extends StatelessWidget {
  const _CompactQuickActions({
    this.onScanPressed,
    this.onImportPhotoPressed,
    this.onPortfolioPressed,
  });

  final VoidCallback? onScanPressed;
  final VoidCallback? onImportPhotoPressed;
  final VoidCallback? onPortfolioPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = [
      HomeQuickAction(
        key: 'scan',
        icon: Icons.photo_camera_outlined,
        label: 'Scan',
        semanticLabel: 'Scan a collectible',
        onTap: onScanPressed,
      ),
      HomeQuickAction(
        key: 'import',
        icon: Icons.image_outlined,
        label: 'Import',
        semanticLabel: 'Import photo',
        onTap: onImportPhotoPressed,
      ),
      HomeQuickAction(
        key: 'portfolio',
        icon: Icons.inventory_2_outlined,
        label: 'Portfolio',
        semanticLabel: 'Open portfolio',
        onTap: onPortfolioPressed,
      ),
    ];

    return HomeSectionSurface(
      title: 'Quick actions',
      backgroundColor: _packLoxRaisedSurfaceColor(colorScheme),
      borderColor: _packLoxSurfaceBorderColor(colorScheme),
      child: Semantics(
        container: true,
        label: 'Collection actions',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start adding to your collection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HomeTokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HomeQuickActionGrid(actions: actions),
          ],
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

  bool get isEmpty => itemCount == 0;
  bool get hasValuedItems => valuedItemCount > 0;

  String get heroSupport {
    if (isEmpty) {
      return 'Scan your first collectible and start building your collection.';
    }
    final valueText = hasValuedItems
        ? ' worth an estimated ${_formatCurrency(totalValuedAmount)}'
        : '';
    return 'You have $_itemCountLabel$valueText.';
  }

  String get overviewTitle {
    if (isEmpty) {
      return 'Your collection is waiting';
    }
    return 'Your collection';
  }

  String get overviewSubtitle {
    if (isEmpty) {
      return 'No items yet';
    }
    return _itemCountLabel;
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

  factory _HomeViewData.fromInsights(CollectorDashboardAnalytics insights) {
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
    );
  }
}

class _CollectionSnapshotSection extends StatelessWidget {
  const _CollectionSnapshotSection({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return HomeSectionSurface(
      title: data.isEmpty ? 'Collection status' : 'Collection snapshot',
      backgroundColor: _packLoxRaisedSurfaceColor(colorScheme),
      borderColor: _packLoxSurfaceBorderColor(colorScheme),
      child: data.isEmpty
          ? _EmptySnapshot(data: data)
          : _SnapshotContent(data: data),
    );
  }
}

class _EmptyCollectionCard extends StatelessWidget {
  const _EmptyCollectionCard({this.onScanPressed});

  static const double iconCircleDiameter = 62;
  static const double archiveIconSize = 30;

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          'Empty collection. Your collection is waiting. Scan your first item to get started.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final stackHero = constraints.maxWidth < 328 || textScale > 1.25;
          final fixedPhoneHero = !stackHero && constraints.maxWidth <= 430;

          return Container(
            key: const ValueKey('home-empty-authority-card'),
            width: double.infinity,
            height: fixedPhoneHero ? 164 : null,
            constraints: BoxConstraints(minHeight: fixedPhoneHero ? 156 : 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _packLoxRaisedSurfaceColor(colorScheme),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: _packLoxSurfaceBorderColor(colorScheme),
              ),
              boxShadow: AppElevation.level1,
            ),
            child: stackHero
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EmptyHeroIcon(colorScheme: colorScheme),
                      const SizedBox(height: AppSpacing.md),
                      _EmptyHeroCopy(onScanPressed: onScanPressed),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _EmptyHeroIcon(colorScheme: colorScheme),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _EmptyHeroCopy(
                          onScanPressed: onScanPressed,
                          compact: fixedPhoneHero,
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _EmptyHeroIcon extends StatelessWidget {
  const _EmptyHeroIcon({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-empty-hero-icon-circle'),
      width: _EmptyCollectionCard.iconCircleDiameter,
      height: _EmptyCollectionCard.iconCircleDiameter,
      decoration: BoxDecoration(
        color: PackLoxTokens.surface.withValues(alpha: 0.86),
        shape: BoxShape.circle,
        border: Border.all(color: PackLoxTokens.blue.withValues(alpha: 0.34)),
      ),
      child: Icon(
        key: const ValueKey('home-empty-hero-archive-icon'),
        Icons.inventory_2_outlined,
        color: colorScheme.primary,
        size: _EmptyCollectionCard.archiveIconSize,
      ),
    );
  }
}

class _EmptyHeroCopy extends StatelessWidget {
  const _EmptyHeroCopy({this.onScanPressed, this.compact = false});

  final VoidCallback? onScanPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your collection is waiting',
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style:
              (compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Text(
          'Scan your first item to get started.',
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style:
              (compact
                      ? Theme.of(context).textTheme.bodySmall
                      : Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
        ),
        SizedBox(height: compact ? 10 : AppSpacing.md),
        _HeroScanButton(
          key: const ValueKey('home-primary-scan'),
          onPressed: onScanPressed,
        ),
      ],
    );
  }
}

class _HeroScanButton extends StatelessWidget {
  const _HeroScanButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Scan a Collectible',
      excludeSemantics: true,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.photo_camera_outlined, size: 22),
          label: const Text(
            'Scan a Collectible',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
              enabled
                  ? PackLoxTokens.blue
                  : PackLoxTokens.blue.withValues(alpha: .45),
            ),
            foregroundColor: const WidgetStatePropertyAll(
              PackLoxTokens.textPrimary,
            ),
            overlayColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: .08),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 18),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: const BorderSide(color: Color(0xFF60A5FA)),
              ),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnapshotContent extends StatelessWidget {
  const _SnapshotContent({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      data.itemMetric,
      if (data.categoryMetric != null) data.categoryMetric!,
      if (data.lastScanMetric != null) data.lastScanMetric!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.snapshotValue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final metric in metrics) _SnapshotPill(label: metric),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _TopCollectiblePreview(item: data.topCollectible),
      ],
    );
  }
}

class _SnapshotPill extends StatelessWidget {
  const _SnapshotPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TopCollectiblePreview extends StatelessWidget {
  const _TopCollectiblePreview({required this.item});

  final CollectibleItem? item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (item == null) {
      return const SizedBox.shrink();
    }

    return MotionTapScale(
      onTap: () => _openCollectibleDetail(context, item!),
      child: Container(
        key: ValueKey('home-top-collectible-${item!.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _packLoxRaisedSurfaceColor(colorScheme),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: PortfolioThumbnail(imagePath: item!.imagePath, size: 72),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasDisplayValue(item!)
                        ? 'Top collectible'
                        : 'Latest collectible',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item!.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item!.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                _formatItemValue(item!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: textTheme.titleSmall?.copyWith(
                  color: _hasDisplayValue(item!)
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

class _EmptySnapshot extends StatelessWidget {
  const _EmptySnapshot({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          'Collection dashboard summary. Zero items. Estimated value unavailable. Average condition unavailable.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 300;
              final metrics = <Widget>[
                _StatusMetric(
                  key: const ValueKey('home-status-metric-items'),
                  icon: Icons.layers_outlined,
                  value: '${data.itemCount}',
                  label: 'Items',
                ),
                const _StatusMetric(
                  key: ValueKey('home-status-metric-estimated-value'),
                  icon: Icons.inventory_2_outlined,
                  value: '\u2014',
                  label: 'Est. value',
                  semanticValue: 'unavailable',
                ),
                const _StatusMetric(
                  key: ValueKey('home-status-metric-average-condition'),
                  icon: Icons.verified_user_outlined,
                  value: '\u2014',
                  label: 'Avg. condition',
                  semanticValue: 'unavailable',
                ),
              ];

              if (compact) {
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.sm) / 2,
                        child: metric,
                      ),
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    if (i > 0) const _MetricDivider(),
                    Expanded(child: metrics[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Value and condition stay unavailable until items are saved.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.semanticValue,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: '$label ${semanticValue ?? value}',
      excludeSemantics: true,
      child: Column(
        key: ValueKey(
          'home-status-metric-${label.toLowerCase().replaceAll(' ', '-').replaceAll('.', '')}',
        ),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: colorScheme.onSurfaceVariant,
            size: AppIconSizes.sm,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: _packLoxSurfaceBorderColor(Theme.of(context).colorScheme),
    );
  }
}

class _PopularCategoriesSection extends StatelessWidget {
  const _PopularCategoriesSection();

  static const _categories = [
    (
      label: 'Cards',
      icon: Icons.style_outlined,
      semanticMeaning: 'trading cards',
    ),
    (
      label: 'Coins',
      icon: Icons.album_outlined,
      semanticMeaning: 'collectible coins and medallions',
    ),
    (
      label: 'Figures',
      icon: Icons.smart_toy_outlined,
      semanticMeaning: 'figurines and action figures',
    ),
    (
      label: 'More',
      icon: Icons.grid_view_outlined,
      semanticMeaning: 'more categories grid',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return HomeSectionSurface(
      title: 'Popular Categories',
      backgroundColor: _packLoxRaisedSurfaceColor(colorScheme),
      borderColor: _packLoxSurfaceBorderColor(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'See what collectors love',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          HomeCategoryGrid(
            categories: [
              for (final category in _categories)
                HomeCategoryTile(
                  label: category.label,
                  icon: category.icon,
                  semanticMeaning: category.semanticMeaning,
                ),
            ],
          ),
        ],
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return HomeSectionSurface(
      title: 'Recent collectibles',
      actionLabel: hasMore ? 'View all' : null,
      onAction: hasMore ? onViewAll : null,
      backgroundColor: _packLoxRaisedSurfaceColor(colorScheme),
      borderColor: _packLoxSurfaceBorderColor(colorScheme),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            HomeRecentItemCard(
              id: items[i].id,
              title: items[i].title,
              category: items[i].category,
              condition: items[i].condition,
              imagePath: items[i].imagePath,
              valueLabel: _formatItemValue(items[i]),
              valueUnavailable: !_hasDisplayValue(items[i]),
              addedLabel: 'Added ${_formatRelativeTime(items[i].createdAt)}',
              onTap: () => _openCollectibleDetail(context, items[i]),
              backgroundColor: _packLoxRaisedSurfaceColor(colorScheme),
              borderColor: _packLoxSurfaceBorderColor(colorScheme),
            ),
          ],
        ],
      ),
    );
  }
}

// ignore: unused_element
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
          color: _packLoxRaisedSurfaceColor(colorScheme),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
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

class _GroundedInsightCard extends StatelessWidget {
  const _GroundedInsightCard({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = data.unvaluedCount;

    return Container(
      key: const ValueKey('home-grounded-insight'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _packLoxRaisedSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'collectible still needs' : 'collectibles still need'} a valuation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _packLoxRaisedSurfaceColor(ColorScheme colorScheme) {
  return PackLoxTokens.surfaceRaised.withValues(
    alpha: colorScheme.brightness == Brightness.dark ? 0.94 : 0.90,
  );
}

Color _packLoxSurfaceBorderColor(ColorScheme colorScheme) {
  return PackLoxTokens.border.withValues(
    alpha: colorScheme.brightness == Brightness.dark ? 0.82 : 0.68,
  );
}

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
