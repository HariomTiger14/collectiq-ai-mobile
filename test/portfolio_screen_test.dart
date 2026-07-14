import 'dart:convert';

import 'package:collectiq_ai/core/theme/app_theme.dart';
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

  testWidgets('approved header search summary and empty order render at top', (
    tester,
  ) async {
    await _pumpPortfolio(tester);

    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('My Collection'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-search-field-')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-compact-snapshot')),
      findsOneWidget,
    );
    expect(find.text('Total Items'), findsOneWidget);
    expect(find.text('Total Value (Est.)'), findsOneWidget);
    expect(find.text('Your collection is empty'), findsOneWidget);
    expect(find.text('Scan Your First Item'), findsOneWidget);

    final searchTop = tester
        .getTopLeft(find.byKey(const ValueKey('portfolio-search-field-')))
        .dy;
    final summaryTop = tester
        .getTopLeft(find.byKey(const ValueKey('portfolio-compact-snapshot')))
        .dy;
    final emptyTop = tester
        .getTopLeft(find.byKey(const ValueKey('portfolio-empty-state-surface')))
        .dy;

    expect(searchTop, lessThan(summaryTop));
    expect(summaryTop, lessThan(emptyTop));
  });

  testWidgets('populated summary uses real count value and approved controls', (
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

    expect(find.text('3'), findsWidgets);
    expect(find.text('\$18'), findsWidgets);
    expect(find.byKey(const ValueKey('portfolio-action-sort')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-action-filter')),
      findsOneWidget,
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-card-1')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-card-1')),
      findsOneWidget,
    );
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
        matching: find.text('-'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-zero-card')),
        matching: find.text('\$0'),
      ),
      findsOneWidget,
    );
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

    expect(find.text('No items found'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
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
    expect(
      find.byKey(const ValueKey('portfolio-premium-sort-sheet-surface')),
      findsOneWidget,
    );
    expect(find.text('Sort portfolio'), findsOneWidget);
    await tester.tap(find.text('Recently Added'));
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

  testWidgets('gallery fallback badge and item card dimensions stay in range', (
    tester,
  ) async {
    _seedPortfolio([
      _item(
        'gallery-card',
        'Gallery Hot Wheels',
        48,
        imagePath: '',
        galleryImages: const [
          {'path': 'sample://front', 'role': 'front', 'isPrimary': true},
          {'path': 'sample://back', 'role': 'back', 'isPrimary': false},
        ],
      ),
    ]);

    await _pumpPortfolio(tester);

    final cardFinder = find.byKey(
      const ValueKey('portfolio-grid-item-gallery-card'),
    );
    await _revealPortfolio(tester, cardFinder);
    expect(cardFinder, findsOneWidget);
    expect(find.text('2 images'), findsOneWidget);

    final rect = tester.getRect(cardFinder);
    expect(rect.width, inInclusiveRange(150, 210));
    expect(rect.height / rect.width, inInclusiveRange(1.55, 1.95));
  });

  testWidgets(
    'card opens existing Detail route and first entry starts at top',
    (tester) async {
      _seedPortfolio([_item('detail-card', 'Detail Charizard', 1850)]);
      await _pumpPortfolio(tester);

      final scrollView = tester.widget<CustomScrollView>(
        find.byKey(const ValueKey('portfolio-scroll-view')),
      );
      expect(scrollView.controller?.offset ?? 0, 0);

      await _revealPortfolio(
        tester,
        find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
      );
      await tester.tap(
        find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Charizard'), findsWidgets);
    },
  );

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
}

Future<void> _pumpPortfolio(
  WidgetTester tester, {
  Size size = const Size(430, 844),
  TextScaler textScaler = TextScaler.noScaling,
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
          child: const Scaffold(body: PortfolioScreen()),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _revealPortfolio(WidgetTester tester, Finder finder) async {
  final scroll = find.byKey(const ValueKey('portfolio-scroll-view'));
  for (var attempt = 0; attempt < 12; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(scroll, const Offset(0, -260));
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
  List<Map<String, Object?>> galleryImages = const [],
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
    'galleryImages': galleryImages,
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
