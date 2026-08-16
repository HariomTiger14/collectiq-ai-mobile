import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/search/data/repositories/api_catalog_search_repository.dart';
import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';
import 'package:collectiq_ai/features/search/domain/repositories/catalog_search_repository.dart';
import 'package:collectiq_ai/features/search/presentation/search_screen.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Discover is Catalog-only (market-price lookup) — searching your own
  // saved items lives in Portfolio, which already has a richer search/sort/
  // filter system, so Discover no longer duplicates it. See
  // search_screen.dart for the rationale.

  testWidgets('quick filters fill the query and trigger a catalog search', (
    tester,
  ) async {
    final catalogRepository = _MemoryCatalogSearchRepository([
      const CatalogSearchResult(
        id: 'pc-charizard',
        title: 'Charizard #4 Base Set',
        category: 'Pokemon Cards',
        source: 'PriceCharting',
        setName: 'Base Set',
        identifier: '4/102',
        currency: 'USD',
        marketValue: 161,
        confidence: 0.91,
        attribution: 'Pricing data by PriceCharting',
      ),
    ]);
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: catalogRepository,
    );

    await tester.tap(find.text('Pokemon Cards'));
    await tester.pump();

    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('discover-search-input')),
    );
    expect(input.controller?.text, 'Pokemon Cards');

    // A quick-filter tap is a deliberate action, not a keystroke, so it
    // searches immediately rather than waiting out the typing debounce.
    await tester.pumpAndSettle();
    expect(catalogRepository.queries, ['Pokemon Cards']);
    expect(find.text('Charizard #4 Base Set'), findsOneWidget);
  });

  testWidgets('catalog search shows backend catalog results', (tester) async {
    final catalogRepository = _MemoryCatalogSearchRepository([
      const CatalogSearchResult(
        id: 'pc-charizard',
        title: 'Charizard #4 Base Set',
        category: 'Pokemon Cards',
        source: 'PriceCharting',
        setName: 'Base Set',
        identifier: '4/102',
        currency: 'USD',
        marketValue: 161,
        confidence: 0.91,
        attribution: 'Pricing data by PriceCharting',
      ),
    ]);
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: catalogRepository,
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'charizard',
    );
    // Catalog search is debounced; advance past the debounce window before
    // settling the resulting async search.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(catalogRepository.queries, ['charizard']);
    expect(find.text('Charizard #4 Base Set'), findsOneWidget);
    expect(find.text('USD \$161'), findsOneWidget);
    expect(find.text('91% match'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('discover-catalog-placeholder-pc-charizard')),
      findsOneWidget,
    );
  });

  testWidgets('catalog result with a real image renders it instead of the placeholder', (
    tester,
  ) async {
    final catalogRepository = _MemoryCatalogSearchRepository([
      const CatalogSearchResult(
        id: 'kdb-air-jordan-1',
        title: 'Air Jordan 1 Retro High OG',
        category: 'Sneakers',
        source: 'KicksDB',
        setName: 'Jordan',
        currency: 'USD',
        marketValue: 310,
        attribution: 'Pricing data by KicksDB',
        imageUrl: 'https://images.kicks.dev/air-jordan-1.png',
      ),
    ]);
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: catalogRepository,
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'air jordan',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Air Jordan 1 Retro High OG'), findsOneWidget);
    final image = tester.widget<Image>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey('discover-catalog-placeholder-kdb-air-jordan-1'),
            ),
            matching: find.byType(Image),
          )
          .first,
    );
    expect(image.image, isA<NetworkImage>());
    expect(
      (image.image as NetworkImage).url,
      'https://images.kicks.dev/air-jordan-1.png',
    );
  });

  testWidgets('catalog result detail saves a portfolio snapshot', (
    tester,
  ) async {
    final repository = _MemoryPortfolioRepository([]);
    await _pumpSearch(
      tester,
      repository: repository,
      catalogRepository: _MemoryCatalogSearchRepository([
        CatalogSearchResult(
          id: 'pc-mario-kart',
          title: 'Mario Kart 64',
          category: 'Video Games',
          source: 'PriceCharting',
          setName: 'Nintendo 64',
          currency: 'USD',
          marketValue: 82,
          lowEstimate: 70,
          highEstimate: 96,
          confidence: 0.87,
          lastUpdated: DateTime(2026, 7, 25),
          attribution: 'Pricing data by PriceCharting',
        ),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'mario kart',
    );
    // Catalog search is debounced; advance past the debounce window before
    // settling the resulting async search.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('discover-catalog-result-pc-mario-kart')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('catalog-result-detail-screen')),
      findsOneWidget,
    );
    expect(find.text('Current value'), findsOneWidget);
    expect(find.text('USD \$82'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Pricing evidence'), findsOneWidget);
    expect(find.text('Trusted provider value'), findsOneWidget);
    expect(find.text('Currency'), findsWidgets);
    expect(find.text('High (87%)'), findsOneWidget);
    expect(find.text('Matched by title, set/product family'), findsOneWidget);
    expect(find.text('USD \$70 - USD \$96'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('catalog-detail-add-to-portfolio')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('catalog-detail-add-to-portfolio')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(repository.items, hasLength(1));
    expect(repository.items.single.title, 'Mario Kart 64');
    expect(repository.items.single.pricing?.pricingSource, 'PriceCharting');
    expect(
      repository.items.single.valuationStatus,
      ValuationStatus.marketEstimated,
    );
    expect(find.byType(CollectibleDetailPage), findsOneWidget);
  });

  testWidgets('catalog result detail shows backend price history', (
    tester,
  ) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: _MemoryCatalogSearchRepository([
        CatalogSearchResult(
          id: 'pc-charizard',
          title: 'Charizard #4 Base Set',
          category: 'Pokemon Cards',
          source: 'PriceCharting',
          setName: 'Base Set',
          currency: 'USD',
          marketValue: 161,
          confidence: 0.91,
          lastUpdated: DateTime(2026, 7, 26),
          attribution: 'Pricing data by PriceCharting',
          history: [
            CatalogPriceHistoryPoint(
              validFrom: DateTime(2026, 7, 26),
              isCurrent: true,
              currency: 'USD',
              marketValue: 161,
              lowEstimate: 150,
              highEstimate: 800,
              sourceFile: 'pokemon.csv',
            ),
            CatalogPriceHistoryPoint(
              validFrom: DateTime(2026, 7, 25),
              validTo: DateTime(2026, 7, 26),
              currency: 'USD',
              marketValue: 150,
              sourceFile: 'pokemon.csv',
            ),
          ],
        ),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'charizard',
    );
    // Catalog search is debounced; advance past the debounce window before
    // settling the resulting async search.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('discover-catalog-result-pc-charizard')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Price history'), findsOneWidget);
    expect(find.text('Current from 26 Jul 2026'), findsOneWidget);
    expect(find.text('25 Jul 2026 - 26 Jul 2026'), findsOneWidget);
    expect(find.text('USD \$161'), findsWidgets);
    expect(find.text('pokemon'), findsWidgets);
  });

  testWidgets('catalog search has a clear unavailable state', (tester) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: _FailingCatalogSearchRepository(),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'nintendo',
    );
    // Catalog search is debounced; advance past the debounce window before
    // settling the resulting async search.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('discover-catalog-error-state')),
      findsOneWidget,
    );
    expect(find.text('Catalog search unavailable'), findsOneWidget);
  });
}

Future<void> _pumpSearch(
  WidgetTester tester, {
  required PortfolioRepository repository,
  CatalogSearchRepository? catalogRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
        if (catalogRepository != null)
          catalogSearchRepositoryProvider.overrideWithValue(catalogRepository),
      ],
      child: const MaterialApp(home: SearchScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _MemoryPortfolioRepository implements PortfolioRepository {
  _MemoryPortfolioRepository(this.items);

  final List<CollectibleItem> items;

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async {
    items.add(item);
    return item;
  }

  @override
  Future<void> clearPortfolio() async {
    items.clear();
  }

  @override
  Future<List<CollectibleItem>> getItems() async {
    return items;
  }

  @override
  Future<void> removeItem(String id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> updateItem(CollectibleItem item) async {
    final index = items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      items[index] = item;
    }
  }

  @override
  Future<void> updateItemImageSync({
    required String itemId,
    required String imageStoragePath,
    required String cloudImageUrl,
  }) async {}

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {
    await updateItem(item);
  }
}

class _MemoryCatalogSearchRepository implements CatalogSearchRepository {
  _MemoryCatalogSearchRepository(this.results);

  final List<CatalogSearchResult> results;
  final List<String> queries = [];

  @override
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
  }) async {
    queries.add(query);
    return results;
  }

  @override
  Future<CatalogSearchResult> getCatalogDetail({
    required CatalogSearchResult result,
    int historyLimit = 30,
  }) async {
    return results.firstWhere(
      (candidate) => candidate.id == result.id,
      orElse: () => result,
    );
  }
}

class _FailingCatalogSearchRepository implements CatalogSearchRepository {
  @override
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
  }) async {
    throw StateError('Catalog endpoint missing');
  }

  @override
  Future<CatalogSearchResult> getCatalogDetail({
    required CatalogSearchResult result,
    int historyLimit = 30,
  }) async {
    throw StateError('Catalog endpoint missing');
  }
}
