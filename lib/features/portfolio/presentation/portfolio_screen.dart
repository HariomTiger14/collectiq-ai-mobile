import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _PortfolioSortMode {
  newest(label: 'Recently added'),
  valueHigh(label: 'Value: high to low'),
  valueLow(label: 'Value: low to high'),
  status(label: 'Status'),
  category(label: 'Category');

  const _PortfolioSortMode({required this.label});

  final String label;

  String get compactLabel {
    return switch (this) {
      _PortfolioSortMode.newest => 'Recent',
      _PortfolioSortMode.valueHigh => 'High value',
      _PortfolioSortMode.valueLow => 'Low value',
      _PortfolioSortMode.status => 'Status',
      _PortfolioSortMode.category => 'Category',
    };
  }
}

enum _PortfolioStatusFilter {
  all(label: 'All'),
  valued(label: 'Valued'),
  pending(label: 'Pending'),
  needsAttention(label: 'Needs attention');

  const _PortfolioStatusFilter({required this.label});

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

enum PortfolioPreviewScenario {
  defaultData(
    label: 'Default',
    subtitle: 'Saved items with values and pending work.',
  ),
  empty(
    label: 'Empty',
    subtitle: 'No saved collectibles and one clear scan path.',
  ),
  loading(
    label: 'Loading',
    subtitle: 'Structured skeleton for portfolio refresh.',
  ),
  error(label: 'Error', subtitle: 'Retry state for a failed portfolio load.'),
  partial(
    label: 'Partial',
    subtitle: 'Confirmed values plus pending valuations in amber.',
  ),
  filteredEmpty(
    label: 'Filtered empty',
    subtitle: 'Saved items exist, but search/filter returns no results.',
  );

  const PortfolioPreviewScenario({required this.label, required this.subtitle});

  final String label;
  final String subtitle;
}

enum PortfolioSheetPreview { defaultState, selected }

enum PortfolioSearchPreview { active, results, empty, filterEmpty }

final portfolioPreviewScenarioProvider =
    NotifierProvider<
      PortfolioPreviewScenarioController,
      PortfolioPreviewScenario?
    >(PortfolioPreviewScenarioController.new);

class PortfolioPreviewScenarioController
    extends Notifier<PortfolioPreviewScenario?> {
  @override
  PortfolioPreviewScenario? build() => null;

  void select(PortfolioPreviewScenario? scenario) {
    state = scenario;
  }
}

class PortfolioStatePreviewScreen extends ConsumerWidget {
  const PortfolioStatePreviewScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const PortfolioStatePreviewScreen(),
      settings: const RouteSettings(name: '/settings/portfolio-preview'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: HomeTokens.background,
        appBar: AppBar(
          title: const Text('Portfolio State Preview'),
          backgroundColor: HomeTokens.background,
          foregroundColor: HomeTokens.textPrimary,
        ),
        body: HomeStateContainer(
          sections: [
            const HomeSection(child: HomeBrandLockup()),
            HomeSection(
              child: HomeSectionSurface(
                keySeed: 'portfolio-preview-scenario-picker',
                title: 'Portfolio states',
                child: Column(
                  children: [
                    for (final scenario in PortfolioPreviewScenario.values) ...[
                      HomeActionRow(
                        keySeed: 'portfolio-preview-${scenario.name}',
                        icon: _previewIcon(scenario),
                        title: scenario.label,
                        subtitle: scenario.subtitle,
                        onTap: () => _selectScenario(context, ref, scenario),
                      ),
                      if (scenario != PortfolioPreviewScenario.values.last)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    HomeActionRow(
                      keySeed: 'portfolio-preview-clear',
                      icon: Icons.layers_clear_outlined,
                      title: 'Clear preview',
                      subtitle: 'Return Portfolio to live local data.',
                      onTap: () => _selectScenario(context, ref, null),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _previewIcon(PortfolioPreviewScenario scenario) {
    return switch (scenario) {
      PortfolioPreviewScenario.defaultData => Icons.inventory_2_outlined,
      PortfolioPreviewScenario.empty => Icons.add_box_outlined,
      PortfolioPreviewScenario.loading => Icons.blur_on_outlined,
      PortfolioPreviewScenario.error => Icons.error_outline,
      PortfolioPreviewScenario.partial => Icons.pending_actions_outlined,
      PortfolioPreviewScenario.filteredEmpty => Icons.filter_alt_off_outlined,
    };
  }

  void _selectScenario(
    BuildContext context,
    WidgetRef ref,
    PortfolioPreviewScenario? scenario,
  ) {
    ref.read(portfolioPreviewScenarioProvider.notifier).select(scenario);
    ref
        .read(appShellTabControllerProvider.notifier)
        .selectTab(AppShellTabController.portfolioTab);
    Navigator.of(context).pop();
  }
}

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({
    this.onScanPressed,
    this.previewScenario,
    this.qaInitialScrollOffset = 0,
    this.qaInitialSheet,
    this.qaSearchPreview,
    super.key,
  });

  final VoidCallback? onScanPressed;
  final PortfolioPreviewScenario? previewScenario;
  final double qaInitialScrollOffset;
  final PortfolioSheetPreview? qaInitialSheet;
  final PortfolioSearchPreview? qaSearchPreview;

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  late final ScrollController _scrollController;
  late String _searchQuery;
  bool _filteredPreviewCleared = false;
  _PortfolioSortMode _sortMode = _PortfolioSortMode.newest;
  _PortfolioStatusFilter _statusFilter = _PortfolioStatusFilter.all;
  _PortfolioCategoryFilter _categoryFilter = _PortfolioCategoryFilter.all;
  _PortfolioConfidenceFilter _confidenceFilter = _PortfolioConfidenceFilter.all;
  _PortfolioTrendFilter _trendFilter = _PortfolioTrendFilter.all;

  @override
  void initState() {
    super.initState();
    _searchQuery = _initialSearchQuery(widget.qaSearchPreview);
    if (widget.qaSearchPreview == PortfolioSearchPreview.filterEmpty) {
      _categoryFilter = _PortfolioCategoryFilter.coins;
    }
    _scrollController = ScrollController(
      initialScrollOffset: widget.qaInitialScrollOffset,
      keepScrollOffset: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(portfolioControllerProvider.notifier).ensureLoaded();
      if (widget.qaInitialSheet != null) {
        _showSortFilterSheet(context, preview: widget.qaInitialSheet);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewScenario =
        widget.previewScenario ?? ref.watch(portfolioPreviewScenarioProvider);
    final isPreview = previewScenario != null;
    final portfolioState = isPreview
        ? _previewStateFor(previewScenario)
        : ref.watch(portfolioControllerProvider);
    final portfolioController = ref.read(portfolioControllerProvider.notifier);
    final effectiveSearchQuery = _effectiveSearchQuery(previewScenario);
    final orderedItems = _orderedItems(portfolioState.items);
    final visibleItems = _visibleItems(orderedItems, effectiveSearchQuery);
    final hasItems = portfolioState.items.isNotEmpty;
    final isFilteredEmpty = hasItems && visibleItems.isEmpty;
    final showLoading =
        portfolioState.isLoading && portfolioState.items.isEmpty;
    final showError =
        portfolioState.errorMessage != null && portfolioState.items.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: HomeTokens.background,
        systemNavigationBarDividerColor: HomeTokens.background,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Theme(
        data: AppTheme.dark,
        child: Scaffold(
          key: const ValueKey('portfolio-screen-scaffold'),
          backgroundColor: HomeTokens.background,
          body: SafeArea(
            bottom: false,
            child: ColoredBox(
              key: const ValueKey('portfolio-screen-surface'),
              color: HomeTokens.background,
              child: HomeStateContainer(
                controller: _scrollController,
                bottomClearance: GlassBottomNavBar.scrollContentClearance(
                  context,
                ),
                sections: [
                  const HomeSection(child: HomeBrandLockup()),
                  const HomeSection(child: _PortfolioTitleBlock()),
                  if (!showError)
                    HomeSection(
                      child: HomeAuthorityHero(
                        eyebrow: 'Portfolio overview',
                        title: _heroTitle(
                          state: portfolioState,
                          showLoading: showLoading,
                          isFilteredEmpty: isFilteredEmpty,
                          hasSearchQuery: effectiveSearchQuery
                              .trim()
                              .isNotEmpty,
                          isPartialState:
                              previewScenario ==
                              PortfolioPreviewScenario.partial,
                        ),
                        body: _heroBody(
                          state: portfolioState,
                          showLoading: showLoading,
                          isFilteredEmpty: isFilteredEmpty,
                          hasSearchQuery: effectiveSearchQuery
                              .trim()
                              .isNotEmpty,
                          isPartialState:
                              previewScenario ==
                              PortfolioPreviewScenario.partial,
                        ),
                        ctaLabel: _heroCtaLabel(
                          hasItems: hasItems,
                          showLoading: showLoading,
                          isFilteredEmpty: isFilteredEmpty,
                          hasSearchQuery: effectiveSearchQuery
                              .trim()
                              .isNotEmpty,
                        ),
                        icon: isFilteredEmpty
                            ? effectiveSearchQuery.trim().isNotEmpty
                                  ? Icons.search_off_outlined
                                  : Icons.filter_alt_off_outlined
                            : hasItems
                            ? Icons.photo_camera_outlined
                            : Icons.add_a_photo_outlined,
                        onPressed: showLoading
                            ? null
                            : isFilteredEmpty
                            ? effectiveSearchQuery.trim().isNotEmpty
                                  ? _clearSearch
                                  : _clearFilters
                            : widget.onScanPressed,
                      ),
                    ),
                  if (showError)
                    HomeSection(
                      child: _PortfolioErrorPanel(
                        errorMessage: portfolioState.errorMessage,
                        onRetry: isPreview
                            ? () {}
                            : portfolioController.loadItems,
                      ),
                    )
                  else if (showLoading)
                    const HomeSection(child: _PortfolioLoadingSkeleton())
                  else ...[
                    if (hasItems)
                      HomeSection(
                        child: _PortfolioToolbar(
                          searchQuery: effectiveSearchQuery,
                          onSearchChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _filteredPreviewCleared = true;
                            });
                          },
                          onSearchCleared: _clearSearch,
                          onSort: () => _showSortFilterSheet(context),
                          onFilter: () => _showSortFilterSheet(context),
                          activeFilterCount: _activeFilterCount,
                          sortLabel: _sortMode.compactLabel,
                          autofocus:
                              widget.qaSearchPreview ==
                              PortfolioSearchPreview.active,
                        ),
                      ),
                    if (hasItems)
                      HomeSection(
                        child: _PortfolioMetrics(
                          totalValue: _displayTotalValue(portfolioState.items),
                          itemCount: portfolioState.items.length,
                          valuedItemCount: _valuedItemCount(
                            portfolioState.items,
                          ),
                          pendingItemCount: _pendingItemCount(
                            portfolioState.items,
                          ),
                          filteredCount: isFilteredEmpty
                              ? visibleItems.length
                              : null,
                        ),
                      ),
                    HomeSection(
                      bottomPadding: AppSpacing.xl,
                      child: _PortfolioContent(
                        allItems: portfolioState.items,
                        visibleItems: visibleItems,
                        isFilteredEmpty: isFilteredEmpty,
                        hasSearchQuery: effectiveSearchQuery.trim().isNotEmpty,
                        hasActiveFilters: _activeFilterCount > 0,
                        onScanPressed: widget.onScanPressed,
                        onClearFilters: _clearFilters,
                        onClearSearch: _clearSearch,
                        onItemTap: _openItem,
                        onItemEdit: _editItem,
                      ),
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

  String _effectiveSearchQuery(PortfolioPreviewScenario? scenario) {
    if (scenario == PortfolioPreviewScenario.filteredEmpty &&
        !_filteredPreviewCleared &&
        _searchQuery.trim().isEmpty) {
      return 'vintage camera';
    }
    return _searchQuery;
  }

  String _initialSearchQuery(PortfolioSearchPreview? preview) {
    return switch (preview) {
      PortfolioSearchPreview.active => '',
      PortfolioSearchPreview.results => 'charizard',
      PortfolioSearchPreview.empty => 'vintage camera',
      PortfolioSearchPreview.filterEmpty => 'charizard',
      null => '',
    };
  }

  List<CollectibleItem> _orderedItems(List<CollectibleItem> items) {
    return switch (_sortMode) {
      _PortfolioSortMode.newest => collectiblesNewestFirst(items),
      _PortfolioSortMode.valueHigh => [
        ...items,
      ]..sort((a, b) => b.estimatedValue.compareTo(a.estimatedValue)),
      _PortfolioSortMode.valueLow => [
        ...items,
      ]..sort((a, b) => a.estimatedValue.compareTo(b.estimatedValue)),
      _PortfolioSortMode.status =>
        [...items]..sort((a, b) {
          final statusCompare = _statusSortRank(
            a,
          ).compareTo(_statusSortRank(b));
          if (statusCompare != 0) {
            return statusCompare;
          }
          return b.estimatedValue.compareTo(a.estimatedValue);
        }),
      _PortfolioSortMode.category => [
        ...items,
      ]..sort((a, b) => a.category.compareTo(b.category)),
    };
  }

  List<CollectibleItem> _visibleItems(
    List<CollectibleItem> items,
    String searchQuery,
  ) {
    final query = searchQuery.trim().toLowerCase();
    return items
        .where((item) {
          final title = item.title.toLowerCase();
          final category = item.category.toLowerCase();
          final condition = item.condition.toLowerCase();
          final matchesSearch =
              query.isEmpty ||
              title.contains(query) ||
              category.contains(query) ||
              condition.contains(query);
          final matchesCategory = switch (_categoryFilter) {
            _PortfolioCategoryFilter.all => true,
            _PortfolioCategoryFilter.cards => category.contains('card'),
            _PortfolioCategoryFilter.coins => category.contains('coin'),
            _PortfolioCategoryFilter.comics => category.contains('comic'),
            _PortfolioCategoryFilter.memorabilia =>
              category.contains('memorabilia') || category.contains('sport'),
            _PortfolioCategoryFilter.other =>
              !category.contains('card') &&
                  !category.contains('coin') &&
                  !category.contains('comic') &&
                  !category.contains('memorabilia') &&
                  !category.contains('sport'),
          };
          final matchesStatus = switch (_statusFilter) {
            _PortfolioStatusFilter.all => true,
            _PortfolioStatusFilter.valued => _hasDisplayableValuation(item),
            _PortfolioStatusFilter.pending =>
              _isPendingItem(item) &&
                  item.syncStatus != CloudItemSyncStatus.failed,
            _PortfolioStatusFilter.needsAttention =>
              item.syncStatus == CloudItemSyncStatus.failed ||
                  item.valuationStatus == ValuationStatus.noMarketMatch,
          };
          final matchesConfidence = switch (_confidenceFilter) {
            _PortfolioConfidenceFilter.all => true,
            _PortfolioConfidenceFilter.high => item.confidence >= .8,
            _PortfolioConfidenceFilter.low => item.confidence < .8,
          };
          final trend = _trendLabel(item).toLowerCase();
          final matchesTrend = switch (_trendFilter) {
            _PortfolioTrendFilter.all => true,
            _PortfolioTrendFilter.rising => trend.contains('rising'),
            _PortfolioTrendFilter.stable => trend.contains('stable'),
            _PortfolioTrendFilter.cooling => trend.contains('cooling'),
          };
          return matchesSearch &&
              matchesStatus &&
              matchesCategory &&
              matchesConfidence &&
              matchesTrend;
        })
        .toList(growable: false);
  }

  int get _activeFilterCount {
    var count = 0;
    if (_categoryFilter != _PortfolioCategoryFilter.all) {
      count += 1;
    }
    if (_statusFilter != _PortfolioStatusFilter.all) {
      count += 1;
    }
    if (_confidenceFilter != _PortfolioConfidenceFilter.all) {
      count += 1;
    }
    if (_trendFilter != _PortfolioTrendFilter.all) {
      count += 1;
    }
    return count;
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _filteredPreviewCleared = true;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _filteredPreviewCleared = true;
      _statusFilter = _PortfolioStatusFilter.all;
      _categoryFilter = _PortfolioCategoryFilter.all;
      _confidenceFilter = _PortfolioConfidenceFilter.all;
      _trendFilter = _PortfolioTrendFilter.all;
      _sortMode = _PortfolioSortMode.newest;
    });
  }

  Future<void> _openItem(CollectibleItem item) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectibleDetailPage(
          item: item,
          onDelete: (itemId) async {
            await ref
                .read(portfolioControllerProvider.notifier)
                .removeItem(itemId);
            return true;
          },
        ),
        settings: RouteSettings(name: '/portfolio/${item.id}'),
      ),
    );
  }

  Future<void> _editItem(CollectibleItem item) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectibleDetailPage(
          item: item,
          qaShowEditSheet: true,
          onDelete: (itemId) async {
            await ref
                .read(portfolioControllerProvider.notifier)
                .removeItem(itemId);
            return true;
          },
        ),
        settings: RouteSettings(name: '/portfolio/${item.id}/edit'),
      ),
    );
  }

  Future<void> _showSortFilterSheet(
    BuildContext context, {
    PortfolioSheetPreview? preview,
  }) async {
    final initialState = preview == PortfolioSheetPreview.selected
        ? const _PortfolioSheetSelection(
            sortMode: _PortfolioSortMode.valueHigh,
            statusFilter: _PortfolioStatusFilter.pending,
            categoryFilter: _PortfolioCategoryFilter.coins,
            confidenceFilter: _PortfolioConfidenceFilter.low,
            trendFilter: _PortfolioTrendFilter.cooling,
          )
        : _PortfolioSheetSelection(
            sortMode: _sortMode,
            statusFilter: _statusFilter,
            categoryFilter: _categoryFilter,
            confidenceFilter: _confidenceFilter,
            trendFilter: _trendFilter,
          );
    var draft = initialState;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .58),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(_PortfolioSheetSelection next) {
              setSheetState(() => draft = next);
            }

            return _PortfolioBottomSheet(
              key: const ValueKey('portfolio-premium-filter-sheet-surface'),
              title: 'Sort and filter',
              initialScrollOffset: preview == PortfolioSheetPreview.selected
                  ? 360
                  : 0,
              children: [
                _SheetGroup(
                  title: 'Sort',
                  children: [
                    for (final mode in _PortfolioSortMode.values)
                      _SheetOptionChip(
                        key: ValueKey('portfolio-sort-option-${mode.name}'),
                        label: mode.label,
                        selected: draft.sortMode == mode,
                        onTap: () => update(draft.copyWith(sortMode: mode)),
                      ),
                  ],
                ),
                _SheetGroup(
                  title: 'Status',
                  children: [
                    for (final filter in _PortfolioStatusFilter.values)
                      _SheetOptionChip(
                        key: ValueKey('portfolio-status-filter-${filter.name}'),
                        label: filter.label,
                        selected: draft.statusFilter == filter,
                        onTap: () =>
                            update(draft.copyWith(statusFilter: filter)),
                      ),
                  ],
                ),
                _SheetGroup(
                  title: 'Category',
                  children: [
                    for (final filter in _PortfolioCategoryFilter.values)
                      _SheetOptionChip(
                        key: ValueKey(
                          'portfolio-category-filter-${filter.name}',
                        ),
                        label: filter.label,
                        selected: draft.categoryFilter == filter,
                        onTap: () =>
                            update(draft.copyWith(categoryFilter: filter)),
                      ),
                  ],
                ),
                _SheetGroup(
                  title: 'Confidence',
                  children: [
                    for (final filter in _PortfolioConfidenceFilter.values)
                      _SheetOptionChip(
                        key: ValueKey(
                          'portfolio-confidence-filter-${filter.name}',
                        ),
                        label: filter.label,
                        selected: draft.confidenceFilter == filter,
                        onTap: () =>
                            update(draft.copyWith(confidenceFilter: filter)),
                      ),
                  ],
                ),
                _SheetGroup(
                  title: 'Trend',
                  children: [
                    for (final filter in _PortfolioTrendFilter.values)
                      _SheetOptionChip(
                        key: ValueKey('portfolio-trend-filter-${filter.name}'),
                        label: filter.label,
                        selected: draft.trendFilter == filter,
                        onTap: () =>
                            update(draft.copyWith(trendFilter: filter)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const ValueKey('portfolio-filter-reset'),
                        onPressed: () =>
                            update(const _PortfolioSheetSelection.defaults()),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('portfolio-filter-apply'),
                        onPressed: () {
                          setState(() {
                            _sortMode = draft.sortMode;
                            _statusFilter = draft.statusFilter;
                            _categoryFilter = draft.categoryFilter;
                            _confidenceFilter = draft.confidenceFilter;
                            _trendFilter = draft.trendFilter;
                            _filteredPreviewCleared = true;
                          });
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PortfolioTitleBlock extends StatelessWidget {
  const _PortfolioTitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: HomeTokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saved collectibles, values, and item health.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HomeTokens.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PortfolioToolbar extends StatelessWidget {
  const _PortfolioToolbar({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onSort,
    required this.onFilter,
    required this.activeFilterCount,
    required this.sortLabel,
    this.autofocus = false,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final VoidCallback onSort;
  final VoidCallback onFilter;
  final int activeFilterCount;
  final String sortLabel;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return HomeSurface(
      keySeed: 'toolbar',
      keyPrefix: 'portfolio',
      padding: const EdgeInsets.all(14),
      backgroundColor: HomeTokens.surfaceRaised.withValues(alpha: .94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('portfolio-search-field-$searchQuery'),
            initialValue: searchQuery,
            autofocus: autofocus,
            onChanged: onSearchChanged,
            cursorColor: const Color(0xFF8BE7FF),
            style: const TextStyle(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Search saved items',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8BC7FF)),
              suffixIcon: searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('portfolio-search-clear'),
                      tooltip: 'Clear search',
                      onPressed: onSearchCleared,
                      icon: const Icon(Icons.close, color: Color(0xFFBEEBFF)),
                    ),
              filled: true,
              fillColor: const Color(0xFF101E2A),
              hintStyle: const TextStyle(color: HomeTokens.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: HomeTokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: HomeTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8BE7FF),
                  width: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ToolbarButton(
                  key: const ValueKey('portfolio-action-sort'),
                  icon: Icons.swap_vert_outlined,
                  label: sortLabel,
                  onPressed: onSort,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ToolbarButton(
                  key: const ValueKey('portfolio-action-filter'),
                  icon: Icons.tune_outlined,
                  label: activeFilterCount == 0
                      ? 'Filter'
                      : 'Filter ($activeFilterCount)',
                  onPressed: onFilter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.visible),
        style: OutlinedButton.styleFrom(
          foregroundColor: HomeTokens.textPrimary,
          side: const BorderSide(color: HomeTokens.border),
          backgroundColor: HomeTokens.surfaceInteractive,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _PortfolioMetrics extends StatelessWidget {
  const _PortfolioMetrics({
    required this.totalValue,
    required this.itemCount,
    required this.valuedItemCount,
    required this.pendingItemCount,
    this.filteredCount,
  });

  final double totalValue;
  final int itemCount;
  final int valuedItemCount;
  final int pendingItemCount;
  final int? filteredCount;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      HomeMetricTile(
        label: 'Collection value',
        value: _formatAud(totalValue),
        supportingText: pendingItemCount == 0
            ? 'Estimated'
            : '$pendingItemCount pending',
        supportingColor: pendingItemCount == 0
            ? HomeTokens.positive
            : HomeTokens.warning,
      ),
      HomeMetricTile(
        label: 'Collection items',
        value: '$itemCount',
        supportingText: '$valuedItemCount valued',
      ),
      HomeMetricTile(
        label: filteredCount == null ? 'Pending' : 'Filtered',
        value: filteredCount == null ? '$pendingItemCount' : '$filteredCount',
        supportingText: filteredCount == null
            ? (pendingItemCount == 0 ? 'Healthy' : 'Review')
            : 'No matches',
        supportingColor: filteredCount == null && pendingItemCount > 0
            ? HomeTokens.warning
            : HomeTokens.positive,
      ),
    ];

    return KeyedSubtree(
      key: const ValueKey('portfolio-compact-snapshot'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - AppSpacing.sm) / 2;
          return Wrap(
            key: const ValueKey('portfolio-metric-grid'),
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final metric in metrics)
                SizedBox(width: width, child: metric),
            ],
          );
        },
      ),
    );
  }
}

class _PortfolioContent extends StatelessWidget {
  const _PortfolioContent({
    required this.allItems,
    required this.visibleItems,
    required this.isFilteredEmpty,
    required this.hasSearchQuery,
    required this.hasActiveFilters,
    required this.onScanPressed,
    required this.onClearFilters,
    required this.onClearSearch,
    required this.onItemTap,
    required this.onItemEdit,
  });

  final List<CollectibleItem> allItems;
  final List<CollectibleItem> visibleItems;
  final bool isFilteredEmpty;
  final bool hasSearchQuery;
  final bool hasActiveFilters;
  final VoidCallback? onScanPressed;
  final VoidCallback onClearFilters;
  final VoidCallback onClearSearch;
  final ValueChanged<CollectibleItem> onItemTap;
  final ValueChanged<CollectibleItem> onItemEdit;

  @override
  Widget build(BuildContext context) {
    if (allItems.isEmpty) {
      return _PortfolioEmptyPanel(onScanPressed: onScanPressed);
    }

    if (isFilteredEmpty) {
      return _PortfolioFilteredEmptyPanel(
        hasSearchQuery: hasSearchQuery,
        hasActiveFilters: hasActiveFilters,
        onClearSearch: onClearSearch,
        onClearFilters: onClearFilters,
      );
    }

    return HomeSectionSurface(
      keySeed: 'saved-items',
      title: 'Saved collectibles',
      child: Column(
        children: [
          for (var index = 0; index < visibleItems.length; index += 1) ...[
            _PortfolioItemRow(
              item: visibleItems[index],
              onTap: () => onItemTap(visibleItems[index]),
              onEdit: () => onItemEdit(visibleItems[index]),
            ),
            if (index != visibleItems.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PortfolioItemRow extends StatelessWidget {
  const _PortfolioItemRow({
    required this.item,
    required this.onTap,
    required this.onEdit,
  });

  final CollectibleItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasValue = _hasDisplayableValuation(item);
    final pending = _isPendingItem(item);
    final statusColor = pending ? HomeTokens.warning : HomeTokens.positive;
    final statusLabel = pending
        ? item.syncStatus == CloudItemSyncStatus.failed
              ? 'Sync issue'
              : 'Needs value'
        : 'Valued';
    final valueLabel = hasValue ? _formatAud(item.estimatedValue) : 'Pending';

    return MotionTapScale(
      onTap: onTap,
      child: Container(
        key: ValueKey('portfolio-grid-item-${item.id}'),
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HomeTokens.surfaceInteractive,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomeTokens.border),
        ),
        child: Row(
          children: [
            PortfolioThumbnail(imagePath: item.imagePath, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: HomeTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.category} - ${item.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: _StatusPill(
                          label: statusLabel,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _trendLabel(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: HomeTokens.textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: hasValue
                          ? HomeTokens.textPrimary
                          : HomeTokens.warning,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 34,
                        child: IconButton(
                          key: ValueKey('portfolio-grid-item-edit-${item.id}'),
                          onPressed: onEdit,
                          tooltip: 'Edit item',
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF8BC7FF),
                            size: 18,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF8BC7FF),
                        size: 22,
                      ),
                    ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .42)),
      ),
      child: Text(
        label,
        key: ValueKey(
          'portfolio-status-${label.toLowerCase().replaceAll(' ', '-')}',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PortfolioEmptyPanel extends StatelessWidget {
  const _PortfolioEmptyPanel({required this.onScanPressed});

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('portfolio-empty-state-surface'),
      child: HomeSectionSurface(
        keySeed: 'portfolio-empty',
        title: 'Start with your first item',
        child: Column(
          children: [
            Text(
              'Your portfolio is waiting for saved collectibles. Scan an item to begin tracking values and condition details.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HomeTokens.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HomeActionRow(
              keySeed: 'portfolio-guided-scan',
              icon: Icons.document_scanner_outlined,
              title: 'Use guided scan',
              subtitle: 'Open the existing scanner flow.',
              onTap: onScanPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioFilteredEmptyPanel extends StatelessWidget {
  const _PortfolioFilteredEmptyPanel({
    required this.hasSearchQuery,
    required this.hasActiveFilters,
    required this.onClearSearch,
    required this.onClearFilters,
  });

  final bool hasSearchQuery;
  final bool hasActiveFilters;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final title = hasSearchQuery ? 'No matches found' : 'No matching filters';
    final body = hasSearchQuery && hasActiveFilters
        ? 'No saved items match this search inside the current filters. Clear search to keep your filters, or reset filters to widen the list.'
        : hasSearchQuery
        ? 'No saved items match this search. Clear the search to return to your current portfolio list.'
        : 'Your saved items are still here, but the current filters found none.';

    return KeyedSubtree(
      key: const ValueKey('portfolio-filtered-empty-state-surface'),
      child: HomeSectionSurface(
        keySeed: 'portfolio-filtered-empty',
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HomeTokens.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                key: hasSearchQuery
                    ? const ValueKey('portfolio-clear-search')
                    : const ValueKey('portfolio-clear-filters'),
                onPressed: hasSearchQuery ? onClearSearch : onClearFilters,
                icon: Icon(
                  hasSearchQuery ? Icons.close : Icons.filter_alt_off_outlined,
                ),
                label: Text(hasSearchQuery ? 'Clear search' : 'Clear filters'),
                style: FilledButton.styleFrom(
                  backgroundColor: HomeTokens.accentStrong,
                  foregroundColor: HomeTokens.textPrimary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            if (hasSearchQuery && hasActiveFilters) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  key: const ValueKey('portfolio-clear-filters'),
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Reset filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomeTokens.textPrimary,
                    side: const BorderSide(color: HomeTokens.border),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PortfolioErrorPanel extends StatelessWidget {
  const _PortfolioErrorPanel({
    required this.errorMessage,
    required this.onRetry,
  });

  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('portfolio-error-state-surface'),
      child: HomeSectionSurface(
        keySeed: 'portfolio-error',
        title: 'Portfolio could not load',
        borderColor: HomeTokens.warning.withValues(alpha: .44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We could not refresh your portfolio.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HomeTokens.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HomeTokens.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                key: const ValueKey('portfolio-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: HomeTokens.accentStrong,
                  foregroundColor: HomeTokens.textPrimary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioLoadingSkeleton extends StatelessWidget {
  const _PortfolioLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const KeyedSubtree(
      key: ValueKey('portfolio-loading-skeleton'),
      child: HomeSkeletonBlock(),
    );
  }
}

class _PortfolioSheetSelection {
  const _PortfolioSheetSelection({
    required this.sortMode,
    required this.statusFilter,
    required this.categoryFilter,
    required this.confidenceFilter,
    required this.trendFilter,
  });

  const _PortfolioSheetSelection.defaults()
    : sortMode = _PortfolioSortMode.newest,
      statusFilter = _PortfolioStatusFilter.all,
      categoryFilter = _PortfolioCategoryFilter.all,
      confidenceFilter = _PortfolioConfidenceFilter.all,
      trendFilter = _PortfolioTrendFilter.all;

  final _PortfolioSortMode sortMode;
  final _PortfolioStatusFilter statusFilter;
  final _PortfolioCategoryFilter categoryFilter;
  final _PortfolioConfidenceFilter confidenceFilter;
  final _PortfolioTrendFilter trendFilter;

  _PortfolioSheetSelection copyWith({
    _PortfolioSortMode? sortMode,
    _PortfolioStatusFilter? statusFilter,
    _PortfolioCategoryFilter? categoryFilter,
    _PortfolioConfidenceFilter? confidenceFilter,
    _PortfolioTrendFilter? trendFilter,
  }) {
    return _PortfolioSheetSelection(
      sortMode: sortMode ?? this.sortMode,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      confidenceFilter: confidenceFilter ?? this.confidenceFilter,
      trendFilter: trendFilter ?? this.trendFilter,
    );
  }
}

class _PortfolioBottomSheet extends StatelessWidget {
  const _PortfolioBottomSheet({
    required this.title,
    required this.children,
    this.initialScrollOffset = 0,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final double initialScrollOffset;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .76,
        minChildSize: .42,
        maxChildSize: .92,
        builder: (context, scrollController) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (initialScrollOffset <= 0 || !scrollController.hasClients) {
              return;
            }
            final target = initialScrollOffset.clamp(
              scrollController.position.minScrollExtent,
              scrollController.position.maxScrollExtent,
            );
            if (scrollController.offset != target) {
              scrollController.jumpTo(target);
            }
          });
          return Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: HomeTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: HomeTokens.border),
              boxShadow: AppElevation.level3,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: HomeTokens.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HomeTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Changes apply only when you tap Apply.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...children,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SheetGroup extends StatelessWidget {
  const _SheetGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _SheetOptionChip extends StatelessWidget {
  const _SheetOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(Icons.check, size: 16, color: HomeTokens.textPrimary),
            const SizedBox(width: 6),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: HomeTokens.accentStrong,
      backgroundColor: HomeTokens.surfaceInteractive,
      labelStyle: TextStyle(
        color: selected ? HomeTokens.textPrimary : HomeTokens.textSecondary,
        fontWeight: FontWeight.w900,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF8BE7FF) : HomeTokens.border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    );
  }
}

String _heroTitle({
  required PortfolioState state,
  required bool showLoading,
  required bool isFilteredEmpty,
  required bool hasSearchQuery,
  required bool isPartialState,
}) {
  if (showLoading) {
    return 'Preparing portfolio';
  }
  if (isFilteredEmpty) {
    return hasSearchQuery ? 'No matches found' : 'No matches for these filters';
  }
  if (state.items.isEmpty) {
    return 'Start your portfolio';
  }
  if (isPartialState) {
    return 'Review pending values';
  }
  return 'Your collection at a glance';
}

String _heroBody({
  required PortfolioState state,
  required bool showLoading,
  required bool isFilteredEmpty,
  required bool hasSearchQuery,
  required bool isPartialState,
}) {
  if (showLoading) {
    return 'Preparing your saved items, values, and filters.';
  }
  if (isFilteredEmpty) {
    if (hasSearchQuery) {
      return 'Clear search to return to the current filtered and sorted list.';
    }
    return 'Your saved items are still here. Clear filters to return to the full portfolio.';
  }
  if (state.items.isEmpty) {
    return 'Scan your first collectible to start building a saved portfolio.';
  }
  if (isPartialState) {
    return 'Confirmed values stay visible while pending items are marked for review.';
  }
  return 'Review saved collectibles, values, and items that need attention.';
}

String _heroCtaLabel({
  required bool hasItems,
  required bool showLoading,
  required bool isFilteredEmpty,
  required bool hasSearchQuery,
}) {
  if (showLoading) {
    return 'Loading';
  }
  if (isFilteredEmpty) {
    return hasSearchQuery ? 'Clear search' : 'Clear filters';
  }
  return hasItems ? 'Scan item' : 'Scan first item';
}

PortfolioState _previewStateFor(PortfolioPreviewScenario scenario) {
  return switch (scenario) {
    PortfolioPreviewScenario.defaultData => PortfolioState(
      items: _defaultItems(),
    ),
    PortfolioPreviewScenario.empty => const PortfolioState(),
    PortfolioPreviewScenario.loading => const PortfolioState(isLoading: true),
    PortfolioPreviewScenario.error => const PortfolioState(
      errorMessage: 'Unable to load portfolio.',
    ),
    PortfolioPreviewScenario.partial => PortfolioState(items: _partialItems()),
    PortfolioPreviewScenario.filteredEmpty => PortfolioState(
      items: _defaultItems(),
    ),
  };
}

List<CollectibleItem> _defaultItems() {
  return [
    _previewItem(
      id: 'preview-charizard',
      title: 'Base Set Charizard',
      category: 'Trading Card',
      value: 1850,
      condition: 'Near Mint',
      trendLabel: 'Rising',
    ),
    _previewItem(
      id: 'preview-eagle',
      title: 'Silver Eagle 2015',
      category: 'Coin',
      value: 52,
      condition: 'Brilliant Uncirculated',
      trendLabel: 'Stable',
    ),
    _previewItem(
      id: 'preview-hot-wheels',
      title: 'Hot Wheels 15 Mazda MX-5',
      category: 'Die-cast',
      value: 18,
      condition: 'Carded',
      trendLabel: 'Stable',
    ),
  ];
}

List<CollectibleItem> _partialItems() {
  return [
    _previewItem(
      id: 'partial-charizard',
      title: 'Base Set Charizard',
      category: 'Trading Card',
      value: 1850,
      condition: 'Near Mint',
      trendLabel: 'Rising',
    ),
    _previewItem(
      id: 'partial-comic',
      title: 'Amazing Spider-Man 361',
      category: 'Comic',
      value: 0,
      condition: 'Fine',
      status: ValuationStatus.providerNotConfigured,
      trendLabel: 'Pending',
    ),
    _previewItem(
      id: 'partial-eagle',
      title: 'Silver Eagle 2015',
      category: 'Coin',
      value: 52,
      condition: 'Brilliant Uncirculated',
      trendLabel: 'Stable',
    ),
  ];
}

CollectibleItem _previewItem({
  required String id,
  required String title,
  required String category,
  required double value,
  required String condition,
  required String trendLabel,
  ValuationStatus status = ValuationStatus.marketEstimated,
}) {
  return CollectibleItem(
    id: id,
    title: title,
    category: category,
    estimatedValue: value,
    confidence: value > 0 ? .91 : .48,
    condition: condition,
    recommendation: value > 0
        ? 'Keep protected and review market movement.'
        : 'Scan details are saved while valuation finishes.',
    imagePath: 'sample://$id',
    createdAt: DateTime.utc(2026, 7, 1),
    valuationStatus: status,
    valuationSource: status.wireValue,
  );
}

int _valuedItemCount(List<CollectibleItem> items) {
  return items.where(_hasDisplayableValuation).length;
}

int _pendingItemCount(List<CollectibleItem> items) {
  return items.where(_isPendingItem).length;
}

double _displayTotalValue(List<CollectibleItem> items) {
  return items
      .where(_hasDisplayableValuation)
      .fold<double>(0, (total, item) => total + item.estimatedValue);
}

bool _hasDisplayableValuation(CollectibleItem item) {
  return switch (item.valuationStatus) {
    ValuationStatus.marketEstimated || ValuationStatus.aiEstimated => true,
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.noMarketMatch ||
    ValuationStatus.lookupFailed ||
    ValuationStatus.unavailable => false,
  };
}

bool _isPendingItem(CollectibleItem item) {
  return !_hasDisplayableValuation(item) ||
      item.syncStatus == CloudItemSyncStatus.pendingUpload ||
      item.syncStatus == CloudItemSyncStatus.failed;
}

int _statusSortRank(CollectibleItem item) {
  if (item.syncStatus == CloudItemSyncStatus.failed ||
      item.valuationStatus == ValuationStatus.noMarketMatch) {
    return 0;
  }
  if (_isPendingItem(item)) {
    return 1;
  }
  return 2;
}

String _formatAud(double value) {
  final rounded = value.round();
  final formatted = rounded.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$formatted';
}

String _trendLabel(CollectibleItem item) {
  if (!_hasDisplayableValuation(item)) {
    return 'Pending';
  }
  return 'Stable';
}
