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
  testWidgets('searches saved portfolio items by title and metadata', (
    tester,
  ) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([
        _item(
          id: 'hot-wheels',
          title: 'Hot Wheels Mazda MX-5',
          category: 'Toy Cars',
          brand: 'Mattel',
        ),
        _item(
          id: 'charizard',
          title: 'Charizard Base Set',
          category: 'Pokemon Cards',
          setName: 'Base Set',
          cardNumber: '4/102',
        ),
      ]),
    );

    expect(find.text('2 saved items searchable'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      '4/102',
    );
    await tester.pump();

    expect(find.text('1 saved match'), findsOneWidget);
    expect(find.text('Charizard Base Set'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('discover-portfolio-image-charizard')),
      findsOneWidget,
    );
    expect(find.text('Hot Wheels Mazda MX-5'), findsNothing);
  });

  testWidgets('quick filters fill the query from saved categories', (
    tester,
  ) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([
        _item(
          id: 'hot-wheels',
          title: 'Hot Wheels Mazda MX-5',
          category: 'Toy Cars',
        ),
      ]),
    );

    await tester.tap(find.text('Toy Cars'));
    await tester.pump();

    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('discover-search-input')),
    );
    expect(input.controller?.text, 'Toy Cars');
    expect(find.text('Hot Wheels Mazda MX-5'), findsOneWidget);
  });

  testWidgets('result cards open the saved item detail screen', (tester) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([
        _item(
          id: 'hot-wheels',
          title: 'Hot Wheels Mazda MX-5',
          category: 'Toy Cars',
        ),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'mazda',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('discover-result-hot-wheels')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CollectibleDetailPage), findsOneWidget);
  });

  testWidgets('portfolio load failure shows retryable search error state', (
    tester,
  ) async {
    final repository = _FailingOncePortfolioRepository([
      _item(id: 'coin', title: 'Silver Eagle', category: 'Coins'),
    ]);
    await _pumpSearch(tester, repository: repository);

    expect(find.byKey(const ValueKey('discover-error-state')), findsOneWidget);
    expect(find.text('Search is unavailable'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('discover-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('discover-error-state')), findsNothing);
    expect(find.text('1 saved item searchable'), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('discover-scope-catalog')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'charizard',
    );
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

    await tester.tap(find.byKey(const ValueKey('discover-scope-catalog')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'mario kart',
    );
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
    expect(find.text('Pricing confidence'), findsOneWidget);
    expect(find.text('Provider-backed catalog value'), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('discover-scope-catalog')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'charizard',
    );
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

    await tester.tap(find.byKey(const ValueKey('discover-scope-catalog')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'nintendo',
    );
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

CollectibleItem _item({
  required String id,
  required String title,
  required String category,
  String? brand,
  String? setName,
  String? cardNumber,
}) {
  return CollectibleItem(
    id: id,
    title: title,
    category: category,
    estimatedValue: id == 'hot-wheels' ? 18 : 0,
    confidence: 0.88,
    condition: 'Good',
    recommendation: 'Saved test item.',
    imagePath: '',
    createdAt: DateTime(2026, 7, 26, 12),
    brand: brand,
    setName: setName,
    cardNumber: cardNumber,
  );
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

class _FailingOncePortfolioRepository extends _MemoryPortfolioRepository {
  _FailingOncePortfolioRepository(super.items);

  var _hasFailed = false;

  @override
  Future<List<CollectibleItem>> getItems() async {
    if (!_hasFailed) {
      _hasFailed = true;
      throw StateError('Search test failure');
    }
    return super.getItems();
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
