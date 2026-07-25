import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/search/data/repositories/api_catalog_search_repository.dart';
import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SearchPreviewState { defaultView, active, results, empty }

enum _SearchScope { collection, catalog }

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
  _SearchScope _scope = _SearchScope.collection;
  var _catalogResults = const <CatalogSearchResult>[];
  var _isCatalogLoading = false;
  String? _catalogError;
  String _lastCatalogQuery = '';
  int _catalogRequestId = 0;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: _initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(portfolioControllerProvider.notifier).ensureLoaded();
      }
    });
  }

  @override
  void dispose() {
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
    final portfolioState = ref.watch(portfolioControllerProvider);
    final query = _queryController.text.trim();
    final results = _searchItems(portfolioState.items, query);
    final quickFilters = _quickFilters(portfolioState.items);
    final catalogQuickFilters = const [
      'Charizard 4/102',
      'Pokemon Cards',
      'Nintendo 64',
      'Magic Cards',
    ];
    final hasQuery = query.isNotEmpty;
    final hasResults = results.isNotEmpty;
    final isCollection = _scope == _SearchScope.collection;
    final isCatalog = _scope == _SearchScope.catalog;
    final isEmpty = isCollection && hasQuery && !hasResults;
    final isCatalogReady = query.length >= 2;
    final isCatalogEmpty =
        isCatalog &&
        isCatalogReady &&
        !_isCatalogLoading &&
        _catalogError == null &&
        _catalogResults.isEmpty &&
        _lastCatalogQuery == query;
    final showInitialLoading =
        isCollection &&
        portfolioState.isLoading &&
        portfolioState.items.isEmpty;
    final showInitialError =
        isCollection &&
        portfolioState.errorMessage != null &&
        portfolioState.items.isEmpty;

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
                padding: EdgeInsets.fromLTRB(16, 28, 16, bottomPadding),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SearchHeader(),
                          const SizedBox(height: 22),
                          _SearchField(
                            controller: _queryController,
                            hintText: isCatalog
                                ? 'Search catalog prices'
                                : 'Search saved items',
                            onChanged: _onQueryChanged,
                            onClear: () {
                              _queryController.clear();
                              _onQueryChanged('');
                            },
                          ),
                          const SizedBox(height: 12),
                          _SearchScopeControl(
                            scope: _scope,
                            onChanged: _setScope,
                          ),
                          const SizedBox(height: 18),
                          if (showInitialLoading)
                            const _SearchLoadingState()
                          else if (showInitialError)
                            _SearchErrorState(
                              message:
                                  portfolioState.errorMessage ??
                                  'Unable to load saved items.',
                              onRetry: () => ref
                                  .read(portfolioControllerProvider.notifier)
                                  .loadItems(),
                            )
                          else if (isEmpty)
                            const _SearchEmptyState()
                          else if (isCatalog) ...[
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
                              _QuickFilterGrid(
                                labels: catalogQuickFilters,
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
                                _CatalogResultCard(result: result),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ] else ...[
                            _SearchStatusCard(
                              itemCount: portfolioState.items.length,
                              resultCount: results.length,
                              hasQuery: hasQuery,
                            ),
                            const SizedBox(height: 18),
                            if (hasQuery && hasResults) ...[
                              const _SectionTitle('Saved matches'),
                              const SizedBox(height: 10),
                              for (final item in results.take(12)) ...[
                                _PortfolioResultCard(
                                  item: item,
                                  onTap: () => _openItem(context, item),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ] else ...[
                              const _SectionTitle('Search your collection'),
                              const SizedBox(height: 10),
                              _QuickFilterGrid(
                                labels: quickFilters,
                                onSelected: _setQuery,
                              ),
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

  List<CollectibleItem> _searchItems(
    List<CollectibleItem> items,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }
    return items
        .where((item) {
          return [
            item.title,
            item.category,
            item.condition,
            item.brand,
            item.setName,
            item.series,
            item.cardNumber,
            item.playerOrCharacter,
            item.rarity,
            item.edition,
          ].whereType<String>().any((value) {
            return value.toLowerCase().contains(normalized);
          });
        })
        .toList(growable: false);
  }

  List<String> _quickFilters(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return const ['Cards', 'Coins', 'Figures', 'Games'];
    }

    final counts = <String, int>{};
    for (final item in items) {
      final category = item.category.trim();
      if (category.isEmpty) {
        continue;
      }
      counts[category] = (counts[category] ?? 0) + 1;
    }

    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.key.compareTo(b.key);
      });

    return ranked.take(4).map((entry) => entry.key).toList(growable: false);
  }

  void _setQuery(String query) {
    _queryController.text = query;
    _queryController.selection = TextSelection.collapsed(
      offset: _queryController.text.length,
    );
    _onQueryChanged(query);
  }

  void _setScope(_SearchScope scope) {
    if (_scope == scope) {
      return;
    }
    setState(() => _scope = scope);
    if (scope == _SearchScope.catalog) {
      _runCatalogSearch(_queryController.text);
    }
  }

  void _onQueryChanged(String query) {
    setState(() {});
    if (_scope == _SearchScope.catalog) {
      _runCatalogSearch(query);
    }
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
        _catalogError =
            'Catalog search is not connected yet. Collection search still works.';
      });
    }
  }

  Future<void> _openItem(BuildContext context, CollectibleItem item) {
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
        settings: RouteSettings(name: '/search/portfolio/${item.id}'),
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
          'Search saved collectibles by name, category, brand, set, or identifier.',
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

class _SearchScopeControl extends StatelessWidget {
  const _SearchScopeControl({required this.scope, required this.onChanged});

  final _SearchScope scope;
  final ValueChanged<_SearchScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('discover-search-scope-control'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PackLoxTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PackLoxTokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScopeButton(
              label: 'Collection',
              icon: Icons.inventory_2_outlined,
              selected: scope == _SearchScope.collection,
              onTap: () => onChanged(_SearchScope.collection),
            ),
          ),
          Expanded(
            child: _ScopeButton(
              label: 'Catalog',
              icon: Icons.manage_search_outlined,
              selected: scope == _SearchScope.catalog,
              onTap: () => onChanged(_SearchScope.catalog),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
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
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        key: ValueKey('discover-scope-${label.toLowerCase()}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? PackLoxTokens.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? PackLoxTokens.textPrimary
                    : PackLoxTokens.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? PackLoxTokens.textPrimary
                        : PackLoxTokens.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchStatusCard extends StatelessWidget {
  const _SearchStatusCard({
    required this.itemCount,
    required this.resultCount,
    required this.hasQuery,
  });

  final int itemCount;
  final int resultCount;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PackLoxTokens.blue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasQuery
                  ? Icons.manage_search_rounded
                  : Icons.inventory_2_outlined,
              color: PackLoxTokens.cyan,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasQuery
                      ? '$resultCount saved ${resultCount == 1 ? 'match' : 'matches'}'
                      : '$itemCount saved ${itemCount == 1 ? 'item' : 'items'} searchable',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: PackLoxTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasQuery
                      ? 'Results come from your PackLox portfolio.'
                      : 'Scan or save items, then search them here.',
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

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      key: const ValueKey('discover-empty-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PackLoxTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PackLoxTokens.border),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: PackLoxTokens.cyan,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try an item name, category, brand, set, card number, or character.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: PackLoxTokens.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      key: const ValueKey('discover-loading-state'),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: PackLoxTokens.cyan,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Loading saved items...',
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

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      key: const ValueKey('discover-error-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: PackLoxTokens.amber),
          const SizedBox(height: 12),
          Text(
            'Search is unavailable',
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
            key: const ValueKey('discover-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
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

class _QuickFilterGrid extends StatelessWidget {
  const _QuickFilterGrid({required this.labels, required this.onSelected});

  final List<String> labels;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 4 : 2;
        return GridView.builder(
          key: const ValueKey('discover-quick-filter-grid'),
          itemCount: labels.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 4 ? 1.1 : 2.2,
          ),
          itemBuilder: (context, index) {
            final label = labels[index];
            return GestureDetector(
              key: ValueKey('discover-quick-filter-$index'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(label),
              child: _SurfaceCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _quickFilterIcon(label),
                      color: _quickFilterColor(index),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: PackLoxTokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PortfolioResultCard extends StatelessWidget {
  const _PortfolioResultCard({required this.item, required this.onTap});

  final CollectibleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = _formatSearchValue(item);
    return Semantics(
      button: true,
      label: 'Open ${item.title}',
      child: GestureDetector(
        key: ValueKey('discover-result-${item.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _SurfaceCard(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: PackLoxTokens.cyan.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: PackLoxTokens.cyan,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: PackLoxTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} - ${item.condition}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PackLoxTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: PackLoxTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: PackLoxTokens.textSecondary,
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

class _CatalogResultCard extends StatelessWidget {
  const _CatalogResultCard({required this.result});

  final CatalogSearchResult result;

  @override
  Widget build(BuildContext context) {
    final value = _formatCatalogValue(result);
    final subtitle = [
      result.category,
      result.setName,
      result.identifier,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' - ');
    final confidence = result.confidence == null
        ? null
        : '${(result.confidence!.clamp(0, 1) * 100).round()}% match';
    return _SurfaceCard(
      key: ValueKey('discover-catalog-result-${result.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PackLoxTokens.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.dataset_outlined,
              color: PackLoxTokens.amber,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
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
                const SizedBox(height: 4),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _SearchPill(label: result.source),
                    if (confidence != null) _SearchPill(label: confidence),
                    if (result.attribution != null)
                      _SearchPill(label: result.attribution!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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

IconData _quickFilterIcon(String label) {
  final normalized = label.toLowerCase();
  if (normalized.contains('card')) {
    return Icons.style_outlined;
  }
  if (normalized.contains('coin')) {
    return Icons.album_outlined;
  }
  if (normalized.contains('game')) {
    return Icons.sports_esports_outlined;
  }
  if (normalized.contains('figure') || normalized.contains('toy')) {
    return Icons.smart_toy_outlined;
  }
  return Icons.grid_view_outlined;
}

Color _quickFilterColor(int index) {
  return switch (index % 4) {
    0 => PackLoxTokens.cyan,
    1 => PackLoxTokens.amber,
    2 => const Color(0xFF9B7CFF),
    _ => PackLoxTokens.success,
  };
}

String _formatSearchValue(CollectibleItem item) {
  if (item.estimatedValue <= 0) {
    return 'Pending';
  }
  final currency = item.pricing?.currency.trim().toUpperCase() ?? 'AUD';
  final whole = item.estimatedValue.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  if (currency == 'AUD' || currency.isEmpty) {
    return '\$$withCommas AUD';
  }
  if (currency == 'USD') {
    return 'USD \$$withCommas';
  }
  return '$currency $withCommas';
}

String _formatCatalogValue(CatalogSearchResult result) {
  final value = result.marketValue;
  if (value == null || value <= 0) {
    return 'No price';
  }
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
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
