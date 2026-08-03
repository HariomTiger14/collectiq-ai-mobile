import 'dart:async';
import 'dart:convert';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/currency_format.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/domain/services/portfolio_export_service.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_focus_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
  pending(label: 'Needs value'),
  needsAttention(label: 'Needs attention');

  const _PortfolioStatusFilter({required this.label});

  final String label;
}

enum _PortfolioCategoryFilter {
  all(label: 'All'),
  cards(label: 'Cards'),
  videoGames(label: 'Video Games'),
  sneakers(label: 'Sneakers'),
  comics(label: 'Comics'),
  coins(label: 'Coins'),
  figures(label: 'LEGO / Funko'),
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

enum _PortfolioIntelligenceFocus {
  trustedValue(label: 'Needs trusted value'),
  refreshPriority(label: 'Refresh priority'),
  metadataGaps(label: 'Metadata gaps'),
  lowConfidence(label: 'Low confidence');

  const _PortfolioIntelligenceFocus({required this.label});

  final String label;
}

enum PortfolioPreviewScenario {
  defaultData(
    label: 'Default',
    subtitle: 'Saved items with trusted values and review work.',
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
    subtitle: 'Confirmed values plus missing valuations in amber.',
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
          storageKey: 'portfolio-preview-scroll-position',
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
  _PortfolioIntelligenceFocus? _intelligenceFocus;

  @override
  void initState() {
    super.initState();
    _searchQuery = _initialSearchQuery(widget.qaSearchPreview);
    if (widget.qaSearchPreview == PortfolioSearchPreview.filterEmpty) {
      _categoryFilter = _PortfolioCategoryFilter.other;
    }
    // One-shot focus intent from another surface (e.g. the Home "N items need
    // a valuation" strip) — open pre-filtered to "Needs value". Read the value
    // here (mutating a provider during initState is not allowed); it is cleared
    // in the post-frame callback below so it fires only once.
    final focus = ref.read(portfolioFocusProvider);
    if (focus == PortfolioFocus.needsValuation) {
      _statusFilter = _PortfolioStatusFilter.pending;
    }
    _scrollController = ScrollController(
      initialScrollOffset: widget.qaInitialScrollOffset,
      keepScrollOffset: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // Consume the one-shot focus intent now that we're past build.
      if (focus != null) {
        ref.read(portfolioFocusProvider.notifier).clear();
      }
      ref.read(portfolioControllerProvider.notifier).ensureLoaded();
      if (widget.previewScenario == null) {
        unawaited(
          ref
              .read(portfolioControllerProvider.notifier)
              .syncCloudPortfolioNow(),
        );
      }
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
    final portfolioAnalytics = const CollectorDashboardAnalyticsService().build(
      orderedItems,
    );
    final hasItems = portfolioState.items.isNotEmpty;
    final isFilteredEmpty = hasItems && visibleItems.isEmpty;
    final showLoading =
        portfolioState.isLoading && portfolioState.items.isEmpty;
    final showError =
        portfolioState.errorMessage != null && portfolioState.items.isEmpty;
    final planLimits = ref.watch(activePlanLimitsProvider);

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
                storageKey: 'portfolio-scroll-position',
                controller: _scrollController,
                bottomClearance: GlassBottomNavBar.scrollContentClearance(
                  context,
                ),
                sections: [
                  const HomeSection(child: _PortfolioTitleBlock()),
                  // The overview hero doubles as the empty/filtered/loading
                  // state. In the normal populated view it just restates the
                  // subtitle and adds a redundant Scan CTA (Scan is a nav tab),
                  // so suppress it there and let the metrics + list lead.
                  if (!showError && (showLoading || isFilteredEmpty || !hasItems))
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
                          onSort: _openAdvancedFilters,
                          onFilter: _openAdvancedFilters,
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
                          displayCurrency: dominantDisplayCurrency(
                            portfolioState.items,
                          ),
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
                    if (hasItems && !isFilteredEmpty)
                      HomeSection(
                        child: _PortfolioIntelligencePanel(
                          analytics: portfolioAnalytics,
                          valuedItemCount: _valuedItemCount(
                            portfolioState.items,
                          ),
                          pendingItemCount: _pendingItemCount(
                            portfolioState.items,
                          ),
                          isUnlocked: planLimits.canUsePortfolioIntelligence,
                          onAttentionFocus: _applyIntelligenceFocus,
                          onAddMoreCollectibles: widget.onScanPressed,
                        ),
                      ),
                    if (hasItems)
                      HomeSection(
                        child: _PortfolioExportPanel(
                          itemCount: portfolioState.items.length,
                          onExport: () =>
                              _startPortfolioExport(portfolioState.items),
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
            _PortfolioCategoryFilter.cards =>
              category.contains('card') ||
                  category.contains('pokemon') ||
                  category.contains('magic') ||
                  category.contains('yugioh') ||
                  category.contains('yu-gi-oh') ||
                  category.contains('one piece'),
            _PortfolioCategoryFilter.videoGames =>
              category.contains('video game') || category.contains('game'),
            _PortfolioCategoryFilter.sneakers =>
              category.contains('sneaker') ||
                  category.contains('shoe') ||
                  category.contains('streetwear'),
            _PortfolioCategoryFilter.comics =>
              category.contains('comic') || category.contains('manga'),
            _PortfolioCategoryFilter.coins =>
              category.contains('coin') ||
                  category.contains('numismatic') ||
                  category.contains('penny') ||
                  category.contains('cent'),
            _PortfolioCategoryFilter.figures =>
              category.contains('lego') ||
                  category.contains('building set') ||
                  category.contains('funko') ||
                  category.contains('pop') ||
                  category.contains('vinyl figure'),
            _PortfolioCategoryFilter.other =>
              !category.contains('card') &&
                  !category.contains('pokemon') &&
                  !category.contains('magic') &&
                  !category.contains('yugioh') &&
                  !category.contains('yu-gi-oh') &&
                  !category.contains('one piece') &&
                  !category.contains('video game') &&
                  !category.contains('game') &&
                  !category.contains('sneaker') &&
                  !category.contains('shoe') &&
                  !category.contains('streetwear') &&
                  !category.contains('comic') &&
                  !category.contains('manga') &&
                  !category.contains('coin') &&
                  !category.contains('numismatic') &&
                  !category.contains('penny') &&
                  !category.contains('cent') &&
                  !category.contains('lego') &&
                  !category.contains('building set') &&
                  !category.contains('funko') &&
                  !category.contains('pop') &&
                  !category.contains('vinyl figure'),
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
          final matchesIntelligenceFocus = switch (_intelligenceFocus) {
            null => true,
            _PortfolioIntelligenceFocus.trustedValue => _isPendingItem(item),
            _PortfolioIntelligenceFocus.refreshPriority => _hasStalePricing(
              item,
            ),
            _PortfolioIntelligenceFocus.metadataGaps =>
              _hasMissingImportantData(item),
            _PortfolioIntelligenceFocus.lowConfidence => item.confidence < .75,
          };
          return matchesSearch &&
              matchesStatus &&
              matchesCategory &&
              matchesConfidence &&
              matchesTrend &&
              matchesIntelligenceFocus;
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
    if (_intelligenceFocus != null) {
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
      _intelligenceFocus = null;
      _sortMode = _PortfolioSortMode.newest;
    });
  }

  void _applyIntelligenceFocus(_PortfolioIntelligenceFocus focus) {
    setState(() {
      _searchQuery = '';
      _filteredPreviewCleared = true;
      _intelligenceFocus = focus;
      _categoryFilter = _PortfolioCategoryFilter.all;
      _trendFilter = _PortfolioTrendFilter.all;
      switch (focus) {
        case _PortfolioIntelligenceFocus.trustedValue:
          _statusFilter = _PortfolioStatusFilter.pending;
          _confidenceFilter = _PortfolioConfidenceFilter.all;
          _sortMode = _PortfolioSortMode.status;
        case _PortfolioIntelligenceFocus.refreshPriority:
          _statusFilter = _PortfolioStatusFilter.all;
          _confidenceFilter = _PortfolioConfidenceFilter.all;
          _sortMode = _PortfolioSortMode.status;
        case _PortfolioIntelligenceFocus.metadataGaps:
          _statusFilter = _PortfolioStatusFilter.all;
          _confidenceFilter = _PortfolioConfidenceFilter.all;
          _sortMode = _PortfolioSortMode.newest;
        case _PortfolioIntelligenceFocus.lowConfidence:
          _statusFilter = _PortfolioStatusFilter.all;
          _confidenceFilter = _PortfolioConfidenceFilter.low;
          _sortMode = _PortfolioSortMode.newest;
      }
    });
    _showPortfolioSnackBar('${focus.label} view applied.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final target = (_scrollController.position.maxScrollExtent * .72).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openAdvancedFilters() {
    final planLimits = ref.read(activePlanLimitsProvider);
    if (!planLimits.canUseAdvancedFilters) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Advanced filters are included with Pro and Premium.',
            ),
          ),
        );
      return;
    }
    _showSortFilterSheet(context);
  }

  Future<void> _startPortfolioExport(List<CollectibleItem> items) async {
    final planLimits = ref.read(activePlanLimitsProvider);
    if (!planLimits.canExportPortfolio) {
      _showPortfolioSnackBar(
        'Portfolio export is included with Pro and Premium.',
      );
      return;
    }
    if (items.isEmpty) {
      _showPortfolioSnackBar('Add items before exporting your portfolio.');
      return;
    }

    final confirmed = await _showExportConfirmationSheet(items.length);
    if (!mounted || !confirmed) {
      return;
    }

    await _sharePortfolioCsv(items);
  }

  Future<bool> _showExportConfirmationSheet(int itemCount) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .58),
      isScrollControlled: true,
      builder: (context) {
        return _PortfolioBottomSheet(
          key: const ValueKey('portfolio-export-confirmation-sheet'),
          title: 'Export portfolio',
          subtitle:
              'PackLox will create a CSV file only after you confirm. You choose where it is saved or shared.',
          children: [
            _ExportDisclosureRow(
              icon: Icons.inventory_2_outlined,
              title: '$itemCount saved items',
              subtitle:
                  'Includes item names, categories, condition, values, notes, and metadata.',
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ExportDisclosureRow(
              icon: Icons.price_check_outlined,
              title: 'Pricing context',
              subtitle:
                  'Includes valuation status, currency, source, confidence, and timestamps.',
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ExportDisclosureRow(
              icon: Icons.no_photography_outlined,
              title: 'No private image files',
              subtitle:
                  'The CSV includes image count only. It does not attach your photos.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('portfolio-export-cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('portfolio-export-create-csv'),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Create CSV'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _sharePortfolioCsv(List<CollectibleItem> items) async {
    try {
      final csv = const PortfolioExportService().buildCsv(
        collectiblesNewestFirst(items),
      );
      final fileName =
          'packlox-portfolio-${_exportDateStamp(DateTime.now())}.csv';
      await SharePlus.instance.share(
        ShareParams(
          title: 'Export PackLox portfolio',
          subject: 'PackLox portfolio export',
          text: 'PackLox portfolio export with ${items.length} items.',
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(csv)),
              mimeType: 'text/csv',
              name: fileName,
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showPortfolioSnackBar('Portfolio export is unavailable right now.');
    }
  }

  void _showPortfolioSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            categoryFilter: _PortfolioCategoryFilter.other,
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
                            _intelligenceFocus = null;
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

String _exportDateStamp(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.year}$month$day-$hour$minute';
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

class _PortfolioExportPanel extends StatelessWidget {
  const _PortfolioExportPanel({
    required this.itemCount,
    required this.onExport,
  });

  final int itemCount;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return HomeSectionSurface(
      keySeed: 'portfolio-export',
      title: 'Collector tools',
      child: HomeActionRow(
        keySeed: 'portfolio-export-csv',
        icon: Icons.file_download_outlined,
        title: 'Export portfolio CSV',
        subtitle: '$itemCount items with values, sources, notes, and metadata.',
        onTap: onExport,
      ),
    );
  }
}

class _ExportDisclosureRow extends StatelessWidget {
  const _ExportDisclosureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceInteractive,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8BC7FF), size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HomeTokens.textSecondary,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioToolbar extends StatefulWidget {
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
  State<_PortfolioToolbar> createState() => _PortfolioToolbarState();
}

class _PortfolioToolbarState extends State<_PortfolioToolbar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _PortfolioToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync the field only when the query changes from OUTSIDE the field (the
    // clear button, or a QA preset). During normal typing the controller text
    // already matches, so we skip resetting value/selection — resetting on each
    // keystroke is exactly what used to drop focus after a single character.
    if (widget.searchQuery != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          TextField(
            // Stable key: the key previously embedded the query, so every
            // keystroke rebuilt the field as a new widget and dropped focus.
            key: const ValueKey('portfolio-search-field'),
            controller: _controller,
            autofocus: widget.autofocus,
            onChanged: widget.onSearchChanged,
            cursorColor: const Color(0xFF8BE7FF),
            style: const TextStyle(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Search saved items',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8BC7FF)),
              suffixIcon: widget.searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('portfolio-search-clear'),
                      tooltip: 'Clear search',
                      onPressed: widget.onSearchCleared,
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
                  label: widget.sortLabel,
                  onPressed: widget.onSort,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ToolbarButton(
                  key: const ValueKey('portfolio-action-filter'),
                  icon: Icons.tune_outlined,
                  label: widget.activeFilterCount == 0
                      ? 'Filter'
                      : 'Filter (${widget.activeFilterCount})',
                  onPressed: widget.onFilter,
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
    required this.displayCurrency,
    required this.itemCount,
    required this.valuedItemCount,
    required this.pendingItemCount,
    this.filteredCount,
  });

  final double totalValue;
  final String displayCurrency;
  final int itemCount;
  final int valuedItemCount;
  final int pendingItemCount;
  final int? filteredCount;

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      HomeMetricTile(
        label: 'Collection value',
        value: _formatAud(totalValue, displayCurrency),
        supportingText: pendingItemCount == 0
            ? 'Estimated'
            : '$pendingItemCount need value',
        supportingColor: pendingItemCount == 0
            ? HomeTokens.positive
            : HomeTokens.warning,
      ),
      HomeMetricTile(
        label: 'Collection items',
        value: '$itemCount',
        supportingText: '$valuedItemCount valued',
      ),
      // The old third "Needs value" tile just restated the sublines above, so it
      // is dropped. The slot is reused only to report a filtered-empty result.
      if (filteredCount != null)
        HomeMetricTile(
          label: 'Filtered',
          value: '$filteredCount',
          supportingText: 'No matches',
          supportingColor: HomeTokens.positive,
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

class _PortfolioIntelligencePanel extends StatelessWidget {
  const _PortfolioIntelligencePanel({
    required this.analytics,
    required this.valuedItemCount,
    required this.pendingItemCount,
    required this.isUnlocked,
    required this.onAttentionFocus,
    required this.onAddMoreCollectibles,
  });

  final CollectorDashboardAnalytics analytics;
  final int valuedItemCount;
  final int pendingItemCount;
  final bool isUnlocked;
  final ValueChanged<_PortfolioIntelligenceFocus> onAttentionFocus;
  final VoidCallback? onAddMoreCollectibles;

  @override
  Widget build(BuildContext context) {
    final health = analytics.collectionHealth;
    final attentionCount = _attentionCount;
    final recommendations = analytics.recommendations
        .where(
          (recommendation) =>
              !isUnlocked ||
              recommendation.type != CollectionRecommendationType.upgradePlan,
        )
        .take(2)
        .toList();
    final textTheme = Theme.of(context).textTheme;

    return KeyedSubtree(
      key: const ValueKey('portfolio-intelligence-panel'),
      child: HomeSectionSurface(
        keySeed: 'portfolio-intelligence',
        title: 'Portfolio intelligence',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _healthColor(health).withValues(alpha: .95),
                        HomeTokens.accentStrong.withValues(alpha: .84),
                      ],
                    ),
                    border: Border.all(
                      color: _healthColor(health).withValues(alpha: .52),
                    ),
                  ),
                  child: Text(
                    '${health.score}',
                    key: const ValueKey('portfolio-health-score'),
                    style: textTheme.titleLarge?.copyWith(
                      color: HomeTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        health.label,
                        key: const ValueKey('portfolio-health-label'),
                        style: textTheme.titleMedium?.copyWith(
                          color: HomeTokens.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _summaryCopy(attentionCount),
                        style: textTheme.bodySmall?.copyWith(
                          color: HomeTokens.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1.32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: _IntelligenceMetricTile(
                        label: 'Pricing coverage',
                        value: '$valuedItemCount/${analytics.itemCount}',
                        supportingText: '$pendingItemCount need value',
                        color: pendingItemCount == 0
                            ? HomeTokens.positive
                            : HomeTokens.warning,
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _IntelligenceMetricTile(
                        label: 'Avg confidence',
                        value:
                            '${(analytics.averageConfidence * 100).round()}%',
                        supportingText: analytics.lowConfidenceItems.isEmpty
                            ? 'Strong signal'
                            : '${analytics.lowConfidenceItems.length} low',
                        color: analytics.lowConfidenceItems.isEmpty
                            ? HomeTokens.positive
                            : HomeTokens.warning,
                      ),
                    ),
                    // "Stale values" and "Missing details" were dropped here to
                    // cut stat density — both are low-signal (usually 0), already
                    // rolled into the health score above and surfaced as review
                    // signals in the Pro attention queue below.
                  ],
                );
              },
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: AppSpacing.md),
              const _PortfolioIntelligenceLockedPreview(),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              _PortfolioAttentionQueue(
                analytics: analytics,
                pendingItemCount: pendingItemCount,
                attentionCount: attentionCount,
                onFocusSelected: onAttentionFocus,
              ),
              if (analytics.topHighestValue.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _PortfolioTopValueList(items: analytics.topHighestValue),
              ],
              if (recommendations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                for (final recommendation in recommendations) ...[
                  _PortfolioRecommendationRow(
                    recommendation: recommendation,
                    onTap:
                        recommendation.type ==
                            CollectionRecommendationType.addMoreCollectibles
                        ? onAddMoreCollectibles
                        : null,
                  ),
                  if (recommendation != recommendations.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _summaryCopy(int attentionCount) {
    if (!isUnlocked) {
      return 'Preview your collection health. Pro unlocks the full attention queue, top value items, and refresh priorities.';
    }
    if (attentionCount == 0) {
      return 'Your saved items have healthy valuation coverage and metadata.';
    }
    return '$attentionCount review signals across pricing, confidence, photos, or metadata.';
  }

  int get _attentionCount {
    return pendingItemCount +
        analytics.lowConfidenceItems.length +
        analytics.collectionHealth.stalePricingCount +
        analytics.collectionHealth.missingDataCount +
        analytics.collectionHealth.lowQualityCount;
  }
}

class _PortfolioIntelligenceLockedPreview extends StatelessWidget {
  const _PortfolioIntelligenceLockedPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('portfolio-intelligence-locked-preview'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceInteractive.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HomeTokens.accentStrong.withValues(alpha: .32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HomeTokens.accentStrong.withValues(alpha: .16),
              border: Border.all(
                color: HomeTokens.accentStrong.withValues(alpha: .34),
              ),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: HomeTokens.accentStrong,
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro intelligence preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upgrade to see which items need photos, fresh pricing, confidence review, and the highest value records in your collection.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HomeTokens.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioAttentionQueue extends StatelessWidget {
  const _PortfolioAttentionQueue({
    required this.analytics,
    required this.pendingItemCount,
    required this.attentionCount,
    required this.onFocusSelected,
  });

  final CollectorDashboardAnalytics analytics;
  final int pendingItemCount;
  final int attentionCount;
  final ValueChanged<_PortfolioIntelligenceFocus> onFocusSelected;

  @override
  Widget build(BuildContext context) {
    final health = analytics.collectionHealth;
    final rows = [
      _AttentionQueueRowData(
        icon: Icons.price_check_outlined,
        focus: _PortfolioIntelligenceFocus.trustedValue,
        title: 'Needs trusted value',
        value: pendingItemCount,
        message: pendingItemCount == 0
            ? 'All saved items have a displayable value.'
            : 'Correct item identity and retry trusted pricing.',
      ),
      _AttentionQueueRowData(
        icon: Icons.refresh_outlined,
        focus: _PortfolioIntelligenceFocus.refreshPriority,
        title: 'Refresh priority',
        value: health.stalePricingCount,
        message: health.stalePricingCount == 0
            ? 'Pricing evidence is fresh.'
            : 'Refresh stale values to create new snapshots.',
      ),
      _AttentionQueueRowData(
        icon: Icons.fact_check_outlined,
        focus: _PortfolioIntelligenceFocus.metadataGaps,
        title: 'Metadata gaps',
        value: health.missingDataCount,
        message: health.missingDataCount == 0
            ? 'Core identity fields look complete.'
            : 'Add set, brand, year, notes, or identifiers.',
      ),
      _AttentionQueueRowData(
        icon: Icons.center_focus_strong_outlined,
        focus: _PortfolioIntelligenceFocus.lowConfidence,
        title: 'Low confidence',
        value: analytics.lowConfidenceItems.length,
        message: analytics.lowConfidenceItems.isEmpty
            ? 'Identification confidence is strong.'
            : 'Correct details or rescan weak matches.',
      ),
    ];

    return Container(
      key: const ValueKey('portfolio-intelligence-attention-queue'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceInteractive.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Attention queue',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                attentionCount == 0 ? 'Clear' : '$attentionCount signals',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: attentionCount == 0
                      ? HomeTokens.positive
                      : HomeTokens.warning,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final row in rows) ...[
            _PortfolioAttentionRow(
              data: row,
              onTap: () => onFocusSelected(row.focus),
            ),
            if (row != rows.last) const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _AttentionQueueRowData {
  const _AttentionQueueRowData({
    required this.icon,
    required this.focus,
    required this.title,
    required this.value,
    required this.message,
  });

  final IconData icon;
  final _PortfolioIntelligenceFocus focus;
  final String title;
  final int value;
  final String message;
}

class _PortfolioAttentionRow extends StatelessWidget {
  const _PortfolioAttentionRow({required this.data, required this.onTap});

  final _AttentionQueueRowData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = data.value == 0 ? HomeTokens.positive : HomeTokens.warning;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('portfolio-intelligence-action-${data.focus.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: HomeTokens.background.withValues(alpha: .36),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomeTokens.border.withValues(alpha: .72)),
          ),
          child: Row(
            children: [
              Icon(data.icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: HomeTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: HomeTokens.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${data.value}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF8BC7FF),
                    size: 20,
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

class _PortfolioTopValueList extends StatelessWidget {
  const _PortfolioTopValueList({required this.items});

  final List<CollectibleItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList(growable: false);
    return Container(
      key: const ValueKey('portfolio-intelligence-top-value'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceInteractive.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top value items',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in visibleItems) ...[
            _PortfolioTopValueRow(item: item),
            if (item != visibleItems.last)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _PortfolioTopValueRow extends StatelessWidget {
  const _PortfolioTopValueRow({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _formatAud(item.estimatedValue, currencyForItem(item)),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: HomeTokens.positive,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _IntelligenceMetricTile extends StatelessWidget {
  const _IntelligenceMetricTile({
    required this.label,
    required this.value,
    required this.supportingText,
    required this.color,
  });

  final String label;
  final String value;
  final String supportingText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceInteractive,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            supportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioRecommendationRow extends StatelessWidget {
  const _PortfolioRecommendationRow({required this.recommendation, this.onTap});

  final CollectionRecommendation recommendation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _recommendationIcon(recommendation.type),
          color: _recommendationColor(recommendation.type),
          size: 22,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: HomeTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                recommendation.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HomeTokens.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, color: Color(0xFF8BC7FF), size: 22),
        ],
      ],
    );
    if (onTap == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HomeTokens.surfaceInteractive.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HomeTokens.border),
        ),
        child: content,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(
          'portfolio-recommendation-action-${recommendation.type.name}',
        ),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HomeTokens.surfaceInteractive.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeTokens.border),
          ),
          child: content,
        ),
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
    final needsValue = !hasValue;
    final statusColor = needsValue ? HomeTokens.warning : HomeTokens.positive;
    final statusLabel = needsValue ? 'Needs value' : 'Valued';
    final valueLabel = hasValue
        ? _formatAud(item.estimatedValue, currencyForItem(item))
        : _valuationDisplayLabel(item);

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
                    // For unvalued items the "Needs value" pill already conveys
                    // status, so drop the placeholder condition (e.g. "Review
                    // needed") that only repeated it and clipped the line.
                    hasValue
                        ? '${item.category} · ${item.condition}'
                        : item.category,
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
                      // Pill sizes to its label so "Needs value" never clips.
                      _StatusPill(label: statusLabel, color: statusColor),
                      // The trend restates "Needs value" for unvalued items, so
                      // only show it when there is an actual value to trend.
                      if (hasValue) ...[
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
                  // The whole row is tappable (opens the item), so no trailing
                  // chevron. One contextual action remains: edit, or correct &
                  // reprice for items that still need a value.
                  SizedBox.square(
                    dimension: 34,
                    child: IconButton(
                      key: ValueKey('portfolio-grid-item-edit-${item.id}'),
                      onPressed: onEdit,
                      tooltip: needsValue
                          ? 'Correct details and reprice'
                          : 'Edit item',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        needsValue
                            ? Icons.manage_search_outlined
                            : Icons.edit_outlined,
                        color: needsValue
                            ? HomeTokens.warning
                            : const Color(0xFF8BC7FF),
                        size: 18,
                      ),
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
    this.subtitle = 'Changes apply only when you tap Apply.',
    this.initialScrollOffset = 0,
    super.key,
  });

  final String title;
  final String subtitle;
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
                    subtitle,
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
    return 'Review items needing value';
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
    return 'Confirmed values stay visible while no-value items are marked for review.';
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
  // Shared with Home via CollectibleItem.hasTrustedValuation so both screens
  // report the same value total and valued/trusted counts.
  return item.hasTrustedValuation;
}

bool _isPendingItem(CollectibleItem item) {
  return !_hasDisplayableValuation(item);
}

bool _hasMissingImportantData(CollectibleItem item) {
  final fields = [
    item.year,
    item.brand,
    item.setName,
    item.series,
    item.cardNumber,
    item.playerOrCharacter,
    item.rarity,
    item.condition,
    item.notes,
  ];
  return fields
          .where((value) => value != null && value.trim().isNotEmpty)
          .length <
      3;
}

bool _hasStalePricing(CollectibleItem item) {
  final lastUpdated =
      item.marketSummary?.lastUpdated ?? item.pricing?.lastUpdated;
  if (lastUpdated == null) {
    return true;
  }
  return collectibleDisplayTimestamp(item).difference(lastUpdated).inDays > 30;
}

Color _healthColor(CollectionHealthScore health) {
  if (health.score >= 70) {
    return HomeTokens.positive;
  }
  if (health.score >= 50) {
    return HomeTokens.warning;
  }
  return const Color(0xFFFF7A9A);
}

IconData _recommendationIcon(CollectionRecommendationType type) {
  return switch (type) {
    CollectionRecommendationType.scanAgain => Icons.document_scanner_outlined,
    CollectionRecommendationType.improvePhoto => Icons.add_a_photo_outlined,
    CollectionRecommendationType.upgradePlan =>
      Icons.workspace_premium_outlined,
    CollectionRecommendationType.reviewLowConfidence =>
      Icons.manage_search_outlined,
    CollectionRecommendationType.addMoreCollectibles => Icons.add_box_outlined,
  };
}

Color _recommendationColor(CollectionRecommendationType type) {
  return switch (type) {
    CollectionRecommendationType.scanAgain ||
    CollectionRecommendationType.reviewLowConfidence => HomeTokens.warning,
    CollectionRecommendationType.improvePhoto ||
    CollectionRecommendationType.addMoreCollectibles => const Color(0xFF8BC7FF),
    CollectionRecommendationType.upgradePlan => HomeTokens.positive,
  };
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

String _formatAud(double value, [String currencyCode = 'AUD']) {
  return formatCollectionValue(value, currencyCode: currencyCode);
}

String _trendLabel(CollectibleItem item) {
  if (!_hasDisplayableValuation(item)) {
    return switch (item.valuationStatus) {
      ValuationStatus.noMarketMatch => 'No market match',
      ValuationStatus.providerNotConfigured => 'Source unavailable',
      ValuationStatus.lookupFailed => 'Retry value',
      ValuationStatus.unavailable => 'Review value',
      ValuationStatus.marketEstimated ||
      ValuationStatus.aiEstimated => 'Stable',
    };
  }
  return 'Stable';
}

String _valuationDisplayLabel(CollectibleItem item) {
  return switch (item.valuationStatus) {
    ValuationStatus.noMarketMatch => 'No match',
    ValuationStatus.providerNotConfigured => 'No source',
    ValuationStatus.lookupFailed => 'Retry',
    ValuationStatus.unavailable => 'No value',
    ValuationStatus.marketEstimated ||
    ValuationStatus.aiEstimated => _formatAud(item.estimatedValue, currencyForItem(item)),
  };
}
