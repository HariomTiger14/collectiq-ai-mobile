import 'dart:async';
import 'dart:convert';

import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
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

  testWidgets('default state follows frozen v0.3 with real portfolio data', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('home-brand-emblem')), findsOneWidget);
    expect(find.text('PackLox'), findsOneWidget);
    expect(find.text('Pack  Lox'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(
      find.text(
        'Your collection has real saved items, with some values still pending.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-authority-hero')), findsOneWidget);
    expect(find.text('Know what your collection is worth'), findsOneWidget);
    expect(find.text('Scan next item'), findsOneWidget);
    expect(find.text('Collection value'), findsOneWidget);
    expect(find.text('\$2,275'), findsOneWidget);
    expect(find.text('Collection items'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-action-scan-collectible')),
    );
    expect(
      find.byKey(const ValueKey('home-action-scan-collectible')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-action-market-insights')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-action-recent-scan')),
      findsOneWidget,
    );
    expect(find.text('Premium Charizard'), findsWidgets);
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
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-action-guided-scan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-action-supported-categories')),
        findsOneWidget,
      );
      expect(find.text('Collection value'), findsNothing);
      expect(find.text('Collection items'), findsNothing);
      expect(find.text('\$0'), findsNothing);
      expect(find.text('REPRESENTATIVE DESIGN DATA'), findsNothing);
      expect(find.text('READY FOR REVIEW / NOT FROZEN'), findsNothing);
      expect(find.text('HOME FLOW AUTHORITY'), findsNothing);
      expect(find.byKey(const ValueKey('bottom-navigation')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('home-primary-scan')));
      await tester.pump();

      expect(scanTaps, 1);
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
      expect(find.text('\$50'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1 valued'), findsOneWidget);
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-action-partial-valuation')),
      );
      expect(
        find.byKey(const ValueKey('home-action-partial-valuation')),
        findsOneWidget,
      );
      expect(find.text('1 item needs a real valuation.'), findsOneWidget);
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

    expect(find.text('Collection items'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Collection value'), findsNothing);
    expect(find.text('\$0'), findsNothing);
    expect(find.byKey(const ValueKey('home-alert-button')), findsOneWidget);
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
    expect(find.text('Collection could not load'), findsOneWidget);
    expect(find.text('Unable to load portfolio.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-retry')));
    await tester.pump(const Duration(milliseconds: 120));

    expect(repository.calls, 2);
    expect(find.text('Your collection is waiting'), findsOneWidget);
  });

  testWidgets('recent scan row opens the existing collectible detail route', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pump(const Duration(milliseconds: 120));

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-action-recent-scan')),
    );
    await tester.tap(find.byKey(const ValueKey('home-action-recent-scan')));
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

    expect(find.text('PackLox'), findsOneWidget);
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
    expect(find.text('Collection value'), findsOneWidget);
    expect(find.text('\$2,275'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-alert-button')), findsNothing);

    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.loading));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('home-loading-skeleton')), findsOneWidget);
    expect(find.text('\$18.4K'), findsNothing);

    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.error));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('home-error-panel')), findsOneWidget);
    expect(find.text('Unable to load portfolio.'), findsOneWidget);

    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.partial));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('home-alert-button')), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-action-partial-valuation')),
    );
    expect(
      find.byKey(const ValueKey('home-action-partial-valuation')),
      findsOneWidget,
    );

    await tester.pumpWidget(_previewHomeApp(HomePreviewScenario.guest));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Your collection is waiting'), findsOneWidget);
  });
}

Widget _homeApp({
  VoidCallback? onScanPressed,
  VoidCallback? onSampleScanPressed,
  VoidCallback? onImportPhotoPressed,
  VoidCallback? onPortfolioPressed,
  PortfolioRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      if (repository != null)
        portfolioRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: HomePage(
        onScanPressed: onScanPressed,
        onSampleScanPressed: onSampleScanPressed,
        onImportPhotoPressed: onImportPhotoPressed,
        onPortfolioPressed: onPortfolioPressed,
      ),
    ),
  );
}

Widget _previewHomeApp(HomePreviewScenario scenario) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: HomePage(
      previewScenario: scenario,
      onScanPressed: () {},
      onSampleScanPressed: () {},
      onPortfolioPressed: () {},
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
