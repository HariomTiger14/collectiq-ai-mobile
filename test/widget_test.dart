import 'package:collectiq_ai/main.dart';
import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/services/ai_providers.dart';
import 'package:collectiq_ai/features/ai/services/ai_recognition_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/core/network/network_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows bottom navigation tabs', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('shows home dashboard content', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Scan, value and manage your collectibles.'),
      findsOneWidget,
    );
    expect(find.text('Portfolio Value'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Trending Collectibles'), findsOneWidget);
    expect(find.text('Recent Scans'), findsOneWidget);
    expect(find.text('Unlock unlimited AI scans'), findsOneWidget);
  });

  testWidgets('shows scanner experience content', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan'));
    await tester.pump();

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(
      find.text('Instantly identify and value collectibles.'),
      findsOneWidget,
    );
    expect(find.text('Scan with Camera'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Use Sample Scan'), findsOneWidget);
    expect(find.text('Supported Categories'), findsOneWidget);
    expect(find.text('How It Works'), findsOneWidget);
    expect(find.text('Unlimited AI Scans'), findsOneWidget);
  });

  testWidgets('shows portfolio empty state', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Portfolio'), findsWidgets);
    expect(
      find.text('Track saved collectibles and estimated value.'),
      findsOneWidget,
    );
    expect(find.text('No collectibles saved yet'), findsOneWidget);
  });

  testWidgets('shows settings screen content', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('switches between feature placeholders', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();

    expect(find.text('Portfolio'), findsWidgets);
  });

  testWidgets('scanner gallery button opens picker without placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _FakeGalleryService());

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Gallery picker coming next'), findsNothing);
  });

  testWidgets('scanner sample scan shows fake AI result', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Use Sample Scan'));
    await tester.pump();
    await tester.tap(find.text('Use Sample Scan'));
    await tester.pump();

    expect(find.text('Sample Sports Card'), findsOneWidget);
    expect(find.text('Ready for AI analysis'), findsOneWidget);

    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pump();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('1999 Pokémon Charizard'), findsOneWidget);
    expect(find.text('Trading Card'), findsOneWidget);
    expect(find.text('AUD 1,850'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('Near Mint'), findsOneWidget);
    expect(find.text('Consider grading before selling.'), findsOneWidget);
  });

  testWidgets('scanner backend failure shows friendly message', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiRecognitionService: const _FailingAIRecognitionService(),
      galleryService: _SelectedGalleryService(),
    );

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pump();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();

    expect(find.text('Unable to connect to AI service.'), findsOneWidget);
    expect(find.text('AI Result'), findsNothing);
  });

  testWidgets('saves scanner result to portfolio', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Use Sample Scan'));
    await tester.pump();
    await tester.tap(find.text('Use Sample Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pump();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.ensureVisible(find.text('Save to Portfolio'));
    await tester.pump();
    await tester.tap(find.text('Save to Portfolio'));
    await tester.pump();

    expect(find.text('Saved to portfolio'), findsOneWidget);

    await tester.tap(find.text('Portfolio'));
    await tester.pump();

    expect(find.text('1999 Pokémon Charizard'), findsOneWidget);
    expect(find.text('Total Value'), findsOneWidget);
    expect(find.text('Total Items'), findsOneWidget);
    expect(find.text('AUD 1,850'), findsWidgets);
  });

  testWidgets('loads saved portfolio items from local storage', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Persisted Charizard'), findsOneWidget);
    expect(find.text('AUD 1,850'), findsWidgets);
  });

  testWidgets('removes saved portfolio item from local storage', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byTooltip('Remove item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Persisted Charizard'), findsNothing);
    expect(find.text('No collectibles saved yet'), findsOneWidget);
  });

  testWidgets('filters portfolio items by search query', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"coin-1","title":"Silver Eagle","category":"Coin","estimatedValue":300,"confidence":0.82,"condition":"Mint","recommendation":"Store safely.","imagePath":"sample://coin","createdAt":"2026-06-26T00:00:00.000"},{"id":"card-1","title":"Charizard Holo","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading.","imagePath":"sample://card","createdAt":"2026-06-27T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'coin');
    await tester.pump();

    expect(find.text('Silver Eagle'), findsOneWidget);
    expect(find.text('Charizard Holo'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'watch');
    await tester.pump();

    expect(find.text('No matching collectibles'), findsOneWidget);
  });

  testWidgets('sorts portfolio items by value and confidence', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"new-low","title":"Newest Low","category":"Comic","estimatedValue":100,"confidence":0.50,"condition":"Good","recommendation":"Hold.","imagePath":"sample://new","createdAt":"2026-06-27T00:00:00.000"},{"id":"old-high","title":"Old High Value","category":"Coin","estimatedValue":2000,"confidence":0.40,"condition":"Mint","recommendation":"Insure.","imagePath":"sample://old","createdAt":"2026-06-26T00:00:00.000"},{"id":"confident","title":"Best Confidence","category":"Card","estimatedValue":500,"confidence":0.99,"condition":"Near Mint","recommendation":"Grade.","imagePath":"sample://confident","createdAt":"2026-06-25T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('Newest Low')).dy,
      lessThan(tester.getTopLeft(find.text('Old High Value')).dy),
    );

    await tester.tap(find.text('Newest first'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Value high to low').last);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Old High Value')).dy,
      lessThan(tester.getTopLeft(find.text('Newest Low')).dy),
    );

    await tester.tap(find.text('Value high to low'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confidence high to low').last);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Best Confidence')).dy,
      lessThan(tester.getTopLeft(find.text('Old High Value')).dy),
    );
  });

  testWidgets('opens portfolio item detail page actions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Persisted Charizard'));
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Estimated Value'), findsOneWidget);
    expect(find.text('Confidence'), findsOneWidget);
    expect(find.text('Condition'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Date Saved'), findsOneWidget);

    await tester.ensureVisible(find.text('Price History'));
    await tester.pump();
    expect(find.text('Price History'), findsOneWidget);
    expect(find.text('Current Value'), findsOneWidget);
    expect(find.text('6-month Change'), findsOneWidget);
    expect(find.text('Highest Value'), findsOneWidget);
    expect(find.text('Lowest Value'), findsOneWidget);
    expect(find.text('AUD 1,200'), findsWidgets);
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Jun'), findsOneWidget);

    await tester.ensureVisible(
      find.text(
        'Market trend looks positive. Consider holding or grading before selling.',
      ),
    );
    await tester.pump();
    expect(
      find.text(
        'Market trend looks positive. Consider holding or grading before selling.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Re-analyze'));
    await tester.pump();
    await tester.tap(find.text('Re-analyze'));
    await tester.pump();
    expect(find.text('Re-analysis coming next'), findsOneWidget);

    await tester.ensureVisible(find.text('Track Price'));
    await tester.pump();
    await tester.tap(find.text('Track Price'));
    await tester.pump();
    expect(find.text('Price tracking coming next'), findsOneWidget);

    await tester.ensureVisible(find.text('Sell Item'));
    await tester.pump();
    await tester.tap(find.text('Sell Item'));
    await tester.pump();
    expect(find.text('Marketplace listing coming next'), findsOneWidget);
  });
}

extension on WidgetTester {
  Future<void> pumpCollectIqApp({
    AIRecognitionService aiRecognitionService =
        const _FakeAIRecognitionService(),
    GalleryService? galleryService,
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: [
          aiRecognitionServiceProvider.overrideWithValue(aiRecognitionService),
          if (galleryService != null)
            galleryServiceProvider.overrideWithValue(galleryService),
        ],
        child: const CollectIqApp(),
      ),
    );
  }
}

class _FailingAIRecognitionService implements AIRecognitionService {
  const _FailingAIRecognitionService();

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) {
    throw const NetworkException(message: 'Network connection failed.');
  }
}

class _FakeAIRecognitionService implements AIRecognitionService {
  const _FakeAIRecognitionService();

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) async {
    return const RecognitionResult(
      success: true,
      filename: 'scan.png',
      imageUrl: 'http://127.0.0.1:8000/uploads/scan.png',
      title: '1999 Pokémon Charizard',
      category: 'Trading Card',
      confidence: 0.94,
      description: 'Likely a Pokémon Base Set Charizard.',
      estimatedValue: 1850,
      condition: 'Near Mint',
      recommendation: 'Consider grading before selling.',
    );
  }
}

class _FakeGalleryService extends GalleryService {
  @override
  Future<XFile?> pickImage() async {
    return null;
  }
}

class _SelectedGalleryService extends GalleryService {
  @override
  Future<XFile?> pickImage() async {
    return XFile('test/fixtures/card.jpg');
  }

  @override
  Future<bool> validateImage(XFile image) async {
    return true;
  }
}
