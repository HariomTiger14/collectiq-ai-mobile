import 'dart:convert';

import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_entry_tile.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_hero.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _seedPortfolio(_portfolioItems());
  });

  testWidgets('renders approved Header Hero Button and Entry Tile composition', (
    tester,
  ) async {
    var scanTaps = 0;

    await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
    await tester.pumpAndSettle();

    expect(find.byType(PackLoxHeader), findsOneWidget);
    expect(find.text('Your collection'), findsOneWidget);
    expect(find.text('Collector'), findsOneWidget);
    expect(find.byType(PackLoxHero), findsOneWidget);
    expect(find.text('Your collection, at a glance'), findsOneWidget);
    expect(find.byType(PackLoxEntryTile), findsNWidgets(2));
    expect(find.byType(PackLoxButton), findsOneWidget);
    expect(find.widgetWithText(PackLoxButton, 'Scan a collectible'), findsOneWidget);
    expect(find.byType(MotionElasticHero), findsNothing);
    expect(find.byType(MotionParallax), findsNothing);
    expect(find.byType(MotionReveal), findsNothing);

    await tester.tap(find.widgetWithText(PackLoxButton, 'Scan a collectible'));
    await tester.pump();

    expect(scanTaps, 1);
  });

  testWidgets('loaded data displays real collection values and recent content', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('\$2,275'), findsOneWidget);
    expect(
      find.text('You have 5 collectibles worth an estimated \$2,275.'),
      findsOneWidget,
    );

    await _scrollUntilVisible(tester, find.text('Collection snapshot'));

    expect(find.text('\$2,275 estimated value'), findsOneWidget);
    expect(find.text('5 collectibles'), findsOneWidget);
    expect(find.text('3 categories'), findsOneWidget);
    expect(find.textContaining('Last scan'), findsOneWidget);
    expect(find.text('Top collectible'), findsOneWidget);
    expect(find.text('Premium Charizard'), findsWidgets);
    expect(find.text('Recent collectibles'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-recent-home-test-card')), findsOneWidget);
  });

  testWidgets('unavailable values are not fabricated as zero', (tester) async {
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
    expect(find.text('\$0'), findsNothing);
    expect(find.text('\$0 estimated value'), findsNothing);
    expect(find.text('Latest collectible'), findsOneWidget);

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-grounded-insight')),
    );
    expect(find.text('1 collectible still needs a valuation'), findsOneWidget);
  });

  testWidgets('zero-value market estimates remain distinct from unavailable', (
    tester,
  ) async {
    _seedPortfolio([
      _item(
        id: 'zero-market',
        title: 'Zero Dollar Market Item',
        category: 'Coin',
        value: 0,
        valuationStatus: 'market_estimated',
      ),
    ]);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('\$0'), findsOneWidget);
    await _scrollUntilVisible(tester, find.text('Collection snapshot'));
    expect(find.text('\$0 estimated value'), findsOneWidget);
    expect(find.text('Value unavailable'), findsNothing);
    expect(find.byKey(const ValueKey('home-grounded-insight')), findsNothing);
  });

  testWidgets('empty collection renders honest empty state and no fake metrics', (
    tester,
  ) async {
    _seedPortfolio(const []);
    var scanTaps = 0;

    await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
    await tester.pumpAndSettle();

    expect(find.text('Your collection starts here'), findsOneWidget);
    expect(
      find.text('Scan your first collectible and start building your collection.'),
      findsOneWidget,
    );
    expect(find.text('No collectibles saved yet'), findsOneWidget);
    expect(find.text('Recent collectibles'), findsNothing);
    expect(find.byKey(const ValueKey('home-grounded-insight')), findsNothing);

    await _scrollUntilVisible(tester, find.text('Scan first collectible'));
    await tester.tap(find.text('Scan first collectible'));
    await tester.pump();

    expect(scanTaps, 1);
  });

  testWidgets('partial-value data preserves valid collection content', (
    tester,
  ) async {
    _seedPortfolio([
      _item(id: 'valued', title: 'Valued Card', category: 'Trading Card', value: 50),
      _item(id: 'missing', title: 'Unvalued Coin', category: 'Coin', value: 0),
    ]);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();
    await _scrollUntilVisible(tester, find.text('Collection snapshot'));

    expect(find.text('\$50 estimated value'), findsOneWidget);
    expect(find.text('2 collectibles'), findsOneWidget);
    expect(find.text('Valued Card'), findsWidgets);
    expect(find.text('Unvalued Coin'), findsWidgets);

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-grounded-insight')),
    );
    expect(find.text('1 collectible still needs a valuation'), findsOneWidget);
  });

  testWidgets('quick actions use existing callbacks and no unsupported actions', (
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
    expect(find.byKey(const ValueKey('home-secondary-portfolio')), findsOneWidget);
    expect(find.text('Import photo'), findsOneWidget);
    expect(find.text('Open portfolio'), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
    expect(find.text('Trends'), findsNothing);
    expect(find.text('Notifications'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-secondary-import')));
    await tester.tap(find.byKey(const ValueKey('home-secondary-portfolio')));
    await tester.pump();

    expect(importTaps, 1);
    expect(portfolioTaps, 1);
  });

  testWidgets('detail rows open the existing collectible detail route', (
    tester,
  ) async {
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

  testWidgets('Home is reachable inside frozen App Shell and preserves handoffs', (
    tester,
  ) async {
    await tester.pumpShell();

    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-destination-home')), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    await tester.tap(find.widgetWithText(PackLoxButton, 'Scan a collectible'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-destination-scan')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey<String>('home-scroll-position')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-secondary-portfolio')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-destination-portfolio')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell-destination-home')), findsOneWidget);
    expect(find.text('Your collection, at a glance'), findsOneWidget);
  });

  testWidgets('light dark large text narrow width and reduced motion render', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _homeApp(
        themeMode: ThemeMode.dark,
        textScale: 1.8,
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PackLoxHero), findsOneWidget);
    expect(find.text('Scan a collectible'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_homeApp(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    expect(find.byType(PackLoxHero), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsupported loading retry and error UI are not invented', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(find.textContaining('Unable to load'), findsNothing);
    expect(find.textContaining('Loading'), findsNothing);
  });

  testWidgets('recent rows remain compact and use existing thumbnails', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-recent-home-test-card')),
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
  });

  testWidgets('collection snapshot and recent surfaces use PackLox tokens in light mode', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-section-collection-snapshot')),
    );
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-recent-home-test-card')),
    );

    expect(
      _containerColor(tester, const ValueKey('home-section-collection-snapshot')),
      _expectedPackLoxRaisedSurface(Brightness.light),
    );
    expect(
      _containerColor(tester, const ValueKey('home-recent-home-test-card')),
      _expectedPackLoxRaisedSurface(Brightness.light),
    );
  });

  testWidgets('collection snapshot and recent surfaces use PackLox tokens in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-section-collection-snapshot')),
    );
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('home-recent-home-test-card')),
    );

    expect(
      _containerColor(tester, const ValueKey('home-section-collection-snapshot')),
      _expectedPackLoxRaisedSurface(Brightness.dark),
    );
    expect(
      _containerColor(tester, const ValueKey('home-recent-home-test-card')),
      _expectedPackLoxRaisedSurface(Brightness.dark),
    );
  });
}

Widget _homeApp({
  VoidCallback? onScanPressed,
  VoidCallback? onImportPhotoPressed,
  VoidCallback? onPortfolioPressed,
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          );
          return MediaQuery(
            data: mediaQuery,
            child: HomePage(
              onScanPressed: onScanPressed,
              onImportPhotoPressed: onImportPhotoPressed,
              onPortfolioPressed: onPortfolioPressed,
            ),
          );
        },
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

Color? _containerColor(WidgetTester tester, ValueKey<String> key) {
  final container = tester.widget<Container>(find.byKey(key));
  final decoration = container.decoration as BoxDecoration?;
  return decoration?.color;
}

Color _expectedPackLoxRaisedSurface(Brightness brightness) {
  return PackLoxTokens.surfaceRaised.withValues(
    alpha: brightness == Brightness.dark ? 0.94 : 0.90,
  );
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

extension _ShellPump on WidgetTester {
  Future<void> pumpShell() async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            const _ImmediateOnboardingRepository(completed: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const AppShell(),
        ),
      ),
    );
    await pumpAndSettle();
  }
}

class _ImmediateOnboardingRepository implements OnboardingRepository {
  const _ImmediateOnboardingRepository({required this.completed});

  final bool completed;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}
}
