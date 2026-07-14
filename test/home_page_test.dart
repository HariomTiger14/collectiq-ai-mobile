import 'dart:convert';

import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
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

  testWidgets(
    'renders approved empty Home structure without legacy blue Hero',
    (tester) async {
      _seedPortfolio(const []);
      var scanTaps = 0;

      await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
      await tester.pumpAndSettle();

      expect(find.byType(PackLoxHeader), findsOneWidget);
      expect(find.text('Your collection'), findsOneWidget);
      expect(find.text('Collector'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-empty-authority-card')),
        findsOneWidget,
      );
      expect(find.text('Your collection is waiting'), findsOneWidget);
      expect(find.text('Scan your first item to get started.'), findsOneWidget);
      expect(
        find.widgetWithText(PackLoxButton, 'Scan a Collectible'),
        findsOneWidget,
      );
      expect(find.text('Your collection starts here'), findsNothing);
      expect(find.text('Start your collection'), findsNothing);
      expect(find.text('Try a Sample Scan'), findsNothing);
      expect(find.text('Popular Categories'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-popular-category-cards')),
        findsOneWidget,
      );
      expect(find.byType(MotionElasticHero), findsNothing);
      expect(find.byType(MotionParallax), findsNothing);
      expect(find.byType(MotionReveal), findsNothing);

      await tester.tap(
        find.widgetWithText(PackLoxButton, 'Scan a Collectible'),
      );
      await tester.pump();

      expect(scanTaps, 1);
    },
  );

  testWidgets(
    'loaded data displays real collection values and recent content',
    (tester) async {
      await tester.pumpWidget(_homeApp());
      await tester.pumpAndSettle();

      expect(find.text('Collection snapshot'), findsOneWidget);
      expect(find.text('\$2,275 estimated value'), findsOneWidget);
      expect(find.text('5 collectibles'), findsOneWidget);
      expect(find.text('3 categories'), findsOneWidget);
      expect(find.textContaining('Last scan'), findsOneWidget);
      expect(find.text('Top collectible'), findsOneWidget);
      expect(find.text('Premium Charizard'), findsWidgets);
      expect(find.text('Recent collectibles'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-recent-home-test-card')),
        findsOneWidget,
      );
    },
  );

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
    await _scrollUntilVisible(tester, find.text('Collection status'));

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

    await _scrollUntilVisible(tester, find.text('Collection snapshot'));
    expect(find.text('\$0 estimated value'), findsOneWidget);
    expect(find.text('Value unavailable'), findsNothing);
    expect(find.byKey(const ValueKey('home-grounded-insight')), findsNothing);
  });

  testWidgets(
    'empty collection renders honest empty state and no fake metrics',
    (tester) async {
      _seedPortfolio(const []);
      var scanTaps = 0;

      await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('home-empty-authority-card')),
        findsOneWidget,
      );
      expect(find.text('Your collection is waiting'), findsOneWidget);
      expect(find.text('Popular Categories'), findsOneWidget);
      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Coins'), findsOneWidget);
      expect(find.text('Figures'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Est. value'), findsOneWidget);
      expect(find.text('Avg. condition'), findsOneWidget);
      expect(find.text('Scans'), findsOneWidget);
      expect(
        find.text('Value, condition, and saved history will appear here.'),
        findsOneWidget,
      );
      expect(find.text('Scan first collectible'), findsNothing);
      expect(find.text('Recent collectibles'), findsNothing);
      expect(find.byKey(const ValueKey('home-grounded-insight')), findsNothing);

      await tester.tap(
        find.widgetWithText(PackLoxButton, 'Scan a Collectible'),
      );
      await tester.pump();

      expect(scanTaps, 1);
    },
  );

  testWidgets('partial-value data preserves valid collection content', (
    tester,
  ) async {
    _seedPortfolio([
      _item(
        id: 'valued',
        title: 'Valued Card',
        category: 'Trading Card',
        value: 50,
      ),
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

  testWidgets(
    'compact actions use existing callbacks and no unsupported actions',
    (tester) async {
      var importTaps = 0;
      var portfolioTaps = 0;

      await tester.pumpWidget(
        _homeApp(
          onImportPhotoPressed: () => importTaps++,
          onPortfolioPressed: () => portfolioTaps++,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('home-quick-action-import')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-quick-action-portfolio')),
        findsOneWidget,
      );
      expect(find.text('Import'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);
      expect(find.text('Trends'), findsNothing);
      expect(find.text('Notifications'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('home-quick-action-import')));
      await tester.tap(
        find.byKey(const ValueKey('home-quick-action-portfolio')),
      );
      await tester.pump();

      expect(importTaps, 1);
      expect(portfolioTaps, 1);
    },
  );

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

  testWidgets(
    'Home is reachable inside frozen App Shell and preserves handoffs',
    (tester) async {
      await tester.pumpShell();

      expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('shell-destination-home')),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('home-quick-action-scan')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('shell-destination-scan')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const PageStorageKey<String>('home-scroll-position')),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('home-quick-action-portfolio')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('shell-destination-portfolio')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('shell-destination-home')),
        findsOneWidget,
      );
      expect(find.text('Collection snapshot'), findsOneWidget);
    },
  );

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

    expect(find.byType(PackLoxHeader), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-section-collection-snapshot')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_homeApp(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    expect(find.byType(PackLoxHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first viewport density follows owner v1 Home authority ratios', (
    tester,
  ) async {
    _seedPortfolio(const []);
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    const viewportHeight = 1000.0;
    final headerTop = tester.getTopLeft(find.byType(PackLoxHeader)).dy;
    final emptyRect = tester.getRect(
      find.byKey(const ValueKey('home-empty-authority-card')),
    );
    final primaryScanRect = tester.getRect(
      find.byKey(const ValueKey('home-primary-scan')),
    );
    final statusRect = tester.getRect(
      find.byKey(const ValueKey('home-section-collection-status')),
    );
    final categoriesRect = tester.getRect(
      find.byKey(const ValueKey('home-section-popular-categories')),
    );
    final quickActionsRect = tester.getRect(
      find.byKey(const ValueKey('home-section-quick-actions')),
    );
    final cardsRect = tester.getRect(
      find.byKey(const ValueKey('home-popular-category-cards')),
    );
    final moreRect = tester.getRect(
      find.byKey(const ValueKey('home-popular-category-more')),
    );
    final scanActionRect = tester.getRect(
      find.byKey(const ValueKey('home-quick-action-scan')),
    );
    final importActionRect = tester.getRect(
      find.byKey(const ValueKey('home-quick-action-import')),
    );
    final portfolioActionRect = tester.getRect(
      find.byKey(const ValueKey('home-quick-action-portfolio')),
    );
    final statusTop = tester.getTopLeft(find.text('Collection status')).dy;
    final categoriesTop = tester.getTopLeft(find.text('Popular Categories')).dy;
    final actionsTop = tester.getTopLeft(find.text('Quick actions')).dy;

    expect(headerTop, lessThan(emptyRect.top));
    expect(emptyRect.top, lessThan(statusTop));
    expect(statusTop, lessThan(categoriesTop));
    expect(categoriesTop, lessThan(actionsTop));
    expect(emptyRect.height / viewportHeight, inInclusiveRange(0.12, 0.19));
    expect(emptyRect.height / emptyRect.width, inInclusiveRange(0.34, 0.48));
    expect(
      primaryScanRect.left,
      greaterThan(emptyRect.left + emptyRect.width * 0.34),
    );
    expect(primaryScanRect.height, inInclusiveRange(40, 52));
    expect(
      primaryScanRect.width / emptyRect.width,
      inInclusiveRange(0.44, 0.64),
    );
    expect(statusRect.height / viewportHeight, inInclusiveRange(0.15, 0.22));
    expect(
      categoriesRect.height / viewportHeight,
      inInclusiveRange(0.13, 0.20),
    );
    expect(
      quickActionsRect.height / viewportHeight,
      inInclusiveRange(0.13, 0.20),
    );
    expect(cardsRect.height, inInclusiveRange(70, 92));
    expect(moreRect.left, greaterThan(cardsRect.left));
    expect(scanActionRect.height, inInclusiveRange(58, 74));
    expect(importActionRect.height, inInclusiveRange(58, 74));
    expect(portfolioActionRect.height, inInclusiveRange(58, 74));
    expect(scanActionRect.top, greaterThan(actionsTop));
    expect(quickActionsRect.bottom, lessThan(viewportHeight));
  });

  testWidgets('rapid Scan taps trigger one navigation request', (tester) async {
    _seedPortfolio(const []);
    var scanTaps = 0;

    await tester.pumpWidget(_homeApp(onScanPressed: () => scanTaps++));
    await tester.pumpAndSettle();

    final scan = find.widgetWithText(PackLoxButton, 'Scan a Collectible');
    await tester.tap(scan);
    await tester.tap(scan);
    await tester.pump();

    expect(scanTaps, 1);
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

  testWidgets(
    'collection snapshot and recent surfaces use approved dark Home tokens when system is light',
    (tester) async {
      await tester.pumpWidget(_homeApp(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-section-collection-snapshot')),
      );
      expect(
        _containerColor(
          tester,
          const ValueKey('home-section-collection-snapshot'),
        ),
        _expectedPackLoxRaisedSurface(Brightness.dark),
      );

      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-recent-home-test-card')),
      );
      expect(
        _containerColor(tester, const ValueKey('home-recent-home-test-card')),
        _expectedPackLoxRaisedSurface(Brightness.dark),
      );
    },
  );

  testWidgets(
    'collection snapshot and recent surfaces use PackLox tokens in dark mode',
    (tester) async {
      await tester.pumpWidget(_homeApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-section-collection-snapshot')),
      );
      expect(
        _containerColor(
          tester,
          const ValueKey('home-section-collection-snapshot'),
        ),
        _expectedPackLoxRaisedSurface(Brightness.dark),
      );

      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('home-recent-home-test-card')),
      );
      expect(
        _containerColor(tester, const ValueKey('home-recent-home-test-card')),
        _expectedPackLoxRaisedSurface(Brightness.dark),
      );
    },
  );
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
