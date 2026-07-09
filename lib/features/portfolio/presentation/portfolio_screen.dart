import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/portfolio/portfolio_ui.dart';
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
  newest(label: 'Newest'),
  value(label: 'Highest value'),
  confidence(label: 'Highest confidence'),
  name(label: 'Name A-Z');

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

                final crossAxisCount = constraints.crossAxisExtent >= 720
                    ? 3
                    : 2;

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
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: crossAxisCount == 3 ? 0.80 : 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = visibleItems[index];

                        return MotionReveal(
                          key: ValueKey('portfolio-grid-motion-${item.id}'),
                          offset: 12,
                          delay: Duration(milliseconds: 24 * (index % 8)),
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
        _PortfolioSortMode.value => right.estimatedValue.compareTo(
          left.estimatedValue,
        ),
        _PortfolioSortMode.confidence => right.confidence.compareTo(
          left.confidence,
        ),
        _PortfolioSortMode.name => left.title.toLowerCase().compareTo(
          right.title.toLowerCase(),
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
      showDragHandle: true,
      builder: (context) => _PortfolioPickerSheet<_PortfolioSortMode>(
        title: 'Sort portfolio',
        selectedValue: _sortMode,
        values: _PortfolioSortMode.values,
        labelFor: (value) => value.label,
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
      showDragHandle: true,
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
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter portfolio',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _FilterChoiceGroup<_PortfolioCategoryFilter>(
              title: 'Category',
              values: _PortfolioCategoryFilter.values,
              selectedValue: _category,
              labelFor: (value) => value.label,
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FilterChoiceGroup<_PortfolioConfidenceFilter>(
              title: 'Confidence range',
              values: _PortfolioConfidenceFilter.values,
              selectedValue: _confidence,
              labelFor: (value) => value.label,
              onChanged: (value) => setState(() => _confidence = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FilterChoiceGroup<_PortfolioTrendFilter>(
              title: 'Trend',
              values: _PortfolioTrendFilter.values,
              selectedValue: _trend,
              labelFor: (value) => value.label,
              onChanged: (value) => setState(() => _trend = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _PortfolioFilterSelection(
                    category: _category,
                    confidence: _confidence,
                    trend: _trend,
                  ),
                ),
                child: const Text('Apply filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChoiceGroup<T> extends StatelessWidget {
  const _FilterChoiceGroup({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.labelFor,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(labelFor(value)),
                selected: selectedValue == value,
                onSelected: (_) => onChanged(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _PortfolioPickerSheet<T> extends StatelessWidget {
  const _PortfolioPickerSheet({
    required this.title,
    required this.selectedValue,
    required this.values,
    required this.labelFor,
  });

  final String title;
  final T selectedValue;
  final List<T> values;
  final String Function(T value) labelFor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final value in values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(labelFor(value)),
                  trailing: selectedValue == value
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
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
