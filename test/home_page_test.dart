import 'dart:convert';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'portfolio_items': jsonEncode([
        {
          'id': 'home-test-card',
          'title': 'Premium Charizard',
          'category': 'Trading Card',
          'estimatedValue': 1850,
          'confidence': 0.94,
          'condition': 'Near Mint',
          'recommendation': 'Grade it.',
          'imagePath': 'sample://sports-card',
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'home-test-coin',
          'title': 'Silver Eagle',
          'category': 'Coin',
          'estimatedValue': 300,
          'confidence': 0.74,
          'condition': 'Mint',
          'recommendation': 'Store safely.',
          'imagePath': 'sample://coin',
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        },
      ]),
    });
  });

  testWidgets('premium hero renders greeting title and tagline', (
    tester,
  ) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('Good evening'), findsOneWidget);
    expect(find.text('Your Collection Hub'), findsOneWidget);
    expect(
      find.text('Scan, value, and track your collectibles.'),
      findsOneWidget,
    );
    expect(find.byType(MotionParallax), findsOneWidget);
    final heroContainer = tester.widget<Container>(
      find.byKey(const ValueKey('home-hero-container')),
    );
    final heroDecoration = heroContainer.decoration! as BoxDecoration;
    final heroGradient = heroDecoration.gradient! as LinearGradient;
    expect(heroDecoration.gradient, AppGradients.premiumHeroGradient);
    expect(heroGradient.begin, Alignment.topCenter);
    expect(heroGradient.end, Alignment.bottomCenter);
    expect(heroGradient.stops, [0.0, 0.18, 0.55, 1.0]);
    expect(heroGradient.colors, [
      const Color(0xFF0D1117),
      const Color(0xFF1A2A6C),
      const Color(0xFF3A7BD5),
      const Color(0xFF00D2FF),
    ]);
    expect(heroContainer.constraints?.minHeight, 240);
    expect(heroContainer.child, isA<SafeArea>());
    final heroPadding = tester.widget<Padding>(
      find
          .descendant(
            of: find.byKey(const ValueKey('home-hero-container')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Padding &&
                  widget.padding ==
                      const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
            ),
          )
          .first,
    );
    expect(
      heroPadding.padding,
      const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-hero-container')),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == AppSpacing.xs,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-hero-container')),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == AppSpacing.sm,
        ),
      ),
      findsNWidgets(2),
    );

    final heroMotion = tester.widget<MotionElasticHero>(
      find.byKey(const ValueKey('home-hero-motion')),
    );
    expect(heroMotion.baseHeight, 240);
    expect(
      tester.getSize(find.byKey(const ValueKey('home-hero-motion'))).height,
      greaterThanOrEqualTo(240),
    );
    expect(tester.getRect(find.text('Good evening')).height, greaterThan(0));
    expect(
      tester.getRect(find.text('Your Collection Hub')).height,
      greaterThan(0),
    );
    expect(
      tester
          .getRect(find.text('Scan, value, and track your collectibles.'))
          .height,
      greaterThan(0),
    );
    final title = tester.widget<Text>(find.text('Your Collection Hub'));
    expect(title.style?.color, Colors.white);
    final greeting = tester.widget<Text>(find.text('Good evening'));
    expect(greeting.style?.color, Colors.white.withValues(alpha: 0.86));
    final tagline = tester.widget<Text>(
      find.text('Scan, value, and track your collectibles.'),
    );
    expect(tagline.style?.color, Colors.white.withValues(alpha: 0.78));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stats row shows portfolio values', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-stats-surface')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == AppSpacing.lg,
      ),
      findsWidgets,
    );
    expect(find.text('Items'), findsWidgets);
    expect(find.text('2 items'), findsWidgets);
    expect(find.text('Total value'), findsOneWidget);
    expect(find.text(r'$2,150'), findsWidgets);
    expect(find.text('Last scan'), findsOneWidget);
  });

  testWidgets('quick actions are visible and tappable', (tester) async {
    var scanTaps = 0;
    var importTaps = 0;
    var portfolioTaps = 0;
    await tester.pumpWidget(
      _homeApp(
        onScanPressed: () => scanTaps++,
        onImportPhotoPressed: () => importTaps++,
        onPortfolioPressed: () => portfolioTaps++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Actions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-quick-action-Scan')),
      findsOneWidget,
    );
    expect(find.text('Import'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-quick-action-Portfolio')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-quick-action-PI')), findsOneWidget);
    expect(find.text('PI (Soon)'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('home-quick-action-Scan')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-quick-action-Scan')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-quick-action-Import Photo')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('home-quick-action-Import Photo')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-quick-action-Portfolio')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-quick-action-Portfolio')));

    expect(scanTaps, 1);
    expect(importTaps, 1);
    expect(portfolioTaps, 1);
  });

  testWidgets('portfolio overview and recent activity render', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const PageStorageKey<String>('home-scroll-position')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(find.text('Portfolio Overview'), findsOneWidget);
    expect(find.byType(Divider), findsWidgets);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('2 types'), findsOneWidget);
    expect(find.text('Top asset'), findsOneWidget);
    expect(find.text('Premium Charizard'), findsWidgets);

    await tester.drag(
      find.byKey(const PageStorageKey<String>('home-scroll-position')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent Activity'), findsOneWidget);
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
    expect(recentThumbnail.size, 52);
    final recentTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('home-recent-home-test-card')),
        matching: find.text('Premium Charizard'),
      ),
    );
    expect(recentTitle.maxLines, 2);
    expect(recentTitle.overflow, TextOverflow.ellipsis);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-recent-home-test-card')),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 48,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('AI insights use premium card hierarchy', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const PageStorageKey<String>('home-scroll-position')),
      const Offset(0, -1400),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Insights'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-ai-insights-glow')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-ai-insights-icon-motion')),
      findsOneWidget,
    );
    expect(find.textContaining('Portfolio Confidence'), findsOneWidget);
  });

  testWidgets('home page is responsive at 320px', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('Your Collection Hub'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('motion wrappers are present', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.byType(MotionReveal), findsWidgets);
    expect(find.byType(MotionTapScale), findsWidgets);
  });
}

Widget _homeApp({
  VoidCallback? onScanPressed,
  VoidCallback? onImportPhotoPressed,
  VoidCallback? onPortfolioPressed,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: HomePage(
        onScanPressed: onScanPressed,
        onImportPhotoPressed: onImportPhotoPressed,
        onPortfolioPressed: onPortfolioPressed,
      ),
    ),
  );
}
