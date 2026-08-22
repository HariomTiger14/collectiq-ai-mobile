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
}

Future<void> _pumpScanResultScreen(WidgetTester tester) async {
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
      ),
    ),
  );
  await tester.pumpAndSettle();
}
