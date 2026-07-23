import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/qa_capture_app.dart';
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
    'approved detail surface renders compact header and inline sections',
    (tester) async {
      await _pumpDetail(tester, _authorityItem());

      expect(
        find.byKey(const ValueKey('collectible-detail-authority-header')),
        findsOneWidget,
      );
      expect(find.text('Portfolio Detail'), findsOneWidget);
      expect(find.text('Saved collectible'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-overview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-value-card')),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-valued-state')),
        findsOneWidget,
      );
      expect(find.text('Valuation ready'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-inline-content')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-tabs')),
        findsNothing,
      );
      await _revealText(tester, 'Market & Value');
      expect(find.text('Market & Value'), findsOneWidget);
      expect(find.text('Collectible Details'), findsNothing);
    },
  );

  testWidgets(
    'inline gallery preserves saved image order and active preview switching',
    (tester) async {
      await _pumpDetail(tester, _authorityItem());

      await _revealText(tester, 'Image Gallery');

      expect(find.text('Image Gallery'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-gallery-filmstrip')),
        findsOneWidget,
      );

      final detailTile = find
          .byKey(const ValueKey('collectible-detail-gallery-sample://detail'))
          .last;
      await tester.ensureVisible(detailTile);
      await tester.pumpAndSettle();
      await tester.tap(detailTile);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 900));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('collectible-detail-hero-sample://detail')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'inline market section separates unavailable valuation from saved zero value',
    (tester) async {
      await _pumpDetail(
        tester,
        _authorityItem(
          estimatedValue: 0,
          valuationStatus: ValuationStatus.unavailable,
        ),
      );

      await _revealText(tester, 'Market & Value');
      expect(find.text('Value unavailable'), findsWidgets);
      expect(find.text('No valuation saved'), findsWidgets);

      await _pumpDetail(
        tester,
        _authorityItem(
          estimatedValue: 0,
          valuationStatus: ValuationStatus.marketEstimated,
        ),
      );

      await _revealText(tester, 'Market & Value');
      expect(find.textContaining(r'$0'), findsWidgets);
      expect(find.text('Estimated from saved market data'), findsWidgets);
    },
  );

  testWidgets('pending detail state keeps valuation and image fallbacks clear', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _authorityItem(
        estimatedValue: 0,
        valuationStatus: ValuationStatus.noMarketMatch,
        imagePath: '',
        galleryImages: const [],
      ),
    );

    expect(
      find.byKey(const ValueKey('collectible-detail-pending-valuation-state')),
      findsOneWidget,
    );
    expect(find.text('Valuation pending'), findsWidgets);
    expect(find.text('Value unavailable'), findsWidgets);
    expect(
      find.byKey(const ValueKey('collectible-detail-missing-image-fallback')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'collectible-detail-state-art-${PackLoxAssets.portfolioDetailPendingValuation}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fallback art distinguishes valued and missing image states', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _authorityItem(
        valuationStatus: ValuationStatus.marketEstimated,
        imagePath: '',
        galleryImages: const [],
      ),
    );

    expect(
      find.byKey(
        const ValueKey(
          'collectible-detail-state-art-${PackLoxAssets.portfolioDetailValuedItem}',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Valuation ready'), findsWidgets);

    await _pumpDetail(
      tester,
      _authorityItem(
        estimatedValue: 0,
        valuationStatus: ValuationStatus.unavailable,
        imagePath: '',
        galleryImages: const [],
      ),
    );

    expect(
      find.byKey(
        const ValueKey(
          'collectible-detail-state-art-${PackLoxAssets.portfolioDetailMissingImage}',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collectible-detail-unvalued-state')),
      findsOneWidget,
    );
    expect(find.text('Image needed'), findsOneWidget);
    expect(find.text('No valuation saved'), findsWidgets);
  });

  testWidgets('QA capture exposes Portfolio Detail visual states', (
    tester,
  ) async {
    for (final screen in [
      'portfolio_detail_valued',
      'portfolio_detail_pending',
      'portfolio_detail_missing_image',
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PackLoxQaCaptureScreen(screen: screen, scroll: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Portfolio Detail'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-overview')),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'inline detail page exposes metadata, AI evidence, notes, and actions',
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

      await _revealText(tester, 'Details & Info');
      expect(find.text('Details & Info'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('PackLox Motors'), findsOneWidget);

      await _revealText(tester, 'AI Insights');
      expect(find.text('AI Insights'), findsOneWidget);
      expect(
        find.textContaining('Stored scan reasoning only.'),
        findsOneWidget,
      );

      await _revealText(tester, 'Stored owner note.');
      expect(
        find.byKey(const ValueKey('collectible-detail-notes-field')),
        findsOneWidget,
      );
      expect(find.text('Stored owner note.'), findsOneWidget);
      expect(find.text('Local only'), findsOneWidget);

      await _revealText(tester, 'Actions Menu');
      expect(find.text('Actions Menu'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-primary-edit-action')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('collectible-detail-delete-action')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remove collectible?'), findsOneWidget);
      expect(find.text('PackLox Authority Coupe'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('collectible-delete-confirm-action')),
      );
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    },
  );

  testWidgets('delete confirmation cancel keeps item', (tester) async {
    var deleted = false;
    await _pumpDetail(
      tester,
      _authorityItem(),
      onDelete: (_) async {
        deleted = true;
        return true;
      },
    );

    await _revealText(tester, 'Actions Menu');
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('collectible-delete-confirmation-sheet')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('collectible-delete-cancel-action')),
    );
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(
      find.byKey(const ValueKey('collectible-delete-confirmation-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
      findsOneWidget,
    );
  });

  testWidgets('delete confirmation dismiss keeps item', (tester) async {
    var deleted = false;
    await _pumpDetail(
      tester,
      _authorityItem(),
      onDelete: (_) async {
        deleted = true;
        return true;
      },
    );

    await _revealText(tester, 'Actions Menu');
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(
      find.byKey(const ValueKey('collectible-delete-confirmation-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
      findsOneWidget,
    );
  });

  testWidgets('opening edit flow from Detail shows supported fields', (
    tester,
  ) async {
    await _pumpDetail(tester, _authorityItem());

    await _openEditSheet(tester);

    expect(find.text('Edit item details'), findsOneWidget);
    expect(find.text('PackLox Authority Coupe'), findsWidgets);
    expect(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-collectible-category-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-collectible-low-value-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-collectible-save-button')),
      findsOneWidget,
    );
  });

  testWidgets('edit cancel keeps existing item', (tester) async {
    await _pumpDetail(tester, _authorityItem());
    await _openEditSheet(tester);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      'Cancelled Coupe',
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-collectible-cancel-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelled Coupe'), findsNothing);
    expect(find.byKey(const ValueKey('edit-collectible-sheet')), findsNothing);
  });

  testWidgets('edit dismiss keeps existing item', (tester) async {
    await _pumpDetail(tester, _authorityItem());
    await _openEditSheet(tester);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      'Dismissed Coupe',
    );
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(find.text('Dismissed Coupe'), findsNothing);
    expect(find.byKey(const ValueKey('edit-collectible-sheet')), findsNothing);
  });

  testWidgets('edit validation requires supported required fields', (
    tester,
  ) async {
    await _pumpDetail(tester, _authorityItem());
    await _openEditSheet(tester);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      '',
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-collectible-save-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit-collectible-sheet')),
      findsOneWidget,
    );
  });

  testWidgets('edit save updates Detail supported fields', (tester) async {
    await _pumpDetail(tester, _authorityItem());
    await _openEditSheet(tester);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      'Edited Authority Coupe',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-category-field')),
      'Trading Card',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-low-value-field')),
      '260',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-high-value-field')),
      '300',
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-collectible-save-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-collectible-sheet')), findsNothing);
    expect(find.text('Collectible updated'), findsOneWidget);
  });
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

Future<void> _revealText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(finder.first);
  }
  await tester.pumpAndSettle();
}

Future<void> _openEditSheet(WidgetTester tester) async {
  await _revealText(tester, 'Actions Menu');
  await tester.tap(
    find.byKey(const ValueKey('collectible-detail-primary-edit-action')),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('edit-collectible-sheet')), findsOneWidget);
}

CollectibleItem _authorityItem({
  double estimatedValue = 245,
  ValuationStatus valuationStatus = ValuationStatus.marketEstimated,
  String imagePath = 'sample://front',
  List<CollectibleImage> galleryImages = const [
    CollectibleImage(
      path: 'sample://front',
      role: 'front',
      source: 'sample',
      isPrimary: true,
    ),
    CollectibleImage(path: 'sample://detail', role: 'detail', source: 'sample'),
  ],
}) {
  return CollectibleItem(
    id: 'detail-authority-item',
    title: 'PackLox Authority Coupe',
    category: 'Toy Car',
    estimatedValue: estimatedValue,
    confidence: 0.91,
    condition: 'Near mint',
    recommendation: 'Keep the complete saved capture set.',
    imagePath: imagePath,
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
    galleryImages: galleryImages,
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
