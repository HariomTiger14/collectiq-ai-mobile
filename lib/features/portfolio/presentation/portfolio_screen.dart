import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/portfolio/portfolio_ui.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/features/wishlist/presentation/controllers/wishlist_providers.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _PortfolioSortMode {
  valueHigh(label: 'Value (High -> Low)'),
  valueLow(label: 'Value (Low -> High)'),
  confidence(label: 'Confidence'),
  trend(label: 'Trend'),
  category(label: 'Category'),
  newest(label: 'Recently Added');

  const _PortfolioSortMode({required this.label});

  final String label;
}

enum _PortfolioConfidenceFilter {
  all(label: 'All'),
  high(label: '80%+'),
  low(label: 'Below 80%');

  const _PortfolioConfidenceFilter({required this.label});

  final String label;
}

enum _PortfolioTrendFilter {
  all(label: 'All'),
  rising(label: 'Rising'),
  stable(label: 'Stable'),
  cooling(label: 'Cooling');

  const _PortfolioTrendFilter({required this.label});

  final String label;
}

enum _PortfolioCategoryFilter {
  all(label: 'All'),
  cards(label: 'Cards'),
  coins(label: 'Coins'),
  comics(label: 'Comics'),
  memorabilia(label: 'Memorabilia'),
  other(label: 'Other');

  const _PortfolioCategoryFilter({required this.label});

  final String label;
}

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({this.onScanPressed, super.key});

  final VoidCallback? onScanPressed;

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  _PortfolioSortMode _sortMode = _PortfolioSortMode.newest;
  _PortfolioCategoryFilter _categoryFilter = _PortfolioCategoryFilter.all;
  _PortfolioConfidenceFilter _confidenceFilter = _PortfolioConfidenceFilter.all;
  _PortfolioTrendFilter _trendFilter = _PortfolioTrendFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(portfolioControllerProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final portfolioState = ref.watch(portfolioControllerProvider);
    final portfolioController = ref.read(portfolioControllerProvider.notifier);
    final orderedItems = portfolioState.orderedItems;
    final visibleItems = _visibleItems(orderedItems);
    final wishlistStatusByItemId = portfolioState.items.isEmpty
        ? const <String, WishlistStatus>{}
        : ref
              .watch(wishlistEntriesProvider)
              .maybeWhen<Map<String, WishlistStatus>>(
                data: (entries) => {
                  for (final entry in entries) entry.itemId: entry.status,
                },
                orElse: () => const {},
              );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        key: const PageStorageKey<String>('portfolio-scroll-position'),
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: PortfolioHeroHeader(scrollController: _scrollController),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PortfolioActionTile(
                            icon: Icons.sort,
                            title: 'Sort',
                            onTap: () => _showSortSheet(context),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PortfolioActionTile(
                            icon: Icons.filter_alt,
                            title: 'Filter',
                            onTap: () => _showFilterSheet(context),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          PortfolioActionTile(
                            icon: Icons.add,
                            title: 'Add Item',
                            isPrimary: true,
                            onTap: widget.onScanPressed,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (portfolioState.items.isNotEmpty) ...[
                        PortfolioSectionCard(
                          title: 'Find Items',
                          child: _PortfolioControls(
                            searchQuery: _searchQuery,
                            categoryFilter: _categoryFilter,
                            onSearchChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            onCategoryFilterChanged: (value) {
                              setState(() {
                                _categoryFilter = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      PortfolioSectionCard(
                        title: 'Portfolio Snapshot',
                        child: PortfolioSummaryCard(
                          totalValue: portfolioState.totalValue,
                          itemCount: portfolioState.itemCount,
                          averageConfidence: _averageConfidence(orderedItems),
                          categoryCount: _categoryCount(orderedItems),
                          topAssetTitle: _topAssetTitle(orderedItems),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (portfolioState.isLoading &&
                          portfolioState.items.isEmpty)
                        const SizedBox.shrink()
                      else if (portfolioState.errorMessage != null)
                        const SizedBox.shrink()
                      else if (portfolioState.items.isEmpty)
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                if (portfolioState.isLoading && portfolioState.items.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _PortfolioSliverBox(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (portfolioState.errorMessage != null) {
                  return SliverToBoxAdapter(
                    child: _PortfolioSliverBox(
                      child: PortfolioErrorState(
                        message: portfolioState.errorMessage!,
                      ),
                    ),
                  );
                }

                if (portfolioState.items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _PortfolioSliverBox(
                      child: PortfolioEmptyState(
                        onScanPressed: widget.onScanPressed,
                      ),
                    ),
                  );
                }

                if (visibleItems.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _PortfolioSliverBox(
                      child: PortfolioNoSearchResultsState(
                        onResetFilters: () {
                          setState(() {
                            _searchQuery = '';
                            _categoryFilter = _PortfolioCategoryFilter.all;
                            _confidenceFilter = _PortfolioConfidenceFilter.all;
                            _trendFilter = _PortfolioTrendFilter.all;
                            _sortMode = _PortfolioSortMode.newest;
                          });
                        },
                      ),
                    ),
                  );
                }

                final crossAxisCount = constraints.crossAxisExtent < 360
                    ? 1
                    : constraints.crossAxisExtent >= 720
                    ? 3
                    : 2;
                final childAspectRatio = switch (crossAxisCount) {
                  1 => 0.58,
                  2 => 0.47,
                  _ => 0.58,
                };

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Collection Items',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${visibleItems.length} item${visibleItems.length == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: AppSpacing.xl,
                        crossAxisSpacing: AppSpacing.lg,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = visibleItems[index];

                        return MotionReveal(
                          key: ValueKey('portfolio-grid-motion-${item.id}'),
                          offset: 12,
                          delay: Duration(milliseconds: index * 40),
                          curve: Curves.easeOutCubic,
                          child: PortfolioGridTile(
                            key: ValueKey('portfolio-grid-item-${item.id}'),
                            item: item,
                            wishlistStatusLabel: _wishlistStatusLabel(
                              wishlistStatusByItemId[item.id],
                            ),
                            onTap: () =>
                                _openItem(context, item, portfolioController),
                            onViewDetails: () =>
                                _openItem(context, item, portfolioController),
                            onEdit: () => _showEditComingSoon(context),
                            onDelete: () => _confirmDelete(
                              context,
                              item.id,
                              portfolioController,
                            ),
                          ),
                        );
                      }, childCount: visibleItems.length),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<CollectibleItem> _visibleItems(List<CollectibleItem> items) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final queryFilteredItems = normalizedQuery.isEmpty
        ? [...items]
        : items.where((item) {
            return item.title.toLowerCase().contains(normalizedQuery) ||
                item.category.toLowerCase().contains(normalizedQuery);
          }).toList();
    final filteredItems = queryFilteredItems
        .where((item) => _matchesCategoryFilter(item, _categoryFilter))
        .where((item) => _matchesConfidenceFilter(item, _confidenceFilter))
        .where((item) => _matchesTrendFilter(item, _trendFilter))
        .toList();

    filteredItems.sort((left, right) {
      return switch (_sortMode) {
        _PortfolioSortMode.newest => compareCollectiblesNewestFirst(
          left,
          right,
        ),
        _PortfolioSortMode.valueHigh => right.estimatedValue.compareTo(
          left.estimatedValue,
        ),
        _PortfolioSortMode.valueLow => left.estimatedValue.compareTo(
          right.estimatedValue,
        ),
        _PortfolioSortMode.confidence => right.confidence.compareTo(
          left.confidence,
        ),
        _PortfolioSortMode.trend => _trendRank(
          _normalizedTrend(right),
        ).compareTo(_trendRank(_normalizedTrend(left))),
        _PortfolioSortMode.category => left.category.toLowerCase().compareTo(
          right.category.toLowerCase(),
        ),
      };
    });
    return filteredItems;
  }

  bool _matchesCategoryFilter(
    CollectibleItem item,
    _PortfolioCategoryFilter filter,
  ) {
    final category = item.category.toLowerCase();
    final title = item.title.toLowerCase();
    final haystack = '$category $title';

    return switch (filter) {
      _PortfolioCategoryFilter.all => true,
      _PortfolioCategoryFilter.cards =>
        haystack.contains('card') || haystack.contains('tcg'),
      _PortfolioCategoryFilter.coins => haystack.contains('coin'),
      _PortfolioCategoryFilter.comics => haystack.contains('comic'),
      _PortfolioCategoryFilter.memorabilia =>
        haystack.contains('memorabilia') ||
            haystack.contains('sports') ||
            haystack.contains('autograph') ||
            haystack.contains('jersey'),
      _PortfolioCategoryFilter.other =>
        !_matchesCategoryFilter(item, _PortfolioCategoryFilter.cards) &&
            !_matchesCategoryFilter(item, _PortfolioCategoryFilter.coins) &&
            !_matchesCategoryFilter(item, _PortfolioCategoryFilter.comics) &&
            !_matchesCategoryFilter(item, _PortfolioCategoryFilter.memorabilia),
    };
  }

  bool _matchesConfidenceFilter(
    CollectibleItem item,
    _PortfolioConfidenceFilter filter,
  ) {
    return switch (filter) {
      _PortfolioConfidenceFilter.all => true,
      _PortfolioConfidenceFilter.high => item.confidence >= 0.80,
      _PortfolioConfidenceFilter.low => item.confidence < 0.80,
    };
  }

  bool _matchesTrendFilter(CollectibleItem item, _PortfolioTrendFilter filter) {
    final trend = _normalizedTrend(item);
    return switch (filter) {
      _PortfolioTrendFilter.all => true,
      _PortfolioTrendFilter.rising => trend == 'Rising',
      _PortfolioTrendFilter.stable => trend == 'Stable',
      _PortfolioTrendFilter.cooling => trend == 'Cooling',
    };
  }

  double _averageConfidence(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return 0;
    }

    return items.fold<double>(0, (sum, item) => sum + item.confidence) /
        items.length;
  }

  int _categoryCount(List<CollectibleItem> items) {
    return {
      for (final item in items)
        if (item.category.trim().isNotEmpty) item.category.trim().toLowerCase(),
    }.length;
  }

  String _topAssetTitle(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return 'None yet';
    }
    final sorted = [...items]
      ..sort(
        (left, right) => right.estimatedValue.compareTo(left.estimatedValue),
      );
    return sorted.first.title;
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    String itemId,
    PortfolioController portfolioController,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete item?'),
          content: const Text(
            'This collectible will be removed from your portfolio.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    await portfolioController.removeItem(itemId);
    return true;
  }

  void _openItem(
    BuildContext context,
    CollectibleItem item,
    PortfolioController portfolioController,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectibleDetailPage(
          item: item,
          onDelete: (id) async {
            final deleted = await _confirmDelete(
              context,
              id,
              portfolioController,
            );
            if (deleted && context.mounted) {
              Navigator.of(context).pop();
            }
            return deleted;
          },
        ),
      ),
    );
  }

  void _showEditComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit coming soon')));
  }

  Future<void> _showSortSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<_PortfolioSortMode>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      isScrollControlled: true,
      builder: (context) => _PortfolioPickerSheet<_PortfolioSortMode>(
        title: 'Sort portfolio',
        subtitle: 'Choose how your collection is ordered',
        selectedValue: _sortMode,
        values: _PortfolioSortMode.values,
        labelFor: (value) => value.label,
        iconFor: _sortIcon,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() => _sortMode = selected);
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<_PortfolioFilterSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      isScrollControlled: true,
      builder: (context) => _PortfolioFilterSheet(
        categoryFilter: _categoryFilter,
        confidenceFilter: _confidenceFilter,
        trendFilter: _trendFilter,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _categoryFilter = selected.category;
      _confidenceFilter = selected.confidence;
      _trendFilter = selected.trend;
    });
  }
}

String _normalizedTrend(CollectibleItem item) {
  final raw = item.marketSummary?.trendLabel.trim().toLowerCase() ?? '';
  if (raw.contains('ris') || raw.contains('up') || raw.contains('gain')) {
    return 'Rising';
  }
  if (raw.contains('cool') || raw.contains('fall') || raw.contains('down')) {
    return 'Cooling';
  }
  return 'Stable';
}

int _trendRank(String trend) {
  return switch (trend) {
    'Rising' => 3,
    'Stable' => 2,
    'Cooling' => 1,
    _ => 0,
  };
}

IconData _sortIcon(_PortfolioSortMode mode) {
  return switch (mode) {
    _PortfolioSortMode.valueHigh => Icons.south_east_rounded,
    _PortfolioSortMode.valueLow => Icons.north_east_rounded,
    _PortfolioSortMode.confidence => Icons.verified_outlined,
    _PortfolioSortMode.trend => Icons.trending_up_rounded,
    _PortfolioSortMode.category => Icons.category_outlined,
    _PortfolioSortMode.newest => Icons.schedule_rounded,
  };
}

IconData _categoryFilterIcon(_PortfolioCategoryFilter filter) {
  return switch (filter) {
    _PortfolioCategoryFilter.all => Icons.all_inclusive_rounded,
    _PortfolioCategoryFilter.cards => Icons.style_outlined,
    _PortfolioCategoryFilter.coins => Icons.monetization_on_outlined,
    _PortfolioCategoryFilter.comics => Icons.menu_book_outlined,
    _PortfolioCategoryFilter.memorabilia => Icons.sports_basketball_outlined,
    _PortfolioCategoryFilter.other => Icons.inventory_2_outlined,
  };
}

IconData _trendFilterIcon(_PortfolioTrendFilter filter) {
  return switch (filter) {
    _PortfolioTrendFilter.rising => Icons.trending_up_rounded,
    _PortfolioTrendFilter.cooling => Icons.trending_down_rounded,
    _PortfolioTrendFilter.stable => Icons.trending_flat_rounded,
    _PortfolioTrendFilter.all => Icons.query_stats_outlined,
  };
}

class _PortfolioFilterSelection {
  const _PortfolioFilterSelection({
    required this.category,
    required this.confidence,
    required this.trend,
  });

  final _PortfolioCategoryFilter category;
  final _PortfolioConfidenceFilter confidence;
  final _PortfolioTrendFilter trend;
}

class _PortfolioFilterSheet extends StatefulWidget {
  const _PortfolioFilterSheet({
    required this.categoryFilter,
    required this.confidenceFilter,
    required this.trendFilter,
  });

  final _PortfolioCategoryFilter categoryFilter;
  final _PortfolioConfidenceFilter confidenceFilter;
  final _PortfolioTrendFilter trendFilter;

  @override
  State<_PortfolioFilterSheet> createState() => _PortfolioFilterSheetState();
}

class _PortfolioFilterSheetState extends State<_PortfolioFilterSheet> {
  late _PortfolioCategoryFilter _category;
  late _PortfolioConfidenceFilter _confidence;
  late _PortfolioTrendFilter _trend;

  @override
  void initState() {
    super.initState();
    _category = widget.categoryFilter;
    _confidence = widget.confidenceFilter;
    _trend = widget.trendFilter;
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumSheetSurface(
      key: const ValueKey('portfolio-premium-filter-sheet-surface'),
      gradientStyle: GradientStyle.tealEmerald,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PremiumSheetHeader(
                title: 'Filter portfolio',
                subtitle: 'Refine your collection view',
                caption: 'Category, confidence, and market movement',
              ),
              const SizedBox(height: AppSpacing.xl),
              _PremiumFilterGroup<_PortfolioCategoryFilter>(
                title: 'Category',
                values: _PortfolioCategoryFilter.values,
                selectedValue: _category,
                labelFor: (value) => value.label,
                iconFor: _categoryFilterIcon,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              _PremiumConfidenceRangeFilter(
                selectedValue: _confidence,
                onChanged: (value) => setState(() => _confidence = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              _PremiumTrendFilterGroup(
                selectedValue: _trend,
                onChanged: (value) => setState(() => _trend = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              _PremiumSheetActions(
                primaryLabel: 'Apply filters',
                secondaryLabel: 'Clear filters',
                stackVertically: isNarrow,
                onPrimary: () => Navigator.of(context).pop(
                  _PortfolioFilterSelection(
                    category: _category,
                    confidence: _confidence,
                    trend: _trend,
                  ),
                ),
                onSecondary: () {
                  setState(() {
                    _category = _PortfolioCategoryFilter.all;
                    _confidence = _PortfolioConfidenceFilter.all;
                    _trend = _PortfolioTrendFilter.all;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PremiumFilterGroup<T> extends StatelessWidget {
  const _PremiumFilterGroup({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.labelFor,
    required this.onChanged,
    this.iconFor,
  });

  final String title;
  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelFor;
  final IconData Function(T value)? iconFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MotionReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final value in values)
                _PremiumFilterChip(
                  key: ValueKey(
                    'portfolio-premium-filter-chip-${_sheetSlug(labelFor(value))}',
                  ),
                  label: labelFor(value),
                  icon: iconFor?.call(value),
                  selected: selectedValue == value,
                  onTap: () => onChanged(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumConfidenceRangeFilter extends StatelessWidget {
  const _PremiumConfidenceRangeFilter({
    required this.selectedValue,
    required this.onChanged,
  });

  final _PortfolioConfidenceFilter selectedValue;
  final ValueChanged<_PortfolioConfidenceFilter> onChanged;

  RangeValues get _range {
    return switch (selectedValue) {
      _PortfolioConfidenceFilter.all => const RangeValues(0, 100),
      _PortfolioConfidenceFilter.high => const RangeValues(80, 100),
      _PortfolioConfidenceFilter.low => const RangeValues(0, 79),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final range = _range;

    return MotionReveal(
      child: DecoratedBox(
        key: const ValueKey('portfolio-premium-range-slider'),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.58),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Confidence',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _confidenceRangeLabel(selectedValue),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerLow,
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: AppRadius.md,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: AppRadius.lg,
                  ),
                  rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                ),
                child: RangeSlider(
                  values: range,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  labels: RangeLabels(
                    '${range.start.round()}%',
                    '${range.end.round()}%',
                  ),
                  onChanged: (values) {
                    final start = values.start;
                    final end = values.end;
                    if (start >= 70) {
                      onChanged(_PortfolioConfidenceFilter.high);
                    } else if (end <= 80) {
                      onChanged(_PortfolioConfidenceFilter.low);
                    } else {
                      onChanged(_PortfolioConfidenceFilter.all);
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final value in _PortfolioConfidenceFilter.values)
                    _PremiumFilterChip(
                      key: ValueKey(
                        'portfolio-premium-confidence-chip-${value.name}',
                      ),
                      label: value.label,
                      icon: value == _PortfolioConfidenceFilter.all
                          ? Icons.all_inclusive_rounded
                          : Icons.verified_outlined,
                      selected: selectedValue == value,
                      onTap: () => onChanged(value),
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

class _PremiumTrendFilterGroup extends StatelessWidget {
  const _PremiumTrendFilterGroup({
    required this.selectedValue,
    required this.onChanged,
  });

  final _PortfolioTrendFilter selectedValue;
  final ValueChanged<_PortfolioTrendFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MotionReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            key: const ValueKey('portfolio-premium-trend-badges'),
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final value in _PortfolioTrendFilter.values)
                _PremiumBadgeSelector(
                  label: value.label,
                  icon: _trendFilterIcon(value),
                  selected: selectedValue == value,
                  onTap: () => onChanged(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumFilterChip extends StatelessWidget {
  const _PremiumFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MotionTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PackLoxMotionTheme.fast,
        curve: PackLoxMotionTheme.tapCurve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.34)
                : colorScheme.outlineVariant.withValues(alpha: 0.70),
          ),
          boxShadow: selected ? AppElevation.level1 : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBadgeSelector extends StatelessWidget {
  const _PremiumBadgeSelector({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotionTapScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.62),
          ),
          boxShadow: selected ? AppElevation.accentGlow : null,
        ),
        child: PremiumBadge.trend(label: label, icon: icon, maxWidth: 116),
      ),
    );
  }
}

class _PremiumSheetSurface extends StatelessWidget {
  const _PremiumSheetSurface({
    required this.child,
    this.gradientStyle = GradientStyle.blueIndigo,
    super.key,
  });

  final Widget child;
  final GradientStyle gradientStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = PackLoxGradients.build(gradientStyle, context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return MotionElasticSheet(
      key: const ValueKey('portfolio-premium-elastic-sheet'),
      child: SafeArea(
        top: false,
        child: MotionParallax(
          scrollOffset: 0,
          depth: PackLoxMotionTheme.cardParallaxDepth,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            child: MotionAmbientGradient(
              gradientBuilder: gradientStyle == GradientStyle.purpleDeepBlue
                  ? PackLoxMotionTheme.ambientPurpleDeepBlue
                  : PackLoxMotionTheme.ambientBlueIndigo,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xxl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(
                        alpha: isDark ? 0.22 : 0.28,
                      ),
                      blurRadius: 36,
                      offset: const Offset(0, -12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    bottomInset + AppSpacing.xl,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MotionElasticSheet extends StatelessWidget {
  const MotionElasticSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (PackLoxMotionTheme.isTestMode) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: PackLoxMotionTheme.navSpringDuration,
      curve: PackLoxMotionTheme.navSpringCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _PremiumSheetHeader extends StatelessWidget {
  const _PremiumSheetHeader({
    required this.title,
    required this.subtitle,
    this.caption,
  });

  final String title;
  final String subtitle;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('portfolio-premium-sheet-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.68),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _PremiumSheetActions extends StatelessWidget {
  const _PremiumSheetActions({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.stackVertically,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final bool stackVertically;

  @override
  Widget build(BuildContext context) {
    final primary = _PremiumCTA.primary(label: primaryLabel, onTap: onPrimary);
    final secondary = _PremiumCTA.secondary(
      label: secondaryLabel,
      onTap: onSecondary,
    );

    return MotionReveal(
      child: stackVertically
          ? Column(
              key: const ValueKey('portfolio-premium-cta-stack'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                primary,
                const SizedBox(height: AppSpacing.sm),
                secondary,
              ],
            )
          : Row(
              key: const ValueKey('portfolio-premium-cta-row'),
              children: [
                Expanded(child: secondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: primary),
              ],
            ),
    );
  }
}

class _PremiumCTA extends StatelessWidget {
  const _PremiumCTA._({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  const _PremiumCTA.primary({
    required String label,
    required VoidCallback onTap,
  }) : this._(label: label, onTap: onTap, primary: true);

  const _PremiumCTA.secondary({
    required String label,
    required VoidCallback onTap,
  }) : this._(label: label, onTap: onTap, primary: false);

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MotionTapScale(
      onTap: onTap,
      child: DecoratedBox(
        key: ValueKey(
          primary
              ? 'portfolio-premium-primary-cta'
              : 'portfolio-premium-secondary-cta',
        ),
        decoration: BoxDecoration(
          gradient: primary ? AppGradients.primary : null,
          color: primary ? null : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: primary
              ? null
              : Border.all(color: colorScheme.outlineVariant),
          boxShadow: primary ? AppElevation.level1 : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              color: primary ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

String _confidenceRangeLabel(_PortfolioConfidenceFilter value) {
  return switch (value) {
    _PortfolioConfidenceFilter.all => '0%-100%',
    _PortfolioConfidenceFilter.high => '80%-100%',
    _PortfolioConfidenceFilter.low => '0%-79%',
  };
}

String _sheetSlug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class _PortfolioPickerSheet<T> extends StatelessWidget {
  const _PortfolioPickerSheet({
    required this.title,
    required this.subtitle,
    required this.selectedValue,
    required this.values,
    required this.labelFor,
    required this.iconFor,
  });

  final String title;
  final String subtitle;
  final T selectedValue;
  final List<T> values;
  final String Function(T value) labelFor;
  final IconData Function(T value) iconFor;

  @override
  Widget build(BuildContext context) {
    return _PremiumSheetSurface(
      key: const ValueKey('portfolio-premium-sort-sheet-surface'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PremiumSheetHeader(
            title: title,
            subtitle: subtitle,
            caption: 'Premium ordering for collection review',
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var index = 0; index < values.length; index++) ...[
            _PremiumSortTile<T>(
              value: values[index],
              label: labelFor(values[index]),
              icon: iconFor(values[index]),
              selected: selectedValue == values[index],
              delay: Duration(milliseconds: index * 40),
            ),
            if (index != values.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PremiumSortTile<T> extends StatelessWidget {
  const _PremiumSortTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.delay,
  });

  final T value;
  final String label;
  final IconData icon;
  final bool selected;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MotionReveal(
      delay: delay,
      child: MotionTapScale(
        onTap: () => Navigator.of(context).pop(value),
        child: DecoratedBox(
          key: ValueKey('portfolio-premium-sort-tile-${_sheetSlug(label)}'),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.38)
                  : colorScheme.outlineVariant.withValues(alpha: 0.64),
            ),
            boxShadow: selected ? AppElevation.level1 : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 22, color: colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedContainer(
                  duration: PackLoxMotionTheme.fast,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioSliverBox extends StatelessWidget {
  const _PortfolioSliverBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, minHeight: 160),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

String? _wishlistStatusLabel(WishlistStatus? status) {
  return switch (status) {
    WishlistStatus.owned => 'Owned',
    WishlistStatus.wanted => 'Wanted',
    WishlistStatus.missing => 'Missing',
    null => null,
  };
}

class _PortfolioControls extends StatelessWidget {
  const _PortfolioControls({
    required this.searchQuery,
    required this.categoryFilter,
    required this.onSearchChanged,
    required this.onCategoryFilterChanged,
  });

  final String searchQuery;
  final _PortfolioCategoryFilter categoryFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_PortfolioCategoryFilter> onCategoryFilterChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchField = TextFormField(
          key: const ValueKey('portfolio-search-field'),
          initialValue: searchQuery,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search items',
            isDense: true,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchField,
            const SizedBox(height: AppSpacing.sm),
            _PortfolioCategoryFilterChips(
              selectedFilter: categoryFilter,
              onChanged: onCategoryFilterChanged,
            ),
          ],
        );
      },
    );
  }
}

class _PortfolioCategoryFilterChips extends StatelessWidget {
  const _PortfolioCategoryFilterChips({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _PortfolioCategoryFilter selectedFilter;
  final ValueChanged<_PortfolioCategoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const visibleFilters = [
      _PortfolioCategoryFilter.all,
      _PortfolioCategoryFilter.cards,
      _PortfolioCategoryFilter.coins,
      _PortfolioCategoryFilter.comics,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in visibleFilters) ...[
            ChoiceChip(
              key: ValueKey('portfolio-filter-${filter.name}'),
              label: Text(filter.label),
              selected: selectedFilter == filter,
              onSelected: (_) => onChanged(filter),
            ),
            if (filter != visibleFilters.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
