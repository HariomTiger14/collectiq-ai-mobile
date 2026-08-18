import 'dart:async';
import 'dart:math' as math;

import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/category_visual.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/search/data/repositories/api_catalog_search_repository.dart';
import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:collectiq_ai/shared/domain/pricing_unavailable_reason.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

enum SearchPreviewState { defaultView, active, results, empty }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    this.previewState = SearchPreviewState.defaultView,
    super.key,
  });

  final SearchPreviewState previewState;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryController;
  var _catalogResults = const <CatalogSearchResult>[];
  var _isCatalogLoading = false;
  String? _catalogError;
  String _lastCatalogQuery = '';
  int _catalogRequestId = 0;
  Timer? _catalogDebounceTimer;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: _initialQuery);
  }

  @override
  void dispose() {
    _catalogDebounceTimer?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  String get _initialQuery {
    return switch (widget.previewState) {
      SearchPreviewState.active => 'Char',
      SearchPreviewState.results => 'Charizard',
      SearchPreviewState.empty => 'vintage camera',
      SearchPreviewState.defaultView => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = GlassBottomNavBar.scrollContentClearance(context);
    final query = _queryController.text.trim();
    // Only categories with real catalog coverage belong here — a chip that
    // searches to zero results reads as a broken/missing item, not an empty
    // category. Sneakers has no catalog data yet, and this specific card
    // isn't in the catalog, so both were removed (confirmed live against
    // SIT: both returned zero results while every chip below returns real
    // matches).
    final catalogQuickFilters = const [
      (label: 'Pokemon Cards', category: 'Cards'),
      (label: 'Magic Cards', category: 'Cards'),
      (label: 'Comics', category: 'Comics'),
      (label: 'Coins', category: 'Coins'),
      (label: 'Video Games', category: 'Video Games'),
    ];
    final hasQuery = query.isNotEmpty;
    final isCatalogReady = query.length >= 2;
    final isCatalogEmpty =
        isCatalogReady &&
        !_isCatalogLoading &&
        _catalogError == null &&
        _catalogResults.isEmpty &&
        _lastCatalogQuery == query;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('search-screen'),
        backgroundColor: PackLoxTokens.background,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            key: const ValueKey('search-scroll-view'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HomeBrandLockup(),
                          const SizedBox(height: 20),
                          const _SearchHeader(),
                          const SizedBox(height: 22),
                          _SearchField(
                            controller: _queryController,
                            hintText: 'Search catalog prices',
                            onChanged: _onQueryChanged,
                            // Clearing is a deliberate one-off action, not a
                            // keystroke to debounce — route it the same way
                            // as a quick-filter tap so results disappear
                            // immediately instead of after the typing delay.
                            onClear: () => _setQuery(''),
                          ),
                          const SizedBox(height: 18),
                          _CatalogStatusCard(
                            resultCount: _catalogResults.length,
                            hasQuery: hasQuery,
                            isConnected:
                                _catalogError == null ||
                                _catalogResults.isNotEmpty,
                          ),
                          const SizedBox(height: 18),
                          if (!isCatalogReady) ...[
                            const _SectionTitle('Search the catalog'),
                            const SizedBox(height: 10),
                            _QuickFilterChips(
                              filters: catalogQuickFilters,
                              onSelected: _setQuery,
                            ),
                          ] else if (_isCatalogLoading)
                            const _CatalogLoadingState()
                          else if (_catalogError != null)
                            _CatalogErrorState(
                              message: _catalogError!,
                              onRetry: () => _runCatalogSearch(query),
                            )
                          else if (isCatalogEmpty)
                            const _CatalogEmptyState()
                          else ...[
                            const _SectionTitle('Catalog matches'),
                            const SizedBox(height: 10),
                            for (final result in _catalogResults.take(
                              20,
                            )) ...[
                              _CatalogResultCard(
                                result: result,
                                onTap: () =>
                                    _openCatalogResult(context, result),
                              ),
                              const SizedBox(height: 10),
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
        ),
      ),
    );
  }

  void _setQuery(String query) {
    _queryController.text = query;
    _queryController.selection = TextSelection.collapsed(
      offset: _queryController.text.length,
    );
    // A quick-filter tap is a deliberate, one-off action rather than a
    // stream of keystrokes, so it should search immediately rather than
    // wait out the typing debounce below.
    _catalogDebounceTimer?.cancel();
    setState(() {});
    _runCatalogSearch(query);
  }

  void _onQueryChanged(String query) {
    setState(() {});
    // Catalog search hits the backend (which itself queries Supabase), so
    // debounce it — otherwise a query like "Charizard" fires a request per
    // keystroke.
    _catalogDebounceTimer?.cancel();
    _catalogDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _runCatalogSearch(query);
      }
    });
  }

  Future<void> _runCatalogSearch(String query) async {
    final trimmed = query.trim();
    final requestId = ++_catalogRequestId;
    if (trimmed.length < 2) {
      setState(() {
        _catalogResults = const [];
        _isCatalogLoading = false;
        _catalogError = null;
        _lastCatalogQuery = '';
      });
      return;
    }
    setState(() {
      _isCatalogLoading = true;
      _catalogError = null;
      _lastCatalogQuery = trimmed;
    });
    try {
      final results = await ref
          .read(catalogSearchRepositoryProvider)
          .searchCatalog(query: trimmed);
      if (!mounted || requestId != _catalogRequestId) {
        return;
      }
      setState(() {
        _catalogResults = results;
        _isCatalogLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _catalogRequestId) {
        return;
      }
      setState(() {
        _catalogResults = const [];
        _isCatalogLoading = false;
        _catalogError = 'Catalog search is not connected yet.';
      });
    }
  }

  Future<void> _openCatalogResult(
    BuildContext context,
    CatalogSearchResult result,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CatalogResultDetailPage(result: result),
        settings: RouteSettings(name: '/search/catalog/${result.id}'),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover',
          style: textTheme.displaySmall?.copyWith(
            color: PackLoxTokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Search real market prices by name, category, brand, set, or identifier.',
          style: textTheme.titleMedium?.copyWith(
            color: PackLoxTokens.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isActive = controller.text.trim().isNotEmpty;

    return Container(
      key: const ValueKey('discover-search-field'),
      decoration: BoxDecoration(
        color: PackLoxTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? PackLoxTokens.blue : PackLoxTokens.border,
          width: isActive ? 1.6 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: PackLoxTokens.blue.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isActive ? PackLoxTokens.blue : PackLoxTokens.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const ValueKey('discover-search-input'),
              controller: controller,
              onChanged: onChanged,
              cursorColor: PackLoxTokens.cyan,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: PackLoxTokens.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: PackLoxTokens.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (isActive)
            IconButton(
              tooltip: 'Clear search',
              onPressed: onClear,
              icon: const Icon(
                Icons.close_rounded,
                color: PackLoxTokens.textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}


class _CatalogStatusCard extends StatelessWidget {
  const _CatalogStatusCard({
    required this.resultCount,
    required this.hasQuery,
    required this.isConnected,
  });

  final int resultCount;
  final bool hasQuery;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PackLoxTokens.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isConnected ? Icons.dataset_outlined : Icons.cloud_off_outlined,
              color: PackLoxTokens.amber,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasQuery
                      ? '$resultCount catalog ${resultCount == 1 ? 'match' : 'matches'}'
                      : 'Search PackLox catalog',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: PackLoxTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Looks beyond your saved items. Uses backend pricing/catalog data when connected.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PackLoxTokens.textSecondary,
                    height: 1.35,
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

class _CatalogLoadingState extends StatelessWidget {
  const _CatalogLoadingState();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      key: const ValueKey('discover-catalog-loading-state'),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: PackLoxTokens.amber,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Searching PackLox catalog...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: PackLoxTokens.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  const _CatalogErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      key: const ValueKey('discover-catalog-error-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, color: PackLoxTokens.amber),
          const SizedBox(height: 12),
          Text(
            'Catalog search unavailable',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey('discover-catalog-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      key: const ValueKey('discover-catalog-empty-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.manage_search_outlined, color: PackLoxTokens.cyan),
          const SizedBox(height: 12),
          Text(
            'No catalog match yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a more specific name, card number, set, console, or product identifier.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// A fixed-column grid forces every label into the same width regardless of
// how long it is — "Coins" and "Nike Air Force 1" don't belong in equally
// sized boxes, and the longer ones were truncating illegibly. A Wrap of
// pill chips sizes each one to its own content instead, so nothing clips
// and short/long examples can sit naturally side by side.
class _QuickFilterChips extends StatelessWidget {
  const _QuickFilterChips({required this.filters, required this.onSelected});

  final List<({String label, String category})> filters;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('discover-quick-filter-grid'),
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var index = 0; index < filters.length; index++)
          _QuickFilterChip(
            key: ValueKey('discover-quick-filter-$index'),
            label: filters[index].label,
            category: filters[index].category,
            onTap: () => onSelected(filters[index].label),
          ),
      ],
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.category,
    required this.onTap,
    super.key,
  });

  final String label;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Same category → same icon/art/color everywhere in the app: resolve
    // through the shared mapping (also used by Home's category tiles)
    // instead of this screen's own icon logic. The category is passed in
    // explicitly (not inferred from the label) since example product names
    // like "Charizard 4/102" don't contain a recognizable category keyword.
    final visual = categoryVisualFor(category);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: PackLoxTokens.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: PackLoxTokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryArtwork(visual: visual, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: PackLoxTokens.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogResultCard extends StatelessWidget {
  const _CatalogResultCard({required this.result, required this.onTap});

  final CatalogSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = _formatCatalogValue(result);
    final hasValue = _hasCatalogValue(result);
    final subtitle = [
      result.category,
      result.setName,
      result.identifier,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' - ');
    final sourceLabel = result.source;
    return Semantics(
      button: true,
      label: 'Open ${result.title}',
      child: GestureDetector(
        key: ValueKey('discover-catalog-result-${result.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: _CatalogPlaceholderThumbnail(
                  key: ValueKey('discover-catalog-placeholder-${result.id}'),
                  category: result.category,
                  title: result.title,
                  setName: result.setName,
                  imageUrl: result.imageUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: PackLoxTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle.isEmpty ? result.source : subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PackLoxTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _CatalogValueBadge(
                                value: value,
                                hasValue: hasValue,
                                unavailableLabel: pricingUnavailableCopy(
                                  reasonCode: result.reasonCode,
                                ).shortLabel,
                              ),
                              _CatalogMetaPill(label: sourceLabel),
                              if (result.confidence != null)
                                _CatalogMetaPill(
                                  label:
                                      '${(result.confidence!.clamp(0, 1) * 100).round()}% match',
                                ),
                              if (_catalogExternalLink(result) case final link?)
                                _CatalogListingLink(
                                  key: ValueKey(
                                    'discover-catalog-listing-link-${result.id}',
                                  ),
                                  label: link.isImage
                                      ? 'View image'
                                      : 'View listing',
                                  onTap: () =>
                                      _launchExternalLink(context, link.url),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: PackLoxTokens.textSecondary,
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
      ),
    );
  }
}

class _CatalogValueBadge extends StatelessWidget {
  const _CatalogValueBadge({
    required this.value,
    required this.hasValue,
    this.unavailableLabel,
  });

  final String value;
  final bool hasValue;
  final String? unavailableLabel;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 126),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasValue
              ? PackLoxTokens.cyan.withValues(alpha: 0.12)
              : PackLoxTokens.textSecondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hasValue
                ? PackLoxTokens.cyan.withValues(alpha: 0.28)
                : PackLoxTokens.border.withValues(alpha: 0.82),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            hasValue ? value : unavailableLabel ?? 'Value unavailable',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: hasValue
                  ? PackLoxTokens.textPrimary
                  : PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogMetaPill extends StatelessWidget {
  const _CatalogMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 124),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: PackLoxTokens.surfaceRaised.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: PackLoxTokens.border.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: PackLoxTokens.textSecondary,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Small, unobtrusive "View listing"/"View image" affordance shown on
/// catalog cards so users can see a real photo of the item -- either its
/// original source page or, when available, a direct link straight to a
/// publisher-sourced product image -- without the app hosting/rendering
/// the image itself.
class _CatalogListingLink extends StatelessWidget {
  const _CatalogListingLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PackLoxTokens.cyan,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.north_east_rounded,
                size: 12,
                color: PackLoxTokens.cyan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogResultDetailPage extends ConsumerStatefulWidget {
  const _CatalogResultDetailPage({
    required this.result,
    this.qaInitialScrollOffset = 0,
  });

  final CatalogSearchResult result;
  final double qaInitialScrollOffset;

  @override
  ConsumerState<_CatalogResultDetailPage> createState() =>
      _CatalogResultDetailPageState();
}

class CatalogResultDetailPreviewPage extends StatelessWidget {
  const CatalogResultDetailPreviewPage({
    required this.result,
    this.qaInitialScrollOffset = 0,
    super.key,
  });

  final CatalogSearchResult result;
  final double qaInitialScrollOffset;

  @override
  Widget build(BuildContext context) => _CatalogResultDetailPage(
    result: result,
    qaInitialScrollOffset: qaInitialScrollOffset,
  );
}

class _CatalogResultDetailPageState
    extends ConsumerState<_CatalogResultDetailPage> {
  var _isSaving = false;
  var _isLoadingDetail = true;
  String? _detailError;
  late CatalogSearchResult _result;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _result = widget.result;
    _scrollController = ScrollController(
      initialScrollOffset: widget.qaInitialScrollOffset,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalogDetail();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final value = _formatCatalogValue(result);
    final confidence = result.confidence == null
        ? 'Not supplied'
        : '${(result.confidence!.clamp(0, 1) * 100).round()}%';
    final rows = [
      _CatalogDetailRowData('Category', result.category),
      if (_clean(result.setName) != null)
        _CatalogDetailRowData('Set / product family', result.setName!.trim()),
      if (_clean(result.identifier) != null)
        _CatalogDetailRowData('Identifier', result.identifier!.trim()),
      _CatalogDetailRowData('Source', result.source),
      _CatalogDetailRowData('Currency', result.currency.toUpperCase()),
      _CatalogDetailRowData('Confidence', confidence),
      if (result.lastUpdated != null)
        _CatalogDetailRowData('Updated', _formatShortDate(result.lastUpdated!)),
      if (_clean(result.attribution) != null)
        _CatalogDetailRowData('Attribution', result.attribution!.trim()),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('catalog-result-detail-screen'),
        backgroundColor: PackLoxTokens.background,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CatalogDetailTopBar(
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: PackLoxTokens.surfaceRaised,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: PackLoxTokens.border,
                                  ),
                                ),
                                child: _CatalogPlaceholderArt(
                                  category: result.category,
                                  title: result.title,
                                  setName: result.setName,
                                  imageUrl: result.imageUrl,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            result.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: PackLoxTokens.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.04,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SearchPill(label: result.category),
                              _SearchPill(label: result.source),
                            ],
                          ),
                          if (_catalogExternalLink(result) case final link?) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: const ValueKey(
                                  'catalog-detail-view-listing',
                                ),
                                onPressed: () =>
                                    _launchExternalLink(context, link.url),
                                icon: const Icon(
                                  Icons.north_east_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  link.isImage
                                      ? 'View image'
                                      : 'View original listing',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: PackLoxTokens.cyan,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          _CatalogValuePanel(result: result, value: value),
                          const SizedBox(height: 14),
                          _CatalogTrustPanel(result: result),
                          const SizedBox(height: 14),
                          _CatalogHistoryPanel(
                            history: result.history,
                            isLoading: _isLoadingDetail,
                            errorMessage: _detailError,
                          ),
                          const SizedBox(height: 14),
                          _SurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle('Catalog identity'),
                                const SizedBox(height: 12),
                                for (final row in rows) ...[
                                  _CatalogDetailRow(row: row),
                                  if (row != rows.last)
                                    const Divider(
                                      color: PackLoxTokens.border,
                                      height: 18,
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle('Portfolio snapshot'),
                                const SizedBox(height: 8),
                                Text(
                                  'Saving stores this catalog match and current valuation as a dated portfolio snapshot. Browsing your portfolio will not call pricing APIs again.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: PackLoxTokens.textSecondary,
                                        height: 1.34,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              key: const ValueKey(
                                'catalog-detail-add-to-portfolio',
                              ),
                              onPressed: _isSaving ? null : _saveToPortfolio,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add_rounded),
                              label: Text(
                                _isSaving ? 'Saving' : 'Add to Portfolio',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: PackLoxTokens.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToPortfolio() async {
    setState(() => _isSaving = true);
    final item = _catalogResultToPortfolioItem(_result);
    try {
      final saved = await ref
          .read(portfolioControllerProvider.notifier)
          .saveItem(item);
      if (!mounted) {
        return;
      }
      if (!saved) {
        // Blocked by the free cap; the app shell shows the upgrade sheet.
        setState(() => _isSaving = false);
        return;
      }
      final savedItem = ref
          .read(portfolioControllerProvider)
          .items
          .where((candidate) => candidate.id == item.id)
          .firstOrNull;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CollectibleDetailPage(
            item: savedItem ?? item,
            onDelete: (itemId) async {
              await ref
                  .read(portfolioControllerProvider.notifier)
                  .removeItem(itemId);
              return true;
            },
          ),
          settings: RouteSettings(name: '/portfolio/catalog/${item.id}'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save catalog item')),
      );
    }
  }

  Future<void> _loadCatalogDetail() async {
    try {
      final detail = await ref
          .read(catalogSearchRepositoryProvider)
          .getCatalogDetail(result: widget.result);
      if (!mounted) {
        return;
      }
      setState(() {
        _result = detail;
        _isLoadingDetail = false;
        _detailError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingDetail = false;
        _detailError = 'History unavailable';
      });
    }
  }
}

class _CatalogDetailTopBar extends StatelessWidget {
  const _CatalogDetailTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          key: const ValueKey('catalog-detail-back'),
          onPressed: onBack,
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            backgroundColor: PackLoxTokens.surfaceRaised,
            foregroundColor: PackLoxTokens.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Catalog match',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: PackLoxTokens.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CatalogValuePanel extends StatelessWidget {
  const _CatalogValuePanel({required this.result, required this.value});

  final CatalogSearchResult result;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current value',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CatalogEstimateChip(
                label: 'Low',
                value: _formatOptionalCatalogValue(
                  result.lowEstimate,
                  result.currency,
                ),
              ),
              _CatalogEstimateChip(
                label: 'High',
                value: _formatOptionalCatalogValue(
                  result.highEstimate,
                  result.currency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatalogEstimateChip extends StatelessWidget {
  const _CatalogEstimateChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PackLoxTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PackLoxTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogTrustPanel extends StatelessWidget {
  const _CatalogTrustPanel({required this.result});

  final CatalogSearchResult result;

  @override
  Widget build(BuildContext context) {
    final hasValue = _hasCatalogValue(result);
    final confidence = result.confidence;
    final unavailableCopy = pricingUnavailableCopy(
      reasonCode: result.reasonCode,
    );
    final rows = [
      _CatalogDetailRowData(
        'Status',
        hasValue ? 'Trusted provider value' : unavailableCopy.title,
      ),
      _CatalogDetailRowData('Source', result.source),
      _CatalogDetailRowData('Currency', result.currency.toUpperCase()),
      if (confidence != null)
        _CatalogDetailRowData(
          'Confidence',
          '${_catalogConfidenceBand(confidence)} (${(confidence.clamp(0, 1) * 100).round()}%)',
        ),
      if (_clean(result.setName) != null || _clean(result.identifier) != null)
        _CatalogDetailRowData('Match basis', _catalogMatchBasis(result)),
      _CatalogDetailRowData(
        'Value range',
        '${_formatOptionalCatalogValue(result.lowEstimate, result.currency)} - ${_formatOptionalCatalogValue(result.highEstimate, result.currency)}',
      ),
      if (result.lastUpdated != null)
        _CatalogDetailRowData(
          'Provider checked',
          _formatShortDate(result.lastUpdated!),
        ),
      if (_clean(result.attribution) != null)
        _CatalogDetailRowData('Attribution', result.attribution!.trim()),
      if (!hasValue)
        _CatalogDetailRowData('Reason', unavailableCopy.shortLabel),
      if (!hasValue)
        _CatalogDetailRowData('Next step', unavailableCopy.actionLabel),
    ];

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Pricing evidence'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (hasValue ? PackLoxTokens.success : PackLoxTokens.cyan)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        (hasValue ? PackLoxTokens.success : PackLoxTokens.cyan)
                            .withValues(alpha: 0.30),
                  ),
                ),
                child: Icon(
                  hasValue
                      ? Icons.verified_user_outlined
                      : Icons.info_outline_rounded,
                  color: hasValue ? PackLoxTokens.success : PackLoxTokens.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue
                      ? 'This value comes from provider-backed catalog evidence. PackLox saves it as a dated portfolio snapshot when you add the item.'
                      : _clean(result.displayMessage) ??
                            unavailableCopy.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PackLoxTokens.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.34,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            _CatalogDetailRow(row: row),
            if (row != rows.last)
              const Divider(color: PackLoxTokens.border, height: 18),
          ],
        ],
      ),
    );
  }
}

class _CatalogHistoryPanel extends StatelessWidget {
  const _CatalogHistoryPanel({
    required this.history,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<CatalogPriceHistoryPoint> history;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('Price history')),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (history.isNotEmpty) ...[
            for (final point in history.take(4)) ...[
              _CatalogHistoryRow(point: point),
              if (point != history.take(4).last)
                const Divider(color: PackLoxTokens.border, height: 18),
            ],
          ] else
            Text(
              isLoading
                  ? 'Loading observed catalog history...'
                  : errorMessage ??
                        'History starts after daily catalog refreshes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PackLoxTokens.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.32,
              ),
            ),
        ],
      ),
    );
  }
}

class _CatalogHistoryRow extends StatelessWidget {
  const _CatalogHistoryRow({required this.point});

  final CatalogPriceHistoryPoint point;

  @override
  Widget build(BuildContext context) {
    final value = _formatOptionalCatalogValue(
      point.marketValue,
      point.currency,
    );
    final range = point.isCurrent
        ? 'Current from ${_formatShortDate(point.validFrom)}'
        : '${_formatShortDate(point.validFrom)} - ${point.validTo == null ? 'ended' : _formatShortDate(point.validTo!)}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: point.isCurrent ? PackLoxTokens.success : PackLoxTokens.cyan,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: PackLoxTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                range,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PackLoxTokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (_clean(point.sourceFile) != null)
          _SearchPill(label: point.sourceFile!.replaceAll('.csv', '')),
      ],
    );
  }
}

class _CatalogDetailRowData {
  const _CatalogDetailRowData(this.label, this.value);

  final String label;
  final String value;
}

class _CatalogDetailRow extends StatelessWidget {
  const _CatalogDetailRow({required this.row});

  final _CatalogDetailRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            row.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 7,
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.24,
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogPlaceholderThumbnail extends StatelessWidget {
  const _CatalogPlaceholderThumbnail({
    required this.category,
    required this.title,
    required this.setName,
    this.imageUrl,
    super.key,
  });

  final String category;
  final String title;
  final String? setName;

  /// Real catalog product photo (KicksDB today). Falls back to the
  /// bucketed illustration below on null/empty or a failed load.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 64,
        decoration: BoxDecoration(
          color: PackLoxTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PackLoxTokens.border),
        ),
        child: _CatalogPlaceholderArt(
          category: category,
          title: title,
          setName: setName,
          imageUrl: imageUrl,
        ),
      ),
    );
  }
}

class _CatalogPlaceholderArt extends StatelessWidget {
  const _CatalogPlaceholderArt({
    required this.category,
    required this.title,
    required this.setName,
    this.imageUrl,
  });

  final String category;
  final String title;
  final String? setName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final style = _placeholderStyle(category, title, setName);
    final photoUrl = imageUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _catalogArtFallback(style),
      );
    }
    return _catalogArtFallback(style);
  }

  Widget _catalogArtFallback(_PlaceholderStyle style) {
    if (style.assetPath != null) {
      return Image.asset(
        style.assetPath!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _FallbackCatalogPlaceholderArt(
          style: style,
        ),
      );
    }
    return _FallbackCatalogPlaceholderArt(style: style);
  }
}

class _FallbackCatalogPlaceholderArt extends StatelessWidget {
  const _FallbackCatalogPlaceholderArt({required this.style});

  final _PlaceholderStyle style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: style.background),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PackLoxTokens.textPrimary.withValues(alpha: 0.045),
                  Colors.transparent,
                  style.accent.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: PackLoxTokens.textPrimary.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: 38,
            height: 38,
            child: CustomPaint(
              painter: _PlaceholderMarkPainter(
                mark: style.mark,
                accent: style.accent,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: PackLoxTokens.surface.withValues(alpha: 0.62),
              border: Border(
                top: BorderSide(color: style.accent.withValues(alpha: 0.24)),
              ),
            ),
            child: Text(
              style.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: PackLoxTokens.textSecondary,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: PackLoxTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PackLoxTokens.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: PackLoxTokens.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

enum _PlaceholderMark { card, game, toy, coin, comic, watch, shoe, collectible }

class _PlaceholderMarkPainter extends CustomPainter {
  const _PlaceholderMarkPainter({required this.mark, required this.accent});

  final _PlaceholderMark mark;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    switch (mark) {
      case _PlaceholderMark.card:
        _drawCard(canvas, size, glow);
        _drawCard(canvas, size, stroke);
      case _PlaceholderMark.game:
        _drawGame(canvas, size, fill, glow, stroke);
      case _PlaceholderMark.toy:
        _drawToy(canvas, size, fill, glow, stroke);
      case _PlaceholderMark.coin:
        _drawCoin(canvas, size, fill, glow, stroke);
      case _PlaceholderMark.comic:
        _drawComic(canvas, size, fill, glow, stroke);
      case _PlaceholderMark.watch:
        _drawWatch(canvas, size, fill, glow, stroke);
      case _PlaceholderMark.shoe:
        _drawShoe(canvas, size, fill, glow, stroke);
      case _PlaceholderMark.collectible:
        _drawCollectible(canvas, size, fill, glow, stroke);
    }
  }

  void _drawCard(Canvas canvas, Size size, Paint paint) {
    final rect = Rect.fromLTWH(
      size.width * 0.30,
      size.height * 0.16,
      size.width * 0.44,
      size.height * 0.62,
    );
    canvas.save();
    canvas.translate(size.width * 0.05, size.height * 0.02);
    canvas.rotate(-0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.07)),
      paint,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(-size.width * 0.04, size.height * 0.05);
    canvas.rotate(0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.07)),
      paint,
    );
    canvas.restore();
  }

  void _drawGame(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint glow,
    Paint stroke,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.32,
        size.width * 0.76,
        size.height * 0.34,
      ),
      Radius.circular(size.width * 0.18),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, glow);
    canvas.drawRRect(body, stroke);
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.49),
      Offset(size.width * 0.42, size.height * 0.49),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.42),
      Offset(size.width * 0.35, size.height * 0.56),
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.46),
      2.8,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.53),
      2.8,
      stroke,
    );
  }

  void _drawToy(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint glow,
    Paint stroke,
  ) {
    final body = Path()
      ..moveTo(size.width * 0.18, size.height * 0.56)
      ..lineTo(size.width * 0.28, size.height * 0.40)
      ..lineTo(size.width * 0.62, size.height * 0.40)
      ..lineTo(size.width * 0.78, size.height * 0.55)
      ..lineTo(size.width * 0.84, size.height * 0.61)
      ..lineTo(size.width * 0.16, size.height * 0.61)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, glow);
    canvas.drawPath(body, stroke);
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.65),
      4.2,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.65),
      4.2,
      stroke,
    );
  }

  void _drawCoin(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint glow,
    Paint stroke,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.31;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, glow);
    canvas.drawCircle(center, radius, stroke);
    canvas.drawCircle(center, radius * 0.64, stroke);
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(center.dx + i * 4, center.dy - radius * 0.88),
        Offset(center.dx + i * 4, center.dy - radius * 0.62),
        stroke,
      );
    }
  }

  void _drawComic(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint glow,
    Paint stroke,
  ) {
    final page = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.16,
        size.width * 0.52,
        size.height * 0.68,
      ),
      Radius.circular(size.width * 0.05),
    );
    canvas.drawRRect(page, fill);
    canvas.drawRRect(page, glow);
    canvas.drawRRect(page, stroke);
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.36),
      Offset(size.width * 0.66, size.height * 0.36),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.52),
      Offset(size.width * 0.66, size.height * 0.52),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.24),
      Offset(size.width * 0.50, size.height * 0.72),
      stroke,
    );
  }

  void _drawWatch(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint glow,
    Paint stroke,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.39,
          2,
          size.width * 0.22,
          size.height * 0.24,
        ),
        Radius.circular(size.width * 0.05),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.39,
          size.height * 0.74,
          size.width * 0.22,
          size.height * 0.24,
        ),
        Radius.circular(size.width * 0.05),
      ),
      stroke,
    );
    canvas.drawCircle(center, size.shortestSide * 0.25, fill);
    canvas.drawCircle(center, size.shortestSide * 0.25, glow);
    canvas.drawCircle(center, size.shortestSide * 0.25, stroke);
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - size.height * 0.13),
      stroke,
    );
    canvas.drawLine(
      center,
      Offset(center.dx + size.width * 0.11, center.dy),
      stroke,
    );
  }

  void _drawShoe(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint glow,
    Paint stroke,
  ) {
    final shoe = Path()
      ..moveTo(size.width * 0.18, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.52,
        size.width * 0.42,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.48,
        size.width * 0.78,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.58,
        size.width * 0.84,
        size.height * 0.68,
      )
      ..lineTo(size.width * 0.20, size.height * 0.68)
      ..close();
    canvas.drawPath(shoe, fill);
    canvas.drawPath(shoe, glow);
    canvas.drawPath(shoe, stroke);
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.50),
      Offset(size.width * 0.58, size.height * 0.55),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.46, size.height * 0.44),
      Offset(size.width * 0.62, size.height * 0.50),
      stroke,
    );
  }

  void _drawCollectible(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint glow,
    Paint stroke,
  ) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -1.5708 + i * 1.0472;
      final point = Offset(
        center.dx + size.width * 0.30 * math.cos(angle),
        center.dy + size.height * 0.30 * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - size.height * 0.30),
      stroke,
    );
    canvas.drawLine(
      center,
      Offset(center.dx + size.width * 0.26, center.dy + size.height * 0.15),
      stroke,
    );
    canvas.drawLine(
      center,
      Offset(center.dx - size.width * 0.26, center.dy + size.height * 0.15),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PlaceholderMarkPainter oldDelegate) {
    return oldDelegate.mark != mark || oldDelegate.accent != accent;
  }
}

CollectibleItem _catalogResultToPortfolioItem(CatalogSearchResult result) {
  final now = DateTime.now();
  final value = result.marketValue ?? 0;
  final low = result.lowEstimate ?? value;
  final high = result.highEstimate ?? value;
  final confidence = (result.confidence?.clamp(0, 1) ?? 0.72).toDouble();
  final attribution = result.attribution ?? 'Pricing data by ${result.source}';
  final imagePath =
      result.imageUrl ??
      _placeholderStyle(
        result.category,
        result.title,
        result.setName,
      ).assetPath ??
      '';
  final pricing = PricingInfo(
    estimatedMarketValue: value,
    lowEstimate: low,
    highEstimate: high,
    currency: result.currency,
    pricingSource: result.source,
    pricingConfidence: confidence,
    lastUpdated: result.lastUpdated ?? now,
    valuationStatus: value > 0
        ? ValuationStatus.marketEstimated
        : ValuationStatus.noMarketMatch,
    valuationSource: result.source.toLowerCase().replaceAll(' ', '_'),
    pricingExplanation:
        'Saved from PackLox catalog search as a dated portfolio snapshot.',
    reasonCode: value > 0 ? 'CATALOG_SEARCH_MATCH' : 'CATALOG_NO_PRICE',
    valuationStrategy: 'catalog_lookup',
    attributionText: attribution,
    displayString: value > 0 ? _formatCatalogValue(result) : null,
  );
  return CollectibleItem(
    id: 'catalog-${_safeId(result.id)}-${now.microsecondsSinceEpoch}',
    title: result.title,
    category: result.category,
    estimatedValue: value,
    confidence: confidence,
    condition: 'Unspecified',
    recommendation:
        'Saved from catalog search. Add your own photos and condition notes to improve portfolio accuracy.',
    imagePath: imagePath,
    createdAt: now,
    setName: _clean(result.setName),
    cardNumber: _clean(result.identifier),
    notes: _catalogSnapshotNotes(result),
    valuationStatus: pricing.valuationStatus,
    valuationSource: pricing.valuationSource,
    pricing: pricing,
  );
}

String _catalogSnapshotNotes(CatalogSearchResult result) {
  final parts = [
    'Catalog ID: ${result.id}',
    'Source: ${result.source}',
    if (_clean(result.attribution) != null) result.attribution!.trim(),
  ];
  return parts.join('\n');
}

String _safeId(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'item' : normalized;
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

_PlaceholderStyle _placeholderStyle(
  String category,
  String title,
  String? setName,
) {
  final text = '$category $title ${setName ?? ''}'.toLowerCase();
  if (text.contains('pokemon') ||
      text.contains('magic') ||
      text.contains('yugioh') ||
      text.contains('yu-gi-oh') ||
      text.contains('one piece') ||
      text.contains('card')) {
    return const _PlaceholderStyle(
      label: 'CARD',
      mark: _PlaceholderMark.card,
      accent: PackLoxTokens.cyan,
      background: Color(0xFF171421),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_card_v1.png',
    );
  }
  if (text.contains('comic')) {
    return const _PlaceholderStyle(
      label: 'COMIC',
      mark: _PlaceholderMark.comic,
      accent: Color(0xFF9B7CFF),
      background: Color(0xFF171421),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_comic_v1.png',
    );
  }
  if (text.contains('watch')) {
    return const _PlaceholderStyle(
      label: 'WATCH',
      mark: _PlaceholderMark.watch,
      accent: PackLoxTokens.success,
      background: Color(0xFF102019),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_watch_v1.png',
    );
  }
  if (text.contains('funko') ||
      text.contains('vinyl figure') ||
      text.contains('vinyl collectible')) {
    return const _PlaceholderStyle(
      label: 'FUNKO',
      mark: _PlaceholderMark.toy,
      accent: PackLoxTokens.blue,
      background: Color(0xFF111827),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_toy_v1.png',
    );
  }
  if (text.contains('shoe') || text.contains('sneaker')) {
    return const _PlaceholderStyle(
      label: 'SHOE',
      mark: _PlaceholderMark.shoe,
      accent: PackLoxTokens.blue,
      background: Color(0xFF111827),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_shoe_v1.png',
    );
  }
  if (text.contains('game') ||
      text.contains('nintendo') ||
      text.contains('playstation') ||
      text.contains('xbox') ||
      text.contains('sega')) {
    return const _PlaceholderStyle(
      label: 'GAME',
      mark: _PlaceholderMark.game,
      accent: PackLoxTokens.cyan,
      background: Color(0xFF101C22),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_game_v1.png',
    );
  }
  if (text.contains('lego') ||
      text.contains('building set') ||
      text.contains('brick set')) {
    return const _PlaceholderStyle(
      label: 'LEGO',
      mark: _PlaceholderMark.collectible,
      accent: PackLoxTokens.cyan,
      background: Color(0xFF101A20),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_item_v1.png',
    );
  }
  if (text.contains('toy') ||
      text.contains('car') ||
      text.contains('hot wheels')) {
    return const _PlaceholderStyle(
      label: 'TOY',
      mark: _PlaceholderMark.toy,
      accent: PackLoxTokens.blue,
      background: Color(0xFF111827),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_toy_v1.png',
    );
  }
  if (text.contains('coin')) {
    return const _PlaceholderStyle(
      label: 'COIN',
      mark: _PlaceholderMark.coin,
      accent: PackLoxTokens.amber,
      background: Color(0xFF201C12),
      assetPath:
          'assets/packlox/icons/categories/3d/packlox_category_placeholder_coin_v1.png',
    );
  }
  return const _PlaceholderStyle(
    label: 'ITEM',
    mark: _PlaceholderMark.collectible,
    accent: PackLoxTokens.cyan,
    background: Color(0xFF101A20),
    assetPath:
        'assets/packlox/icons/categories/3d/packlox_category_placeholder_item_v1.png',
  );
}

class _PlaceholderStyle {
  const _PlaceholderStyle({
    required this.label,
    required this.mark,
    required this.accent,
    required this.background,
    this.assetPath,
  });

  final String label;
  final _PlaceholderMark mark;
  final Color accent;
  final Color background;
  final String? assetPath;
}

/// Opens a catalog item's source product page -- or, when available, a
/// direct link to a publisher-sourced product image -- in an in-app
/// browser tab (SFSafariViewController on iOS, Chrome Custom Tabs on
/// Android), failing silently with a brief snackbar if the link cannot be
/// opened.
Future<void> _launchExternalLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  var launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    launched = false;
  }
  if (!launched) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Unable to open link')),
    );
  }
}

/// Picks the outbound link target for a catalog result: a direct
/// publisher-sourced image link when available (preferred, since
/// PriceCharting's own product page frequently has no image at all for
/// TCG categories -- the entire reason a separate image-enrichment
/// pipeline exists), otherwise a fallback to the source's product page.
/// Returns null when neither is available.
({String url, bool isImage})? _catalogExternalLink(CatalogSearchResult result) {
  final externalImageUrl = (result.externalImageUrl ?? '').trim();
  if (externalImageUrl.isNotEmpty) {
    return (url: externalImageUrl, isImage: true);
  }
  final productUrl = (result.productUrl ?? '').trim();
  if (productUrl.isNotEmpty) {
    return (url: productUrl, isImage: false);
  }
  return null;
}

String _formatCatalogValue(CatalogSearchResult result) {
  final value = result.marketValue;
  if (value == null || value <= 0) {
    return 'Price unavailable';
  }
  final amount = _formatCatalogAmount(value);
  final withCommas = amount.replaceFirstMapped(
    RegExp(r'^\d+'),
    (match) => match
        .group(0)!
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','),
  );
  final currency = result.currency.trim().toUpperCase();
  if (currency == 'AUD' || currency.isEmpty) {
    return '\$$withCommas AUD';
  }
  if (currency == 'USD') {
    return 'USD \$$withCommas';
  }
  return '$currency $withCommas';
}

bool _hasCatalogValue(CatalogSearchResult result) {
  final value = result.marketValue;
  return value != null && value > 0;
}

String _catalogConfidenceBand(double confidence) {
  final bounded = confidence.clamp(0, 1);
  if (bounded >= 0.85) {
    return 'High';
  }
  if (bounded >= 0.70) {
    return 'Medium';
  }
  if (bounded > 0) {
    return 'Low';
  }
  return 'Not scored';
}

String _catalogMatchBasis(CatalogSearchResult result) {
  final parts = <String>[
    'title',
    if (_clean(result.setName) != null) 'set/product family',
    if (_clean(result.identifier) != null) 'identifier',
  ];
  return 'Matched by ${parts.join(', ')}';
}

String _formatOptionalCatalogValue(double? value, String currency) {
  if (value == null || value <= 0) {
    return 'Not supplied';
  }
  return _formatCatalogValue(
    CatalogSearchResult(
      id: 'estimate',
      title: 'Estimate',
      category: 'Catalog',
      source: 'PackLox',
      currency: currency,
      marketValue: value,
    ),
  );
}

String _formatCatalogAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
}

String _formatShortDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: PackLoxTokens.textPrimary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PackLoxTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PackLoxTokens.border),
      ),
      padding: padding,
      child: child,
    );
  }
}
