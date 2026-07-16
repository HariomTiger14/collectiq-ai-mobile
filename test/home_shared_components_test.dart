import 'dart:io';

import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  testWidgets('HomeSurface uses dark Home tokens', (tester) async {
    await tester.pumpHomeComponent(const HomeSurface(child: Text('Surface')));

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(HomeSurface),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, HomeTokens.surfaceRaised);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(HomeTokens.cardRadius),
    );
  });

  testWidgets('HomeSectionHeader renders title and action', (tester) async {
    var tapped = 0;
    await tester.pumpHomeComponent(
      HomeSectionHeader(
        title: 'Collection',
        actionLabel: 'View all',
        onAction: () => tapped++,
      ),
    );

    expect(find.text('Collection'), findsOneWidget);
    await tester.tap(find.text('View all'));
    expect(tapped, 1);
  });

  testWidgets('CollectionStrip renders real item count', (tester) async {
    await tester.pumpHomeComponent(
      HomeCollectionStrip(
        title: 'Recent scans',
        itemCount: 2,
        items: [_stripItem('one'), _stripItem('two')],
      ),
    );

    expect(find.text('2 items'), findsOneWidget);
  });

  testWidgets('CollectionStrip renders real overflow count', (tester) async {
    await tester.pumpHomeComponent(
      HomeCollectionStrip(
        title: 'Recent scans',
        itemCount: 6,
        maxVisibleItems: 4,
        items: [
          _stripItem('one'),
          _stripItem('two'),
          _stripItem('three'),
          _stripItem('four'),
        ],
      ),
    );

    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('ValueMetricCard distinguishes unavailable from zero', (
    tester,
  ) async {
    await tester.pumpHomeComponent(
      const Column(
        children: [
          HomeValueMetricCard(
            label: 'Total Value',
            value: 'AUD 0',
            isUnavailable: true,
          ),
          HomeValueMetricCard(label: 'Scans', value: '0'),
        ],
      ),
    );

    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('ValueMetricCard hides trend without actual history', (
    tester,
  ) async {
    await tester.pumpHomeComponent(
      const HomeValueMetricCard(
        label: 'Total Value',
        value: 'AUD 10',
        trendValues: [10],
      ),
    );

    expect(find.byKey(const ValueKey('home-value-metric-trend')), findsNothing);
  });

  testWidgets('Category Cards exposes trading card semantics', (tester) async {
    await tester.pumpHomeComponent(HomeCategoryTile.cards());
    expect(
      find.bySemanticsLabel('Popular category Cards, trading cards'),
      findsOneWidget,
    );
  });

  testWidgets('Category Coins is collectible, not currency semantics', (
    tester,
  ) async {
    await tester.pumpHomeComponent(HomeCategoryTile.coins());
    expect(
      find.bySemanticsLabel(
        'Popular category Coins, collectible coins and medallions',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.attach_money), findsNothing);
  });

  testWidgets('Category Figures is figurine, not vehicle semantics', (
    tester,
  ) async {
    await tester.pumpHomeComponent(HomeCategoryTile.figures());
    expect(
      find.bySemanticsLabel(
        'Popular category Figures, figurines and action figures',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.directions_car_outlined), findsNothing);
  });

  testWidgets('More icon uses grid semantics', (tester) async {
    await tester.pumpHomeComponent(HomeCategoryTile.more());
    expect(
      find.bySemanticsLabel('Popular category More, more categories grid'),
      findsOneWidget,
    );
    final moreIcon = tester.widget<SvgPicture>(
      find.byKey(const ValueKey('home-popular-category-more-icon')),
    );
    expect(
      (moreIcon.bytesLoader as SvgAssetLoader).assetName,
      PackLoxAssets.categoryMore,
    );
  });

  testWidgets('Popular category icons use authority color separation', (
    tester,
  ) async {
    await tester.pumpHomeComponent(HomeCategoryGrid.popular());

    final cardsIcon = tester.widget<SvgPicture>(
      find.byKey(const ValueKey('home-popular-category-cards-icon')),
    );
    final coinsIcon = tester.widget<SvgPicture>(
      find.byKey(const ValueKey('home-popular-category-coins-icon')),
    );
    final figuresIcon = tester.widget<SvgPicture>(
      find.byKey(const ValueKey('home-popular-category-figures-icon')),
    );
    final moreIcon = tester.widget<SvgPicture>(
      find.byKey(const ValueKey('home-popular-category-more-icon')),
    );

    expect(
      (cardsIcon.bytesLoader as SvgAssetLoader).assetName,
      PackLoxAssets.categoryCards,
    );
    expect(
      (coinsIcon.bytesLoader as SvgAssetLoader).assetName,
      PackLoxAssets.categoryCoins,
    );
    expect(
      (figuresIcon.bytesLoader as SvgAssetLoader).assetName,
      PackLoxAssets.categoryFigures,
    );
    expect(
      (moreIcon.bytesLoader as SvgAssetLoader).assetName,
      PackLoxAssets.categoryMore,
    );
  });

  testWidgets('Category grid wraps responsively', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpHomeComponent(HomeCategoryGrid.popular());

    final cardsTop = tester.getTopLeft(find.text('Cards')).dy;
    final figuresTop = tester.getTopLeft(find.text('Figures')).dy;
    expect(figuresTop, greaterThan(cardsTop));
  });

  testWidgets('Quick action callback fires once', (tester) async {
    var tapped = 0;
    await tester.pumpHomeComponent(
      HomeQuickActionTile(
        action: HomeQuickAction(
          key: 'scan',
          icon: Icons.photo_camera_outlined,
          label: 'Scan',
          semanticLabel: 'Scan a collectible',
          onTap: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Scan a collectible'));
    expect(tapped, 1);
  });

  testWidgets('Disabled quick action does not invoke callback', (tester) async {
    await tester.pumpHomeComponent(
      const HomeQuickActionTile(
        action: HomeQuickAction(
          key: 'search',
          icon: Icons.search_outlined,
          label: 'Search',
          semanticLabel: 'Search collection',
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Search collection'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recent item renders missing-image fallback', (tester) async {
    await tester.pumpHomeComponent(_recentItem(imagePath: ''));

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  testWidgets('Recent item keeps unavailable value unavailable', (
    tester,
  ) async {
    await tester.pumpHomeComponent(_recentItem(valueUnavailable: true));

    expect(find.text('Value unavailable'), findsOneWidget);
  });

  testWidgets('320 dp layout does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpHomeComponent(
      HomeStateContainer(
        sections: [
          HomeSection(
            child: HomeSectionSurface(
              title: 'Actions',
              child: HomeQuickActionGrid(
                actions: [
                  _action('scan', 'Scan'),
                  _action('import', 'Import'),
                  _action('portfolio', 'Portfolio'),
                ],
              ),
            ),
          ),
          HomeSection(child: HomeCategoryGrid.popular()),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Large text grows without clipping exceptions', (tester) async {
    await tester.pumpHomeComponent(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: HomeStateContainer(
          sections: [
            HomeSection(
              child: HomeSectionSurface(
                title: 'Very Long Home Section Heading',
                child: HomeCategoryGrid.popular(),
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Dark theme has no white surface leakage', (tester) async {
    await tester.pumpHomeComponent(
      const HomeSurface(child: HomeQuickActionGrid(actions: [])),
    );

    final containers = tester.widgetList<Container>(find.byType(Container));
    final colors = containers
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.color);
    expect(colors, isNot(contains(Colors.white)));
  });

  testWidgets('StateContainer includes bottom clearance', (tester) async {
    await tester.pumpHomeComponent(
      const HomeStateContainer(sections: [HomeSection(child: Text('Home'))]),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 80,
      ),
      findsOneWidget,
    );
  });

  test(
    'shared components have no direct provider or repository dependency',
    () {
      final source = File(
        'lib/features/home/presentation/widgets/home_shared_components.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('flutter_riverpod')));
      expect(source, isNot(contains('Provider')));
      expect(source, isNot(contains('Repository')));
    },
  );
}

extension on WidgetTester {
  Future<void> pumpHomeComponent(Widget child) {
    return pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          backgroundColor: HomeTokens.background,
          body: Center(child: child),
        ),
      ),
    );
  }
}

HomeCollectionStripItem _stripItem(String id) {
  return HomeCollectionStripItem(id: id, title: 'Item $id', imagePath: '');
}

HomeQuickAction _action(String key, String label) {
  return HomeQuickAction(
    key: key,
    icon: Icons.photo_camera_outlined,
    label: label,
    semanticLabel: label,
  );
}

HomeRecentItemCard _recentItem({
  String imagePath = '',
  bool valueUnavailable = false,
}) {
  return HomeRecentItemCard(
    id: 'recent',
    title: 'Charizard',
    category: 'Cards',
    imagePath: imagePath,
    valueLabel: valueUnavailable ? 'Value unavailable' : 'AUD 120',
    valueUnavailable: valueUnavailable,
    addedLabel: 'Added today',
  );
}
