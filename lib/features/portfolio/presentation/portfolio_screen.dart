import 'package:collectiq_ai/core/design_system/design_system.dart';
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
  newest(label: 'Newest first'),
  value(label: 'Value high to low'),
  confidence(label: 'Confidence high to low');

  const _PortfolioSortMode({required this.label});

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
    final categories = _groupByCategory(visibleItems);
    final wishlistStatusByItemId = ref
        .watch(wishlistEntriesProvider)
        .maybeWhen<Map<String, WishlistStatus>>(
          data: (entries) => {
            for (final entry in entries) entry.itemId: entry.status,
          },
          orElse: () => const {},
        );
    _logPortfolioOrder(visibleItems);

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          const SizedBox(width: 12),
                          PortfolioActionTile(
                            icon: Icons.filter_alt,
                            title: 'Filter',
                            onTap: () => _showFilterSheet(context),
                          ),
                          const SizedBox(width: 12),
                          PortfolioActionTile(
                            icon: Icons.add,
                            title: 'Add Item',
                            onTap: widget.onScanPressed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (portfolioState.items.isNotEmpty) ...[
                        PortfolioSectionCard(
                          title: 'Find Items',
                          subtitle: 'Search and refine your saved collectibles',
                          child: _PortfolioControls(
                            searchQuery: _searchQuery,
                            sortMode: _sortMode,
                            categoryFilter: _categoryFilter,
                            onSearchChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            onSortChanged: (value) {
                              setState(() {
                                _sortMode = value;
                              });
                            },
                            onCategoryFilterChanged: (value) {
                              setState(() {
                                _categoryFilter = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      PortfolioSectionCard(
                        title: 'Portfolio Snapshot',
                        subtitle: 'PackLox collection value and confidence',
                        child: PortfolioSummaryCard(
                          totalValue: portfolioState.totalValue,
                          itemCount: portfolioState.itemCount,
                          averageConfidence: _averageConfidence(orderedItems),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (portfolioState.isLoading &&
                          portfolioState.items.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (portfolioState.errorMessage != null)
                        PortfolioErrorState(
                          message: portfolioState.errorMessage!,
                        )
                      else if (portfolioState.items.isEmpty)
                        PortfolioEmptyState(onScanPressed: widget.onScanPressed)
                      else ...[
                        if (visibleItems.isEmpty)
                          PortfolioNoSearchResultsState(
                            onResetFilters: () {
                              setState(() {
                                _searchQuery = '';
                                _categoryFilter = _PortfolioCategoryFilter.all;
                              });
                            },
                          )
                        else
                          for (final category in categories) ...[
                            CategoryHeader(
                              title: category.name,
                              subtitle:
                                  '${category.items.length} ${category.items.length == 1 ? 'item' : 'items'}',
                              gradientStyle: GradientStyle.tealEmerald,
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < category.items.length;
                                  i++
                                ) ...[
                                  Transform.translate(
                                    offset: Offset(0, i * 8.0),
                                    child: PortfolioGlassItemCard(
                                      key: ValueKey(
                                        'portfolio-item-${category.items[i].id}',
                                      ),
                                      item: category.items[i],
                                      index: i,
                                      wishlistStatusLabel: _wishlistStatusLabel(
                                        wishlistStatusByItemId[category
                                            .items[i]
                                            .id],
                                      ),
                                      onTap: () => _openItem(
                                        context,
                                        category.items[i],
                                        portfolioController,
                                      ),
                                      onEdit: () => _openItem(
                                        context,
                                        category.items[i],
                                        portfolioController,
                                      ),
                                      onShare: () => _showShareMessage(
                                        context,
                                        category.items[i],
                                      ),
                                      onDelete: () => _confirmDelete(
                                        context,
                                        category.items[i].id,
                                        portfolioController,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                            const SizedBox(height: 36),
                          ],
                      ],
                    ],
                  ),
                ),
              ),
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
      };
    });
    return filteredItems;
  }

  List<_PortfolioCategorySection> _groupByCategory(
    List<CollectibleItem> items,
  ) {
    final sections = <String, List<CollectibleItem>>{};
    for (final item in items) {
      final name = item.category.trim().isEmpty
          ? 'Other'
          : item.category.trim();
      sections.putIfAbsent(name, () => []).add(item);
    }

    return [
      for (final entry in sections.entries)
        _PortfolioCategorySection(name: entry.key, items: entry.value),
    ];
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

  double _averageConfidence(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return 0;
    }

    return items.fold<double>(0, (sum, item) => sum + item.confidence) /
        items.length;
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

  void _showShareMessage(BuildContext context, CollectibleItem item) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Share ready for ${item.title}')));
  }

  Future<void> _showSortSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<_PortfolioSortMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PortfolioPickerSheet<_PortfolioSortMode>(
        title: 'Sort Collections',
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
    final selected = await showModalBottomSheet<_PortfolioCategoryFilter>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PortfolioPickerSheet<_PortfolioCategoryFilter>(
        title: 'Filter Collections',
        selectedValue: _categoryFilter,
        values: _PortfolioCategoryFilter.values,
        labelFor: (value) => value.label,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() => _categoryFilter = selected);
  }
}

class _PortfolioCategorySection {
  const _PortfolioCategorySection({required this.name, required this.items});

  final String name;
  final List<CollectibleItem> items;
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

void _logPortfolioOrder(List<CollectibleItem> items) {
  debugPrint(
    '[PortfolioScreen] final render order: '
    '${items.map((item) => '${item.id}@${collectibleDisplayTimestamp(item).toIso8601String()}').join(' > ')}',
  );
  for (final item in items) {
    debugPrint(
      '[PortfolioScreen] render item '
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

class _PortfolioControls extends StatelessWidget {
  const _PortfolioControls({
    required this.searchQuery,
    required this.sortMode,
    required this.categoryFilter,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onCategoryFilterChanged,
  });

  final String searchQuery;
  final _PortfolioSortMode sortMode;
  final _PortfolioCategoryFilter categoryFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_PortfolioSortMode> onSortChanged;
  final ValueChanged<_PortfolioCategoryFilter> onCategoryFilterChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchField = TextFormField(
          key: const ValueKey('portfolio-search-field'),
          initialValue: searchQuery,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search portfolio',
          ),
        );
        final sortSelector = _PortfolioSortSelector(
          sortMode: sortMode,
          onSortChanged: onSortChanged,
        );

        final searchAndSort = constraints.maxWidth >= 680
            ? Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(width: 360, child: sortSelector),
                ],
              )
            : Column(
                children: [
                  searchField,
                  const SizedBox(height: AppSpacing.md),
                  sortSelector,
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchAndSort,
            const SizedBox(height: AppSpacing.md),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _PortfolioCategoryFilter.values) ...[
            ChoiceChip(
              key: ValueKey('portfolio-filter-${filter.name}'),
              label: Text(filter.label),
              selected: selectedFilter == filter,
              onSelected: (_) => onChanged(filter),
            ),
            if (filter != _PortfolioCategoryFilter.values.last)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PortfolioSortSelector extends StatelessWidget {
  const _PortfolioSortSelector({
    required this.sortMode,
    required this.onSortChanged,
  });

  final _PortfolioSortMode sortMode;
  final ValueChanged<_PortfolioSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return AppStableSegmentedSelector<_PortfolioSortMode>(
      selectedValue: sortMode,
      onChanged: onSortChanged,
      options: const [
        AppSegmentOption(value: _PortfolioSortMode.newest, label: 'Newest'),
        AppSegmentOption(value: _PortfolioSortMode.value, label: 'Value'),
        AppSegmentOption(
          value: _PortfolioSortMode.confidence,
          label: 'Confidence',
        ),
      ],
    );
  }
}
