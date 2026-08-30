import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_valuation_snapshot_repository.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  _attributionTests();
  setUp(() {
    // Required for any test whose flow touches SharedPreferences (saving a
    // catalog result now seeds local valuation snapshots). Without a mock
    // store the plugin channel has no handler and getInstance() never
    // completes, hanging the test rather than failing it.
    SharedPreferences.setMockInitialValues({});
  });

  // Discover is Catalog-only (market-price lookup) — searching your own
  // saved items lives in Portfolio, which already has a richer search/sort/
  // filter system, so Discover no longer duplicates it. See
  // search_screen.dart for the rationale.

  testWidgets('quick filters browse their category without typing a query', (
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

    await tester.tap(find.text('Pokémon'));
    await tester.pump();

    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('discover-search-input')),
    );
    // Picking a category browses it -- the search box stays empty and
    // theirs to use. It used to be filled with a representative term
    // because the backend refused to return anything without one, which
    // read as the app typing on the user's behalf.
    expect(input.controller?.text, '');

    // A quick-filter tap is a deliberate action, not a keystroke, so it
    // searches immediately rather than waiting out the typing debounce.
    await tester.pumpAndSettle();
    expect(catalogRepository.queries, ['']);
    // The chip must narrow by category, not just seed the search box. Free
    // text alone cannot represent a category: searching the bare word
    // "Pokemon" against the whole catalog returns Pokemon-collab trainers
    // that outrank the cards (confirmed live), and "LEGO" returns a LEGO
    // video game.
    expect(catalogRepository.lastCategoryGroup, 'trading-card-games');
    expect(catalogRepository.lastSubcategory, 'pokemon');
    expect(find.text('Charizard #4 Base Set'), findsOneWidget);
  });

  testWidgets(
    'every category Home advertises has a Discover chip, and each carries a '
    'real category filter rather than only a search term',
    (tester) async {
      final catalogRepository = _MemoryCatalogSearchRepository([]);
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: catalogRepository,
      );

      for (final label in [
        'Pokémon',
        'Magic',
        'Yu-Gi-Oh!',
        'Lorcana',
        'One Piece',
        'Sports Cards',
        'Comics',
        'Coins',
        'Video Games',
        'LEGO Sets',
        'Funko Pops',
        'Sneakers',
      ]) {
        expect(
          find.text(label),
          findsOneWidget,
          reason: '$label is advertised on Home but missing from Discover',
        );
      }

      // Sneakers live only in kicksdb_catalog, so the request pins source
      // to kicksdb rather than sending a category the PriceCharting
      // taxonomy has no entry for.
      await tester.ensureVisible(find.text('Sneakers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sneakers'));
      await tester.pumpAndSettle();
      expect(catalogRepository.lastSource, 'kicksdb');

    },
  );

  testWidgets(
    'a non-sneaker chip pins the request to pricecharting, so KicksDB rows '
    'cannot mix into a filtered view',
    (tester) async {
      final catalogRepository = _MemoryCatalogSearchRepository([]);
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: catalogRepository,
      );

      await tester.ensureVisible(find.text('LEGO Sets'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LEGO Sets'));
      await tester.pumpAndSettle();

      expect(catalogRepository.lastCategoryGroup, 'lego-sets');
      expect(catalogRepository.lastSource, 'pricecharting');
    },
  );

  testWidgets(
    'filter sheet applies a category, deriving the right source for search',
    (tester) async {
      // The default 800x600 test surface is far smaller than a real phone
      // and leaves no room for the category dropdown's popup menu to
      // render within the viewport -- use a realistic phone size so the
      // popup lays out the way it does on-device.
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final catalogRepository = _MemoryCatalogSearchRepository([
        const CatalogSearchResult(
          id: 'pc-mario',
          title: 'Mario & Luigi RPG',
          category: 'Video Games',
          source: 'PriceCharting',
          setName: 'Nintendo 64',
          currency: 'USD',
          marketValue: 40,
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
        'mario',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      // The debounced query search already ran once with no filters --
      // clear it so the assertion below only reflects the filtered search.
      catalogRepository.queries.clear();

      await tester.tap(find.byKey(const ValueKey('discover-filter-button')));
      await tester.pumpAndSettle();

      // Category = Video Games (near the bottom of the flat top-level
      // list, below the popup's own capped height -- scroll its internal
      // list into view before tapping).
      await tester.tap(
        find.byKey(const ValueKey('catalog-filter-category-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byKey(
          const ValueKey('catalog-filter-category-option-video-games'),
        ),
        find.byType(Scrollable).last,
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('catalog-filter-category-option-video-games'),
        ),
      );
      await tester.pumpAndSettle();

      // Subcategory (labeled "Platform" for Video Games) = Nintendo.
      await tester.tap(
        find.byKey(const ValueKey('catalog-filter-subcategory-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('catalog-filter-subcategory-option-nintendo'),
        ),
      );
      await tester.pumpAndSettle();

      // The Apply button is pinned outside the scrollable body now, so no
      // ensureVisible/scroll is needed to reach it.
      await tester.tap(find.byKey(const ValueKey('catalog-filter-apply')));
      await tester.pumpAndSettle();

      expect(catalogRepository.queries, ['mario']);
      expect(catalogRepository.lastCategoryGroup, 'video-games');
      expect(catalogRepository.lastSubcategory, 'nintendo');
      // There's no user-facing source picker -- picking a real PriceCharting
      // category/platform must still pin the search to that source so
      // KicksDB (sneakers) results don't quietly mix into a filtered view.
      expect(catalogRepository.lastSource, 'pricecharting');
      // The filter button shows "Category · Subcategory" and an active
      // count badge of 2 (category + subcategory -- source is derived, not
      // a separate active filter the user picked).
      expect(find.text('Video Games · Nintendo'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'filter sheet applies a Sports Cards subcategory (sport) to search',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final catalogRepository = _MemoryCatalogSearchRepository([]);
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: catalogRepository,
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'trout',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      catalogRepository.queries.clear();

      await tester.tap(find.byKey(const ValueKey('discover-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('catalog-filter-category-dropdown'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('catalog-filter-category-option-sports-cards'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('catalog-filter-subcategory-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('catalog-filter-subcategory-option-baseball'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-filter-apply')));
      await tester.pumpAndSettle();

      expect(catalogRepository.queries, ['trout']);
      expect(catalogRepository.lastCategoryGroup, 'sports-cards');
      expect(catalogRepository.lastSubcategory, 'baseball');
      expect(find.text('Sports Cards · Baseball'), findsOneWidget);
    },
  );

  testWidgets(
    'filter sheet hides the subcategory dropdown for categories with no drill-down',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final catalogRepository = _MemoryCatalogSearchRepository([]);
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: catalogRepository,
      );

      await tester.tap(find.byKey(const ValueKey('discover-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('catalog-filter-category-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('catalog-filter-category-option-comics')),
      );
      await tester.pumpAndSettle();

      // Comics has no subcategory taxonomy -- the dropdown must not appear
      // at all, not just be empty/disabled.
      expect(
        find.byKey(const ValueKey('catalog-filter-subcategory-dropdown')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'filter sheet Sneakers category pins search to the kicksdb source',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final catalogRepository = _MemoryCatalogSearchRepository([]);
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: catalogRepository,
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'jordan',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      catalogRepository.queries.clear();

      await tester.tap(find.byKey(const ValueKey('discover-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('catalog-filter-category-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byKey(
          const ValueKey('catalog-filter-category-option-sneakers'),
        ),
        find.byType(Scrollable).last,
        const Offset(0, -60),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('catalog-filter-category-option-sneakers'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('catalog-filter-apply')));
      await tester.pumpAndSettle();

      expect(catalogRepository.queries, ['jordan']);
      // Sneakers has no PriceCharting category_group of its own -- it must
      // resolve to categoryGroup: null, source: 'kicksdb'.
      expect(catalogRepository.lastCategoryGroup, isNull);
      expect(catalogRepository.lastSource, 'kicksdb');
      expect(find.text('Sneakers'), findsOneWidget);
    },
  );

  testWidgets(
    'filter sheet reset clears every field back to defaults',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final catalogRepository = _MemoryCatalogSearchRepository([]);
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: catalogRepository,
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'mario',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('discover-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('catalog-filter-category-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('catalog-filter-category-option-sports-cards'),
        ),
      );
      await tester.pumpAndSettle();
      // Reset within the same open sheet session (rather than closing and
      // reopening) -- selecting a category, then resetting, then applying,
      // all in one session, still exercises Reset's actual clearing
      // behavior. Reset/Apply are pinned outside the scrollable body, so
      // no ensureVisible/scroll is needed to reach them.
      await tester.tap(find.byKey(const ValueKey('catalog-filter-reset')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('catalog-filter-apply')));
      await tester.pumpAndSettle();

      expect(catalogRepository.lastCategoryGroup, isNull);
      expect(catalogRepository.lastSource, isNull);
      expect(find.text('Filters'), findsOneWidget);
    },
  );

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
    expect(find.text('Loose / Graded'), findsOneWidget);
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

  testWidgets(
    'saving a catalog result seeds its value-history chart from the '
    'catalog\'s own price history, with no server round-trip',
    (tester) async {
      final repository = _MemoryPortfolioRepository([]);
      await _pumpSearch(
        tester,
        repository: repository,
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
                validFrom: DateTime.utc(2026, 7, 26),
                isCurrent: true,
                currency: 'USD',
                marketValue: 161,
                lowEstimate: 150,
                highEstimate: 800,
              ),
              CatalogPriceHistoryPoint(
                validFrom: DateTime.utc(2026, 7, 19),
                validTo: DateTime.utc(2026, 7, 26),
                currency: 'USD',
                // No price recorded for this version -- must not produce a
                // snapshot.
              ),
              CatalogPriceHistoryPoint(
                validFrom: DateTime.utc(2026, 7, 12),
                validTo: DateTime.utc(2026, 7, 19),
                currency: 'USD',
                marketValue: 150,
              ),
            ],
          ),
        ]),
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'charizard',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('discover-catalog-result-pc-charizard')),
      );
      await tester.pumpAndSettle();
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
      final savedItemId = repository.items.single.id;
      final snapshots =
          await const SharedPreferencesValuationSnapshotRepository()
              .getSnapshots(savedItemId);

      expect(snapshots, hasLength(2));
      expect(snapshots.first.valueAud, 150);
      expect(snapshots.first.pricedAt, DateTime.utc(2026, 7, 12));
      expect(snapshots.last.valueAud, 161);
      expect(snapshots.last.pricedAt, DateTime.utc(2026, 7, 26));
    },
  );

  testWidgets(
    'catalog result detail shows only 5 history entries inline, with a '
    'link to the full history',
    (tester) async {
      // Newest first, matching the real API's own ordering
      // (order: valid_from.desc) -- the panel takes the list as-is, it
      // doesn't re-sort.
      final history = List.generate(
        8,
        (index) => CatalogPriceHistoryPoint(
          validFrom: DateTime(2026, 7, 27 - index),
          isCurrent: index == 0,
          currency: 'USD',
          marketValue: 107 - index.toDouble(),
          sourceFile: 'pokemon.csv',
        ),
      );
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
            marketValue: 107,
            attribution: 'Pricing data by PriceCharting',
            history: history,
          ),
        ]),
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'charizard',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('discover-catalog-result-pc-charizard')),
      );
      await tester.pumpAndSettle();

      // Inline: only the 5 most recent history rows, newest first.
      expect(find.text('Current from 27 Jul 2026'), findsOneWidget);
      expect(find.text('23 Jul 2026 - ended'), findsOneWidget);
      expect(find.text('22 Jul 2026 - ended'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('catalog-view-full-price-history')),
      );
      await tester.pumpAndSettle();
      expect(find.text('View full price history (8)'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('catalog-view-full-price-history')),
      );
      await tester.pumpAndSettle();

      // Full page: every entry is now reachable, no second network call
      // (the memory repository only returns data once, on getCatalogDetail).
      expect(find.text('Charizard #4 Base Set'), findsOneWidget);
      expect(find.text('Current from 27 Jul 2026'), findsOneWidget);
      expect(find.text('22 Jul 2026 - ended'), findsOneWidget);
      expect(find.text('20 Jul 2026 - ended'), findsOneWidget);
    },
  );

  testWidgets(
    'catalog result detail merges consecutive same-price history rows',
    (tester) async {
      // Newest first, matching the real API's own ordering. Four
      // consecutive $190 entries in the middle of the run (a price
      // holding steady across several daily SCD2 snapshots) must
      // collapse into one row spanning their combined date range,
      // instead of four separate rows all showing "$190".
      final history = [
        CatalogPriceHistoryPoint(
          validFrom: DateTime(2026, 8, 17),
          isCurrent: true,
          currency: 'AUD',
          marketValue: 190,
        ),
        CatalogPriceHistoryPoint(
          validFrom: DateTime(2026, 8, 13),
          validTo: DateTime(2026, 8, 17),
          currency: 'AUD',
          marketValue: 179.36,
        ),
        CatalogPriceHistoryPoint(
          validFrom: DateTime(2026, 8, 12),
          validTo: DateTime(2026, 8, 13),
          currency: 'AUD',
          marketValue: 190,
        ),
        CatalogPriceHistoryPoint(
          validFrom: DateTime(2026, 8, 11),
          validTo: DateTime(2026, 8, 12),
          currency: 'AUD',
          marketValue: 190,
        ),
        CatalogPriceHistoryPoint(
          validFrom: DateTime(2026, 8, 10),
          validTo: DateTime(2026, 8, 11),
          currency: 'AUD',
          marketValue: 190,
        ),
        CatalogPriceHistoryPoint(
          validFrom: DateTime(2026, 8, 9),
          validTo: DateTime(2026, 8, 10),
          currency: 'AUD',
          marketValue: 190,
        ),
      ];
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: _MemoryCatalogSearchRepository([
          CatalogSearchResult(
            id: 'pc-merge-history',
            title: 'Nike A\'ja Wilson A\'One #1 Draft Pick',
            category: 'Sneakers',
            source: 'KicksDB',
            currency: 'AUD',
            marketValue: 190,
            attribution: 'Pricing data by KicksDB',
            history: history,
          ),
        ]),
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'merge history',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('discover-catalog-result-pc-merge-history')),
      );
      await tester.pumpAndSettle();

      // The four consecutive $190 rows collapse into one, spanning from
      // the oldest (9 Aug) to the newest of that steady run (13 Aug,
      // where the $179.36 row starts) -- not shown as four separate
      // "X Aug 2026 - Y Aug 2026" rows. All 3 merged rows (current,
      // $179.36, merged $190) fit within the inline 5-row cap, so no
      // "View full price history" link is needed to see this.
      expect(find.text('9 Aug 2026 - 13 Aug 2026'), findsOneWidget);
      expect(find.text('10 Aug 2026 - 11 Aug 2026'), findsNothing);
      expect(find.text('11 Aug 2026 - 12 Aug 2026'), findsNothing);
      expect(find.text('12 Aug 2026 - 13 Aug 2026'), findsNothing);
      expect(find.byKey(const ValueKey('catalog-view-full-price-history')), findsNothing);
    },
  );

  testWidgets('multi-image items show a swipeable gallery with credits', (
    tester,
  ) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: _MemoryCatalogSearchRepository([
        const CatalogSearchResult(
          id: 'kdb-butterfly',
          title: 'Saucony The Butterfly',
          category: 'Sneakers',
          source: 'KicksDB',
          currency: 'USD',
          marketValue: 120,
          imageUrl: 'https://images.stockx.com/images/A.jpg?w=700',
          images: [
            CatalogImage(
              url: 'https://images.stockx.com/images/A.jpg?w=700',
              label: 'View 1',
            ),
            CatalogImage(
              url: 'https://images.stockx.com/images/A-2.jpg?w=700',
              label: 'View 2',
              credit: 'Test Contributor',
            ),
          ],
        ),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'saucony',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('discover-catalog-result-kdb-butterfly')),
    );
    await tester.pumpAndSettle();

    // Gallery replaces the single framed image for multi-image items.
    expect(find.byKey(const ValueKey('catalog-detail-gallery')), findsOneWidget);
    // First page carries no credit; the second one does.
    expect(find.text('Photo: Test Contributor'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('catalog-detail-gallery')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Photo: Test Contributor'), findsOneWidget);
  });

  testWidgets('fullscreen viewer stays swipeable across the whole set', (
    tester,
  ) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: _MemoryCatalogSearchRepository([
        const CatalogSearchResult(
          id: 'kdb-multi',
          title: 'New Balance 574',
          category: 'Sneakers',
          source: 'KicksDB',
          currency: 'USD',
          marketValue: 199,
          imageUrl: 'https://images.stockx.com/images/A.jpg?w=700',
          images: [
            CatalogImage(url: 'https://images.stockx.com/images/A.jpg?w=700'),
            CatalogImage(url: 'https://images.stockx.com/images/A-2.jpg?w=700'),
            CatalogImage(url: 'https://images.stockx.com/images/A-3.jpg?w=700'),
          ],
        ),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'new balance',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('discover-catalog-result-kdb-multi')),
    );
    await tester.pumpAndSettle();

    // Tapping the gallery opens fullscreen with the whole set, not just
    // the tapped image -- so a pager is present rather than one photo.
    await tester.tap(find.byKey(const ValueKey('catalog-detail-gallery')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fullscreen-image-pager')), findsOneWidget);
    expect(find.byKey(const ValueKey('fullscreen-image-close')), findsOneWidget);
  });

  testWidgets('single-image items keep the plain framed image', (tester) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: _MemoryCatalogSearchRepository([
        const CatalogSearchResult(
          id: 'kdb-single',
          title: 'Air Jordan 1',
          category: 'Sneakers',
          source: 'KicksDB',
          currency: 'USD',
          marketValue: 200,
          imageUrl: 'https://images.stockx.com/images/B.jpg?w=700',
        ),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'jordan',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('discover-catalog-result-kdb-single')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('catalog-detail-gallery')), findsNothing);
    expect(
      find.byKey(const ValueKey('catalog-detail-image-tap')),
      findsOneWidget,
    );
  });

  testWidgets('catalog result detail shows real eBay listings when present', (
    tester,
  ) async {
    await _pumpSearch(
      tester,
      repository: _MemoryPortfolioRepository([]),
      catalogRepository: _MemoryCatalogSearchRepository([
        const CatalogSearchResult(
          id: 'pc-god-of-war',
          title: 'God of War',
          category: 'Video Games',
          source: 'PriceCharting',
          setName: 'Playstation 4',
          currency: 'AUD',
          marketValue: 19.74,
          attribution: 'Pricing data by PriceCharting',
          marketplaceListings: [
            MarketplaceListing(
              title: 'God of War PS4 Brand New',
              price: 21.49,
              currency: 'AUD',
              condition: 'New',
              url: 'https://www.ebay.com/itm/12345',
            ),
          ],
        ),
      ]),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-search-input')),
      'god of war',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('discover-catalog-result-pc-god-of-war')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Where to buy'), findsOneWidget);
    expect(find.text('God of War PS4 Brand New'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('\$21.49 AUD'), findsOneWidget);
  });

  testWidgets(
    'RAWG attribution renders with video-game imagery in search and detail',
    (tester) async {
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: _MemoryCatalogSearchRepository([
          const CatalogSearchResult(
            id: 'pc-mario-64',
            title: 'Super Mario 64',
            category: 'Video Games',
            source: 'PriceCharting',
            setName: 'Nintendo 64',
            currency: 'USD',
            marketValue: 45,
            imageUrl: 'https://media.rawg.io/media/games/mario64.jpg',
            attribution: 'Pricing data by PriceCharting',
          ),
        ]),
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'mario 64',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(
        find.text('Video game data and cover art via RAWG.io'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('discover-catalog-result-pc-mario-64')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Video game data and cover art via RAWG.io'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'RAWG attribution is absent for non-video-game results',
    (tester) async {
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: _MemoryCatalogSearchRepository([
          const CatalogSearchResult(
            id: 'pc-charizard',
            title: 'Charizard #4 Base Set',
            category: 'Pokemon Cards',
            source: 'PriceCharting',
            currency: 'USD',
            marketValue: 161,
            attribution: 'Pricing data by PriceCharting',
          ),
        ]),
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'charizard',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(
        find.text('Video game data and cover art via RAWG.io'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'sneaker listings show per-size StockX asks with market depth',
    (tester) async {
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: _MemoryCatalogSearchRepository([
          const CatalogSearchResult(
            id: 'kdb-jordan4',
            title: 'Air Jordan 4 Retro Infrared',
            category: 'Sneakers',
            source: 'KicksDB',
            currency: 'USD',
            marketValue: 180,
            attribution: 'Pricing data by KicksDB',
            marketplaceListings: [
              MarketplaceListing(
                title: 'Size US M 10',
                price: 115,
                currency: 'USD',
                condition: 'New',
                url: 'https://stockx.com/air-jordan-4-infrared',
                source: 'StockX',
                size: 'US M 10',
                totalAsks: 13,
                salesLast30Days: 8,
              ),
              MarketplaceListing(
                title: 'Size US M 10.5',
                price: 131,
                currency: 'USD',
                condition: 'New',
                url: 'https://stockx.com/air-jordan-4-infrared',
                source: 'StockX',
                size: 'US M 10.5',
                totalAsks: 1,
              ),
            ],
          ),
        ]),
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'jordan',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('discover-catalog-result-kdb-jordan4')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Where to buy'), findsOneWidget);
      expect(find.text('Size US M 10'), findsOneWidget);
      // Market depth replaces the constant "New" condition on the row.
      expect(find.text('13 asks · 8 sold in 30 days'), findsOneWidget);
      expect(find.text('Size US M 10.5'), findsOneWidget);
      expect(find.text('1 ask'), findsOneWidget);
      expect(find.text('New'), findsNothing);
      expect(find.text('USD \$115'), findsOneWidget);
    },
  );

  testWidgets(
    'catalog result detail hides the eBay panel when there are no listings',
    (tester) async {
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: _MemoryCatalogSearchRepository([
          const CatalogSearchResult(
            id: 'pc-obscure-game',
            title: 'Obscure Game',
            category: 'Video Games',
            source: 'PriceCharting',
            setName: 'Playstation 4',
            currency: 'AUD',
            marketValue: 5,
            attribution: 'Pricing data by PriceCharting',
          ),
        ]),
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'obscure game',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('discover-catalog-result-pc-obscure-game')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Where to buy'), findsNothing);
    },
  );

  testWidgets(
    'catalog result detail shows only 3 marketplace listings inline, with '
    'a link to view all',
    (tester) async {
      final listings = List.generate(
        5,
        (index) => MarketplaceListing(
          title: 'God of War listing #$index',
          price: 20.0 + index,
          currency: 'AUD',
          condition: index.isEven ? 'New' : 'Used',
          url: 'https://www.ebay.com/itm/$index',
          source: index.isEven ? 'eBay' : 'PriceCharting',
        ),
      );
      await _pumpSearch(
        tester,
        repository: _MemoryPortfolioRepository([]),
        catalogRepository: _MemoryCatalogSearchRepository([
          CatalogSearchResult(
            id: 'pc-god-of-war',
            title: 'God of War',
            category: 'Video Games',
            source: 'PriceCharting',
            setName: 'Playstation 4',
            currency: 'AUD',
            marketValue: 19.74,
            attribution: 'Pricing data by PriceCharting',
            marketplaceListings: listings,
          ),
        ]),
      );

      await tester.enterText(
        find.byKey(const ValueKey('discover-search-input')),
        'god of war',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('discover-catalog-result-pc-god-of-war')),
      );
      await tester.pumpAndSettle();

      // Inline: only the 3 most recent listings.
      expect(find.text('God of War listing #0'), findsOneWidget);
      expect(find.text('God of War listing #1'), findsOneWidget);
      expect(find.text('God of War listing #2'), findsOneWidget);
      expect(find.text('God of War listing #3'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('catalog-view-full-marketplace-listings')),
      );
      await tester.pumpAndSettle();
      expect(find.text('View all listings (5)'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('catalog-view-full-marketplace-listings')),
      );
      await tester.pumpAndSettle();

      // Full page: every listing is now reachable, no second network call
      // (the memory repository only returns data once, on getCatalogDetail).
      expect(find.text('Where to buy'), findsOneWidget);
      expect(find.text('God of War'), findsOneWidget);
      expect(find.text('God of War listing #4'), findsOneWidget);
    },
  );

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
  String? lastCategoryGroup;
  String? lastSubcategory;
  double? lastMinPrice;
  double? lastMaxPrice;
  String? lastSource;

  @override
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
    String? categoryGroup,
    String? subcategory,
    double? minPrice,
    double? maxPrice,
    String? source,
  }) async {
    queries.add(query);
    lastCategoryGroup = categoryGroup;
    lastSubcategory = subcategory;
    lastMinPrice = minPrice;
    lastMaxPrice = maxPrice;
    lastSource = source;
    return results;
  }

  @override
  Future<CatalogSearchResult> getCatalogDetail({
    required CatalogSearchResult result,
    int historyLimit = 90,
    String? currency,
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
    String? categoryGroup,
    String? subcategory,
    double? minPrice,
    double? maxPrice,
    String? source,
  }) async {
    throw StateError('Catalog endpoint missing');
  }

  @override
  Future<CatalogSearchResult> getCatalogDetail({
    required CatalogSearchResult result,
    int historyLimit = 90,
    String? currency,
  }) async {
    throw StateError('Catalog endpoint missing');
  }
}

/// Attribution for a CC BY / CC BY-SA image is a condition of the licence:
/// the author must be named wherever the image is shown. These guard the
/// parsing side of that -- the flag has to survive the wire, because the UI
/// decides whether the credit is optional chrome or a legal obligation
/// purely from it.
void _attributionTests() {
  group('CatalogImage attribution', () {
    test('parses a licence-required attribution from the backend', () {
      final image = CatalogImage.fromJson(const {
        'url': 'https://cdn.example/coins/lincoln-shield-penny-reverse.png',
        'label': 'Reverse',
        'credit': 'MisfitMaid / CC BY-SA 4.0',
        'attributionRequired': true,
        'attributionUrl': 'https://commons.wikimedia.org/wiki/File:X.png',
      });

      expect(image.attributionRequired, isTrue);
      expect(image.credit, 'MisfitMaid / CC BY-SA 4.0');
      expect(image.attributionUrl, 'https://commons.wikimedia.org/wiki/File:X.png');
    });

    test('defaults to not-required when the backend omits the fields', () {
      // Public-domain images are the overwhelming majority and send neither
      // field; they must not be treated as attribution-required.
      final image = CatalogImage.fromJson(const {
        'url': 'https://cdn.example/coins/morgan-dollar-obverse.jpg',
        'credit': 'United States Mint',
      });

      expect(image.attributionRequired, isFalse);
      expect(image.attributionUrl, isNull);
      expect(image.credit, 'United States Mint');
    });

    test('treats a non-boolean attributionRequired as not required', () {
      final image = CatalogImage.fromJson(const {
        'url': 'https://cdn.example/x.jpg',
        'attributionRequired': 'yes',
      });

      expect(image.attributionRequired, isFalse);
    });
  });
}
