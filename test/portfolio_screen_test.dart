import 'dart:convert';

import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty state has no fake metrics and keeps scan action active', (
    tester,
  ) async {
    var scanTapped = false;

    await _pumpPortfolio(
      tester,
      onScanPressed: () {
        scanTapped = true;
      },
    );

    expect(find.text('PackLox'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Start your portfolio'), findsOneWidget);
    expect(find.text('Start with your first item'), findsOneWidget);
    expect(find.byKey(const ValueKey('portfolio-metric-grid')), findsNothing);

    await tester.tap(find.text('Scan first item'));
    await tester.pump();
    expect(scanTapped, isTrue);
  });

  testWidgets('default state renders real bound values and saved items', (
    tester,
  ) async {
    _seedPortfolio([
      _item('card-1', 'Hot Wheels 15 Mazda MX-5 Miata', 18),
      _item('card-2', 'Silver Eagle 2015', 0, category: 'Coin'),
      _item(
        'card-3',
        'Mystery No Match',
        0,
        valuationStatus: 'no_market_match',
      ),
    ]);

    await _pumpPortfolio(tester);

    expect(find.text('Your collection at a glance'), findsOneWidget);
    expect(find.text('Collection value'), findsOneWidget);
    expect(find.text('\$18'), findsOneWidget);
    expect(find.text('Collection items'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('1 pending'), findsOneWidget);
    expect(find.byKey(const ValueKey('portfolio-action-sort')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-action-filter')),
      findsOneWidget,
    );

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-card-1')),
    );
    expect(find.text('Hot Wheels 15 Mazda MX-5 Miata'), findsOneWidget);
  });

  testWidgets('unavailable valuation is distinct from genuine zero', (
    tester,
  ) async {
    _seedPortfolio([
      _item(
        'unavailable-card',
        'Unavailable Charizard',
        0,
        valuationStatus: 'no_market_match',
      ),
      _item(
        'zero-card',
        'Zero Value Token',
        0,
        valuationStatus: 'market_estimated',
      ),
    ]);

    await _pumpPortfolio(tester);

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-unavailable-card')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-zero-card')),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-unavailable-card')),
        matching: find.text('Pending'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-zero-card')),
        matching: find.text('\$0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('loading skeleton renders without placeholder data copy', (
    tester,
  ) async {
    await _pumpPortfolio(
      tester,
      previewScenario: PortfolioPreviewScenario.loading,
    );

    expect(find.text('Preparing portfolio'), findsOneWidget);
    expect(
      find.text('Preparing your saved items, values, and filters.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-loading-skeleton')),
      findsOneWidget,
    );
    expect(find.textContaining('placeholder data'), findsNothing);
  });

  testWidgets('error state exposes one active Retry CTA', (tester) async {
    await _pumpPortfolio(
      tester,
      previewScenario: PortfolioPreviewScenario.error,
    );

    expect(find.text('Portfolio could not load'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const ValueKey('portfolio-retry')), findsOneWidget);
  });

  testWidgets('partial state uses amber pending and green confirmed status', (
    tester,
  ) async {
    await _pumpPortfolio(
      tester,
      previewScenario: PortfolioPreviewScenario.partial,
    );

    await _revealPortfolio(tester, find.text('Needs value'));
    final pendingText = tester.widget<Text>(find.text('Needs value').first);
    expect(pendingText.style?.color, HomeTokens.warning);

    final valuedText = tester.widget<Text>(find.text('Valued').first);
    expect(valuedText.style?.color, HomeTokens.positive);
  });

  testWidgets('filtered empty keeps portfolio context and clears filters', (
    tester,
  ) async {
    await _pumpPortfolio(
      tester,
      previewScenario: PortfolioPreviewScenario.filteredEmpty,
    );

    await _revealPortfolio(tester, find.text('No matching collectibles'));
    expect(find.text('No matching collectibles'), findsOneWidget);
    expect(find.text('Your portfolio is waiting'), findsNothing);
    expect(find.text('Clear filters'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('portfolio-clear-filters')));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-preview-charizard')),
    );
    expect(find.text('Base Set Charizard'), findsOneWidget);
  });

  testWidgets('search no-results and clear restore results', (tester) async {
    _seedPortfolio([
      _item('search-card', 'Pokemon Charizard', 1850),
      _item('search-coin', 'Silver Eagle', 52, category: 'Coin'),
    ]);

    await _pumpPortfolio(tester);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field-')),
      'zzzzz',
    );
    await tester.pumpAndSettle();

    await _revealPortfolio(tester, find.text('No matching collectibles'));
    expect(find.text('No matching collectibles'), findsOneWidget);
    expect(find.text('Clear filters'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('portfolio-clear-filters')));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
      findsOneWidget,
    );
  });

  testWidgets('filter and sort sheets keep dark approved surfaces', (
    tester,
  ) async {
    _seedPortfolio([_item('sort-card', 'Pokemon Charizard', 1850)]);
    await _pumpPortfolio(tester);

    await tester.tap(find.byKey(const ValueKey('portfolio-action-sort')));
    await tester.pumpAndSettle();
    final sortSheet = find.byKey(
      const ValueKey('portfolio-premium-sort-sheet-surface'),
    );
    expect(sortSheet, findsOneWidget);
    expect(find.text('Sort portfolio'), findsOneWidget);
    await tester.tap(
      find.descendant(of: sortSheet, matching: find.text('Recently Added')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('portfolio-premium-filter-sheet-surface')),
      findsOneWidget,
    );
    expect(find.text('Filter portfolio'), findsOneWidget);
    expect(find.text('Apply filters'), findsOneWidget);
  });

  testWidgets('item rows open existing Detail route', (tester) async {
    _seedPortfolio([_item('detail-card', 'Detail Charizard', 1850)]);
    await _pumpPortfolio(tester);

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
    );
    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Charizard'), findsWidgets);
  });

  testWidgets(
    'narrow and large text layouts keep Portfolio controls reachable',
    (tester) async {
      _seedPortfolio([_item('narrow-card', 'Narrow Layout Charizard', 1850)]);
      await _pumpPortfolio(
        tester,
        size: const Size(320, 760),
        textScaler: const TextScaler.linear(1.25),
      );

      expect(
        find.byKey(const ValueKey('portfolio-search-field-')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('portfolio-action-sort')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('portfolio-action-filter')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Portfolio preview screen selects in-memory scenario', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(PortfolioStatePreviewScreen.route()),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('home-action-portfolio-preview-partial')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Portfolio State Preview'), findsNothing);
  });
}

Future<void> _pumpPortfolio(
  WidgetTester tester, {
  Size size = const Size(430, 844),
  TextScaler textScaler = TextScaler.noScaling,
  PortfolioPreviewScenario? previewScenario,
  VoidCallback? onScanPressed,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: Scaffold(
            body: PortfolioScreen(
              previewScenario: previewScenario,
              onScanPressed: onScanPressed,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _revealPortfolio(WidgetTester tester, Finder finder) async {
  final scroll = find.byType(CustomScrollView);
  for (var attempt = 0; attempt < 12; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(scroll.first, const Offset(0, -260));
    await tester.pump();
  }
  expect(finder, findsOneWidget);
}

void _seedPortfolio(List<Map<String, Object?>> items) {
  SharedPreferences.setMockInitialValues({
    'portfolio_items': jsonEncode(items),
  });
}

Map<String, Object?> _item(
  String id,
  String title,
  double value, {
  String category = 'Trading Card',
  String imagePath = 'sample://card',
  String valuationStatus = 'market_estimated',
}) {
  return {
    'id': id,
    'title': title,
    'category': category,
    'estimatedValue': value,
    'confidence': 0.91,
    'condition': 'Near Mint',
    'recommendation': 'Keep protected.',
    'imagePath': imagePath,
    'galleryImages': <Object>[],
    'createdAt': '2026-07-01T00:00:00.000Z',
    'valuationStatus': valuationStatus,
    'valuationSource': valuationStatus,
    'marketSummary': {
      'averagePrice': value,
      'medianPrice': value,
      'lowPrice': value,
      'highPrice': value,
      'salesCount': 1,
      'trendLabel': 'Stable',
      'confidence': 0.80,
      'lastUpdated': '2026-07-01T00:00:00.000Z',
      'sources': ['test'],
      'comps': <Object>[],
    },
  };
}
