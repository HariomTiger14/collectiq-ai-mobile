import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
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
        backgroundColor: PackLoxTokens.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = AppSpacing.md;

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
                      topPadding: AppSpacing.xs,
                      child: const PackLoxHeader(
                        firstName: '',
                        fallbackName: 'Collector',
                        greetingText: 'Your collection',
                        onNotifications: null,
                      ),
                    ),
                  ),
                  if (homeData.isEmpty)
                    SliverToBoxAdapter(
                      child: _HomeFrame(
                        horizontalPadding: horizontalPadding,
                        topPadding: AppSpacing.xs,
                        child: _EmptyCollectionCard(
                          onScanPressed: widget.onScanPressed == null
                              ? null
                              : _handleScanPressed,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _HomeFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.sm,
                      child: _CollectionSnapshotSection(data: homeData),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _HomeFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.sm,
                      child: homeData.isEmpty
                          ? const _PopularCategoriesSection()
                          : _CompactQuickActions(
                              onScanPressed: widget.onScanPressed == null
                                  ? null
                                  : _handleScanPressed,
                              onImportPhotoPressed:
                                  widget.onImportPhotoPressed ??
                                  widget.onScanPressed,
                              onPortfolioPressed: widget.onPortfolioPressed,
                            ),
                    ),
                  ),
                  if (homeData.isEmpty)
                    SliverToBoxAdapter(
                      child: _HomeFrame(
                        horizontalPadding: horizontalPadding,
                        topPadding: AppSpacing.sm,
                        child: _CompactQuickActions(
                          onScanPressed: widget.onScanPressed == null
                              ? null
                              : _handleScanPressed,
                          onImportPhotoPressed:
                              widget.onImportPhotoPressed ??
                              widget.onScanPressed,
                          onPortfolioPressed: widget.onPortfolioPressed,
                        ),
                      ),
                    ),
                  if (recentItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _HomeFrame(
                        horizontalPadding: horizontalPadding,
                        topPadding: AppSpacing.lg,
                        child: _RecentCollectiblesSection(
                          items: recentItems,
                          hasMore: homeData.itemCount > recentItems.length,
                          onViewAll: widget.onPortfolioPressed,
                        ),
                      ),
                    ),
                  if (homeData.unvaluedCount > 0 && homeData.itemCount > 0)
                    SliverToBoxAdapter(
                      child: _HomeFrame(
                        horizontalPadding: horizontalPadding,
                        topPadding: AppSpacing.lg,
                        bottomPadding: AppSpacing.xxl,
                        child: _GroundedInsightCard(data: homeData),
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
      _HomeActionData(
        key: 'scan',
        icon: Icons.photo_camera_outlined,
        label: 'Scan',
        semanticLabel: 'Scan a collectible',
        onTap: onScanPressed,
      ),
      _HomeActionData(
        key: 'import',
        icon: Icons.image_outlined,
        label: 'Import',
        semanticLabel: 'Import photo',
        onTap: onImportPhotoPressed,
      ),
      _HomeActionData(
        key: 'portfolio',
        icon: Icons.inventory_2_outlined,
        label: 'Portfolio',
        semanticLabel: 'Open portfolio',
        onTap: onPortfolioPressed,
      ),
    ];

    return _SectionSurface(
      title: 'Quick actions',
      child: Semantics(
        container: true,
        label: 'Collection actions',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start adding to your collection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 300;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final action in actions)
                      SizedBox(
                        width: compact
                            ? (constraints.maxWidth - AppSpacing.sm) / 2
                            : (constraints.maxWidth - AppSpacing.sm * 2) / 3,
                        child: _CompactHomeAction(action: action),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionData {
  const _HomeActionData({
    required this.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.onTap,
  });

  final String key;
  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
}

class _CompactHomeAction extends StatelessWidget {
  const _CompactHomeAction({required this.action});

  final _HomeActionData action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = action.onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: action.semanticLabel,
      child: MotionTapScale(
        onTap: action.onTap,
        child: Container(
          key: ValueKey('home-quick-action-${action.key}'),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _packLoxRaisedSurfaceColor(colorScheme),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
          ),
          child: Row(
            children: [
              Icon(
                action.icon,
                color: enabled
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: AppIconSizes.md,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: AppIconSizes.md,
              ),
            ],
          ),
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

class _CollectionSnapshotSection extends StatelessWidget {
  const _CollectionSnapshotSection({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      title: data.isEmpty ? 'Collection status' : 'Collection snapshot',
      child: data.isEmpty
          ? _EmptySnapshot(data: data)
          : _SnapshotContent(data: data),
    );
  }
}

class _EmptyCollectionCard extends StatelessWidget {
  const _EmptyCollectionCard({this.onScanPressed});

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          'Empty collection. Your collection is waiting. Scan your first item to get started.',
      child: Container(
        key: const ValueKey('home-empty-authority-card'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        decoration: BoxDecoration(
          color: _packLoxRaisedSurfaceColor(colorScheme),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
          boxShadow: AppElevation.level1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: PackLoxTokens.surface.withValues(alpha: 0.86),
                shape: BoxShape.circle,
                border: Border.all(
                  color: PackLoxTokens.blue.withValues(alpha: 0.34),
                ),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: colorScheme.primary,
                size: 44,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your collection is waiting',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Scan your first item to get started.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PackLoxButton(
                    key: const ValueKey('home-primary-scan'),
                    label: 'Scan a Collectible',
                    leadingIcon: Icons.photo_camera_outlined,
                    onPressed: onScanPressed,
                    size: PackLoxButtonSize.compact,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusMetric(
                icon: Icons.layers_outlined,
                value: '${data.itemCount}',
                label: 'Items',
              ),
            ),
            const _MetricDivider(),
            const Expanded(
              child: _StatusMetric(
                icon: Icons.attach_money_rounded,
                value: '-',
                label: 'Est. value',
              ),
            ),
            const _MetricDivider(),
            const Expanded(
              child: _StatusMetric(
                icon: Icons.verified_user_outlined,
                value: '-',
                label: 'Avg. condition',
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _StatusMetric(
                icon: Icons.history_rounded,
                value: '0',
                label: 'Scans',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Value, condition, and saved history will appear here.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant, size: AppIconSizes.md),
        const SizedBox(height: AppSpacing.sm),
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
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: _packLoxSurfaceBorderColor(Theme.of(context).colorScheme),
    );
  }
}

class _PopularCategoriesSection extends StatelessWidget {
  const _PopularCategoriesSection();

  static const _categories = [
    (label: 'Cards', icon: Icons.style_outlined),
    (label: 'Coins', icon: Icons.monetization_on_outlined),
    (label: 'Figures', icon: Icons.toys_outlined),
    (label: 'More', icon: Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionSurface(
      title: 'Popular Categories',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'See what collectors love',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - AppSpacing.sm * 3) / 4;
              return Row(
                children: [
                  for (var i = 0; i < _categories.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: tileWidth,
                      child: _CategoryChip(
                        label: _categories[i].label,
                        icon: _categories[i].icon,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Popular category $label',
      child: Container(
        key: ValueKey('home-popular-category-${label.toLowerCase()}'),
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: PackLoxTokens.surface.withValues(
            alpha: colorScheme.brightness == Brightness.dark ? 0.88 : 0.72,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: AppIconSizes.lg),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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
    return _SectionSurface(
      title: 'Recent collectibles',
      trailing: hasMore
          ? TextButton(onPressed: onViewAll, child: const Text('View all'))
          : null,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _RecentCollectibleTile(item: items[i]),
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

    return Container(
      key: ValueKey('home-section-${title.toLowerCase().replaceAll(' ', '-')}'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _packLoxRaisedSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
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
