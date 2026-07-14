import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/features/wishlist/presentation/controllers/wishlist_providers.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
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
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
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
      key: const ValueKey('portfolio-screen-scaffold'),
      backgroundColor: PackLoxTokens.background,
      body: SafeArea(
        bottom: false,
        child: ColoredBox(
          key: const ValueKey('portfolio-screen-surface'),
          color: PackLoxTokens.background,
          child: LayoutBuilder(
            builder: (context, viewport) {
              final horizontalPadding = viewport.maxWidth <= 360
                  ? AppSpacing.md
                  : AppSpacing.lg;

              return CustomScrollView(
                key: const ValueKey('portfolio-scroll-view'),
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _PortfolioFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.sm,
                      child: const PackLoxHeader(
                        firstName: '',
                        fallbackName: 'My Collection',
                        greetingText: 'Portfolio',
                        onNotifications: null,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _PortfolioFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.sm,
                      child: _PortfolioControls(
                        searchQuery: _searchQuery,
                        categoryFilter: _categoryFilter,
                        onSearchChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onSearchCleared: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        onCategoryFilterChanged: (value) {
                          setState(() {
                            _categoryFilter = value;
                          });
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _PortfolioFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.sm,
                      child: _CollectionOverview(
                        totalValue: portfolioState.totalValue,
                        itemCount: portfolioState.itemCount,
                        valuedItemCount: _valuedItemCount(orderedItems),
                        unvaluedItemCount: _unvaluedItemCount(orderedItems),
                        categoryCount: _categoryCount(orderedItems),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _PortfolioFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.sm,
                      bottomPadding: AppSpacing.md,
                      child: _PortfolioCommandBar(
                        onSort: () => _showSortSheet(context),
                        onFilter: () => _showFilterSheet(context),
                        onAddItem: widget.onScanPressed,
                        activeFilterCount: _activeFilterCount,
                        sortLabel: _sortMode.label,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      176,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        if (portfolioState.isLoading &&
                            portfolioState.items.isEmpty) {
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
                                    _categoryFilter =
                                        _PortfolioCategoryFilter.all;
                                    _confidenceFilter =
                                        _PortfolioConfidenceFilter.all;
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
                          1 => 0.64,
                          2 => 0.56,
                          _ => 0.62,
                        };

                        return SliverMainAxisGroup(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 960,
                                  ),
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
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          '${visibleItems.length} item${visibleItems.length == 1 ? '' : 's'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
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
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: AppSpacing.xl,
                                    crossAxisSpacing: AppSpacing.md,
                                    childAspectRatio: childAspectRatio,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final item = visibleItems[index];

                                return MotionReveal(
                                  key: ValueKey(
                                    'portfolio-grid-motion-${item.id}',
                                  ),
                                  offset: 12,
                                  delay: Duration(milliseconds: index * 40),
                                  curve: Curves.easeOutCubic,
                                  child: PortfolioGridTile(
                                    key: ValueKey(
                                      'portfolio-grid-item-${item.id}',
                                    ),
                                    item: item,
                                    wishlistStatusLabel: _wishlistStatusLabel(
                                      wishlistStatusByItemId[item.id],
                                    ),
                                    onTap: () => _openItem(
                                      context,
                                      item,
                                      portfolioController,
                                    ),
                                    onViewDetails: () => _openItem(
                                      context,
                                      item,
                                      portfolioController,
                                    ),
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
              );
            },
          ),
        ),
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

  int get _activeFilterCount {
    var count = 0;
    if (_categoryFilter != _PortfolioCategoryFilter.all) {
      count++;
    }
    if (_confidenceFilter != _PortfolioConfidenceFilter.all) {
      count++;
    }
    if (_trendFilter != _PortfolioTrendFilter.all) {
      count++;
    }
    return count;
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

  int _categoryCount(List<CollectibleItem> items) {
    return {
      for (final item in items)
        if (item.category.trim().isNotEmpty) item.category.trim().toLowerCase(),
    }.length;
  }

  int _valuedItemCount(List<CollectibleItem> items) {
    return items.where(_hasDisplayableValuation).length;
  }

  int _unvaluedItemCount(List<CollectibleItem> items) {
    return items.where((item) => !_hasDisplayableValuation(item)).length;
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
            style: textTheme.titleSmall?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
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
          color: PackLoxTokens.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: PackLoxTokens.border.withValues(alpha: 0.68),
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
                        color: PackLoxTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _confidenceRangeLabel(selectedValue),
                    style: textTheme.labelSmall?.copyWith(
                      color: PackLoxTokens.textSecondary,
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
            style: textTheme.titleSmall?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
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
              ? colorScheme.primary.withValues(alpha: 0.18)
              : PackLoxTokens.surface.withValues(alpha: 0.72),
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
                  color: PackLoxTokens.textPrimary,
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
    final textTheme = Theme.of(context).textTheme;

    return MotionTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : PackLoxTokens.border.withValues(alpha: 0.68),
          ),
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.18)
              : PackLoxTokens.surface.withValues(alpha: 0.78),
          boxShadow: selected ? AppElevation.accentGlow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: PackLoxTokens.textPrimary,
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return MotionElasticSheet(
      key: const ValueKey('portfolio-premium-elastic-sheet'),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _portfolioRaisedSurfaceColor(colorScheme),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              border: Border(
                top: BorderSide(
                  color: _portfolioSurfaceBorderColor(colorScheme),
                ),
              ),
              boxShadow: AppElevation.level2,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                bottomInset + AppSpacing.lg,
              ),
              child: child,
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
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('portfolio-premium-sheet-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(
            color: PackLoxTokens.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: PackLoxTokens.textSecondary,
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
              color: PackLoxTokens.textSecondary.withValues(alpha: 0.78),
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
          color: primary ? null : PackLoxTokens.surface.withValues(alpha: 0.72),
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
              color: primary ? Colors.white : PackLoxTokens.textPrimary,
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
            color: PackLoxTokens.surface.withValues(alpha: 0.72),
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
                      color: PackLoxTokens.textPrimary,
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

class _PortfolioFrame extends StatelessWidget {
  const _PortfolioFrame({
    required this.horizontalPadding,
    required this.child,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CollectionOverview extends StatelessWidget {
  const _CollectionOverview({
    required this.totalValue,
    required this.itemCount,
    required this.valuedItemCount,
    required this.unvaluedItemCount,
    required this.categoryCount,
  });

  final double totalValue;
  final int itemCount;
  final int valuedItemCount;
  final int unvaluedItemCount;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueLabel = itemCount == 0
        ? _formatPortfolioMoney(0)
        : valuedItemCount == 0
        ? '-'
        : _formatPortfolioMoney(totalValue);
    final valuationLabel = unvaluedItemCount == 0
        ? 'All valued'
        : '$unvaluedItemCount unvalued';

    return Semantics(
      container: true,
      label:
          'Portfolio summary. $itemCount items. $valueLabel total estimated value. $valuationLabel.',
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          key: const ValueKey('portfolio-compact-snapshot'),
          decoration: BoxDecoration(
            color: _portfolioRaisedSurfaceColor(colorScheme),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _portfolioSurfaceBorderColor(colorScheme),
            ),
            boxShadow: AppElevation.level1,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = ((constraints.maxWidth - AppSpacing.sm) / 2)
                    .clamp(126.0, 240.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      key: const ValueKey('portfolio-compact-metrics-grid'),
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _OverviewMetric(
                          width: tileWidth,
                          label: 'Total Items',
                          value: itemCount.toString(),
                          icon: Icons.inventory_2_outlined,
                          emphasized: true,
                        ),
                        _OverviewMetric(
                          width: tileWidth,
                          label: 'Total Value (Est.)',
                          value: valueLabel,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        _OverviewMetric(
                          width: tileWidth,
                          label: 'Valued',
                          value: valuedItemCount.toString(),
                          icon: Icons.price_check_outlined,
                        ),
                        _OverviewMetric(
                          width: tileWidth,
                          label: 'Categories',
                          value: categoryCount.toString(),
                          icon: Icons.category_outlined,
                        ),
                      ],
                    ),
                    if (unvaluedItemCount > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _PartialValuationNote(count: unvaluedItemCount),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        key: ValueKey('portfolio-summary-metric-${label.toLowerCase()}'),
        decoration: BoxDecoration(
          color: emphasized
              ? colorScheme.primary.withValues(alpha: 0.10)
              : PackLoxTokens.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: emphasized
                ? colorScheme.primary.withValues(alpha: 0.28)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: PackLoxTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: PackLoxTokens.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartialValuationNote extends StatelessWidget {
  const _PartialValuationNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: PackLoxTokens.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '$count item${count == 1 ? '' : 's'} still need reliable valuation data.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PortfolioCommandBar extends StatelessWidget {
  const _PortfolioCommandBar({
    required this.onSort,
    required this.onFilter,
    required this.onAddItem,
    required this.activeFilterCount,
    required this.sortLabel,
  });

  final VoidCallback onSort;
  final VoidCallback onFilter;
  final VoidCallback? onAddItem;
  final int activeFilterCount;
  final String sortLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360;
        final tools = Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ToolButton(
              key: const ValueKey('portfolio-action-sort'),
              icon: Icons.sort,
              label: 'Sort',
              value: sortLabel,
              onPressed: onSort,
            ),
            _ToolButton(
              key: const ValueKey('portfolio-action-filter'),
              icon: Icons.filter_alt_outlined,
              label: 'Filter',
              value: activeFilterCount == 0
                  ? 'All'
                  : '$activeFilterCount active',
              onPressed: onFilter,
            ),
          ],
        );
        final addButton = SizedBox(
          key: const ValueKey('portfolio-action-add-item'),
          height: 44,
          child: FilledButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tools,
              const SizedBox(height: AppSpacing.sm),
              addButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: tools),
            const SizedBox(width: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 148),
              child: addButton,
            ),
          ],
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: '$label: $value',
      child: SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text('$label: $value', overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: PackLoxTokens.textPrimary,
            backgroundColor: _portfolioRaisedSurfaceColor(colorScheme),
            side: BorderSide(color: _portfolioSurfaceBorderColor(colorScheme)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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

bool _hasDisplayableValuation(CollectibleItem item) {
  return switch (item.valuationStatus) {
    ValuationStatus.marketEstimated || ValuationStatus.aiEstimated => true,
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.noMarketMatch ||
    ValuationStatus.lookupFailed ||
    ValuationStatus.unavailable => item.estimatedValue > 0,
  };
}

String _formatPortfolioMoney(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

Color _portfolioRaisedSurfaceColor(ColorScheme colorScheme) {
  return PackLoxTokens.surfaceRaised.withValues(
    alpha: colorScheme.brightness == Brightness.dark ? 0.94 : 0.90,
  );
}

Color _portfolioSurfaceBorderColor(ColorScheme colorScheme) {
  return PackLoxTokens.border.withValues(
    alpha: colorScheme.brightness == Brightness.dark ? 0.82 : 0.68,
  );
}

class _PortfolioControls extends StatelessWidget {
  const _PortfolioControls({
    required this.searchQuery,
    required this.categoryFilter,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onCategoryFilterChanged,
  });

  final String searchQuery;
  final _PortfolioCategoryFilter categoryFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<_PortfolioCategoryFilter> onCategoryFilterChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorScheme = Theme.of(context).colorScheme;
        final searchField = TextFormField(
          key: ValueKey('portfolio-search-field-$searchQuery'),
          initialValue: searchQuery,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: PackLoxTokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.trim().isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('portfolio-search-clear'),
                    tooltip: 'Clear portfolio search',
                    icon: const Icon(Icons.close),
                    onPressed: onSearchCleared,
                  ),
            hintText: 'Search items',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            isDense: true,
            filled: true,
            fillColor: _portfolioRaisedSurfaceColor(colorScheme),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: _portfolioSurfaceBorderColor(colorScheme),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: _portfolioSurfaceBorderColor(colorScheme),
              ),
            ),
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
    final colorScheme = Theme.of(context).colorScheme;
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
              backgroundColor: _portfolioRaisedSurfaceColor(colorScheme),
              selectedColor: colorScheme.primary.withValues(alpha: 0.18),
              side: BorderSide(
                color: selectedFilter == filter
                    ? colorScheme.primary.withValues(alpha: 0.52)
                    : _portfolioSurfaceBorderColor(colorScheme),
              ),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: PackLoxTokens.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              checkmarkColor: PackLoxTokens.textPrimary,
            ),
            if (filter != visibleFilters.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
