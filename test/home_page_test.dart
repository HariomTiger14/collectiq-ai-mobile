import 'dart:async';
import 'dart:convert';

import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:collectiq_ai/core/currency/fx_rates_provider.dart';
import 'package:collectiq_ai/core/currency/fx_rates_repository.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/home_dashboard_providers.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _seedPortfolio(_portfolioItems());
  });

  testWidgets(
    'switching display currency converts the portfolio value hero, not just its label',
    (tester) async {
      // A single USD-priced item. With the reported bug, switching the
      // Settings currency to AUD would only relabel the same raw number
      // ("US$150" -> "$150") instead of actually converting it.
      SharedPreferences.setMockInitialValues({
        'portfolio_items': jsonEncode([
          {
            ..._item(
              id: 'usd-item',
              title: 'Imported Booster Box',
              category: 'Trading Card',
              value: 150,
              createdAt: DateTime.now(),
            ),
            'pricing': {
              'estimatedMarketValue': 150,
              'lowEstimate': 150,
              'highEstimate': 150,
              'currency': 'USD',
              'pricingSource': 'test',
              'pricingConfidence': 0.9,
              'valuationStatus': 'market_estimated',
            },
          },
        ]),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeLastAutoSyncProvider.overrideWith(
              _AlreadyAutoSyncedController.new,
            ),
            fxRatesRepositoryProvider.overrideWithValue(
              // 1 USD = 1.5 AUD -> 150 USD should display as $225, not $150.
              const _FixedRateFxRatesRepository({'USD': 1.0, 'AUD': 1.5}),
            ),
            displayCurrencyProvider.overrideWithValue('AUD'),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));

      // Shows up twice: the portfolio value hero and the recent-item card's
      // own value label -- both correctly converted, not just the hero.
      expect(find.text('\$225'), findsNWidgets(2));
      expect(find.text('\$150'), findsNothing);
      expect(find.text('US\$150'), findsNothing);
    },
  );

  testWidgets(
    'MAX period shows true price return, not collection growth from '
    'adding items (real bug found live: an account with one \$15 item and '
    'items added months later showed a many-thousand-percent "MAX" gain)',
    (tester) async {
      // A local history snapshot from two months ago, when the portfolio
      // held only the tiny old item -- this is exactly the shape of data
      // that produced the real bug: the chart's own first point is a tiny
      // early total, so comparing it to today's much larger total (after
      // adding a real item) reported collection growth as a price gain.
      final oldSnapshotDate = DateTime.now().subtract(const Duration(days: 60));
      SharedPreferences.setMockInitialValues({
        'portfolio_items': jsonEncode([
          {
            ..._item(
              id: 'old-item',
              title: 'Early Pikachu',
              category: 'Trading Card',
              value: 20,
              createdAt: oldSnapshotDate,
            ),
            'valueAtScan': 15,
          },
          {
            ..._item(
              id: 'new-item',
              title: 'Black Lotus',
              category: 'Trading Card',
              value: 6000,
              createdAt: DateTime.now(),
            ),
            'valueAtScan': 6000,
          },
        ]),
        'portfolio_value_history_snapshots': jsonEncode([
          {
            'id': 'daily-old',
            'period': 'daily',
            'periodStart': oldSnapshotDate.toIso8601String(),
            'capturedAt': oldSnapshotDate.toIso8601String(),
            'totalPortfolioValue': 15,
            'totalItems': 1,
            'averageValue': 15,
            'categoryTotals': <String, double>{},
            'collectionScore': 0,
            'itemValues': {'old-item': 15},
            'itemTitles': {'old-item': 'Early Pikachu'},
            'itemCategories': {'old-item': 'Trading Card'},
          },
        ]),
      });

      await tester.pumpWidget(_homeApp());
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 120));

      await tester.tap(find.byKey(const ValueKey('home-period-MAX')));
      await tester.pump(const Duration(milliseconds: 120));

      // The old bug would show roughly ($6020-$15)/$15 =~ 39,900%. The
      // correct real gain here is $5 on $6,015 -- under 1%.
      expect(find.textContaining('39,900'), findsNothing);
      expect(find.textContaining('%'), findsWidgets);
      final percentFinder = find.textContaining(RegExp(r'^\d[\d,.]*%\z'));
      final percentTexts = tester
          .widgetList<Text>(percentFinder)
          .map((widget) => widget.data ?? '')
          .toList();
      for (final text in percentTexts) {
        final value = double.tryParse(text.replaceAll('%', ''));
        if (value != null) {
          expect(
            value,
            lessThan(100),
            reason: 'MAX period percent "$text" looks like the old bug (collection growth counted as price gain), not a real return',
          );
        }
      }
    },
  );

  testWidgets(
    'MAX chart colors segments relative to its own first plotted point, not '
    'the true-overall price basis (real bug: wiring the true-overall '
    'baseline into the chart painted almost the entire line red -- "below '
    'baseline" -- even on a real net gain, because that baseline sits above '
    'most of the actual plotted history)',
    (tester) async {
      final oldSnapshotDate = DateTime.now().subtract(const Duration(days: 60));
      SharedPreferences.setMockInitialValues({
        'portfolio_items': jsonEncode([
          {
            ..._item(
              id: 'old-item',
              title: 'Early Pikachu',
              category: 'Trading Card',
              value: 20,
              createdAt: oldSnapshotDate,
            ),
            'valueAtScan': 15,
          },
          {
            ..._item(
              id: 'new-item',
              title: 'Black Lotus',
              category: 'Trading Card',
              value: 6000,
              createdAt: DateTime.now(),
            ),
            'valueAtScan': 6000,
          },
        ]),
        'portfolio_value_history_snapshots': jsonEncode([
          {
            'id': 'daily-old',
            'period': 'daily',
            'periodStart': oldSnapshotDate.toIso8601String(),
            'capturedAt': oldSnapshotDate.toIso8601String(),
            'totalPortfolioValue': 15,
            'totalItems': 1,
            'averageValue': 15,
            'categoryTotals': <String, double>{},
            'collectionScore': 0,
            'itemValues': {'old-item': 15},
            'itemTitles': {'old-item': 'Early Pikachu'},
            'itemCategories': {'old-item': 'Trading Card'},
          },
        ]),
      });

      await tester.pumpWidget(_homeApp());
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 120));

      await tester.tap(find.byKey(const ValueKey('home-period-MAX')));
      await tester.pump(const Duration(milliseconds: 120));

      final chartFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_GainLossChart',
      );
      expect(chartFinder, findsOneWidget);
      final chartWidget = tester.widget(chartFinder) as dynamic;
      final chartValues = (chartWidget.values as List).cast<double>();
      final chartBaseline = chartWidget.baseline as double;

      // The chart's own reference must be its own first point (15) --
      // never the true-overall baseline (6015) the headline number above
      // it uses. Old buggy behavior wired the same value into both, which
      // classified nearly every historical point as "below baseline".
      expect(chartBaseline, chartValues.first);
      expect(chartBaseline, isNot(6015));
    },
  );

  testWidgets('default state follows frozen v0.3 with real portfolio data', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('home-brand-emblem')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-brand-wordmark')), findsOneWidget);
    expect(find.text('Pack  Lox'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(
      find.text('Here\'s how your collection is tracking.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-portfolio-value-hero')),
      findsOneWidget,
    );
    expect(find.text('Portfolio value'), findsOneWidget);
    expect(find.text('\$2,275'), findsOneWidget);
    expect(find.text('3 of 5 items trusted'), findsOneWidget);
    // The "needs value" count is no longer duplicated as a chip in the card;
    // the attention strip below is the single actionable surface for it.
    expect(find.text('2 need value'), findsNothing);
    expect(find.text('Review portfolio'), findsOneWidget);
    // No persisted value history yet, so the trend chart + period tabs are not
    // shown and the card reports the building-history state.
    expect(find.text('Building value history'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-value-hero-trend')), findsNothing);

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-section-recent-items-preview')),
    );
    expect(find.text('Recent items'), findsOneWidget);
    expect(find.text('Premium Charizard'), findsWidgets);

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-section-collection-health')),
    );
    expect(find.text('Collection health'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-health-ring')), findsOneWidget);
    expect(find.text('Cards'), findsWidgets);

    // Supported categories is demoted to the bottom reference zone.
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-section-category-explorer')),
    );
    expect(find.text('Supported categories'), findsOneWidget);
    // Assert the labels unique to the grid (the rest also appear in the
    // collection-health mix above, which is still built at this scroll).
    expect(find.text('Pokémon'), findsOneWidget);
    expect(find.text('MTG'), findsOneWidget);
    expect(find.text('Yu-Gi-Oh'), findsOneWidget);
    expect(find.text('One Piece'), findsOneWidget);
    expect(find.text('Funko'), findsOneWidget);
    expect(find.text('Sports'), findsOneWidget);
    expect(find.text('Watches'), findsNothing);
    expect(find.text('Toys'), findsNothing);
    expect(find.text('Memorabilia'), findsNothing);

    // Recent scan was removed (it duplicated the top of Recent items).
    expect(
      find.byKey(const ValueKey('home-action-recent-scan')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('home-action-market-insights')),
      findsNothing,
    );
  });

  testWidgets(
    'empty state has no fake metrics and primary scan callback works',
    (tester) async {
      _seedPortfolio(const []);
      var scanTaps = 0;

      await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        find.text('Start your collection with a clear first scan.'),
        findsOneWidget,
      );
      expect(find.text('Your collection is waiting'), findsOneWidget);
      expect(find.text('Add first item'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-action-start-first-item')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('home-action-guided-scan')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('home-primary-scan')));
      await tester.pump();

      expect(scanTaps, 1);
      expect(
        find.byKey(const ValueKey('home-floating-scan-button')),
        findsOneWidget,
      );

      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-section-category-explorer')),
      );
      expect(
        find.byKey(const ValueKey('home-section-category-explorer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-popular-category-pokémon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-action-trusted-valuation-chevron')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('home-action-supported-categories-chevron')),
        findsNothing,
      );
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-section-recent-items-preview')),
      );
      expect(find.text('No items yet'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('home-action-recent-items-empty')),
      );
      await tester.pump();
      expect(scanTaps, 2);
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-section-insights-preview')),
      );
      expect(find.text('Collection value'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('\$0'), findsNothing);
      expect(
        find.byKey(const ValueKey('home-action-trusted-valuation-chevron')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('home-action-supported-categories-chevron')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('home-action-recent-items-empty-chevron')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-action-trusted-valuation-chevron')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('home-action-supported-categories-chevron')),
        findsNothing,
      );
      expect(find.text('REPRESENTATIVE DESIGN DATA'), findsNothing);
      expect(find.text('READY FOR REVIEW / NOT FROZEN'), findsNothing);
      expect(find.text('HOME FLOW AUTHORITY'), findsNothing);
      expect(find.byKey(const ValueKey('bottom-navigation')), findsNothing);
    },
  );

  testWidgets(
    'partial valuation state preserves real data and shows state alert',
    (tester) async {
      _seedPortfolio([
        _item(
          id: 'valued',
          title: 'Valued Card',
          category: 'Trading Card',
          value: 50,
        ),
        _item(
          id: 'missing',
          title: 'Unvalued Coin',
          category: 'Coin',
          value: 0,
        ),
      ]);

      await tester.pumpWidget(_homeApp());
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byKey(const ValueKey('home-alert-button')), findsOneWidget);
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-surface-attention-strip')),
      );
      expect(
        find.byKey(const ValueKey('home-surface-attention-strip')),
        findsOneWidget,
      );
      expect(find.text('1 item needs a valuation'), findsOneWidget);
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-section-collection-health')),
      );
      expect(find.text('Collection health'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-health-ring')), findsOneWidget);
      expect(find.text('Value unavailable'), findsNothing);
    },
  );

  testWidgets('unvalued collection does not fabricate a zero value metric', (
    tester,
  ) async {
    _seedPortfolio([
      _item(
        id: 'not-valued',
        title: 'Mystery Promo',
        category: 'Trading Card',
        value: 0,
      ),
    ]);

    await tester.pumpWidget(_homeApp());
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('home-alert-button')), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-section-collection-health')),
    );
    expect(find.text('Collection health'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-health-ring')), findsOneWidget);
    expect(find.text('\$0'), findsNothing);
  });

  testWidgets('loading state renders v0.3 skeletons without sample values', (
    tester,
  ) async {
    final pending = Completer<List<CollectibleItem>>();

    await tester.pumpWidget(
      _homeApp(repository: _PendingPortfolioRepository(pending.future)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('home-loading-skeleton')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-loading-skeleton-hero-title-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-loading-skeleton-cta')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-loading-skeleton-metric-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-loading-skeleton-action-row')),
      findsOneWidget,
    );
    expect(find.text('Preparing your collection overview.'), findsOneWidget);
    expect(find.text('Collection value'), findsNothing);
    expect(find.text('\$18.4K'), findsNothing);
    expect(find.text('42'), findsNothing);

    pending.complete(const []);
  });

  testWidgets('error state uses existing retry callback', (tester) async {
    final repository = _FailingThenSuccessfulPortfolioRepository();

    await tester.pumpWidget(_homeApp(repository: repository));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('home-error-panel')), findsOneWidget);
    expect(
      find.text('We could not refresh your collection overview.'),
      findsOneWidget,
    );
    expect(find.text('Collection could not load'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    final retryButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('home-retry')),
    );
    expect(retryButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('home-retry')));
    await tester.pump(const Duration(milliseconds: 120));

    expect(repository.calls, 2);
    expect(find.text('Your collection is waiting'), findsOneWidget);
  });

  testWidgets('recent item card opens the existing collectible detail route', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pump(const Duration(milliseconds: 120));

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-section-recent-items-preview')),
    );
    await tester.tap(find.text('Premium Charizard').first);
    await tester.pumpAndSettle();

    expect(find.byType(CollectibleDetailPage), findsOneWidget);
  });

  testWidgets('rapid Scan taps trigger one navigation request', (tester) async {
    _seedPortfolio(const []);
    var scanTaps = 0;

    await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
    await tester.pump(const Duration(milliseconds: 120));

    final scan = find.byKey(const ValueKey('home-primary-scan'));
    await tester.tap(scan);
    await tester.tap(scan);
    await tester.pump();

    expect(scanTaps, 1);
  });

  testWidgets('Home page itself does not duplicate AppShell bottom nav', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('home-brand-wordmark')), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-navigation')), findsNothing);
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);
  });

  testWidgets('brand emblem uses approved PackLox asset', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pump(const Duration(milliseconds: 120));

    final emblem = tester.widget<Image>(
      find.byKey(const ValueKey('home-brand-emblem')),
    );
    expect((emblem.image as AssetImage).assetName, PackLoxAssets.brandV2Emblem);
    expect(PackLoxAssets.brandV2Emblem, isNot(PackLoxAssets.emblem));
  });

  testWidgets('Home State Preview lists states without a visible dropdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeStatePreviewScreen())),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Home State Preview'), findsOneWidget);
    expect(find.text('Empty/new collector'), findsOneWidget);
    expect(find.text('Default/signed-in'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-preview-scenario-picker')),
      findsNothing,
    );
    expect(
      find.byType(DropdownButtonFormField<HomePreviewScenario>),
      findsNothing,
    );

    await _revealInScrollable(tester, 'Clear preview / return to real data');
    expect(find.text('Clear preview / return to real data'), findsOneWidget);
  });

  testWidgets('Home preview scenarios render every mocked state', (
    tester,
  ) async {
    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.defaultData));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      find.byKey(const ValueKey('home-preview-scenario-picker')),
      findsNothing,
    );
    // The bell is a persistent inbox entry point whenever a collection exists
    // (checked at the top before scrolling it out of the lazy list).
    expect(find.byKey(const ValueKey('home-alert-button')), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-section-collection-health')),
    );
    expect(find.text('Collection health'), findsOneWidget);

    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.loading));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('home-loading-skeleton')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-loading-skeleton-cta')),
      findsOneWidget,
    );
    expect(find.text('\$18.4K'), findsNothing);

    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.error));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('home-error-panel')), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    final previewRetryButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('home-retry')),
    );
    expect(previewRetryButton.onPressed, isNotNull);

    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.partial));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('home-alert-button')), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-surface-attention-strip')),
    );
    expect(
      find.byKey(const ValueKey('home-surface-attention-strip')),
      findsOneWidget,
    );

    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.guest));
    await tester.pump(const Duration(milliseconds: 120));
    await _scrollUntilVisible(
      tester,
      find.text('Your collection is waiting'),
    );
    expect(find.text('Your collection is waiting'), findsOneWidget);
  });

  testWidgets('alert bell opens the notification inbox', (tester) async {
    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.partial));
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.byKey(const ValueKey('notification-inbox-screen')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('home-alert-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notification-inbox-screen')),
      findsOneWidget,
    );
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('home is pull-to-refresh enabled', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}

Widget _homeApp({
  VoidCallback? onScanPressed,
  VoidCallback? onPortfolioPressed,
  PortfolioRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      if (repository != null)
        portfolioRepositoryProvider.overrideWithValue(repository),
      // Mark Home as recently auto-synced so the throttled on-appear background
      // sync stays out of these deterministic tests.
      homeLastAutoSyncProvider.overrideWith(_AlreadyAutoSyncedController.new),
      // Keeps FX-rate fetching out of these tests entirely (no real network
      // call, no pending Dio timer left behind when the widget tree is torn
      // down).
      fxRatesRepositoryProvider.overrideWithValue(const _FakeFxRatesRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: HomePage(
        onScanPressed: onScanPressed,
        onPortfolioPressed: onPortfolioPressed,
      ),
    ),
  );
}

class _AlreadyAutoSyncedController extends HomeLastAutoSyncController {
  @override
  DateTime? build() => DateTime.now();
}

class _FakeFxRatesRepository implements FxRatesRepository {
  const _FakeFxRatesRepository();

  @override
  Future<FxRateSnapshot> fetchRates({DateTime? fromDate, DateTime? toDate}) async {
    return FxRateSnapshot.empty;
  }
}

class _FixedRateFxRatesRepository implements FxRatesRepository {
  const _FixedRateFxRatesRepository(this.rates);

  final Map<String, double> rates;

  @override
  Future<FxRateSnapshot> fetchRates({DateTime? fromDate, DateTime? toDate}) async {
    return FxRateSnapshot(currentRates: rates, history: const []);
  }
}

Widget _previewHomeApp(HomePreviewScenario scenario) {
  // ProviderScope so routes pushed from Home (e.g. the notification inbox,
  // which always reads providers) resolve a container. HomePage itself
  // short-circuits ref access in preview mode.
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Key per scenario so swapping scenarios recreates the HomePage state
      // (fresh scroll controller at offset 0) rather than reusing the previous
      // scenario's scroll position.
      home: HomePage(
        key: ValueKey(scenario),
        previewScenario: scenario,
        onScanPressed: () {},
        onPortfolioPressed: () {},
      ),
    ),
  );
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 8 && finder.evaluate().isEmpty; i++) {
    await tester.drag(
      find.byKey(const PageStorageKey<String>('home-scroll-position')),
      const Offset(0, -260),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
  }
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _revealInScrollable(WidgetTester tester, String text) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 8; attempt += 1) {
    if (find.text(text).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.text(text).first);
      await tester.pump();
      return;
    }
    await tester.drag(scrollable, const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void _seedPortfolio(List<Map<String, Object?>> items) {
  SharedPreferences.setMockInitialValues({
    'portfolio_items': jsonEncode(items),
  });
}

List<Map<String, Object?>> _portfolioItems() {
  final now = DateTime.now();
  return [
    _item(
      id: 'home-test-card',
      title: 'Premium Charizard',
      category: 'Trading Card',
      value: 1850,
      condition: 'Near Mint',
      createdAt: now,
    ),
    _item(
      id: 'home-test-coin',
      title: 'Silver Eagle',
      category: 'Coin',
      value: 300,
      condition: 'Mint',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    _item(
      id: 'home-test-comic',
      title: 'Signed Variant Comic',
      category: 'Comic',
      value: 125,
      condition: 'Very Fine',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    _item(
      id: 'home-test-card-two',
      title: 'Limited Promo Pikachu',
      category: 'Trading Card',
      value: 0,
      condition: 'Excellent',
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    _item(
      id: 'home-test-card-three',
      title: 'Vintage Holographic Trainer',
      category: 'Trading Card',
      value: 0,
      condition: 'Good',
      createdAt: now.subtract(const Duration(days: 4)),
    ),
  ];
}

Map<String, Object?> _item({
  required String id,
  required String title,
  required String category,
  required double value,
  String condition = 'Near Mint',
  String? valuationStatus,
  DateTime? createdAt,
}) {
  return {
    'id': id,
    'title': title,
    'category': category,
    'estimatedValue': value,
    'confidence': 0.90,
    'condition': condition,
    'recommendation': 'Keep tracking.',
    'imagePath': 'sample://$id',
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    'valuationStatus':
        valuationStatus ?? (value > 0 ? 'market_estimated' : 'unavailable'),
  };
}

class _PendingPortfolioRepository implements PortfolioRepository {
  const _PendingPortfolioRepository(this.itemsFuture);

  final Future<List<CollectibleItem>> itemsFuture;

  @override
  Future<List<CollectibleItem>> getItems() => itemsFuture;

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async => item;

  @override
  Future<void> clearPortfolio() async {}

  @override
  Future<void> removeItem(String id) async {}

  @override
  Future<void> updateItem(CollectibleItem item) async {}

  @override
  Future<void> updateItemImageSync({
    required String itemId,
    required String imageStoragePath,
    required String cloudImageUrl,
  }) async {}

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {}
}

class _FailingThenSuccessfulPortfolioRepository implements PortfolioRepository {
  int calls = 0;

  @override
  Future<List<CollectibleItem>> getItems() async {
    calls += 1;
    if (calls == 1) {
      throw StateError('load failed');
    }
    return const [];
  }

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async => item;

  @override
  Future<void> clearPortfolio() async {}

  @override
  Future<void> removeItem(String id) async {}

  @override
  Future<void> updateItem(CollectibleItem item) async {}

  @override
  Future<void> updateItemImageSync({
    required String itemId,
    required String imageStoragePath,
    required String cloudImageUrl,
  }) async {}

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {}
}
