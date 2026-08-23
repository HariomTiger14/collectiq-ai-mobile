import 'package:collectiq_ai/features/scanner/presentation/pages/scan_result_screen.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tap-to-zoom on the "Analysis Complete" hero image — added so it matches
  // the existing tap-to-zoom pattern already used on Portfolio's collectible
  // detail screen, since this screen's image previously had no interactivity
  // at all.

  testWidgets('tapping the hero image opens a full-screen zoomable preview', (
    tester,
  ) async {
    await _pumpScanResultScreen(tester);

    await tester.tap(find.byKey(const ValueKey('result-hero-image-preview')));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(
      find.byKey(const ValueKey('result-image-viewer-close')),
      findsOneWidget,
    );
  });

  testWidgets('closing the preview returns to the result screen', (
    tester,
  ) async {
    await _pumpScanResultScreen(tester);

    await tester.tap(find.byKey(const ValueKey('result-hero-image-preview')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('result-image-viewer-close')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Analysis Complete'), findsOneWidget);
  });

  group('free-tier portfolio usage indicator', () {
    testWidgets(
      'below cap (9 of 10): shows the live counter and the full analysis '
      'stays visible -- the cap must never hide what the user is about to '
      'save',
      (tester) async {
        await _pumpScanResultScreen(
          tester,
          savedItemCount: 9,
          freeItemCap: 10,
          onUpgrade: () {},
        );

        expect(find.text('9 of 10 free collectibles saved'), findsOneWidget);
        // The analysis itself -- name, value -- is never gated by the cap.
        expect(find.text('Test Collectible'), findsWidgets);
        expect(find.textContaining('120'), findsWidgets);
        expect(
          find.byKey(const ValueKey('result-primary-add-to-portfolio')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'at cap (10 of 10): shows the full-collection message, and analysis '
      'and the Add to Portfolio action both stay visible -- only the save '
      'itself is gated (enforced by PortfolioController, not this screen)',
      (tester) async {
        await _pumpScanResultScreen(
          tester,
          savedItemCount: 10,
          freeItemCap: 10,
          onUpgrade: () {},
        );

        expect(
          find.text('Free collection full — upgrade to save more'),
          findsOneWidget,
        );
        expect(find.text('9 of 10 free collectibles saved'), findsNothing);
        expect(find.text('Test Collectible'), findsWidgets);
        final addButton = tester.widget<FilledButton>(
          find.byKey(const ValueKey('result-primary-add-to-portfolio')),
        );
        expect(addButton.onPressed, isNotNull);
      },
    );

    testWidgets('tapping the counter at cap opens the upgrade path', (
      tester,
    ) async {
      var upgradeTapped = false;
      await _pumpScanResultScreen(
        tester,
        savedItemCount: 10,
        freeItemCap: 10,
        onUpgrade: () => upgradeTapped = true,
      );

      await tester.tap(find.byKey(const ValueKey('free-collectible-counter')));
      await tester.pump();

      expect(upgradeTapped, isTrue);
    });

    testWidgets(
      'no indicator when usage data is not supplied (e.g. a Pro user, '
      'whose cap is unlimited)',
      (tester) async {
        await _pumpScanResultScreen(tester);

        expect(
          find.byKey(const ValueKey('free-collectible-counter')),
          findsNothing,
        );
        expect(find.textContaining('free collectibles'), findsNothing);
      },
    );
  });
}

Future<void> _pumpScanResultScreen(
  WidgetTester tester, {
  int? savedItemCount,
  int? freeItemCap,
  VoidCallback? onUpgrade,
}) async {
  final now = DateTime(2026, 8, 6);
  await tester.pumpWidget(
    MaterialApp(
      home: ScanResultScreen(
        result: ScanResult(
          id: 'test-result',
          title: 'Test Collectible',
          category: 'Trading Card',
          estimatedValue: 120,
          confidence: 0.86,
          condition: 'Good',
          thumbnail: 'sample://test-result',
          scanDate: now,
          primaryMatch: 'Test Collectible',
          alternativeMatches: const [],
          confidenceExplanation: 'Test confidence.',
          detectionQuality: 'Good',
          aiReasoning: 'Test reasoning.',
          pricing: PricingInfo(
            estimatedMarketValue: 120,
            lowEstimate: 100,
            highEstimate: 140,
            currency: 'AUD',
            pricingSource: 'Test',
            pricingConfidence: 0.8,
            lastUpdated: now,
          ),
        ),
        activeSlot: null,
        isSaved: false,
        isSaving: false,
        isRefreshingPricing: false,
        onSave: () async {},
        onScanAnother: () {},
        onViewPortfolio: null,
        onApplyReviewEdits: (_) async => true,
        savedItemCount: savedItemCount,
        freeItemCap: freeItemCap,
        onUpgrade: onUpgrade,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
