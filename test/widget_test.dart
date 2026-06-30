import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:collectiq_ai/main.dart';
import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/services/ai_providers.dart';
import 'package:collectiq_ai/features/ai/services/ai_recognition_service.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/services/sync_service.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/diagnostics/services/diagnostics_providers.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/usage_repository.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/core/network/network_exceptions.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
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

    expect(find.text('Good Evening, Harry'), findsOneWidget);
    expect(find.text('Welcome back to CollectIQ AI'), findsOneWidget);
    expect(find.text('Scan Collectible'), findsOneWidget);
    expect(find.text('Build your collection dashboard'), findsOneWidget);
    expect(find.text('Start First Scan'), findsOneWidget);
    expect(find.text('No collectibles scanned yet.'), findsOneWidget);
    expect(find.text('Dashboard Insights'), findsNothing);
    expect(find.text('Category Breakdown'), findsNothing);
  });

  testWidgets('home dashboard analytics render from portfolio data', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"home-card","title":"Dashboard Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Grade it.","imagePath":"sample://card","createdAt":"2026-06-27T00:00:00.000","marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Rising","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold"],"comps":[]}},{"id":"home-coin","title":"Dashboard Silver Eagle","category":"Coin","estimatedValue":300,"confidence":0.70,"condition":"Mint","recommendation":"Store safely.","imagePath":"sample://coin","createdAt":"2026-06-26T00:00:00.000"},{"id":"home-comic","title":"Dashboard Spider-Man","category":"Comic","estimatedValue":600,"confidence":0.88,"condition":"Fine","recommendation":"Bag and board.","imagePath":"sample://comic","createdAt":"2026-06-10T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();
    await tester.pump();
    await tester.pump();

    expect(find.text('Collection Value'), findsOneWidget);
    expect(find.text('AUD 2,750'), findsOneWidget);
    expect(find.text('Dashboard Insights'), findsOneWidget);
    expect(find.text('Total Collectibles'), findsOneWidget);
    expect(find.text('Average Item Value'), findsOneWidget);
    expect(find.text('AUD 917'), findsOneWidget);
    expect(find.text('Recently Added'), findsOneWidget);
    expect(find.text('Average Confidence'), findsOneWidget);
    expect(find.text('84%'), findsOneWidget);
    expect(find.text('Category Breakdown'), findsOneWidget);
    expect(find.text('Cards'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(find.text('Comics'), findsOneWidget);
    expect(find.text('Memorabilia'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Portfolio Highlights'), findsOneWidget);
    expect(find.text('Highest Value Collectible'), findsOneWidget);
    expect(find.text('Dashboard Charizard'), findsWidgets);
    expect(find.text('Most Recent Collectible'), findsOneWidget);
    expect(find.text('Strongest Confidence Item'), findsOneWidget);
    expect(find.text('Items Needing Review'), findsOneWidget);
    expect(
      find.text('1 low-confidence items may need a closer look.'),
      findsOneWidget,
    );
  });

  testWidgets('home dashboard updates after saving a scan', (
    WidgetTester tester,
  ) async {
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Collection Value'), findsOneWidget);
    expect(find.text('Dashboard Insights'), findsOneWidget);
    expect(find.text('Total Collectibles'), findsOneWidget);
    expect(find.text('Average Item Value'), findsOneWidget);
    expect(find.text('Portfolio Highlights'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.textContaining('Charizard'), findsWidgets);
  });

  testWidgets('home scan button selects Scan tab', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan Collectible').first);
    await tester.pumpAndSettle();

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(find.text('Scan with Camera'), findsOneWidget);
  });

  testWidgets('restores Scan tab after shell recreation', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan Collectible').first);
    await tester.pumpAndSettle();
    expect(find.text('AI Scanner'), findsOneWidget);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(find.text('Scan with Camera'), findsOneWidget);
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
    expect(find.text('Your collectible library'), findsOneWidget);
    expect(find.text('No collectibles saved yet'), findsOneWidget);
    expect(find.text('Scan Collectible'), findsWidgets);
  });

  testWidgets('shows settings screen content', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Manage account and cloud sync options.'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Account mode'), findsOneWidget);
    expect(find.text('Local Anonymous'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
    expect(
      find.byKey(const ValueKey('settings-auth-email-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-password-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-sign-in-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-sign-up-button')),
      findsOneWidget,
    );
    expect(find.text('Local mode'), findsOneWidget);
    expect(find.text('Email / Password'), findsOneWidget);
    expect(find.text('Google Sign-In'), findsOneWidget);
    expect(find.text('Apple Sign-In'), findsOneWidget);
    expect(
      find.text('Use camera, scans, and local portfolio without an account.'),
      findsOneWidget,
    );
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('Plan & Usage'), findsOneWidget);
    expect(find.text('Current plan'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Scans used today'), findsOneWidget);
    expect(find.text('Remaining scans'), findsOneWidget);
    expect(find.text('Unlimited'), findsOneWidget);
    expect(find.text('Payment status'), findsOneWidget);
    expect(find.text('Not configured'), findsWidgets);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('AI & Scanning'), findsOneWidget);
    expect(find.text('Current AI provider'), findsOneWidget);
    expect(find.text('Mock AI'), findsWidgets);
    expect(find.text('Mock mode active'), findsOneWidget);
    expect(find.text('OpenAI Vision'), findsOneWidget);
    expect(find.text('Gemini Vision'), findsOneWidget);
    expect(find.text('Coming soon'), findsWidgets);
    expect(find.text('Cloud Sync'), findsOneWidget);

    await tester.ensureVisible(find.text('Developer Diagnostics'));
    await tester.pump();
    expect(find.text('Developer Diagnostics'), findsOneWidget);
    expect(find.text('AI Provider'), findsOneWidget);
    expect(find.text('Pricing Provider'), findsOneWidget);
    expect(find.text('Mock Pricing'), findsOneWidget);
    expect(find.text('Backend Endpoint Configured'), findsOneWidget);
    expect(find.text('Backend Endpoint Valid'), findsOneWidget);
    expect(find.text('Release Safe Endpoint'), findsOneWidget);
    expect(find.text('HTTP Backend Client'), findsOneWidget);
    expect(find.text('AI Backend Client'), findsOneWidget);
    expect(find.text('Mock Mode Active'), findsOneWidget);
    expect(find.text('Last Scan Pipeline'), findsOneWidget);
    expect(find.text('Not configured'), findsWidgets);

    await tester.ensureVisible(find.text('Cloud Sync'));
    await tester.pump();
    expect(find.text('Cloud status'), findsOneWidget);
    expect(find.text('Signed-in user email'), findsOneWidget);
    expect(find.text('Pending uploads'), findsOneWidget);
    expect(find.text('Retryable uploads'), findsOneWidget);
    expect(find.text('Failed uploads'), findsOneWidget);
    expect(find.text('Last sync'), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);
    expect(find.text('Sync status'), findsOneWidget);
    expect(find.text('Local only'), findsWidgets);
    expect(find.text('Cloud backup'), findsOneWidget);
    expect(find.text('Off'), findsWidgets);

    await tester.ensureVisible(find.text('Storage'));
    await tester.pump();
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Local images'), findsOneWidget);
    expect(find.text('Supabase Storage'), findsOneWidget);

    await tester.ensureVisible(find.text('Data & Privacy'));
    await tester.pump();
    expect(find.text('Data & Privacy'), findsOneWidget);
    expect(find.text('Offline portfolio'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);

    await tester.ensureVisible(find.text('About'));
    await tester.pump();
    expect(find.text('About'), findsOneWidget);
    expect(find.text('App version'), findsOneWidget);
  });

  testWidgets('settings signs in with mocked email auth repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(authRepository: _InteractiveAuthRepository());

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('settings-auth-email-field')),
      'harry@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('settings-auth-password-field')),
      'password123',
    );
    final signInButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('settings-auth-sign-in-button')),
    );
    signInButton.onPressed!();
    await tester.pump();
    await tester.pump();

    expect(find.text('harry@example.com'), findsWidgets);
    expect(find.text('Signed in'), findsWidgets);
    expect(
      find.byKey(const ValueKey('settings-auth-sign-out-button')),
      findsOneWidget,
    );
  });

  testWidgets('settings displays unavailable configured AI provider', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProviderConfig: const AiAnalysisProviderConfig(
        type: AiAnalysisProviderType.openAiVision,
      ),
    );

    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(find.text('Current AI provider'), findsOneWidget);
    expect(find.text('OpenAI Vision'), findsWidgets);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('Coming soon'), findsWidgets);
    expect(
      find.text(
        'OpenAI Vision requires the CollectIQ AI backend endpoint before it can be enabled.',
      ),
      findsOneWidget,
    );
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

  testWidgets('scanner camera capture shows preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Scan with Camera'));
    await tester.pump();
    await tester.tap(find.text('Scan with Camera'));
    await tester.pumpUntilFound(find.text('Captured image'));

    expect(find.text('Captured image'), findsOneWidget);
    expect(find.text('Ready for AI analysis'), findsOneWidget);
    expect(find.text('Analyze with AI'), findsOneWidget);
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .any((image) => image.fit == BoxFit.contain),
      isTrue,
    );
  });

  testWidgets('camera return shows preparing image bridge before preview', (
    WidgetTester tester,
  ) async {
    final cameraService = _DelayedPersistCameraService();
    await tester.pumpCollectIqApp(cameraService: cameraService);

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Scan with Camera'));
    await tester.pump();
    await tester.tap(find.text('Scan with Camera'));
    await tester.pumpUntilFound(find.text('Preparing image...'));

    expect(
      find.text('Copying your photo into CollectIQ storage.'),
      findsOneWidget,
    );
    expect(find.text('Welcome back to CollectIQ AI'), findsNothing);

    cameraService.complete();
    await tester.pumpUntilFound(find.text('Captured image'));

    expect(find.text('Captured image'), findsOneWidget);
    expect(find.text('Analyze with AI'), findsOneWidget);
  });

  testWidgets('camera completion remains on Scan tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

    await tester.tap(find.text('Scan Collectible').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Scan with Camera'));
    await tester.pump();
    await tester.tap(find.text('Scan with Camera'));
    await tester.pumpUntilFound(find.text('Captured image'));

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(find.text('Captured image'), findsOneWidget);
    expect(find.text('Analyze with AI'), findsOneWidget);
    expect(find.text('Welcome back to CollectIQ AI'), findsNothing);
  });

  testWidgets('lost Android camera data recovers to Scan tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      cameraService: _LostDataCameraService(),
      galleryService: _SelectedGalleryService(),
    );

    await tester.pumpUntilFound(find.text('Recovered image'));

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(find.text('Recovered image'), findsOneWidget);
    expect(find.text('Analyze with AI'), findsOneWidget);
    expect(find.text('Welcome back to CollectIQ AI'), findsNothing);
  });

  testWidgets('gallery completion from Home CTA remains on Scan tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _SelectedGalleryService());

    await tester.tap(find.text('Scan Collectible').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpUntilFound(find.text('Gallery image'));

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(find.text('Gallery image'), findsOneWidget);
    expect(find.text('Analyze with AI'), findsOneWidget);
    expect(find.text('Welcome back to CollectIQ AI'), findsNothing);
  });

  testWidgets('scanner camera cancellation shows friendly message', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _CancelledCameraService());

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Scan with Camera'));
    await tester.pump();
    await tester.tap(find.text('Scan with Camera'));
    await tester.pump();

    expect(find.text('Camera capture cancelled.'), findsOneWidget);
    expect(find.text('Analyze with AI'), findsNothing);
  });

  testWidgets('camera missing image path shows error without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _MissingCameraService());

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Scan with Camera'));
    await tester.pump();
    await tester.tap(find.text('Scan with Camera'));
    await tester.pumpUntilFound(
      find.text(
        'Selected image could not be found. Please choose another image.',
      ),
    );

    expect(
      find.text(
        'Selected image could not be found. Please choose another image.',
      ),
      findsOneWidget,
    );
    expect(find.text('Analyze with AI'), findsNothing);
  });

  testWidgets('gallery missing image path shows error without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _MissingGalleryService());

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpUntilFound(
      find.text(
        'Selected image could not be found. Please choose another image.',
      ),
    );

    expect(
      find.text(
        'Selected image could not be found. Please choose another image.',
      ),
      findsOneWidget,
    );
    expect(find.text('Analyze with AI'), findsNothing);
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
    expect(find.text('Trading Card'), findsWidgets);
    expect(find.text('AUD 1,850'), findsWidgets);
    expect(find.text('Market Value'), findsWidgets);
    expect(find.text('Market Summary'), findsWidgets);
    expect(find.text('Recent comparable sales'), findsOneWidget);
    expect(find.textContaining('TCGplayer'), findsWidgets);
    expect(find.text('AUD 1,443 - AUD 2,257'), findsWidgets);
    expect(find.textContaining('Mock pricing blend'), findsWidgets);
    expect(find.text('69%'), findsWidgets);
    expect(find.textContaining('94%'), findsWidgets);
    expect(find.text('Near Mint'), findsWidgets);
    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Base Set'), findsOneWidget);
    expect(find.text('4/102'), findsOneWidget);
    expect(find.text('Charizard'), findsOneWidget);
    expect(find.text('Why this match?'), findsOneWidget);
    expect(find.text('Alternative Matches'), findsOneWidget);
    expect(find.text('2016 Pokemon Evolutions Charizard'), findsOneWidget);
    expect(find.textContaining('High confidence'), findsOneWidget);
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
    await tester.pumpUntilFound(find.text('Analyze with AI'));
    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pump();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();

    expect(find.text('Unable to connect to AI service.'), findsOneWidget);
    expect(find.text('AI Result'), findsNothing);
  });

  testWidgets('scanner controller uses AI analysis provider', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProvider: const _CustomAiAnalysisProvider(),
    );

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Use Sample Scan'));
    await tester.pump();
    await tester.tap(find.text('Use Sample Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pump();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pumpAndSettle();

    expect(find.text('Provider Test Collectible'), findsWidgets);
    expect(find.text('Provider recommendation.'), findsOneWidget);
    expect(find.textContaining('Mock pricing blend'), findsWidgets);
    expect(find.text('Provider fixture'), findsNothing);
  });

  testWidgets('scanner pipeline status updates after mock scan', (
    WidgetTester tester,
  ) async {
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
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(
      container.read(scanPipelineStatusProvider),
      ScanPipelineDiagnostics.completed,
    );
  });

  testWidgets('usage increments after successful analysis', (
    WidgetTester tester,
  ) async {
    final usageRepository = _MemoryUsageRepository();
    await tester.pumpCollectIqApp(
      usageRepository: usageRepository,
      usageLimitConfig: const UsageLimitConfig(
        developmentUnlimited: false,
        dailyFreeScanLimit: 2,
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Use Sample Scan'));
    await tester.pump();
    await tester.tap(find.text('Use Sample Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pump();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pumpAndSettle();

    expect(usageRepository.count, 1);
    expect(find.text('Analysis Complete'), findsOneWidget);
  });

  testWidgets('usage does not increment on failed analysis', (
    WidgetTester tester,
  ) async {
    final usageRepository = _MemoryUsageRepository();
    await tester.pumpCollectIqApp(
      aiAnalysisProvider: const _FailingAiAnalysisProvider(),
      usageRepository: usageRepository,
      usageLimitConfig: const UsageLimitConfig(
        developmentUnlimited: false,
        dailyFreeScanLimit: 2,
      ),
    );

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

    expect(usageRepository.count, 0);
    expect(find.text('Provider failed safely.'), findsOneWidget);
  });

  testWidgets('limit reached shows friendly scan error', (
    WidgetTester tester,
  ) async {
    final usageRepository = _MemoryUsageRepository(initialCount: 1);
    await tester.pumpCollectIqApp(
      usageRepository: usageRepository,
      usageLimitConfig: const UsageLimitConfig(
        developmentUnlimited: false,
        dailyFreeScanLimit: 1,
      ),
    );

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

    expect(usageRepository.count, 1);
    expect(
      find.textContaining('Daily free scan limit reached'),
      findsOneWidget,
    );
    expect(find.text('AI Result'), findsNothing);
  });

  testWidgets('AI provider failure shows scan error panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProvider: const _FailingAiAnalysisProvider(),
    );

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

    expect(find.text('Provider failed safely.'), findsOneWidget);
    expect(find.text('Provider Test Collectible'), findsNothing);
  });

  testWidgets('OpenAI provider skeleton shows scan error', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProviderConfig: const AiAnalysisProviderConfig(
        type: AiAnalysisProviderType.openAiVision,
      ),
    );

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

    expect(
      find.text(
        'Backend AI endpoint not configured. OpenAI Vision must run through the CollectIQ AI backend.',
      ),
      findsOneWidget,
    );
    expect(find.text('Analysis Complete'), findsNothing);
  });

  testWidgets('scan preview remains mounted during analyze', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiRecognitionService: const _DelayedAIRecognitionService(),
      galleryService: _SelectedGalleryService(),
    );

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpUntilFound(find.text('Gallery image'));

    expect(find.text('Gallery image'), findsOneWidget);

    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pump();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Gallery image'), findsOneWidget);
    expect(find.text('Analyzing image'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Gallery image'), findsOneWidget);
    expect(find.text('Analysis Complete'), findsOneWidget);
  });

  testWidgets('premium scan result renders after image is analyzed', (
    WidgetTester tester,
  ) async {
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

    await tester.ensureVisible(find.text('Analysis Result'));
    await tester.pump();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('1999 Pokémon Charizard'), findsOneWidget);
    expect(find.text('Estimated market value'), findsOneWidget);
    expect(find.textContaining('Estimated value range'), findsOneWidget);
    expect(find.text('Key Attributes'), findsOneWidget);
    expect(find.textContaining('Market trend:'), findsOneWidget);
    expect(find.text('Save to Portfolio'), findsOneWidget);
    expect(find.text('Scan Another'), findsOneWidget);
  });

  testWidgets('scan again clears selected image and result', (
    WidgetTester tester,
  ) async {
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
    await tester.ensureVisible(find.text('Scan Another'));
    await tester.pump();
    await tester.tap(find.text('Scan Another'));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsNothing);
    expect(find.text('Sample Sports Card'), findsNothing);
    expect(find.text('Analyze with AI'), findsNothing);
    expect(find.text('Use Sample Scan'), findsOneWidget);
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
    await tester.pumpAndSettle();

    expect(find.text('Saved to portfolio'), findsOneWidget);

    await tester.tap(find.text('Portfolio'));
    await tester.pump();

    expect(find.text('1999 Pokémon Charizard'), findsOneWidget);
    expect(find.text('Total collection value'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('AUD 1,850'), findsWidgets);
  });

  testWidgets('local portfolio save works when auth and cloud fail', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      authRepository: const _FailingAuthRepository(),
      syncService: const _FailingSyncService(),
    );

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
    await tester.pumpAndSettle();

    expect(find.text('Saved to portfolio'), findsOneWidget);

    await tester.tap(find.text('Portfolio'));
    await tester.pump();

    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('AUD 1,850'), findsWidgets);
  });

  testWidgets('saved scan resets after navigating away from Scan', (
    WidgetTester tester,
  ) async {
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
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Sample Sports Card'), findsNothing);
    expect(find.text('Analysis Complete'), findsNothing);
    expect(find.text('Analyze with AI'), findsNothing);
    expect(find.text('Use Sample Scan'), findsOneWidget);
  });

  testWidgets('unsaved analysis is preserved when navigating away from Scan', (
    WidgetTester tester,
  ) async {
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

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Sample Sports Card'), findsOneWidget);
    expect(find.text('1999 Pokémon Charizard'), findsOneWidget);
    expect(find.text('Analysis Complete'), findsOneWidget);
  });

  testWidgets('home scan CTA starts clean after unsaved scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

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

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan Collectible').first);
    await tester.pumpAndSettle();

    expect(find.text('Sample Sports Card'), findsNothing);
    expect(find.text('1999 Pokémon Charizard'), findsNothing);
    expect(find.text('AI Scanner'), findsOneWidget);

    await tester.ensureVisible(find.text('Scan with Camera'));
    await tester.pump();
    await tester.tap(find.text('Scan with Camera'));
    await tester.pumpAndSettle();

    expect(find.text('Captured image'), findsOneWidget);
    expect(find.text('Analyze with AI'), findsOneWidget);
  });

  testWidgets('saves gallery image path to portfolio item', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _SelectedGalleryService());

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpUntilFound(find.text('Analyze with AI'));
    await tester.ensureVisible(find.text('Analyze with AI'));
    await tester.pump();
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.ensureVisible(find.text('Save to Portfolio'));
    await tester.pump();
    await tester.tap(find.text('Save to Portfolio'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();
    final encodedItems = preferences.getString('portfolio_items');
    final decodedItems = jsonDecode(encodedItems!) as List<dynamic>;
    final item = decodedItems.single as Map<String, dynamic>;

    expect(item['imagePath'], _fixturePath('persistent-gallery-card.jpg'));
    expect(item['cloudImageUrl'], isNull);
  });

  testWidgets('saves persistent camera image path to portfolio', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.ensureVisible(find.text('Scan with Camera'));
    await tester.pump();
    await tester.tap(find.text('Scan with Camera'));
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
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();
    final encodedItems = preferences.getString('portfolio_items');
    final decodedItems = jsonDecode(encodedItems!) as List<dynamic>;
    final item = decodedItems.single as Map<String, dynamic>;

    expect(item['imagePath'], _fixturePath('persistent-camera-card.jpg'));
    expect(item['cloudImageUrl'], isNull);
  });

  testWidgets('loads saved portfolio items from local storage', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","year":"1999","brand":"Pokemon","setName":"Base Set","cardNumber":"4/102","playerOrCharacter":"Charizard","rarity":"Holo Rare","material":"Cardstock","notes":"Verify holo surface.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold","TCGplayer"],"comps":[{"source":"eBay Sold","title":"1999 Pokemon Charizard sold listing","soldPrice":1850,"currency":"AUD","soldDate":"2026-06-20T00:00:00Z","condition":"Near Mint"}]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Persisted Charizard'), findsOneWidget);
    expect(find.text('AUD 1,850'), findsWidgets);
    expect(find.text('Trading Card'), findsOneWidget);
    expect(find.text('Near Mint'), findsWidgets);
    expect(find.text('94%'), findsWidgets);
    expect(find.text('Stable'), findsWidgets);
    expect(find.text('Saved 27/06/2026'), findsOneWidget);
  });

  testWidgets('portfolio empty state renders when no items exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No collectibles saved yet'), findsOneWidget);
    expect(find.text('Scan Collectible'), findsWidgets);
  });

  testWidgets('removes saved portfolio item from local storage', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","year":"1999","brand":"Pokemon","setName":"Base Set","cardNumber":"4/102","playerOrCharacter":"Charizard","rarity":"Holo Rare","material":"Cardstock","notes":"Verify holo surface.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold","TCGplayer"],"comps":[{"source":"eBay Sold","title":"1999 Pokemon Charizard sold listing","soldPrice":1850,"currency":"AUD","soldDate":"2026-06-20T00:00:00Z","condition":"Near Mint"}]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('portfolio-item-persisted-1')),
    );
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

  testWidgets('category filter limits portfolio items', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"coin-1","title":"Silver Eagle","category":"Coin","estimatedValue":300,"confidence":0.82,"condition":"Mint","recommendation":"Store safely.","imagePath":"sample://coin","createdAt":"2026-06-26T00:00:00.000"},{"id":"card-1","title":"Charizard Holo","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading.","imagePath":"sample://card","createdAt":"2026-06-27T00:00:00.000"},{"id":"comic-1","title":"Amazing Spider-Man","category":"Comic","estimatedValue":600,"confidence":0.88,"condition":"Fine","recommendation":"Bag and board.","imagePath":"sample://comic","createdAt":"2026-06-25T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    expect(find.text('Charizard Holo'), findsOneWidget);
    expect(find.text('Silver Eagle'), findsNothing);
    expect(find.text('Amazing Spider-Man'), findsNothing);

    await tester.tap(find.text('Coins'));
    await tester.pumpAndSettle();

    expect(find.text('Silver Eagle'), findsOneWidget);
    expect(find.text('Charizard Holo'), findsNothing);
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

    await tester.tap(find.text('Value'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Old High Value')).dy,
      lessThan(tester.getTopLeft(find.text('Newest Low')).dy),
    );

    await tester.tap(find.text('Confidence').first);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Best Confidence')).dy,
      lessThan(tester.getTopLeft(find.text('Old High Value')).dy),
    );
  });

  testWidgets('newest sort uses savedAt descending', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"camera-old","title":"Older Camera Save","category":"Card","estimatedValue":500,"confidence":0.91,"condition":"Near Mint","recommendation":"Hold.","imagePath":"sample://camera","savedAt":"2026-06-29T08:00:00.000","createdAt":"2026-06-29T08:00:00.000"},{"id":"gallery-new","title":"Newer Gallery Save","category":"Comic","estimatedValue":100,"confidence":0.72,"condition":"Good","recommendation":"Keep.","imagePath":"sample://gallery","savedAt":"2026-06-29T09:30:00.000","createdAt":"2026-06-01T00:00:00.000"},{"id":"missing-date","title":"Missing Timestamp Import","category":"Coin","estimatedValue":200,"confidence":0.80,"condition":"Fine","recommendation":"Store.","imagePath":"sample://coin"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('Newer Gallery Save')).dy,
      lessThan(tester.getTopLeft(find.text('Older Camera Save')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Older Camera Save')).dy,
      lessThan(tester.getTopLeft(find.text('Missing Timestamp Import')).dy),
    );
  });

  testWidgets('home scan recent and portfolio share newest ordering', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"camera-old","title":"Older Camera Activity","category":"Card","estimatedValue":500,"confidence":0.91,"condition":"Near Mint","recommendation":"Hold.","imagePath":"sample://camera","savedAt":"2026-06-29T08:00:00.000"},{"id":"gallery-new","title":"Newest Gallery Activity","category":"Comic","estimatedValue":100,"confidence":0.72,"condition":"Good","recommendation":"Keep.","imagePath":"sample://gallery","savedAt":"2026-06-29T09:30:00.000"}]',
    });

    await tester.pumpCollectIqApp();
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('home-recent-gallery-new')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('home-recent-camera-old')))
            .dy,
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Recent Scans'));
    await tester.pump();
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('scan-recent-gallery-new')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('scan-recent-camera-old')))
            .dy,
      ),
    );

    await tester.tap(find.text('Portfolio'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('portfolio-item-gallery-new')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('portfolio-item-camera-old')))
            .dy,
      ),
    );
  });

  testWidgets('portfolio item tap opens detail page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"detail-card","title":"Clickable Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","primaryMatch":"1999 Pokemon Charizard Holo","confidenceExplanation":"High confidence from character artwork.","detectionQuality":"Good","aiReasoning":"The image shows a Charizard-like Pokemon card.","year":"1999","brand":"Pokemon","setName":"Base Set","cardNumber":"4/102","playerOrCharacter":"Charizard","rarity":"Holo Rare","material":"Cardstock","notes":"Verify holo surface.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold","TCGplayer"],"comps":[{"source":"eBay Sold","title":"1999 Pokemon Charizard sold listing","soldPrice":1850,"currency":"AUD","soldDate":"2026-06-20T00:00:00Z","condition":"Near Mint"}]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('portfolio-item-detail-card')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('portfolio-item-detail-card')));
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Estimated market value'), findsOneWidget);
    expect(find.text('Why this match?'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
  });

  testWidgets('home recent activity tap opens detail page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"home-detail","title":"Home Detail Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","primaryMatch":"1999 Pokemon Charizard Holo","confidenceExplanation":"High confidence from character artwork.","detectionQuality":"Good","aiReasoning":"The image shows a Charizard-like Pokemon card.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold"],"comps":[]}}]',
    });

    await tester.pumpCollectIqApp();
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const ValueKey('home-recent-home-detail')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-recent-home-detail')));
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Home Detail Charizard'), findsWidgets);
    expect(find.text('Market trend: Stable'), findsOneWidget);
  });

  testWidgets('scan recent scans tap opens detail page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"scan-detail","title":"Scan Detail Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","primaryMatch":"1999 Pokemon Charizard Holo","confidenceExplanation":"High confidence from character artwork.","detectionQuality":"Good","aiReasoning":"The image shows a Charizard-like Pokemon card.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold"],"comps":[]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Recent Scans'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('scan-recent-scan-detail')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-recent-scan-detail')));
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Scan Detail Charizard'), findsWidgets);
    expect(find.text('Market trend: Stable'), findsOneWidget);
  });

  testWidgets('opens portfolio item detail page actions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","year":"1999","brand":"Pokemon","setName":"Base Set","cardNumber":"4/102","playerOrCharacter":"Charizard","rarity":"Holo Rare","material":"Cardstock","notes":"Verify holo surface.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold","TCGplayer"],"comps":[{"source":"eBay Sold","title":"1999 Pokemon Charizard sold listing","soldPrice":1850,"currency":"AUD","soldDate":"2026-06-20T00:00:00Z","condition":"Near Mint"}]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('portfolio-item-persisted-1')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('portfolio-item-persisted-1')));
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Estimated market value'), findsOneWidget);
    expect(find.text('94% confidence'), findsOneWidget);
    expect(find.text('Saved 27/06/2026'), findsOneWidget);
    expect(find.text('Key Attributes'), findsOneWidget);
    expect(find.text('Base Set'), findsOneWidget);
    expect(find.text('4/102'), findsOneWidget);
    expect(find.text('Charizard'), findsOneWidget);
    expect(find.text('Market Pricing'), findsOneWidget);
    expect(find.text('Market Summary'), findsOneWidget);
    expect(find.text('Market trend: Stable'), findsOneWidget);
    expect(find.text('Recent comparable sales'), findsOneWidget);
    expect(find.text('AUD 1,443 - AUD 2,257'), findsWidgets);
    expect(find.text('Mock market blend'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);

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
    AiAnalysisProviderConfig? aiAnalysisProviderConfig,
    AiAnalysisProvider? aiAnalysisProvider,
    AuthRepository? authRepository,
    SyncService? syncService,
    UsageLimitConfig? usageLimitConfig,
    UsageRepository? usageRepository,
    CameraService? cameraService,
    GalleryService? galleryService,
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: [
          aiRecognitionServiceProvider.overrideWithValue(aiRecognitionService),
          if (aiAnalysisProviderConfig != null)
            aiAnalysisProviderConfigProvider.overrideWithValue(
              aiAnalysisProviderConfig,
            ),
          if (aiAnalysisProvider != null)
            aiAnalysisProviderProvider.overrideWithValue(aiAnalysisProvider),
          if (authRepository != null)
            authRepositoryProvider.overrideWithValue(authRepository),
          if (syncService != null)
            syncServiceProvider.overrideWithValue(syncService),
          if (usageLimitConfig != null)
            usageLimitConfigProvider.overrideWithValue(usageLimitConfig),
          if (usageRepository != null)
            usageRepositoryProvider.overrideWithValue(usageRepository),
          if (cameraService != null)
            cameraServiceProvider.overrideWithValue(cameraService),
          if (galleryService != null)
            galleryServiceProvider.overrideWithValue(galleryService),
        ],
        child: const CollectIqApp(),
      ),
    );
  }

  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final end = binding.clock.fromNowBy(timeout);
    while (binding.clock.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    throw TestFailure('Timed out waiting for $finder');
  }
}

class _CustomAiAnalysisProvider implements AiAnalysisProvider {
  const _CustomAiAnalysisProvider();

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    final now = DateTime.now();

    return AiAnalysisResult(
      recommendation: 'Provider recommendation.',
      scanResult: ScanResult(
        id: 'provider-${now.microsecondsSinceEpoch}',
        title: 'Provider Test Collectible',
        category: 'Trading Card',
        estimatedValue: 123,
        confidence: 0.81,
        condition: 'Excellent',
        thumbnail: request.imagePath,
        scanDate: now,
        primaryMatch: 'Provider Test Collectible',
        alternativeMatches: const [],
        confidenceExplanation: 'Provider controlled confidence explanation.',
        detectionQuality: 'Good',
        aiReasoning: 'Provider controlled reasoning.',
        pricing: PricingInfo(
          estimatedMarketValue: 123,
          lowEstimate: 100,
          highEstimate: 150,
          currency: 'AUD',
          pricingSource: 'Provider fixture',
          pricingConfidence: 0.8,
          lastUpdated: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
      ),
    );
  }
}

class _FailingAiAnalysisProvider implements AiAnalysisProvider {
  const _FailingAiAnalysisProvider();

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) {
    throw const AiAnalysisException('Provider failed safely.');
  }
}

class _FailingAuthRepository implements AuthRepository {
  const _FailingAuthRepository();

  @override
  Future<AppUser?> currentUser() {
    throw const AuthException('Auth unavailable during local save test.');
  }

  @override
  Future<AppUser> signIn() {
    throw const AuthException('Auth unavailable during local save test.');
  }

  @override
  Future<AppUser> signInAnonymously() {
    throw const AuthException('Auth unavailable during local save test.');
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw const AuthException('Auth unavailable during local save test.');
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw const AuthException('Auth unavailable during local save test.');
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException('Auth unavailable during local save test.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException('Auth unavailable during local save test.');
  }

  @override
  Future<void> signOut() {
    throw const AuthException('Auth unavailable during local save test.');
  }
}

class _InteractiveAuthRepository implements AuthRepository {
  AppUser? _user;

  @override
  Future<AppUser?> currentUser() async {
    return _user ??
        const AppUser(
          id: 'local-anonymous-user',
          displayName: 'Local Collector',
          email: null,
          isAnonymous: true,
          isLocalOnly: true,
          provider: AuthProviderType.localAnonymous,
        );
  }

  @override
  Future<AppUser> signIn() async {
    return signInAnonymously();
  }

  @override
  Future<AppUser> signInAnonymously() async {
    _user = const AppUser(
      id: 'local-anonymous-user',
      displayName: 'Local Collector',
      email: null,
      isAnonymous: true,
      isLocalOnly: true,
      provider: AuthProviderType.localAnonymous,
    );
    return _user!;
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _user = AppUser(
      id: 'email-user',
      displayName: email,
      email: email,
      provider: AuthProviderType.emailPassword,
    );
    return _user!;
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return signInWithEmailPassword(email: email, password: password);
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException('Google sign-in is coming soon.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException('Apple sign-in is coming soon.');
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }
}

class _FailingSyncService implements SyncService {
  const _FailingSyncService();

  @override
  Future<SyncStatus> currentStatus() {
    throw StateError('cloud unavailable during local save test');
  }

  @override
  Future<SyncStatus> markPending(List<CollectibleItem> localItems) {
    throw StateError('cloud unavailable during local save test');
  }

  @override
  Future<SyncStatus> syncLocalItems(List<CollectibleItem> localItems) {
    throw StateError('cloud unavailable during local save test');
  }

  @override
  Future<List<CollectibleItem>> downloadCloudItems() {
    throw StateError('cloud unavailable during local save test');
  }
}

class _MemoryUsageRepository implements UsageRepository {
  _MemoryUsageRepository({int initialCount = 0}) : count = initialCount;

  int count;

  @override
  Future<int> scansUsedToday() async {
    return count;
  }

  @override
  Future<int> incrementScansUsedToday() async {
    count += 1;
    return count;
  }

  @override
  Future<void> resetUsage() async {
    count = 0;
  }
}

class _SelectedCameraService extends CameraService {
  @override
  Future<XFile?> pickImageFromCamera() async {
    return XFile(_fixturePath('persistent-camera-card.jpg'));
  }

  @override
  Future<XFile> persistCapturedImage(XFile image) async {
    return XFile(_fixturePath('persistent-camera-card.jpg'));
  }
}

class _DelayedPersistCameraService extends CameraService {
  final Completer<XFile> _persistCompleter = Completer<XFile>();

  @override
  Future<XFile?> pickImageFromCamera() async {
    return XFile(_fixturePath('persistent-camera-card.jpg'));
  }

  @override
  Future<XFile> persistCapturedImage(XFile image) {
    return _persistCompleter.future;
  }

  void complete() {
    if (_persistCompleter.isCompleted) {
      return;
    }

    _persistCompleter.complete(
      XFile(_fixturePath('persistent-camera-card.jpg')),
    );
  }
}

class _CancelledCameraService extends CameraService {
  @override
  Future<XFile?> pickImageFromCamera() async {
    return null;
  }
}

class _MissingCameraService extends CameraService {
  @override
  Future<XFile?> pickImageFromCamera() async {
    return XFile(_fixturePath('missing-camera-card.jpg'));
  }

  @override
  Future<XFile> persistCapturedImage(XFile image) async {
    return XFile(_fixturePath('missing-persistent-camera-card.jpg'));
  }
}

class _LostDataCameraService extends CameraService {
  @override
  Future<XFile?> retrieveLostImage() async {
    return XFile(_fixturePath('persistent-camera-card.jpg'));
  }
}

class _FailingAIRecognitionService implements AIRecognitionService {
  const _FailingAIRecognitionService();

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) {
    throw const NetworkException(message: 'Network connection failed.');
  }
}

class _DelayedAIRecognitionService implements AIRecognitionService {
  const _DelayedAIRecognitionService();

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const _FakeAIRecognitionService().recognizeCollectible(image);
  }
}

class _FakeAIRecognitionService implements AIRecognitionService {
  const _FakeAIRecognitionService();

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) async {
    return RecognitionResult(
      success: true,
      filename: 'scan.png',
      imageUrl: 'http://192.168.0.81:8000/uploads/scan.png',
      title: '1999 Pokémon Charizard',
      category: 'Trading Card',
      confidence: 0.94,
      description: 'Likely a Pokémon Base Set Charizard.',
      estimatedValue: 1850,
      condition: 'Near Mint',
      recommendation: 'Consider grading before selling.',
      primaryMatch: '1999 Pokemon Charizard Holo',
      alternativeMatches: const [
        RecognitionAlternativeMatch(
          title: '2016 Pokemon Evolutions Charizard',
          category: 'Trading Card',
          confidence: 0.68,
          reason: 'Similar artwork and card layout.',
        ),
        RecognitionAlternativeMatch(
          title: 'Pokemon Charizard Promo',
          category: 'Trading Card',
          confidence: 0.61,
          reason: 'Character match is plausible.',
        ),
        RecognitionAlternativeMatch(
          title: 'Pokemon Expedition Charizard',
          category: 'Trading Card',
          confidence: 0.58,
          reason: 'Shares fire-type character cues.',
        ),
      ],
      confidenceExplanation:
          'High confidence from character artwork and holographic cues.',
      detectionQuality: 'Good',
      aiReasoning:
          'The image shows a Charizard-like Pokemon card with collector cues.',
      pricing: PricingInfo(
        estimatedMarketValue: 1850,
        lowEstimate: 1443,
        highEstimate: 2257,
        currency: 'AUD',
        pricingSource: 'Mock market blend: TCGplayer + eBay comps',
        pricingConfidence: 0.85,
        lastUpdated: DateTime.parse('2026-06-29T00:00:00Z'),
      ),
      year: '1999',
      brand: 'Pokemon',
      setName: 'Base Set',
      series: 'Pokemon TCG',
      cardNumber: '4/102',
      playerOrCharacter: 'Charizard',
      rarity: 'Holo Rare',
      estimatedGrade: 'PSA 8-9',
      language: 'English',
      edition: 'Unlimited',
      country: 'United States',
      material: 'Cardstock',
      notes: 'Verify holo surface.',
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
    return XFile(_fixturePath('persistent-gallery-card.jpg'));
  }

  @override
  Future<bool> validateImage(XFile image) async {
    return true;
  }

  @override
  Future<XFile> persistSelectedImage(XFile image) async {
    return XFile(_fixturePath('persistent-gallery-card.jpg'));
  }
}

class _MissingGalleryService extends GalleryService {
  @override
  Future<XFile?> pickImage() async {
    return XFile(_fixturePath('missing-gallery-card.jpg'));
  }

  @override
  Future<bool> validateImage(XFile image) async {
    return true;
  }

  @override
  Future<XFile> persistSelectedImage(XFile image) async {
    return XFile(_fixturePath('missing-persistent-gallery-card.jpg'));
  }
}

String _fixturePath(String name) {
  return File('test/fixtures/$name').absolute.path;
}
