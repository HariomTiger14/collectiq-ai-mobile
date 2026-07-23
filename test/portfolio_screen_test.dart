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

    await _revealPortfolio(tester, find.text('No matches found'));
    expect(find.text('No matches found'), findsWidgets);
    expect(find.text('Your portfolio is waiting'), findsNothing);
    expect(find.text('Clear search'), findsWidgets);

    final previewClearSearch = find.byKey(
      const ValueKey('portfolio-clear-search'),
    );
    await tester.ensureVisible(previewClearSearch);
    await tester.pumpAndSettle();
    await tester.tap(previewClearSearch);
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-preview-charizard')),
    );
    expect(find.text('Base Set Charizard'), findsOneWidget);
  });

  testWidgets('entering a search query shows matching results', (tester) async {
    _seedPortfolio([
      _item('search-card', 'Pokemon Charizard', 1850),
      _item('search-coin', 'Silver Eagle', 52, category: 'Coin'),
    ]);

    await _pumpPortfolio(tester);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field-')),
      'charizard',
    );
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-coin')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('portfolio-search-clear')),
      findsOneWidget,
    );
  });

  testWidgets('clearing a search query restores current result list', (
    tester,
  ) async {
    _seedPortfolio([
      _item('search-card', 'Pokemon Charizard', 1850),
      _item('search-coin', 'Silver Eagle', 52, category: 'Coin'),
    ]);

    await _pumpPortfolio(tester);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field-')),
      'charizard',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('portfolio-search-clear')));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-search-coin')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-coin')),
      findsOneWidget,
    );
  });

  testWidgets('search with no results shows polished empty state', (
    tester,
  ) async {
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

    await _revealPortfolio(tester, find.text('No matches found'));
    expect(find.text('No matches found'), findsWidgets);
    expect(find.text('Clear search'), findsWidgets);
    expect(
      find.byKey(const ValueKey('portfolio-clear-search')),
      findsOneWidget,
    );

    final clearSearch = find.byKey(const ValueKey('portfolio-clear-search'));
    await tester.ensureVisible(clearSearch);
    await tester.pumpAndSettle();
    await tester.tap(clearSearch);
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

  testWidgets('opens combined filter and sort bottom sheet', (tester) async {
    _seedPortfolio([_item('sort-card', 'Pokemon Charizard', 1850)]);
    await _pumpPortfolio(tester);

    await tester.tap(find.byKey(const ValueKey('portfolio-action-sort')));
    await tester.pumpAndSettle();

    expect(_portfolioSheet, findsOneWidget);
    expect(find.text('Sort and filter'), findsOneWidget);
    expect(find.text('Recently added'), findsOneWidget);
    expect(find.text('Value: high to low'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-sort-option-status')),
      findsOneWidget,
    );
    expect(find.text('Valued'), findsOneWidget);
    await _revealSheetControl(tester, const ValueKey('portfolio-filter-reset'));
    await _revealSheetControl(tester, const ValueKey('portfolio-filter-apply'));
  });

  testWidgets('selecting a sort option is staged until Apply', (tester) async {
    _seedPortfolio([
      _item('low-card', 'Low Value Card', 12),
      _item('high-card', 'High Value Card', 240),
    ]);
    await _pumpPortfolio(tester);

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-low-card')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-high-card')),
    );
    expect(
      _itemTop(tester, 'low-card'),
      lessThan(_itemTop(tester, 'high-card')),
    );
    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('portfolio-sort-option-valueHigh')),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();
    expect(
      _itemTop(tester, 'low-card'),
      lessThan(_itemTop(tester, 'high-card')),
    );

    await tester.tap(find.byKey(const ValueKey('portfolio-action-sort')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-sort-option-valueHigh')),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    expect(
      _itemTop(tester, 'high-card'),
      lessThan(_itemTop(tester, 'low-card')),
    );
    expect(find.text('High value'), findsOneWidget);
  });

  testWidgets('selecting a filter option applies to Portfolio results', (
    tester,
  ) async {
    _seedPortfolio([
      _item('valued-card', 'Valued Charizard', 1850),
      _item(
        'pending-coin',
        'Pending Silver Eagle',
        0,
        category: 'Coin',
        valuationStatus: 'provider_not_configured',
      ),
    ]);
    await _pumpPortfolio(tester);

    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-status-filter-pending')),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-pending-coin')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-valued-card')),
      findsNothing,
    );
    expect(find.text('Filter (1)'), findsOneWidget);
  });

  testWidgets('reset restores sheet selections before Apply', (tester) async {
    _seedPortfolio([
      _item('valued-card', 'Valued Charizard', 1850),
      _item(
        'pending-coin',
        'Pending Silver Eagle',
        0,
        category: 'Coin',
        valuationStatus: 'provider_not_configured',
      ),
    ]);
    await _pumpPortfolio(tester);

    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-status-filter-pending')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-sort-option-valueHigh')),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-reset'));
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-pending-coin')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-valued-card')),
    );
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
  });

  testWidgets('apply can drive the filtered-empty Portfolio state', (
    tester,
  ) async {
    _seedPortfolio([
      _item('valued-card', 'Valued Charizard', 1850),
      _item('valued-coin', 'Valued Silver Eagle', 52, category: 'Coin'),
    ]);
    await _pumpPortfolio(tester);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field-')),
      'charizard',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-category-filter-coins')),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await _revealPortfolio(tester, find.text('No matches found'));
    expect(
      find.byKey(const ValueKey('portfolio-filtered-empty-state-surface')),
      findsOneWidget,
    );
    expect(find.text('No matches found'), findsWidgets);
    expect(find.text('Clear search'), findsWidgets);
    expect(find.text('Reset filters'), findsOneWidget);
  });

  testWidgets('search clear preserves applied filter and sort state', (
    tester,
  ) async {
    _seedPortfolio([
      _item('valued-card', 'Valued Charizard', 1850),
      _item('low-coin', 'Low Silver Eagle', 52, category: 'Coin'),
      _item('high-coin', 'High Silver Eagle', 250, category: 'Coin'),
    ]);
    await _pumpPortfolio(tester);

    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-category-filter-coins')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-sort-option-valueHigh')),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field-')),
      'charizard',
    );
    await tester.pumpAndSettle();
    await _revealPortfolio(tester, find.text('No matches found'));

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field-charizard')),
      '',
    );
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-high-coin')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-low-coin')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-valued-card')),
      findsNothing,
    );
    expect(find.text('Filter (1)'), findsOneWidget);
    expect(find.text('High value'), findsOneWidget);
    expect(
      _itemTop(tester, 'high-coin'),
      lessThan(_itemTop(tester, 'low-coin')),
    );
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
    'Portfolio delete confirm removes item and can show empty state',
    (tester) async {
      _seedPortfolio([_item('remove-card', 'Remove Charizard', 1850)]);
      await _pumpPortfolio(tester);

      await _openDetailActions(tester, 'remove-card');
      await tester.tap(
        find.byKey(const ValueKey('collectible-detail-delete-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('collectible-delete-confirm-action')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('portfolio-grid-item-remove-card')),
        findsNothing,
      );
      expect(find.text('Start with your first item'), findsOneWidget);
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

Future<void> _openDetailActions(WidgetTester tester, String id) async {
  await _revealPortfolio(
    tester,
    find.byKey(ValueKey('portfolio-grid-item-$id')),
  );
  await tester.tap(find.byKey(ValueKey('portfolio-grid-item-$id')));
  await tester.pumpAndSettle();
  await _revealPortfolio(tester, find.text('Actions Menu'));
}

Future<void> _revealSheetControl(
  WidgetTester tester,
  ValueKey<String> key,
) async {
  final finder = find.byKey(key);
  for (var attempt = 0; attempt < 8; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(_portfolioSheet, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
}

Future<void> _tapSheetControl(WidgetTester tester, ValueKey<String> key) async {
  await _revealSheetControl(tester, key);
  await tester.tap(find.byKey(key));
}

Finder get _portfolioSheet {
  return find.byKey(const ValueKey('portfolio-premium-filter-sheet-surface'));
}

double _itemTop(WidgetTester tester, String id) {
  return tester.getTopLeft(find.byKey(ValueKey('portfolio-grid-item-$id'))).dy;
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
