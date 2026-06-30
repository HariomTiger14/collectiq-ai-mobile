import 'package:collectiq_ai/features/subscription/domain/repositories/usage_repository.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app launch, empty states and settings render', (tester) async {
    await _pumpCollectIqApp(tester);

    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
    expect(find.text('Good Evening, Harry'), findsOneWidget);
    expect(find.text('No collectibles scanned yet.'), findsOneWidget);

    await _openTab(tester, 'nav-scan');
    expect(find.byKey(const ValueKey('screen-scan')), findsOneWidget);
    expect(find.text('AI Scanner'), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-camera-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-gallery-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-sample-button')), findsOneWidget);

    await _openTab(tester, 'nav-portfolio');
    expect(find.byKey(const ValueKey('screen-portfolio')), findsOneWidget);
    expect(find.text('No collectibles saved yet'), findsOneWidget);

    await _openTab(tester, 'nav-settings');
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Plan & Usage'), findsOneWidget);
    await _ensureVisibleText(tester, 'Developer Diagnostics');
    expect(find.text('AI Provider'), findsOneWidget);
    await _ensureVisibleText(tester, 'Cloud Sync');
    expect(find.text('Cloud status'), findsOneWidget);
    expect(find.text('Manual Sync'), findsOneWidget);
  });

  testWidgets('seeded home, portfolio, detail and settings flows render', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items': _seededPortfolioJson,
    });
    await _pumpCollectIqApp(tester);

    expect(find.text('Collection Value'), findsOneWidget);
    expect(find.text('Dashboard Insights'), findsOneWidget);
    expect(find.text('Collection Score'), findsOneWidget);
    expect(find.text('Smart Collector Insights'), findsOneWidget);
    expect(find.text('AI Collector Recommendations'), findsOneWidget);
    expect(find.text('Wishlist & Goals'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-recent-seeded-card')),
      findsOneWidget,
    );

    await _ensureVisibleKey(tester, const ValueKey('home-recent-seeded-card'));
    await tester.tap(find.byKey(const ValueKey('home-recent-seeded-card')));
    await _settle(tester);
    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Estimated market value'), findsOneWidget);
    expect(find.text('AI Review'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
    Navigator.of(tester.element(find.text('Collectible Details'))).pop();
    await _settle(tester);

    await _openTab(tester, 'nav-portfolio');
    expect(
      find.byKey(const ValueKey('portfolio-item-seeded-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-item-seeded-coin')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      'silver',
    );
    await _settle(tester);
    expect(find.text('Seeded Silver Eagle'), findsWidgets);
    expect(find.text('Seeded Charizard'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      '',
    );
    await _settle(tester);
    await _ensureVisibleKey(tester, const ValueKey('portfolio-filter-coins'));
    await tester.tap(find.byKey(const ValueKey('portfolio-filter-coins')));
    await _settle(tester);
    expect(find.text('Seeded Silver Eagle'), findsWidgets);

    await _ensureVisibleKey(
      tester,
      const ValueKey('portfolio-item-seeded-coin'),
    );
    await tester.tap(find.byKey(const ValueKey('portfolio-item-seeded-coin')));
    await _settle(tester);
    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Market Pricing'), findsOneWidget);
    expect(find.text('Saved 29/06/2026'), findsOneWidget);
    await _ensureVisibleText(tester, 'Delete Item');
    expect(find.text('Delete Item'), findsOneWidget);
  });

  testWidgets('sample scan mock analyze save search and delete flow works', (
    tester,
  ) async {
    await _pumpCollectIqApp(tester);

    await _openTab(tester, 'nav-scan');
    await tester.tap(find.byKey(const ValueKey('scan-sample-button')));
    await _settle(tester);
    expect(find.text('Image selected'), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-analyze-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scan-analyze-button')));
    await _settle(tester);
    await _ensureVisibleText(tester, 'Analysis Complete');
    expect(find.text('Estimated market value'), findsOneWidget);
    expect(find.textContaining('Estimated value range'), findsOneWidget);
    expect(find.text('Condition'), findsWidgets);
    expect(find.text('Save to Portfolio'), findsOneWidget);

    await _ensureVisibleText(tester, 'Save to Portfolio');
    await tester.tap(find.text('Save to Portfolio'));
    await _settle(tester);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('View in Portfolio'), findsOneWidget);
    expect(find.text('Scan Another'), findsOneWidget);

    await tester.tap(find.text('View in Portfolio'));
    await _settle(tester);
    expect(find.byKey(const ValueKey('screen-portfolio')), findsOneWidget);
    expect(find.textContaining('Charizard'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      'charizard',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);
    expect(find.textContaining('Charizard'), findsWidgets);

    final savedItem = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('portfolio-item-'),
      description: 'saved portfolio item card',
    );
    expect(savedItem, findsWidgets);
    await _ensureVisibleFinder(tester, savedItem.first);
    await tester.tap(savedItem.first);
    await _settle(tester);
    expect(find.text('Collectible Details'), findsOneWidget);
    await _ensureVisibleText(tester, 'Delete Item');
    await tester.tap(find.text('Delete Item'));
    await _settle(tester);
    expect(find.text('Delete item?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await _settle(tester);
    expect(find.byKey(const ValueKey('screen-portfolio')), findsOneWidget);
  });

  testWidgets('usage limit blocking scenario shows inline scan error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpCollectIqAppWithBlockedUsage(tester);

    await _openTab(tester, 'nav-scan');
    await tester.tap(find.byKey(const ValueKey('scan-sample-button')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('scan-analyze-button')));
    await _settle(tester);

    expect(find.text('Scan interrupted'), findsOneWidget);
    expect(
      find.textContaining('Daily free scan limit reached'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpCollectIqApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: CollectIqApp()));
  await _settle(tester);
}

Future<void> _pumpCollectIqAppWithBlockedUsage(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        usageLimitConfigProvider.overrideWithValue(
          const UsageLimitConfig(
            developmentUnlimited: false,
            dailyFreeScanLimit: 1,
          ),
        ),
        usageRepositoryProvider.overrideWithValue(
          _MemoryUsageRepository(initialCount: 1),
        ),
      ],
      child: const CollectIqApp(),
    ),
  );
  await _settle(tester);
}

Future<void> _openTab(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await _settle(tester);
}

Future<void> _ensureVisibleText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await _settle(tester);
}

Future<void> _ensureVisibleKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await _settle(tester);
}

Future<void> _ensureVisibleFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

class _MemoryUsageRepository implements UsageRepository {
  _MemoryUsageRepository({int initialCount = 0}) : count = initialCount;

  int count;

  @override
  Future<int> scansUsedToday() async => count;

  @override
  Future<int> incrementScansUsedToday() async {
    count += 1;
    return count;
  }

  @override
  Future<void> resetUsage() async {
    count = 0;
  }
}

const _seededPortfolioJson = '''
[
  {
    "id": "seeded-card",
    "title": "Seeded Charizard",
    "category": "Trading Card",
    "estimatedValue": 1850,
    "confidence": 0.94,
    "condition": "Near Mint",
    "recommendation": "Consider grading before selling.",
    "imagePath": "sample://sports-card",
    "createdAt": "2026-06-30T09:30:00.000",
    "primaryMatch": "1999 Pokemon Charizard Holo",
    "confidenceExplanation": "High confidence from character artwork.",
    "detectionQuality": "Good",
    "aiReasoning": "The image shows a Charizard-like Pokemon card.",
    "year": "1999",
    "brand": "Pokemon",
    "setName": "Base Set",
    "cardNumber": "4/102",
    "playerOrCharacter": "Charizard",
    "rarity": "Holo Rare",
    "notes": "Verify holo surface.",
    "pricing": {
      "estimatedMarketValue": 1850,
      "lowEstimate": 1443,
      "highEstimate": 2257,
      "currency": "AUD",
      "pricingSource": "Mock market blend",
      "pricingConfidence": 0.85,
      "lastUpdated": "2026-06-29T00:00:00Z"
    },
    "marketSummary": {
      "averagePrice": 1810,
      "medianPrice": 1850,
      "lowPrice": 1443,
      "highPrice": 2257,
      "salesCount": 5,
      "trendLabel": "Stable",
      "confidence": 0.86,
      "lastUpdated": "2026-06-29T00:00:00Z",
      "sources": ["eBay Sold"],
      "comps": [
        {
          "source": "eBay Sold",
          "title": "1999 Pokemon Charizard sold listing",
          "soldPrice": 1850,
          "currency": "AUD",
          "soldDate": "2026-06-20T00:00:00Z",
          "condition": "Near Mint"
        }
      ]
    }
  },
  {
    "id": "seeded-coin",
    "title": "Seeded Silver Eagle",
    "category": "Coin",
    "estimatedValue": 300,
    "confidence": 0.88,
    "condition": "Mint",
    "recommendation": "Store safely.",
    "imagePath": "sample://coin",
    "createdAt": "2026-06-29T08:00:00.000",
    "pricing": {
      "estimatedMarketValue": 300,
      "lowEstimate": 240,
      "highEstimate": 360,
      "currency": "AUD",
      "pricingSource": "Mock market blend",
      "pricingConfidence": 0.8,
      "lastUpdated": "2026-06-29T00:00:00Z"
    },
    "marketSummary": {
      "averagePrice": 300,
      "medianPrice": 300,
      "lowPrice": 240,
      "highPrice": 360,
      "salesCount": 3,
      "trendLabel": "Stable",
      "confidence": 0.8,
      "lastUpdated": "2026-06-29T00:00:00Z",
      "sources": ["Mock"],
      "comps": []
    }
  }
]
''';
