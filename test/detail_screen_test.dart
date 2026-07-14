import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'approved detail surface renders compact header, overview, and tabs',
    (tester) async {
      await _pumpDetail(tester, _authorityItem());

      expect(
        find.byKey(const ValueKey('collectible-detail-authority-header')),
        findsOneWidget,
      );
      expect(find.text('Item Overview'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-overview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-tabs')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-value-card')),
        findsOneWidget,
      );
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Collectible Details'), findsNothing);
    },
  );

  testWidgets(
    'gallery tab preserves saved image order and active preview switching',
    (tester) async {
      await _pumpDetail(tester, _authorityItem());

      await _tapTab(tester, 'gallery');

      expect(find.text('Image Gallery'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-hero-sample://front')),
        findsOneWidget,
      );

      final detailTile = find
          .byKey(const ValueKey('collectible-detail-gallery-sample://detail'))
          .last;
      await tester.ensureVisible(detailTile);
      await tester.tap(detailTile);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('collectible-detail-hero-sample://detail')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'market tab separates unavailable valuation from saved zero value',
    (tester) async {
      await _pumpDetail(
        tester,
        _authorityItem(
          estimatedValue: 0,
          valuationStatus: ValuationStatus.unavailable,
        ),
      );

      await _tapTab(tester, 'market');
      expect(find.text('Value unavailable'), findsWidgets);
      expect(find.text('No valuation saved'), findsWidgets);

      await _pumpDetail(
        tester,
        _authorityItem(
          estimatedValue: 0,
          valuationStatus: ValuationStatus.marketEstimated,
        ),
      );

      await _tapTab(tester, 'market');
      expect(find.textContaining(r'$0'), findsWidgets);
      expect(find.text('Estimated from saved market data'), findsWidgets);
    },
  );

  testWidgets(
    'detail tabs use stored metadata, AI evidence, notes, and actions',
    (tester) async {
      var deleted = false;
      await _pumpDetail(
        tester,
        _authorityItem(),
        onDelete: (_) async {
          deleted = true;
          return true;
        },
      );

      await _tapTab(tester, 'details');
      expect(find.text('Details & Info'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('PackLox Motors'), findsOneWidget);

      await _tapTab(tester, 'insights');
      expect(find.text('AI Insights'), findsOneWidget);
      expect(
        find.textContaining('Stored scan reasoning only.'),
        findsOneWidget,
      );

      await _tapTab(tester, 'notes');
      expect(
        find.byKey(const ValueKey('collectible-detail-notes-field')),
        findsOneWidget,
      );
      expect(find.text('Stored owner note.'), findsOneWidget);
      expect(find.text('Local only'), findsOneWidget);

      await _tapTab(tester, 'actions');
      expect(find.text('Actions Menu'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-primary-edit-action')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('collectible-detail-delete-action')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete collectible?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    },
  );
}

Future<void> _pumpDetail(
  WidgetTester tester,
  CollectibleItem item, {
  Future<bool> Function(String itemId)? onDelete,
}) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: CollectibleDetailPage(item: item, onDelete: onDelete),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapTab(WidgetTester tester, String tabName) async {
  final tab = find.byKey(ValueKey('collectible-detail-tab-$tabName'));
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

CollectibleItem _authorityItem({
  double estimatedValue = 245,
  ValuationStatus valuationStatus = ValuationStatus.marketEstimated,
}) {
  return CollectibleItem(
    id: 'detail-authority-item',
    title: 'PackLox Authority Coupe',
    category: 'Toy Car',
    estimatedValue: estimatedValue,
    confidence: 0.91,
    condition: 'Near mint',
    recommendation: 'Keep the complete saved capture set.',
    imagePath: 'sample://front',
    createdAt: DateTime(2026, 7, 14),
    valuationStatus: valuationStatus,
    brand: 'PackLox Motors',
    series: 'Authority Series',
    year: '2026',
    rarity: 'Limited',
    notes: 'Stored owner note.',
    aiReasoning: 'Stored scan reasoning only.',
    confidenceExplanation:
        'Saved evidence matched the front and detail photos.',
    detectionQuality: 'Clear packaging and model markings.',
    galleryImages: const [
      CollectibleImage(
        path: 'sample://front',
        role: 'front',
        source: 'sample',
        isPrimary: true,
      ),
      CollectibleImage(
        path: 'sample://detail',
        role: 'detail',
        source: 'sample',
      ),
    ],
    pricing: const PricingInfo(
      estimatedMarketValue: 245,
      lowEstimate: 220,
      highEstimate: 270,
      currency: 'USD',
      pricingSource: 'Saved provider',
      pricingConfidence: 0.82,
      lastUpdated: null,
    ),
  );
}
