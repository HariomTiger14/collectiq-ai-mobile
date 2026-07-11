import 'dart:convert';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _seedPortfolio(_portfolioItems());
  });

  testWidgets('compact hero renders collection context without old headline', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text('Ready to grow your collection?'), findsOneWidget);
    expect(
      find.text('You have 5 collectibles worth an estimated \$2,275.'),
      findsOneWidget,
    );
    expect(find.text('Your Collection Hub'), findsNothing);
    expect(find.byType(MotionParallax), findsOneWidget);

    final heroContainer = tester.widget<Container>(
      find.byKey(const ValueKey('home-hero-container')),
    );
    final heroDecoration = heroContainer.decoration! as BoxDecoration;
    expect(heroDecoration.gradient, AppGradients.premiumHeroGradient);
    expect(heroContainer.constraints?.minHeight, 156);

    final heroMotion = tester.widget<MotionElasticHero>(
      find.byKey(const ValueKey('home-hero-motion')),
    );
    expect(heroMotion.baseHeight, 156);
    expect(
      tester.getSize(find.byKey(const ValueKey('home-hero-motion'))).height,
      greaterThanOrEqualTo(156),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scan cta is primary and exposes accessibility semantics', (
    tester,
  ) async {
    var scanTaps = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-primary-scan-cta')), findsOneWidget);
    expect(find.text('Scan a collectible'), findsOneWidget);
    expect(find.text('Identify, value, and save an item'), findsOneWidget);
    final node = tester.getSemantics(
      find.byKey(const ValueKey('home-primary-scan-cta')),
    );
    expect(node.label, contains('Scan a collectible'));
    expect(node.hint, contains('Starts a new collectible scan'));
    expect(node.flagsCollection.isButton, isTrue);
    semantics.dispose();

    await tester.tap(find.byKey(const ValueKey('home-primary-scan-cta')));
    await tester.pump();

    expect(scanTaps, 1);
  });

  testWidgets('secondary actions are compact and functional only', (
    tester,
  ) async {
    var importTaps = 0;
    var portfolioTaps = 0;

    await tester.pumpWidget(
      _homeApp(
        onImportPhotoPressed: () => importTaps++,
        onPortfolioPressed: () => portfolioTaps++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-secondary-import')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-secondary-portfolio')),
      findsOneWidget,
    );
    expect(find.text('Import photo'), findsOneWidget);
    expect(find.text('Open portfolio'), findsOneWidget);
    expect(find.text('PI (Soon)'), findsNothing);
    expect(find.text('Trends Planned'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-secondary-import')));
    await tester.tap(find.byKey(const ValueKey('home-secondary-portfolio')));
    await tester.pump();

    expect(importTaps, 1);
    expect(portfolioTaps, 1);
  });

  testWidgets('duplicate standalone metrics panel is absent', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-stats-surface')), findsNothing);
    expect(find.text('Total value'), findsNothing);
    expect(find.text('Portfolio Overview'), findsNothing);
    expect(find.text('Trend'), findsNothing);
  });

  testWidgets(
    'collection snapshot shows real count value and top collectible',
    (tester) async {
      await tester.pumpWidget(_homeApp());
      await tester.pumpAndSettle();

      await _scrollUntilVisible(tester, find.text('Collection snapshot'));

      expect(find.text('Collection snapshot'), findsOneWidget);
      expect(find.text('\$2,275 estimated value'), findsOneWidget);
      expect(find.text('5 collectibles'), findsOneWidget);
      expect(find.text('3 categories'), findsOneWidget);
      expect(find.text('Top collectible'), findsOneWidget);
      expect(find.text('Premium Charizard'), findsWidgets);

      final topThumbnail = tester.widget<PortfolioThumbnail>(
        find.descendant(
          of: find.byKey(const ValueKey('home-top-collectible-home-test-card')),
          matching: find.byType(PortfolioThumbnail),
        ),
      );
      expect(topThumbnail.size, 72);
    },
  );

  testWidgets('unavailable values are honest and do not show misleading zero', (
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
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Collection snapshot'));

    expect(find.text('Value unavailable'), findsWidgets);
    expect(find.text('\$0 estimated value'), findsNothing);
    expect(find.text('\$0'), findsNothing);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-grounded-insight')),
    );
    expect(find.byKey(const ValueKey('home-grounded-insight')), findsOneWidget);
  });

  testWidgets('top collectible and recent rows open detail', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-top-collectible-home-test-card')),
    );
    await tester.tap(
      find.byKey(const ValueKey('home-top-collectible-home-test-card')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CollectibleDetailPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-recent-home-test-coin')),
    );
    await tester.tap(find.byKey(const ValueKey('home-recent-home-test-coin')));
    await tester.pumpAndSettle();

    expect(find.byType(CollectibleDetailPage), findsOneWidget);
  });

  testWidgets('recent collectibles are compact and view all opens portfolio', (
    tester,
  ) async {
    var portfolioTaps = 0;

    await tester.pumpWidget(
      _homeApp(onPortfolioPressed: () => portfolioTaps++),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Recent collectibles'));

    expect(find.text('Recent collectibles'), findsOneWidget);
    expect(find.text('Recent Activity'), findsNothing);
    expect(find.text('View all'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-recent-home-test-card')),
      findsOneWidget,
    );

    final recentThumbnail = tester.widget<PortfolioThumbnail>(
      find.descendant(
        of: find.byKey(const ValueKey('home-recent-home-test-card')),
        matching: find.byType(PortfolioThumbnail),
      ),
    );
    expect(recentThumbnail.size, 64);

    final recentTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('home-recent-home-test-card')),
        matching: find.text('Premium Charizard'),
      ),
    );
    expect(recentTitle.maxLines, 2);
    expect(recentTitle.overflow, TextOverflow.ellipsis);

    await tester.tap(find.text('View all'));
    await tester.pump();
    expect(portfolioTaps, 1);
  });

  testWidgets('empty portfolio state is clean and keeps scan entrypoints', (
    tester,
  ) async {
    _seedPortfolio(const []);
    var scanTaps = 0;

    await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Scan your first collectible and start building your collection.',
      ),
      findsOneWidget,
    );
    expect(find.text('No collectibles saved yet'), findsOneWidget);
    expect(find.text('Recent collectibles'), findsNothing);
    expect(find.byKey(const ValueKey('home-grounded-insight')), findsNothing);

    await tester.tap(find.text('Scan first collectible'));
    await tester.pump();
    expect(scanTaps, 1);
  });

  testWidgets('layout passes at 320px with long collectible titles', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    _seedPortfolio([
      _item(
        id: 'very-long-title',
        title:
            'Extremely Long Collectible Name With Many Words That Must Wrap Cleanly In A Tiny Phone Layout',
        category: 'Trading Card',
        value: 42,
      ),
    ]);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('Ready to grow your collection?'), findsOneWidget);
    expect(find.text('Scan a collectible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout passes at normal phone width and in dark mode', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(find.text('Ready to grow your collection?'), findsOneWidget);
    expect(find.text('Scan a collectible'), findsOneWidget);
    expect(find.byType(MotionReveal), findsWidgets);
    expect(find.byType(MotionTapScale), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _homeApp({
  VoidCallback? onScanPressed,
  VoidCallback? onImportPhotoPressed,
  VoidCallback? onPortfolioPressed,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: HomePage(
        onScanPressed: onScanPressed,
        onImportPhotoPressed: onImportPhotoPressed,
        onPortfolioPressed: onPortfolioPressed,
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
    await tester.pumpAndSettle();
  }
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
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
    'valuationStatus': value > 0 ? 'market_estimated' : 'unavailable',
  };
}
