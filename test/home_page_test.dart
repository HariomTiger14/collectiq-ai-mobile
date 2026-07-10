import 'dart:convert';

import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
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
    expect(find.byType(MotionAmbientGradient), findsOneWidget);
  });

  testWidgets('stats row shows portfolio values', (tester) async {
    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-stats-surface')), findsOneWidget);
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
    expect(
      find.byKey(const ValueKey('home-quick-action-Import Photo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-quick-action-Portfolio')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-quick-action-PI')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-quick-action-Scan')));
    await tester.tap(
      find.byKey(const ValueKey('home-quick-action-Import Photo')),
    );
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
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('2 types'), findsOneWidget);
    expect(find.text('Top asset'), findsOneWidget);
    expect(find.text('Premium Charizard'), findsWidgets);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-recent-home-test-card')),
      findsOneWidget,
    );
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
