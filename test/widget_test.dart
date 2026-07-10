import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:collectiq_ai/main.dart';
import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/domain/analyzer/analyzer_models.dart';
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
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/portfolio_visual_analytics.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/portfolio/domain/services/demo_collectible_seed_service.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/image_enhancement_preview_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/camera_capture_page.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/services/image_enhancement_service.dart';
import 'package:collectiq_ai/features/scanner/services/image_quality_assessment_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/usage_repository.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows bottom navigation tabs', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Scan'), findsWidgets);
    expect(find.text('Portfolio'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('bottom navigation switches all major tabs without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    expect(find.text('Your Collection Hub'), findsOneWidget);

    await tester.tap(find.text('Portfolio').last);
    await tester.pumpAndSettle();
    expect(find.text('Total collection value'), findsOneWidget);
    expectNoFlutterError(tester);

    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();
    expect(find.text('AI Scanner'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
    expectNoFlutterError(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);
    expectNoFlutterError(tester);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Your Collection Hub'), findsOneWidget);
    expectNoFlutterError(tester);
  });

  testWidgets('onboarding appears on first launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(onboardingCompleted: false);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to PackLox'), findsOneWidget);
    expect(find.text('How PackLox works'), findsOneWidget);
    expect(find.text('Local-first by default'), findsOneWidget);
    expect(find.text('Start Scanning'), findsOneWidget);
    expect(find.text('Explore Dashboard'), findsOneWidget);
    expect(find.textContaining('Mock AI'), findsNothing);
    expect(find.textContaining('mock analysis'), findsNothing);
    expect(find.textContaining('beta'), findsNothing);
    expect(find.textContaining('Supabase'), findsNothing);
    expect(find.textContaining('SIT'), findsNothing);
    expect(find.textContaining('API'), findsNothing);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('onboarding Start Scanning navigates to Scan', (
    WidgetTester tester,
  ) async {
    final repository = _FakeOnboardingRepository(completed: false);
    await tester.pumpCollectIqApp(onboardingRepository: repository);
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('onboarding-start-scanning')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-start-scanning')));
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(find.text('AI Scanner'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
  });

  testWidgets('onboarding Explore Dashboard goes Home', (
    WidgetTester tester,
  ) async {
    final repository = _FakeOnboardingRepository(completed: false);
    await tester.pumpCollectIqApp(onboardingRepository: repository);
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('onboarding-explore-dashboard')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('onboarding-explore-dashboard')),
    );
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(find.text('Your Collection Hub'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Welcome to PackLox'), findsNothing);
  });

  testWidgets('onboarding does not reappear after completion', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(onboardingCompleted: true);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to PackLox'), findsNothing);
    expect(find.text('Your Collection Hub'), findsOneWidget);
  });

  testWidgets('portfolio value trend widget renders with snapshot data', (
    WidgetTester tester,
  ) async {
    await tester.pumpVisualAnalytics(
      PortfolioValueTrendCard(
        snapshots: [
          _visualSnapshot(value: 1000, day: 28),
          _visualSnapshot(value: 1400, day: 30),
        ],
      ),
    );

    expect(find.text('Value History'), findsOneWidget);
    expect(find.text('AUD 1,400'), findsOneWidget);
    expect(find.textContaining('Change +AUD 400'), findsOneWidget);
  });

  testWidgets('portfolio value trend widget renders empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpVisualAnalytics(
      const PortfolioValueTrendCard(snapshots: []),
    );

    expect(find.text('Value History'), findsOneWidget);
    expect(find.text('No value history yet'), findsOneWidget);
  });

  testWidgets('category allocation visual renders category labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpVisualAnalytics(
      const CategoryAllocationVisual(
        distribution: {CollectorCategory.cards: 3, CollectorCategory.coins: 1},
      ),
    );

    expect(find.text('Category Allocation'), findsOneWidget);
    expect(find.text('Cards'), findsOneWidget);
    expect(find.text('3 / 75%'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(find.text('1 / 25%'), findsOneWidget);
  });

  testWidgets('top gainer and loser visual cards render movement labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpVisualAnalytics(
      Column(
        children: const [
          PortfolioMoverVisualCard(
            title: 'Top Gainer',
            mover: PortfolioValueMover(
              itemId: 'gain',
              title: 'Rising Charizard',
              category: 'Trading Card',
              previousValue: 1000,
              currentValue: 1250,
            ),
            positive: true,
          ),
          SizedBox(height: 12),
          PortfolioMoverVisualCard(
            title: 'Top Loser',
            mover: PortfolioValueMover(
              itemId: 'loss',
              title: 'Cooling Coin',
              category: 'Coin',
              previousValue: 500,
              currentValue: 400,
            ),
            positive: false,
          ),
        ],
      ),
    );

    expect(find.text('Top Gainer'), findsOneWidget);
    expect(find.text('Rising Charizard'), findsOneWidget);
    expect(find.text('+AUD 250'), findsOneWidget);
    expect(find.text('Top Loser'), findsOneWidget);
    expect(find.text('Cooling Coin'), findsOneWidget);
    expect(find.text('-AUD 100'), findsOneWidget);
  });

  testWidgets('shows home dashboard content', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    expect(find.text('PackLox'), findsOneWidget);
    expect(find.text('Your Collection Hub'), findsOneWidget);
    expect(find.text('0 items'), findsOneWidget);
    expect(find.text(r'$0'), findsWidgets);
    expect(find.text('Ready to scan'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == 'Good morning' ||
                widget.data == 'Good afternoon' ||
                widget.data == 'Good evening' ||
                widget.data == 'Welcome back'),
      ),
      findsOneWidget,
    );
    expect(find.text('Scan'), findsWidgets);
    expect(find.text('Import Photo'), findsOneWidget);
    expect(find.text('From gallery'), findsOneWidget);
    expect(find.text('Portfolio'), findsWidgets);
    expect(find.text('Trends'), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Soon'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    await tester.reveal(find.text('Portfolio Overview'));
    expect(find.text('Portfolio Overview'), findsWidgets);
    expect(
      find.text('Start with one scan to build your collection timeline.'),
      findsOneWidget,
    );
    await tester.reveal(find.text('Recent Activity'));
    expect(
      find.text('No recent activity yet. Scan your first collectible.'),
      findsOneWidget,
    );
    await tester.reveal(find.text('AI Insights'));
    expect(find.text('AI Insights'), findsWidgets);
    expect(find.text('Portfolio Confidence • Learning'), findsOneWidget);
    expect(
      find.text(
        'Scan one collectible to unlock valuation, rarity clues, and recommendations.',
      ),
      findsOneWidget,
    );
    expect(find.text('Starter Categories'), findsNothing);
    expect(find.text('Collection Value'), findsNothing);
    expect(find.text('System Status'), findsNothing);
    expect(find.text('Start PackLox Scan'), findsNothing);
    expect(find.text('Start First Scan'), findsNothing);
    expect(find.text('Dashboard Insights'), findsNothing);
    expect(find.text('Category Breakdown'), findsNothing);
  });

  testWidgets('home shows local price alert summary', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"alert-card","title":"Alert Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Hold.","imagePath":"sample://card","createdAt":"2026-06-27T00:00:00.000"}]',
      'price_alerts':
          '[{"id":"alert-1","itemId":"alert-card","itemTitle":"Alert Charizard","rule":{"type":"priceRisesAboveAmount","amount":1800},"status":"active","createdAt":"2026-06-29T00:00:00.000","updatedAt":"2026-06-29T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Portfolio Overview'), findsWidgets);
    await tester.reveal(find.byKey(const ValueKey('home-recent-alert-card')));
    expect(find.text('Alert Charizard'), findsWidgets);
    expect(find.text('Collection Value'), findsNothing);
    expect(find.text('System Status'), findsNothing);
  });

  testWidgets('home dashboard analytics render from portfolio data', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"home-card","title":"Dashboard Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Grade it.","imagePath":"sample://card","createdAt":"2026-06-27T00:00:00.000","marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Rising","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold"],"comps":[]}},{"id":"home-coin","title":"Dashboard Silver Eagle","category":"Coin","estimatedValue":300,"confidence":0.70,"condition":"Mint","recommendation":"Store safely.","imagePath":"sample://coin","createdAt":"2026-06-26T00:00:00.000"},{"id":"home-comic","title":"Dashboard Spider-Man","category":"Comic","estimatedValue":600,"confidence":0.88,"condition":"Fine","recommendation":"Bag and board.","imagePath":"sample://comic","createdAt":"2026-06-10T00:00:00.000"}]',
      'wishlist_status_entries':
          '[{"itemId":"home-coin","title":"Dashboard Silver Eagle","category":"Coin","status":"wanted","updatedAt":"2026-06-30T00:00:00.000"},{"itemId":"missing-card","title":"Missing Blastoise","category":"Trading Card","status":"missing","updatedAt":"2026-06-29T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.reveal(find.text('Portfolio Overview'));
    expect(find.text('Portfolio Overview'), findsWidgets);
    expect(find.text('Dashboard Charizard'), findsWidgets);
    expect(find.text('Dashboard Silver Eagle'), findsWidgets);
    expect(find.text('Categories'), findsWidgets);
    expect(find.text('3 types'), findsOneWidget);
    expect(find.text('Top asset'), findsWidgets);
    expect(find.text('Trend'), findsWidgets);
    expect(find.text('Ready to grow your collection?'), findsNothing);
    await tester.reveal(find.text('AI Insights'));
    expect(find.text('AI Insights'), findsWidgets);
    expect(find.text('Portfolio Confidence • Excellent (84%)'), findsOneWidget);
    expect(
      find.text(
        'Dashboard Charizard is currently your highest value collectible.',
      ),
      findsOneWidget,
    );
    expect(find.text(r'$2,750'), findsWidgets);
    expect(find.text('Collection Value'), findsNothing);
    expect(find.text('System Status'), findsNothing);
  });

  testWidgets('small portfolio CTA appears only below three items', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(430, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpCollectIqApp();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('home-small-portfolio-cta')),
      findsOneWidget,
    );
    expect(find.text('Ready to grow your collection?'), findsOneWidget);
    expect(find.text('Scan New Collectible'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"item-1","title":"Item One","category":"Trading Card","estimatedValue":100,"confidence":0.80,"condition":"Good","recommendation":"Hold.","imagePath":"sample://card","createdAt":"2026-07-06T10:00:00.000"},{"id":"item-2","title":"Item Two","category":"Coin","estimatedValue":200,"confidence":0.82,"condition":"Fine","recommendation":"Hold.","imagePath":"sample://coin","createdAt":"2026-07-06T09:00:00.000"},{"id":"item-3","title":"Item Three","category":"Comic","estimatedValue":300,"confidence":0.84,"condition":"Fine","recommendation":"Hold.","imagePath":"sample://comic","createdAt":"2026-07-06T08:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('home-small-portfolio-cta')),
      findsNothing,
    );
  });

  testWidgets('home recent activity uses relative saved labels', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    SharedPreferences.setMockInitialValues({
      'portfolio_items': jsonEncode([
        {
          'id': 'saved-today',
          'title': 'Saved Today Card',
          'category': 'Trading Card',
          'estimatedValue': 100,
          'confidence': 0.80,
          'condition': 'Good',
          'recommendation': 'Hold.',
          'imagePath': 'sample://card',
          'createdAt': now.toIso8601String(),
        },
        {
          'id': 'saved-yesterday',
          'title': 'Saved Yesterday Coin',
          'category': 'Coin',
          'estimatedValue': 200,
          'confidence': 0.82,
          'condition': 'Fine',
          'recommendation': 'Hold.',
          'imagePath': 'sample://coin',
          'createdAt': yesterday.toIso8601String(),
        },
        {
          'id': 'saved-two-days',
          'title': 'Saved Two Days Comic',
          'category': 'Comic',
          'estimatedValue': 300,
          'confidence': 0.84,
          'condition': 'Fine',
          'recommendation': 'Hold.',
          'imagePath': 'sample://comic',
          'createdAt': twoDaysAgo.toIso8601String(),
        },
      ]),
    });

    await tester.pumpCollectIqApp();
    await tester.pumpAndSettle();

    await tester.reveal(find.text('Recent Activity'));
    expect(find.text('Saved today'), findsOneWidget);
    expect(find.text('Saved yesterday'), findsOneWidget);
    expect(find.text('Saved 2 days ago'), findsOneWidget);
  });

  testWidgets('home dashboard updates after saving a scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.reveal(find.text('Save to Portfolio'));
    await tester.pump();
    await tester.tap(find.text('Save to Portfolio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.reveal(find.text('Portfolio Overview'));
    expect(find.text('Portfolio Overview'), findsWidgets);
    await tester.reveal(find.text('Recent Activity'));
    expect(find.text('Recent Activity'), findsWidgets);
    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('Collection Value'), findsNothing);
    expect(find.text('System Status'), findsNothing);
  });

  testWidgets('home scan button selects Scan tab', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.byKey(const ValueKey('home-quick-action-Scan')));
    await tester.pumpAndSettle();

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
  });

  testWidgets('home import photo quick action opens gallery flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _SelectedGalleryService());

    await tester.tap(
      find.byKey(const ValueKey('home-quick-action-Import Photo')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.acceptEnhancementPreview();

    expect(find.text('AI Scanner'), findsOneWidget);
    await tester.pumpUntilFound(find.text('Gallery image'));
    expect(find.text('Gallery image'), findsOneWidget);
  });

  testWidgets('shell recreation returns to Home and Scan still works', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.byKey(const ValueKey('home-quick-action-Scan')));
    await tester.pumpAndSettle();
    expect(find.text('AI Scanner'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpCollectIqApp();
    await tester.pumpAndSettle();

    expect(find.text('AI Scanner'), findsNothing);
    expect(find.text('Quick Actions'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-quick-action-Scan')));
    await tester.pumpAndSettle();

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
  });

  testWidgets('shows scanner experience content', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(
      find.text('Instantly identify and value collectibles.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-secondary-Gallery')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
      findsOneWidget,
    );
    expect(find.text('Analyze with AI'), findsNothing);
    expect(find.text('Supported Categories'), findsOneWidget);
    expect(find.text('How It Works'), findsOneWidget);
    expect(find.text('Unlimited AI Scans'), findsOneWidget);
  });

  testWidgets('shows portfolio empty state', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pumpAndSettle();
    await tester.pump();

    await tester.reveal(find.text('No collectibles saved yet'));
    expect(find.text('Portfolio'), findsWidgets);
    expect(find.text('No collectibles saved yet'), findsOneWidget);
    expect(
      find.textContaining('alerts, wishlist status, and goals'),
      findsOneWidget,
    );
    expect(find.text('Scan Collectible'), findsWidgets);
  });

  testWidgets('shows settings screen content', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Profile info'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    await tester.reveal(find.text('Account Access'));
    expect(find.text('Account Access'), findsOneWidget);
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
    expect(
      find.byKey(const ValueKey('settings-auth-forgot-password-button')),
      findsOneWidget,
    );

    await tester.reveal(find.text('Backup & Sync'));
    expect(find.text('Backup & Sync'), findsWidgets);
    expect(find.text('Backup status'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);

    await tester.reveal(find.text('Scanning'));
    expect(find.text('Scanning'), findsOneWidget);
    expect(find.text('Scan quality'), findsOneWidget);
    expect(find.text('Estimate guidance'), findsOneWidget);

    await tester.reveal(find.text('Notifications'));
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Price alerts'), findsOneWidget);
    expect(find.text('Permissions'), findsOneWidget);

    await tester.reveal(find.text('Appearance'));
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('First-launch onboarding'), findsOneWidget);

    await tester.reveal(find.text('Help & About'));
    expect(find.text('Help & About'), findsOneWidget);
    expect(find.text('About PackLox'), findsOneWidget);
    expect(find.text('Export portfolio'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Developer Tools'), findsNothing);
    expect(find.text('Developer Diagnostics'), findsNothing);
    expect(find.text('Mock mode active'), findsNothing);
    expect(find.text('Supabase Project'), findsNothing);
    expect(find.text('SIT readiness'), findsNothing);
    expect(find.text('API backend'), findsNothing);
    expect(find.textContaining('not configured'), findsNothing);
  });
  testWidgets('settings rows respond with safe local messages', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.reveal(find.text('Theme'));
    await tester.pump();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    expect(
      find.text('Theme follows the system setting for now.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));

    await tester.reveal(find.text('Export portfolio'));
    await tester.pump();
    await tester.tap(find.text('Export portfolio'));
    await tester.pumpAndSettle();
    expect(find.text('Portfolio export is coming soon.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('settings disabled cloud controls show config-required state', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.reveal(find.text('Backup & Sync'));
    await tester.pump();

    expect(
      find.text('Sign in to prepare backup and restore for your collection.'),
      findsOneWidget,
    );
    final syncButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sync Now'),
    );
    expect(syncButton.onPressed, isNull);

    expect(find.text('Local only'), findsWidgets);
  });

  testWidgets('backup and sync route renders consumer copy without diagnostics', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.openSettings();
    await tester.reveal(find.text('Backup & Sync'));
    await tester.pump();
    await tester.tap(find.text('Backup & Sync').last);
    await tester.pumpAndSettle();

    expect(find.text('PackLox Backup & Restore'), findsOneWidget);
    expect(find.text('Backup details'), findsOneWidget);
    expect(find.text('Backup Location'), findsOneWidget);
    expect(find.text('Storage Usage'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);
    expect(
      find.text(
        'Sign in to enable backup and restore. Your local portfolio stays on this device.',
      ),
      findsOneWidget,
    );
    expect(find.text('Diagnostics'), findsNothing);
    expect(find.text('Supabase Project'), findsNothing);
    expect(find.textContaining('Supabase'), findsNothing);
    expect(find.textContaining('not configured'), findsNothing);
    expect(find.textContaining('API backend'), findsNothing);
    expect(find.textContaining('SIT'), findsNothing);
  });

  testWidgets('about route renders PackLox info without placeholder links', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.openSettings();
    await tester.reveal(find.text('About PackLox'));
    await tester.pump();
    await tester.tap(find.text('About PackLox'));
    await tester.pumpAndSettle();

    expect(find.text('About PackLox'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Storage Location'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('Terms of Service'), findsNothing);
    expect(find.text('Documentation'), findsNothing);
    expect(find.textContaining('Flutter'), findsNothing);
    expect(find.textContaining('Supabase'), findsNothing);
    expect(find.textContaining('will open here before release'), findsNothing);
  });

  testWidgets('reset onboarding works from Settings', (
    WidgetTester tester,
  ) async {
    final repository = _FakeOnboardingRepository(completed: true);
    await tester.pumpCollectIqApp(onboardingRepository: repository);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.reveal(
      find.byKey(const ValueKey('settings-reset-onboarding-button')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('settings-reset-onboarding-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.completed, isFalse);
    expect(find.text('Welcome to PackLox'), findsOneWidget);
  });

  testWidgets('settings signs in with mocked email auth repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(authRepository: _InteractiveAuthRepository());

    await tester.openSettings();
    await tester.enterSettingsAuthCredentials(
      email: 'harry@example.com',
      password: 'password123',
    );
    final signInButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('settings-auth-sign-in-button')),
    );
    signInButton.onPressed!();
    await tester.pump();
    await tester.pumpAndSettle();

    final navigation = tester.widget<GlassBottomNavBar>(
      find.byType(GlassBottomNavBar),
    );
    expect(navigation.currentIndex, 0);
    expect(find.text(AuthMessages.signedIn), findsOneWidget);

    await tester.openSettings();
    await tester.reveal(
      find.byKey(const ValueKey('settings-auth-account-panel')),
    );
    await tester.pump();

    expect(find.text('harry@example.com'), findsWidgets);
    expect(find.text('Connected'), findsWidgets);
    expect(
      find.byKey(const ValueKey('settings-auth-sign-out-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-email-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-sign-in-button')),
      findsNothing,
    );
  });

  testWidgets('settings blocks empty Sign Up before repository call', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository();
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    final signUpButton = find.byKey(
      const ValueKey('settings-auth-sign-up-button'),
    );
    await tester.reveal(signUpButton);
    await tester.pump();
    await tester.tap(signUpButton);
    await tester.pump();

    expect(find.text('Enter an email address.'), findsWidgets);
    expect(
      find.byKey(const ValueKey('settings-auth-sign-out-button')),
      findsNothing,
    );
    expect(authRepository.signUpCalls, 0);
  });

  testWidgets('settings blocks empty Sign In before repository call', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository();
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    final signInButton = find.byKey(
      const ValueKey('settings-auth-sign-in-button'),
    );
    await tester.reveal(signInButton);
    await tester.pump();
    await tester.tap(signInButton);
    await tester.pump();

    expect(find.text('Enter an email address.'), findsWidgets);
    expect(
      find.byKey(const ValueKey('settings-auth-sign-out-button')),
      findsNothing,
    );
    expect(authRepository.signInCalls, 0);
  });

  testWidgets('settings shows email confirmation message after Sign Up', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository(
      signUpError: const SupabaseEmailConfirmationRequiredException(),
    );
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    await tester.enterSettingsAuthCredentials();
    final signUpButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('settings-auth-sign-up-button')),
    );
    signUpButton.onPressed!();
    await tester.pump();
    await tester.pump();

    expect(
      find.text(SupabaseEmailConfirmationRequiredException.message),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-sign-out-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-sign-in-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-resend-confirmation-button')),
      findsOneWidget,
    );
    expect(authRepository.signUpCalls, 1);
    expect(authRepository.signInCalls, 0);
  });

  testWidgets('settings resends confirmation only when confirmation required', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository(
      signUpError: const SupabaseEmailConfirmationRequiredException(),
    );
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    expect(
      find.byKey(const ValueKey('settings-auth-resend-confirmation-button')),
      findsNothing,
    );
    await tester.enterSettingsAuthCredentials();
    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('settings-auth-sign-up-button')),
        )
        .onPressed!();
    await tester.pump();
    await tester.pump();

    final resendButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('settings-auth-resend-confirmation-button')),
    );
    resendButton.onPressed!();
    await tester.pump();
    await tester.pump();

    expect(find.text(AuthMessages.confirmationEmailSent), findsWidgets);
    expect(find.textContaining('Resend available in'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-auth-sign-out-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-sign-in-button')),
      findsOneWidget,
    );
    final blockedResendButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('settings-auth-resend-confirmation-button')),
    );
    expect(blockedResendButton.onPressed, isNull);
    expect(authRepository.signUpCalls, 1);
    expect(authRepository.resendCalls, 1);
    expect(authRepository.lastResendEmail, 'collector@example.com');
  });

  testWidgets('settings shows resend after unconfirmed Sign In', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository(
      signInError: const SupabaseAuthException(
        'Please confirm your email before signing in.',
      ),
    );
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    await tester.enterSettingsAuthCredentials();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('settings-auth-sign-in-button')),
        )
        .onPressed!();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Please confirm your email before signing in.'),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-resend-confirmation-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-sign-out-button')),
      findsNothing,
    );
  });

  testWidgets('settings resend rate limit shows clear wait message', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository(
      signUpError: const SupabaseEmailConfirmationRequiredException(),
      resendError: const SupabaseConfirmationRateLimitedException(
        cooldown: Duration(minutes: 5),
        cooldownSource: 'fallback',
      ),
    );
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    await tester.enterSettingsAuthCredentials();
    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('settings-auth-sign-up-button')),
        )
        .onPressed!();
    await tester.pump();
    await tester.pump();
    tester
        .widget<OutlinedButton>(
          find.byKey(
            const ValueKey('settings-auth-resend-confirmation-button'),
          ),
        )
        .onPressed!();
    await tester.pump();
    await tester.pump();

    expect(find.text(AuthMessages.confirmationRateLimited), findsWidgets);
    expect(find.text(AuthMessages.confirmationEmailSent), findsNothing);
    expect(find.textContaining('Resend available in'), findsOneWidget);
    expect(authRepository.resendCalls, 1);
  });

  testWidgets('settings shows SIT resend diagnostics', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      environmentConfig: const EnvironmentConfig(
        environment: AppEnvironment.sit,
      ),
    );

    await tester.openSettings();
    await tester.reveal(find.text('Pending confirmation email'));
    await tester.pump();

    expect(find.text('Pending confirmation email'), findsOneWidget);
    expect(find.text('Last resend attempted'), findsOneWidget);
    expect(find.text('Last resend status'), findsOneWidget);
    expect(find.text('Cooldown remaining'), findsOneWidget);
    expect(find.text('Cooldown source'), findsOneWidget);
    expect(find.text(AuthMessages.confirmationTestingTip), findsOneWidget);
  });

  testWidgets('settings sends password reset email', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository();
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    await tester.enterSettingsAuthEmail('reset@example.com');
    await tester.reveal(
      find.byKey(const ValueKey('settings-auth-forgot-password-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-auth-forgot-password-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text(AuthMessages.passwordResetSentWithCooldown), findsWidgets);
    expect(authRepository.passwordResetCalls, 1);
    expect(authRepository.lastPasswordResetEmail, 'reset@example.com');
    final forgotPasswordButton = tester.widget<TextButton>(
      find.byKey(const ValueKey('settings-auth-forgot-password-button')),
    );
    expect(forgotPasswordButton.onPressed, isNull);
  });

  testWidgets('settings shows password reset rate-limit message', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository(
      passwordResetError: const SupabasePasswordResetRateLimitedException(
        cooldown: Duration(minutes: 5),
        cooldownSource: 'fallback',
      ),
    );
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    await tester.enterSettingsAuthEmail('reset@example.com');
    await tester.reveal(
      find.byKey(const ValueKey('settings-auth-forgot-password-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-auth-forgot-password-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text(AuthMessages.passwordResetRateLimited), findsWidgets);
    expect(authRepository.passwordResetCalls, 1);
  });

  testWidgets('settings shows password reset errors cleanly', (
    WidgetTester tester,
  ) async {
    final authRepository = _InteractiveAuthRepository(
      passwordResetError: const SupabaseAuthException(
        'Unable to reach Supabase. Check your internet connection.',
      ),
    );
    await tester.pumpCollectIqApp(authRepository: authRepository);

    await tester.openSettings();
    await tester.enterSettingsAuthEmail('reset@example.com');
    await tester.reveal(
      find.byKey(const ValueKey('settings-auth-forgot-password-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-auth-forgot-password-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to reach Supabase. Check your internet connection.'),
      findsWidgets,
    );
    expect(authRepository.passwordResetCalls, 1);
  });

  testWidgets('settings does not show Sign Out for anonymous cloud session', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      authRepository: _InteractiveAuthRepository(
        initialUser: const AppUser(
          id: 'anonymous-user',
          displayName: 'Anonymous Collector',
          email: null,
          isAnonymous: true,
          provider: AuthProviderType.supabaseAnonymous,
        ),
      ),
    );

    await tester.openSettings();
    await tester.reveal(
      find.byKey(const ValueKey('settings-auth-signed-out-panel')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('settings-auth-signed-out-panel')),
      findsOneWidget,
    );
    expect(find.text('Anonymous'), findsWidgets);
    expect(
      find.byKey(const ValueKey('settings-auth-sign-out-button')),
      findsNothing,
    );
  });

  testWidgets(
    'settings shows account panel instead of auth form when signed in',
    (WidgetTester tester) async {
      await tester.pumpCollectIqApp(
        authRepository: _InteractiveAuthRepository(
          initialUser: const AppUser(
            id: 'email-user',
            displayName: 'Signed In Collector',
            email: 'collector@example.com',
            provider: AuthProviderType.emailPassword,
          ),
        ),
      );

      await tester.openSettings();
      final accountPanel = find.byKey(
        const ValueKey('settings-auth-account-panel'),
      );
      final settingsScrollView = find.byType(Scrollable).last;
      for (var attempt = 0; attempt < 12; attempt += 1) {
        if (accountPanel.evaluate().isNotEmpty) {
          break;
        }
        await tester.drag(settingsScrollView, const Offset(0, -320));
        await tester.pump();
      }
      await tester.pump();

      expect(
        find.byKey(const ValueKey('settings-auth-resend-confirmation-button')),
        findsNothing,
      );
      expect(accountPanel, findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-auth-email-field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('settings-auth-sign-in-button')),
        findsNothing,
      );
      expect(find.text('collector@example.com'), findsWidgets);
      expect(find.text('Auth status connected'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-auth-sign-out-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets('settings hides configured AI provider internals', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProviderConfig: const AiAnalysisProviderConfig(
        type: AiAnalysisProviderType.openAiVision,
      ),
    );

    await tester.openSettings();
    await tester.reveal(find.text('Scanning'));
    await tester.pump();

    expect(find.text('Scanning'), findsOneWidget);
    expect(find.text('Estimate guidance'), findsOneWidget);
    expect(find.text('Current AI provider'), findsNothing);
    expect(find.text('OpenAI Vision'), findsNothing);
    expect(find.text('Unavailable'), findsNothing);
  });

  testWidgets('switches between feature placeholders', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();

    expect(find.text('Portfolio'), findsWidgets);
  });

  testWidgets('scanner gallery button opens picker without placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _FakeGalleryService());

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Gallery picker coming next'), findsNothing);
  });

  testWidgets('scanner camera capture shows preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pumpUntilFound(find.text('Captured image'));

    expect(find.text('Captured image'), findsOneWidget);
    expect(find.text('Ready for AI analysis'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .any((image) => image.fit == BoxFit.cover),
      isTrue,
    );
  });

  testWidgets('empty scanner category stays awaiting scan state', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();

    expect(find.text('Not selected yet'), findsWidgets);
    expect(find.text('0 photos'), findsWidgets);
    expect(find.text('--'), findsWidgets);
    expect(find.text('Selected: Toy car'), findsNothing);
    expect(find.text('Detected: Toy car'), findsNothing);
    expect(
      find.byKey(const ValueKey('scan-enhance-active-photo')),
      findsNothing,
    );
  });

  testWidgets('manual and detected scanner categories are labeled clearly', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-category-toy_car')));
    await tester.pumpAndSettle();

    expect(find.text('Selected: Toy car'), findsWidgets);

    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(find.text('Detected: Pokemon Card'), findsWidgets);
  });

  testWidgets('scanner slot updates after captured front image', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pumpUntilFound(find.text('Captured image'));

    expect(find.text('Captured image'), findsOneWidget);
  });

  testWidgets('camera denied UI shows friendly message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraServiceProvider.overrideWithValue(_DeniedCameraService()),
        ],
        child: const MaterialApp(home: CameraCapturePage(imageRole: 'front')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Camera permission is required to capture scans.'),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('camera return shows preparing image bridge before preview', (
    WidgetTester tester,
  ) async {
    final cameraService = _DelayedPersistCameraService();
    await tester.pumpCollectIqApp(cameraService: cameraService);

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pumpUntilFound(find.text('Preparing image...'));

    expect(find.text('Preparing your PackLox scan.'), findsOneWidget);
    expect(find.text('Welcome back to PackLox'), findsNothing);

    cameraService.complete();
    await tester.pumpUntilFound(find.text('Captured image'));

    expect(find.text('Captured image'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsOneWidget,
    );
  });

  testWidgets('camera completion remains on Scan tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

    await tester.tap(find.byKey(const ValueKey('home-quick-action-Scan')));
    await tester.pumpAndSettle();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pumpUntilFound(find.text('Captured image'));

    expect(find.text('Captured image'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsOneWidget,
    );
    expect(find.text('Welcome back to PackLox'), findsNothing);
  });

  testWidgets('lost Android camera data recovers to Scan tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      cameraService: _LostDataCameraService(),
      galleryService: _SelectedGalleryService(),
    );

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.pumpUntilFound(find.text('Recovered image'));

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(find.text('Recovered image'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsOneWidget,
    );
    expect(find.text('Welcome back to PackLox'), findsNothing);
  });

  testWidgets('gallery completion from Home CTA remains on Scan tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _SelectedGalleryService());

    await tester.tap(find.byKey(const ValueKey('home-quick-action-Scan')));
    await tester.pumpAndSettle();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.acceptEnhancementPreview();
    await tester.pumpUntilFound(find.text('Gallery image'));

    expect(find.text('Gallery image'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsOneWidget,
    );
    expect(find.text('Welcome back to PackLox'), findsNothing);
  });

  testWidgets('scanner camera cancellation is neutral', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _CancelledCameraService());

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();

    expect(find.text('Camera capture cancelled.'), findsNothing);
    expect(find.text('Scan interrupted'), findsNothing);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
  });

  testWidgets('camera missing image path shows error without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _MissingCameraService());

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
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
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
  });

  testWidgets('gallery missing image path shows error without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _MissingGalleryService());

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.acceptEnhancementPreview();
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
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
  });

  testWidgets('scanner sample scan shows fake AI result', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();

    expect(find.text('Sample Sports Card'), findsOneWidget);
    expect(find.text('Ready for AI analysis'), findsOneWidget);

    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('Pokemon Card'), findsWidgets);
    expect(find.text(r'$1,850'), findsWidgets);
    expect(find.text('Market pricing'), findsOneWidget);
    expect(find.text('Market Summary'), findsWidgets);
    expect(find.text('Recent comparable sales'), findsNothing);
    expect(find.textContaining('Mock pricing blend'), findsNothing);
    expect(find.textContaining('94%'), findsWidgets);
    expect(find.text('Near Mint'), findsWidgets);
    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('Condition notes'), findsOneWidget);
    expect(find.text('Alternative Matches'), findsOneWidget);
    expect(find.text('1999 Pokemon Charizard Holo variant'), findsNothing);
    expect(find.textContaining('Mock confidence'), findsNothing);
    expect(find.textContaining('Sleeve it'), findsNothing);
  });

  testWidgets('gallery import confirms enhancement before adding photo', (
    WidgetTester tester,
  ) async {
    final provider = _CapturingAiAnalysisProvider();
    await tester.pumpCollectIqApp(
      aiAnalysisProvider: provider,
      galleryService: _SelectedGalleryService(),
      imageEnhancementService: const _FakeImageEnhancementService(),
      imageQualityAssessmentService: const _FakeImageQualityAssessmentService(),
    );

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pumpUntilFound(
      find.byKey(const ValueKey('enhancement-preview-presets')),
    );

    expect(
      find.byKey(const ValueKey('enhancement-preview-presets')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsNothing,
    );
    tester
        .widget<ChoiceChip>(
          find.byKey(const ValueKey('enhancement-preview-brighten')).last,
        )
        .onSelected
        ?.call(true);
    await tester.pump(const Duration(seconds: 1));
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('enhancement-preview-use-photo')).last,
        )
        .onPressed
        ?.call();
    await tester.pumpUntilFound(
      find.text('Brighten applied'),
      timeout: const Duration(seconds: 10),
    );

    expect(find.text('Brighten applied'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final controller = container.read(scannerControllerProvider);
    expect(controller.captureImages.single.enhancementPreset.id, 'brighten');
    expect(controller.captureImages.single.qualityMetadata['enhanced'], isTrue);
    expect(
      controller.captureImages.single.qualityMetadata['readinessScore'],
      57,
    );
    expect(
      controller.captureImages.single.qualityMetadata['originalImagePath'],
      isNotEmpty,
    );

    tester
        .widget<InkWell>(
          find.byKey(const ValueKey('scan-active-capture-preview')),
        )
        .onTap
        ?.call();
    await tester.pump();
    await tester.pumpUntilFound(
      find.byKey(const ValueKey('photo-review-enhance')),
    );
    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('photo-review-enhance')),
        )
        .onPressed
        ?.call();
    await tester.pumpUntilFound(
      find.byKey(const ValueKey('enhancement-preview-presets')),
    );
    tester
        .widget<ChoiceChip>(
          find.byKey(const ValueKey('enhancement-preview-original')).last,
        )
        .onSelected
        ?.call(true);
    await tester.pump(const Duration(milliseconds: 300));
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('enhancement-preview-use-photo')).last,
        )
        .onPressed
        ?.call();
    await tester.pumpUntilFound(
      find.byKey(const ValueKey('photo-review-enhance')),
    );

    final reverted = container.read(scannerControllerProvider);
    expect(reverted.captureImages.single.enhancementPreset.id, 'original');
    expect(reverted.captureImages.single.qualityMetadata['enhanced'], isFalse);

    await container
        .read(scannerControllerProvider.notifier)
        .applyEnhancementToPhoto(
          reverted.captureImages.single,
          ImageEnhancementPreset.brighten,
        );
    await tester.pumpUntilFound(
      find.text('Brighten applied'),
      timeout: const Duration(seconds: 10),
    );
    await tester.tap(find.byKey(const ValueKey('photo-review-close')));
    await tester.pump(const Duration(seconds: 2));
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(
      provider.lastRequest?.metadata['activeEnhancementPreset'],
      'brighten',
    );
    expect(provider.lastRequest?.metadata['activeReadinessScore'], 57);
    expect(
      provider.lastRequest?.metadata['activeQualityWarnings'],
      contains('Slight blur detected'),
    );
    expect(provider.lastRequest?.metadata['enhancedImageCount'], 1);
  });

  testWidgets(
    'enhancement preview shows AI recommendation and compare toggle',
    (WidgetTester tester) async {
      ImageEnhancementPreviewResult? accepted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageEnhancementPreviewSurface(
              image: XFile(_fixturePath('persistent-gallery-card.jpg')),
              initialPreset: ImageEnhancementPreset.original,
              title: 'Review photo',
              subtitle: 'Choose the clearest version for analysis.',
              enhancementService: const _FakeImageEnhancementService(),
              assessmentService: const _FakeImageQualityAssessmentService(),
              onCancel: () {},
              onRetake: () {},
              onUsePhoto: (result) => accepted = result,
            ),
          ),
        ),
      );

      await tester.pumpUntilFound(
        find.text('AI recommends: Text / Package Clarity'),
      );
      expect(
        find.byKey(const ValueKey('enhancement-ai-recommendation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('enhancement-readiness-summary')),
        findsOneWidget,
      );
      expect(find.textContaining('57/100'), findsWidgets);
      expect(find.text('Package AI'), findsOneWidget);
      expect(find.text('Slight blur detected'), findsOneWidget);

      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('enhancement-preview-contrast')),
          )
          .onSelected
          ?.call(true);
      await tester.pump();
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey('enhancement-preview-presets')),
          matching: find.byType(Scrollable),
        ),
      );
      final offsetAfterSelection = scrollable.position.pixels;
      expect(offsetAfterSelection, greaterThanOrEqualTo(0));

      await tester.tap(
        find.byKey(const ValueKey('enhancement-preview-compare')),
      );
      await tester.pump();
      expect(find.text('Original preview'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('enhancement-preview-compare')),
      );
      await tester.pump();
      expect(find.text('Original preview'), findsNothing);

      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('enhancement-preview-use-photo')).last,
          )
          .onPressed
          ?.call();
      expect(accepted?.preset, ImageEnhancementPreset.contrast);
      expect(accepted?.metadata['readinessScore'], 57);
    },
  );

  testWidgets('enhancement preview retake and cancel do not add photos', (
    WidgetTester tester,
  ) async {
    ImageEnhancementPreviewResult? accepted;
    var retakes = 0;
    var cancels = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageEnhancementPreviewSurface(
            image: XFile(_fixturePath('persistent-gallery-card.jpg')),
            initialPreset: ImageEnhancementPreset.original,
            title: 'Review photo',
            subtitle: 'Choose the clearest version for analysis.',
            onCancel: () => cancels += 1,
            onRetake: () => retakes += 1,
            onUsePhoto: (result) => accepted = result,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('enhancement-preview-auto_enhance')),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(accepted, isNull);

    await tester.tap(find.byKey(const ValueKey('enhancement-preview-retake')));
    expect(retakes, 1);
    expect(accepted, isNull);

    await tester.tap(find.byKey(const ValueKey('enhancement-preview-cancel')));
    expect(cancels, 1);
  });

  testWidgets('saving enhanced scan preserves portfolio gallery metadata', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      galleryService: _SelectedGalleryService(),
      imageEnhancementService: const _FakeImageEnhancementService(),
      imageQualityAssessmentService: const _FakeImageQualityAssessmentService(),
    );

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pumpUntilFound(
      find.byKey(const ValueKey('enhancement-preview-presets')),
    );
    await tester.tap(
      find.byKey(const ValueKey('enhancement-preview-contrast')),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find.byKey(const ValueKey('enhancement-preview-use-photo')).last,
    );
    await tester.pumpUntilFound(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      timeout: const Duration(seconds: 10),
    );
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('scan-result-analyzed-with-enhancement')),
      findsOneWidget,
    );
    await tester.reveal(find.text('Save to Portfolio'));
    await tester.pump();
    await tester.tap(find.text('Save to Portfolio'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('portfolio_items')!;
    final item =
        (jsonDecode(stored) as List<dynamic>).first as Map<String, dynamic>;
    final gallery = item['galleryImages'] as List<dynamic>;
    final firstImage = gallery.first as Map<String, dynamic>;
    expect(firstImage['enhancementPreset'], 'contrast');
    expect(firstImage['originalPath'], isNotEmpty);
    expect(
      (firstImage['qualityMetadata'] as Map<String, dynamic>)['readinessScore'],
      57,
    );
  });

  testWidgets('scanner backend failure shows friendly message', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProvider: const _FailingAiAnalysisProvider(),
      galleryService: _SelectedGalleryService(),
    );

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.acceptEnhancementPreview();
    await tester.pumpUntilFound(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();

    expect(find.text('Provider failed safely.'), findsOneWidget);
    expect(find.text('AI Result'), findsNothing);
  });

  testWidgets('scanner controller uses AI analysis provider', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProvider: const _CustomAiAnalysisProvider(),
    );

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(find.text('Provider Test Collectible'), findsWidgets);
    expect(find.text('Recommendation'), findsOneWidget);
    expect(find.text('Provider recommendation.'), findsNothing);
    expect(find.textContaining('Mock pricing blend'), findsNothing);
    expect(find.text('Provider fixture'), findsNothing);
  });

  testWidgets('scanner pipeline status updates after mock scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
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

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
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

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
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

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
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

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
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

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
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
      aiAnalysisProvider: const _DelayedAiAnalysisProvider(),
      galleryService: _SelectedGalleryService(),
    );

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.acceptEnhancementPreview();
    await tester.pumpUntilFound(find.text('Gallery image'));

    expect(find.text('Gallery image'), findsOneWidget);

    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Gallery image'), findsOneWidget);
    expect(find.text('Analyzing scan'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Gallery image'), findsOneWidget);
    expect(find.text('Analysis Complete'), findsOneWidget);
  });

  testWidgets('premium scan result renders after image is analyzed', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    await tester.reveal(find.text('AI Review'));
    await tester.pump();

    expect(find.text('AI Review'), findsOneWidget);
    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('Estimated value'), findsOneWidget);
    expect(find.textContaining(r'$'), findsWidgets);
    expect(find.textContaining('High confidence'), findsWidgets);
    expect(find.text('Category'), findsWidgets);
    expect(find.text('Condition'), findsWidgets);
    expect(find.text('Valuation evidence'), findsOneWidget);
    expect(find.text('Pricing source'), findsNothing);
    expect(find.text('Freshness'), findsNothing);
    expect(find.text('Pricing confidence'), findsNothing);
    expect(find.textContaining('Mock pricing blend'), findsNothing);
    expect(
      find.textContaining('AI estimates are a starting point'),
      findsOneWidget,
    );
    expect(find.text('Identification details'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Save to Portfolio'), findsOneWidget);
    expect(find.text('Edit Details'), findsOneWidget);
    expect(find.text('Retry Analysis'), findsOneWidget);
  });

  testWidgets('scan result missing value shows unavailable state', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();
    await tester.completeSampleScan();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final result = container.read(scannerControllerProvider).scanResult!;
    container
        .read(scannerControllerProvider.notifier)
        .applyResultReviewEdits(
          title: result.title,
          category: result.category,
          condition: result.condition,
          estimatedValue: 0,
          notes: result.notes,
        );
    await tester.pump();

    expect(find.text('Value unavailable'), findsWidgets);
  });

  testWidgets('scan result renders valuation unavailable statuses', (
    WidgetTester tester,
  ) async {
    const cases = <ValuationStatus, String>{
      ValuationStatus.providerNotConfigured:
          'Market value unavailable — pricing source not connected yet',
      ValuationStatus.noMarketMatch: 'No reliable market match found yet',
      ValuationStatus.lookupFailed: 'Value lookup failed — try again',
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpCollectIqApp(
        aiAnalysisProvider: _ValuationStatusAiAnalysisProvider(entry.key),
      );
      await tester.completeSampleScan();

      expect(find.text(entry.value), findsWidgets);
      await tester.tap(find.text('Valuation evidence').first);
      await tester.pumpAndSettle();
      expect(find.text('Valuation status'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('scan result low confidence shows needs review', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProvider: const _LowConfidenceAiAnalysisProvider(),
    );
    await tester.completeSampleScan();

    expect(find.textContaining('Needs review'), findsWidgets);
    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('Not detected'), findsWidgets);
  });

  testWidgets('scan result edit bottom sheet updates visible fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();
    await tester.completeSampleScan();

    await tester.reveal(find.text('Edit Details'));
    await tester.pump();
    await tester.tap(find.text('Edit Details'));
    await tester.pumpAndSettle();
    expect(
      find.text('Review the AI result before saving it to your portfolio.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Reviewed Charizard',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Category'), 'Card');
    await tester.enterText(
      find.widgetWithText(TextField, 'Condition'),
      'Near Mint',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Estimated value'),
      '777',
    );
    await tester.tap(find.text('Apply Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Reviewed Charizard'), findsWidgets);
    expect(find.text(r'$777'), findsWidgets);
    expect(find.text('Near Mint'), findsWidgets);
  });

  testWidgets('scan result retry action is safe', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();
    await tester.completeSampleScan();

    await tester.reveal(find.text('Retry Analysis'));
    await tester.pump();
    await tester.tap(find.text('Retry Analysis'));
    await tester.pump();

    expect(find.text('Retry analysis coming soon'), findsOneWidget);
  });

  testWidgets('scan analysis error renders useful recovery guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      aiAnalysisProvider: const _FailingAiAnalysisProvider(),
    );

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(find.text('We need a clearer photo'), findsOneWidget);
    expect(
      find.text('Try better lighting or include the full item.'),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Choose Another Photo'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
  });

  testWidgets('scan result long title is safe on small Android width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpCollectIqApp(
      aiAnalysisProvider: const _LongTitleAiAnalysisProvider(),
    );
    await tester.completeSampleScan();

    expect(
      find.textContaining('Extremely Long Collector Variant'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scan again clears selected image and result', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.reveal(find.text('Scan Another'));
    await tester.pump();
    await tester.tap(find.text('Scan Another'));
    await tester.pumpAndSettle();

    expect(find.text('Analysis Result'), findsNothing);
    expect(find.text('Sample Sports Card'), findsNothing);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
      findsOneWidget,
    );
  });

  testWidgets('saves scanner result to portfolio', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.reveal(find.text('Save to Portfolio'));
    await tester.pump();
    await tester.tap(find.text('Save to Portfolio'));
    await tester.pumpAndSettle();

    expect(find.text('Saved to portfolio'), findsOneWidget);

    await tester.tap(find.text('Portfolio').last);
    await tester.pumpAndSettle();
    await tester.reveal(find.textContaining('Charizard'));

    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('Total collection value'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text(r'$1,850'), findsWidgets);
  });

  testWidgets('scan result save prevents duplicate portfolio items', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();
    await tester.completeSampleScan();
    await tester.reveal(find.text('Save to Portfolio'));
    await tester.pump();

    await tester.tap(find.text('Save to Portfolio'));
    await tester.tap(find.text('Save to Portfolio'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(portfolioControllerProvider).items.length, 1);
    expect(find.text('Saved to Portfolio'), findsOneWidget);
  });

  test(
    'portfolio item serialization preserves valuation status and source',
    () {
      final item = CollectibleItem(
        id: 'valuation-item',
        title: 'Hot Wheels 17 Audi RS 6 Avant',
        category: 'Die-cast Car',
        estimatedValue: 0,
        confidence: 0.92,
        condition: 'Packaged',
        recommendation: 'Review valuation status before saving.',
        imagePath: 'sample://hot-wheels',
        createdAt: DateTime.utc(2026, 7, 7),
        valuationStatus: ValuationStatus.providerNotConfigured,
        valuationSource: 'not_configured',
      );

      final restored = CollectibleItem.fromJson(item.toJson());

      expect(restored.valuationStatus, ValuationStatus.providerNotConfigured);
      expect(restored.valuationSource, 'not_configured');
      expect(restored.aiEstimatedValue, isNull);
    },
  );

  testWidgets('local portfolio save works when auth and cloud fail', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(
      authRepository: const _FailingAuthRepository(),
      syncService: const _FailingSyncService(),
    );

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.reveal(find.text('Save to Portfolio'));
    await tester.pump();
    await tester.tap(find.text('Save to Portfolio'));
    await tester.pumpAndSettle();

    expect(find.text('Saved to portfolio'), findsOneWidget);

    await tester.tap(find.text('Portfolio').last);
    await tester.pumpAndSettle();
    await tester.reveal(find.textContaining('Charizard'));

    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text(r'$1,850'), findsWidgets);
  });

  testWidgets('saved scan resets after navigating away from Scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.reveal(find.text('Save to Portfolio'));
    await tester.pump();
    await tester.tap(find.text('Save to Portfolio'));
    await tester.pumpAndSettle();

    expect(find.text('Saved to Portfolio'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();

    expect(find.text('Sample Sports Card'), findsNothing);
    expect(find.text('Analysis Complete'), findsNothing);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
      findsOneWidget,
    );
  });

  testWidgets('unsaved analysis is preserved when navigating away from Scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();

    expect(find.text('Sample Sports Card'), findsOneWidget);
    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('Analysis Complete'), findsOneWidget);
  });

  testWidgets('home scan CTA starts clean after unsaved scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-quick-action-Scan')));
    await tester.pumpAndSettle();

    expect(find.text('Sample Sports Card'), findsNothing);
    expect(find.text('1999 PokÃ©mon Charizard'), findsNothing);
    expect(find.text('AI Scanner'), findsOneWidget);

    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Captured image'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsOneWidget,
    );
  });

  testWidgets('saves gallery image path to portfolio item', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _SelectedGalleryService());

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.acceptEnhancementPreview();
    await tester.pumpUntilFound(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.reveal(find.text('Save to Portfolio'));
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

    await tester.tap(find.text('Scan').last);
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
    );
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    );
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('scan-primary-Analyze Image')),
        )
        .onPressed
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.reveal(find.text('Save to Portfolio'));
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

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('Your Collections'), findsWidgets);
    expect(
      find.text('Track, organize and grow your collection'),
      findsOneWidget,
    );
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
        matching: find.text('Persisted Charizard'),
      ),
      findsOneWidget,
    );
    expect(find.text(r'$1,850'), findsWidgets);
    expect(find.text('Trading Card'), findsOneWidget);
    expect(find.text('94%'), findsWidgets);
    expect(find.text('Stable'), findsWidgets);
    expect(find.text('Categories'), findsWidgets);
    expect(find.text('Top asset'), findsWidgets);
  });

  testWidgets('portfolio empty state renders when no items exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();

    await tester.reveal(find.text('No collectibles saved yet'));
    expect(find.text('No collectibles saved yet'), findsOneWidget);
    expect(find.text('Scan Collectible'), findsWidgets);
  });

  testWidgets('portfolio grid renders local thumbnail and overflow actions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"local-thumb","title":"Local Thumbnail Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading.","imagePath":"test/fixtures/persistent-camera-card.jpg","createdAt":"2026-06-27T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-local-thumb')),
    );

    final gridItem = find.byKey(
      const ValueKey('portfolio-grid-item-local-thumb'),
    );
    expect(gridItem, findsOneWidget);
    expect(
      find.descendant(
        of: gridItem,
        matching: find.text('Local Thumbnail Charizard'),
      ),
      findsOneWidget,
    );
    final titleText = tester.widget<Text>(
      find.descendant(
        of: gridItem,
        matching: find.text('Local Thumbnail Charizard'),
      ),
    );
    expect(titleText.maxLines, 2);
    expect(
      find.byKey(const ValueKey('portfolio-grid-image-local-thumb')),
      findsOneWidget,
    );
    expect(find.byTooltip('Item actions'), findsOneWidget);
    expect(find.byTooltip('Edit item'), findsNothing);
    expect(find.byTooltip('Share item'), findsNothing);
    expect(find.byTooltip('Remove item'), findsNothing);

    await tester.tap(find.byTooltip('Item actions'));
    await tester.pumpAndSettle();

    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('demo mode can seed portfolio from Settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(demoSeedEnabled: true);

    await tester.openSettings();
    await tester.reveal(find.text('Demo Data'));
    expect(find.text('Demo Data'), findsOneWidget);
    expect(find.text('Demo portfolio data'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('settings-seed-demo-data-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Seeded 500 demo/mock collectibles locally.'),
      findsOneWidget,
    );
    final preferences = await SharedPreferences.getInstance();
    final encodedItems = preferences.getString('portfolio_items');
    final decodedItems = jsonDecode(encodedItems!) as List<dynamic>;

    expect(decodedItems, hasLength(packLoxDemoSeedItemCount));
    expect(
      decodedItems.every(
        (item) =>
            (item as Map<String, dynamic>)['id'].toString().startsWith(
              packLoxDemoItemIdPrefix,
            ) &&
            item['notes'].toString().contains('DEMO MOCK DATA'),
      ),
      isTrue,
    );
  });

  testWidgets('portfolio renders 500 seeded demo items without crashing', (
    WidgetTester tester,
  ) async {
    final demoItems = const DemoCollectibleSeedService().generateItems(
      anchorDate: DateTime.utc(2026, 7),
    );
    SharedPreferences.setMockInitialValues({
      'portfolio_items': jsonEncode([
        for (final item in demoItems) item.toJson(),
      ]),
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('Total collection value'), findsOneWidget);
    await tester.reveal(
      find.byKey(ValueKey('portfolio-grid-item-${demoItems.first.id}')),
    );
    expect(find.text(demoItems.first.title), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('portfolio-grid-item-${demoItems.last.id}')),
      800,
      maxScrolls: 80,
    );
    expect(find.text(demoItems.last.title), findsOneWidget);
    expectNoFlutterError(tester);
  });

  testWidgets('removes saved portfolio item from local storage', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","year":"1999","brand":"Pokemon","setName":"Base Set","cardNumber":"4/102","playerOrCharacter":"Charizard","rarity":"Holo Rare","material":"Cardstock","notes":"Verify holo surface.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold","TCGplayer"],"comps":[{"source":"eBay Sold","title":"1999 Pokemon Charizard sold listing","soldPrice":1850,"currency":"AUD","soldDate":"2026-06-20T00:00:00Z","condition":"Near Mint"}]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Item actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
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

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'coin');
    await tester.pump();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-coin-1')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-coin-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-card-1')),
      findsNothing,
    );

    await tester.enterText(find.byType(TextFormField).first, 'watch');
    await tester.pump();

    expect(find.text('No collectibles found'), findsOneWidget);
    expect(find.text('Try adjusting your search or filters.'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('category filter limits portfolio items', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"coin-1","title":"Silver Eagle","category":"Coin","estimatedValue":300,"confidence":0.82,"condition":"Mint","recommendation":"Store safely.","imagePath":"sample://coin","createdAt":"2026-06-26T00:00:00.000"},{"id":"card-1","title":"Charizard Holo","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading.","imagePath":"sample://card","createdAt":"2026-06-27T00:00:00.000"},{"id":"comic-1","title":"Amazing Spider-Man","category":"Comic","estimatedValue":600,"confidence":0.88,"condition":"Fine","recommendation":"Bag and board.","imagePath":"sample://comic","createdAt":"2026-06-25T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();

    final chipScrollViews = tester.widgetList<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(
      chipScrollViews.any(
        (scrollView) => scrollView.scrollDirection == Axis.horizontal,
      ),
      isTrue,
    );

    tester
        .widget<ChoiceChip>(
          find.byKey(const ValueKey('portfolio-filter-cards')),
        )
        .onSelected!(true);
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-card-1')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-card-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-coin-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-comic-1')),
      findsNothing,
    );

    await tester.scrollToTop();
    tester
        .widget<ChoiceChip>(
          find.byKey(const ValueKey('portfolio-filter-coins')),
        )
        .onSelected!(true);
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-coin-1')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-coin-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-card-1')),
      findsNothing,
    );
  });

  testWidgets('portfolio filter sheet filters by confidence and trend', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"rising-high","title":"Rising High Card","category":"Trading Card","estimatedValue":900,"confidence":0.91,"condition":"Near Mint","recommendation":"Hold.","imagePath":"sample://card","createdAt":"2026-06-27T00:00:00.000","marketSummary":{"averagePrice":900,"medianPrice":880,"lowPrice":750,"highPrice":950,"salesCount":4,"trendLabel":"Rising","confidence":0.82,"lastUpdated":"2026-06-29T00:00:00Z","sources":[],"comps":[]}},{"id":"cool-low","title":"Cooling Low Coin","category":"Coin","estimatedValue":90,"confidence":0.62,"condition":"Good","recommendation":"Hold.","imagePath":"sample://coin","createdAt":"2026-06-26T00:00:00.000","marketSummary":{"averagePrice":90,"medianPrice":90,"lowPrice":80,"highPrice":100,"salesCount":3,"trendLabel":"Cooling","confidence":0.64,"lastUpdated":"2026-06-29T00:00:00Z","sources":[],"comps":[]}},{"id":"stable-high","title":"Stable High Comic","category":"Comic","estimatedValue":300,"confidence":0.84,"condition":"Fine","recommendation":"Hold.","imagePath":"sample://comic","createdAt":"2026-06-25T00:00:00.000","marketSummary":{"averagePrice":300,"medianPrice":300,"lowPrice":250,"highPrice":350,"salesCount":5,"trendLabel":"Stable","confidence":0.75,"lastUpdated":"2026-06-29T00:00:00Z","sources":[],"comps":[]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filter portfolio'), findsOneWidget);
    expect(find.text('Confidence range'), findsOneWidget);
    expect(find.text('Trend'), findsOneWidget);

    await tester.tap(find.text('80%+'));
    await tester.tap(find.text('Rising'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-rising-high')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-rising-high')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-cool-low')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-stable-high')),
      findsNothing,
    );

    await tester.scrollToTop();
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Below 80%'));
    await tester.tap(find.text('Cooling'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-cool-low')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-cool-low')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-rising-high')),
      findsNothing,
    );
  });

  testWidgets('sorts portfolio items by value and confidence', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"new-low","title":"Newest Low","category":"Comic","estimatedValue":100,"confidence":0.50,"condition":"Good","recommendation":"Hold.","imagePath":"sample://new","createdAt":"2026-06-27T00:00:00.000"},{"id":"old-high","title":"Old High Value","category":"Coin","estimatedValue":2000,"confidence":0.40,"condition":"Mint","recommendation":"Insure.","imagePath":"sample://old","createdAt":"2026-06-26T00:00:00.000"},{"id":"confident","title":"Best Confidence","category":"Card","estimatedValue":500,"confidence":0.99,"condition":"Near Mint","recommendation":"Grade.","imagePath":"sample://confident","createdAt":"2026-06-25T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-new-low')),
    );
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-old-high')),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('portfolio-grid-item-new-low')))
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('portfolio-grid-item-old-high')),
            )
            .dx,
      ),
    );

    await tester.scrollToTop();
    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();
    expect(find.text('Sort portfolio'), findsOneWidget);
    await tester.tap(find.text('Highest value'));
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-old-high')),
    );
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-new-low')),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('portfolio-grid-item-old-high')),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('portfolio-grid-item-new-low')),
            )
            .dx,
      ),
    );

    await tester.scrollToTop();
    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Highest confidence'));
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-confident')),
    );
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-old-high')),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('portfolio-grid-item-confident')),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('portfolio-grid-item-old-high')),
            )
            .dx,
      ),
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

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-gallery-new')),
    );
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-camera-old')),
    );
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-missing-date')),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('portfolio-grid-item-gallery-new')),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('portfolio-grid-item-camera-old')),
            )
            .dx,
      ),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('portfolio-grid-item-camera-old')),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('portfolio-grid-item-missing-date')),
            )
            .dx,
      ),
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

    await tester.reveal(find.byKey(const ValueKey('home-recent-gallery-new')));
    await tester.reveal(find.byKey(const ValueKey('home-recent-camera-old')));
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

    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();
    await tester.reveal(find.text('Recent Scans'));
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

    await tester.tap(find.text('Portfolio').last);
    await tester.pumpAndSettle();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-gallery-new')),
    );
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-camera-old')),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('portfolio-grid-item-gallery-new')),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('portfolio-grid-item-camera-old')),
            )
            .dx,
      ),
    );
  });

  testWidgets('portfolio item tap opens detail page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"detail-card","title":"Clickable Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","primaryMatch":"1999 Pokemon Charizard Holo","confidenceExplanation":"High confidence from character artwork.","detectionQuality":"Good","aiReasoning":"The image shows a Charizard-like Pokemon card.","year":"1999","brand":"Pokemon","setName":"Base Set","cardNumber":"4/102","playerOrCharacter":"Charizard","rarity":"Holo Rare","material":"Cardstock","notes":"Verify holo surface.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold","TCGplayer"],"comps":[{"source":"eBay Sold","title":"1999 Pokemon Charizard sold listing","soldPrice":1850,"currency":"AUD","soldDate":"2026-06-20T00:00:00Z","condition":"Near Mint"}]}}]',
      'wishlist_status_entries':
          '[{"itemId":"detail-card","title":"Clickable Charizard","category":"Trading Card","status":"wanted","updatedAt":"2026-06-30T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
    );
    await tester.pump();
    expect(find.text('Wanted'), findsOneWidget);
    await tester.tap(find.byTooltip('Item actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Item actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit coming soon'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Estimated value'), findsOneWidget);
    expect(find.text('Wishlist Status'), findsOneWidget);
    expect(find.text('AI Analysis'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
  });

  testWidgets('portfolio detail gallery thumbnails switch hero image', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items': jsonEncode([_portfolioGalleryItemJson()]),
    });

    await tester.pumpCollectIqApp();
    await _openGalleryDetail(tester);

    expect(
      find.byKey(const ValueKey('collectible-detail-hero-sample://front')),
      findsOneWidget,
    );

    final detailThumb = find.byKey(
      const ValueKey('collectible-detail-gallery-sample://detail'),
    );
    await tester.reveal(detailThumb);
    await tester.tap(detailThumb);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('collectible-detail-hero-sample://detail')),
      findsOneWidget,
    );
  });

  testWidgets('portfolio detail hero opens swipe gallery carousel', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items': jsonEncode([_portfolioGalleryItemJson()]),
    });

    await tester.pumpCollectIqApp();
    await _openGalleryDetail(tester);

    final hero = find.byKey(const ValueKey('collectible-detail-image-preview'));
    await tester.reveal(hero);
    await tester.tap(hero);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('portfolio-gallery-page-view')),
      findsOneWidget,
    );
    expect(find.text('Photo 1 of 3'), findsOneWidget);
    expect(find.text('Primary image'), findsOneWidget);

    await tester.fling(
      find.byKey(const ValueKey('portfolio-gallery-page-view')),
      const Offset(-500, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Photo 2 of 3'), findsOneWidget);
    expect(find.text('Back'), findsWidgets);
  });

  testWidgets('portfolio detail primary image update persists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items': jsonEncode([_portfolioGalleryItemJson()]),
    });

    await tester.pumpCollectIqApp();
    await _openGalleryDetail(tester);

    final detailThumb = find.byKey(
      const ValueKey('collectible-detail-gallery-sample://detail'),
    );
    await tester.reveal(detailThumb);
    await tester.tap(detailThumb);
    await tester.pumpAndSettle();
    final hero = find.byKey(const ValueKey('collectible-detail-image-preview'));
    await tester.reveal(hero);
    await tester.tap(hero);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('portfolio-gallery-primary')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final items =
        jsonDecode(preferences.getString('portfolio_items')!) as List<dynamic>;
    final item = items.single as Map<String, dynamic>;
    expect(item['imagePath'], 'sample://detail');
    final gallery = item['galleryImages'] as List<dynamic>;
    final primary = gallery.whereType<Map<String, dynamic>>().singleWhere(
      (image) => image['isPrimary'] == true,
    );
    expect(primary['path'], 'sample://detail');
  });

  testWidgets(
    'portfolio detail gallery deletion persists only selected image',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'portfolio_items': jsonEncode([_portfolioGalleryItemJson()]),
      });

      await tester.pumpCollectIqApp();
      await _openGalleryDetail(tester);

      final backThumb = find.byKey(
        const ValueKey('collectible-detail-gallery-sample://back'),
      );
      await tester.reveal(backThumb);
      await tester.tap(backThumb);
      await tester.pumpAndSettle();
      final hero = find.byKey(
        const ValueKey('collectible-detail-image-preview'),
      );
      await tester.reveal(hero);
      await tester.tap(hero);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('portfolio-gallery-delete')));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      final items =
          jsonDecode(preferences.getString('portfolio_items')!)
              as List<dynamic>;
      final item = items.single as Map<String, dynamic>;
      final gallery = item['galleryImages'] as List<dynamic>;
      expect(gallery, hasLength(2));
      expect(
        gallery.whereType<Map<String, dynamic>>().map((image) => image['path']),
        isNot(contains('sample://back')),
      );
      expect(item['imagePath'], 'sample://front');
    },
  );

  testWidgets('portfolio detail cannot delete final gallery image', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items': jsonEncode([
        _portfolioGalleryItemJson(
          id: 'single-gallery',
          title: 'Single Gallery Item',
          galleryImages: const [
            {
              'path': 'sample://only',
              'role': 'front',
              'source': 'sample',
              'isPrimary': true,
            },
          ],
          imagePath: 'sample://only',
        ),
      ]),
    });

    await tester.pumpCollectIqApp();
    await _openGalleryDetail(tester, itemId: 'single-gallery');

    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-image-preview')),
    );
    await tester.pumpAndSettle();

    final deleteButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('portfolio-gallery-delete')),
    );
    expect(deleteButton.onPressed, isNull);
    expect(find.text('Keep final photo'), findsOneWidget);
  });

  testWidgets('legacy one-image portfolio detail renders without overflow', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items': jsonEncode([
        _portfolioGalleryItemJson(
          id: 'legacy-one',
          title: 'Legacy One Image',
          imagePath: 'sample://legacy-card',
          galleryImages: const [],
        ),
      ]),
    });

    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpCollectIqApp();
    await _openGalleryDetail(tester, itemId: 'legacy-one');

    expect(find.text('Legacy One Image'), findsWidgets);
    expect(
      find.byKey(const ValueKey('collectible-detail-gallery-filmstrip')),
      findsOneWidget,
    );
    expectNoFlutterError(tester);
  });

  testWidgets('collectible detail handles missing optional fields safely', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"minimal-detail","title":"Minimal Silver Coin","category":"Coin","estimatedValue":0,"confidence":0.62,"condition":"","recommendation":"Store safely.","imagePath":"","createdAt":"2026-06-27T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-minimal-detail')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-minimal-detail')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Minimal Silver Coin'), findsWidgets);
    expect(find.text('Value unavailable'), findsWidgets);
    expect(find.text('Coin'), findsWidgets);
    expect(find.text('Needs Review'), findsOneWidget);
    expect(find.textContaining('62%'), findsWidgets);
    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('AI Summary'), findsOneWidget);
    expect(
      find.textContaining(
        'Confidence is lower because some details may be unclear',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collectible-detail-edit-button')),
      findsOneWidget,
    );
    await tester.reveal(find.text('Price Alerts'));
    expect(find.text('Price Alerts'), findsOneWidget);
    expectNoFlutterError(tester);
  });

  testWidgets('edit collectible persists locally and preserves image path', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"edit-card","title":"Editable Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"test/fixtures/persistent-camera-card.jpg","createdAt":"2026-06-27T00:00:00.000","year":"1999","brand":"Pokemon","series":"Pokemon TCG","country":"United States","notes":"Verify holo surface.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-edit-card')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-edit-card')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('collectible-detail-edit-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-edit-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit collectible'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      'Edited Silver Eagle',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-category-field')),
      'Coin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-manufacturer-field')),
      'US Mint',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-series-field')),
      'American Eagle',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-year-field')),
      '2001',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-country-field')),
      'United States',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-low-value-field')),
      '250',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-high-value-field')),
      '350',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-notes-field')),
      'Edited local notes.',
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-collectible-save-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collectible updated'), findsOneWidget);
    expect(find.text('Edited Silver Eagle'), findsWidgets);
    expect(find.text('Coin'), findsWidgets);
    expect(find.text(r'$300'), findsWidgets);
    expect(find.text('Edited local notes.'), findsWidgets);

    final preferences = await SharedPreferences.getInstance();
    final encodedItems = preferences.getString('portfolio_items');
    expect(encodedItems, isNotNull);
    final decodedItems = jsonDecode(encodedItems!) as List<dynamic>;
    final savedItem = decodedItems.single as Map<String, dynamic>;
    expect(savedItem['title'], 'Edited Silver Eagle');
    expect(savedItem['category'], 'Coin');
    expect(savedItem['estimatedValue'], 300);
    expect(savedItem['imagePath'], 'test/fixtures/persistent-camera-card.jpg');
    expect(savedItem['brand'], 'US Mint');
    expect(savedItem['series'], 'American Eagle');
    expect(savedItem['year'], '2001');
    expect(savedItem['country'], 'United States');
    expect(savedItem['notes'], 'Edited local notes.');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-edit-card')),
        matching: find.text('Edited Silver Eagle'),
      ),
      findsOneWidget,
    );
    expect(find.text('Coin'), findsWidgets);
    expect(find.text(r'$300'), findsWidgets);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.reveal(find.text('Portfolio Overview'));
    expect(find.text('Portfolio Overview'), findsWidgets);
    expect(find.text('Collection Value'), findsNothing);
    expect(find.text(r'$300'), findsWidgets);
  });

  testWidgets('collectible detail image preview and notes editing are safe', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"notes-card","title":"Preview Notes Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.88,"condition":"Near Mint","recommendation":"Keep protected.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","year":"1999","brand":"Pokemon","rarity":"Holo Rare","notes":"Original note."}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-notes-card')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-notes-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-image-preview')),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close image preview'), findsOneWidget);
    await tester.tap(
      find.byTooltip('Close image preview'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await tester.reveal(
      find.byKey(const ValueKey('collectible-detail-notes-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('collectible-detail-notes-field')),
      'Sleeved and stored in a hard case.',
    );
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('collectible-detail-notes-save-button')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    expect(find.text('Notes saved'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('portfolio_items'),
      contains('Sleeved and stored in a hard case.'),
    );
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

    await tester.reveal(find.byKey(const ValueKey('home-recent-home-detail')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-recent-home-detail')));
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Home Detail Charizard'), findsWidgets);
    expect(find.text('Raw Diagnostics'), findsOneWidget);
  });

  testWidgets('scan recent scans tap opens detail page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"scan-detail","title":"Scan Detail Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","primaryMatch":"1999 Pokemon Charizard Holo","confidenceExplanation":"High confidence from character artwork.","detectionQuality":"Good","aiReasoning":"The image shows a Charizard-like Pokemon card.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold"],"comps":[]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();
    await tester.reveal(find.text('Recent Scans'));
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-recent-scan-detail')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-recent-scan-detail')));
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Scan Detail Charizard'), findsWidgets);
    expect(find.text('Raw Diagnostics'), findsOneWidget);
  });

  testWidgets('opens portfolio item detail page actions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000","year":"1999","brand":"Pokemon","setName":"Base Set","cardNumber":"4/102","playerOrCharacter":"Charizard","rarity":"Holo Rare","material":"Cardstock","notes":"Verify holo surface.","pricing":{"estimatedMarketValue":1850,"lowEstimate":1443,"highEstimate":2257,"currency":"AUD","pricingSource":"Mock market blend","pricingConfidence":0.85,"lastUpdated":"2026-06-29T00:00:00Z"},"marketSummary":{"averagePrice":1810,"medianPrice":1850,"lowPrice":1443,"highPrice":2257,"salesCount":5,"trendLabel":"Stable","confidence":0.86,"lastUpdated":"2026-06-29T00:00:00Z","sources":["eBay Sold","TCGplayer"],"comps":[{"source":"eBay Sold","title":"1999 Pokemon Charizard sold listing","soldPrice":1850,"currency":"AUD","soldDate":"2026-06-20T00:00:00Z","condition":"Near Mint"}]}}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio').last);
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Estimated value'), findsOneWidget);
    expect(find.text(r'$1,850'), findsWidgets);
    expect(find.text('High confidence (94%)'), findsOneWidget);
    expect(find.text('Primary Metadata'), findsOneWidget);
    expect(find.text('AI Summary'), findsOneWidget);
    expect(find.text('Raw Diagnostics'), findsOneWidget);
    expect(find.text('Date Added'), findsNothing);
    expect(find.text('27/06/2026'), findsNothing);
    expect(find.text('Key Attributes'), findsWidgets);
    expect(find.text('Base Set'), findsWidgets);
    expect(find.text('4/102'), findsNothing);
    await tester.reveal(find.text('Primary Metadata'));
    await tester.tap(find.text('Primary Metadata'));
    await tester.pumpAndSettle();
    expect(find.text('4/102'), findsWidgets);
    expect(find.text('Charizard'), findsWidgets);
    expect(find.text('Market Evidence'), findsOneWidget);
    await tester.reveal(find.text('Market Evidence'));
    await tester.tap(find.text('Market Evidence'));
    await tester.pumpAndSettle();
    expect(find.text('Market Summary'), findsOneWidget);
    await tester.reveal(find.text('Market Summary'));
    await tester.tap(find.text('Market Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Trend'), findsOneWidget);
    expect(find.text('Stable'), findsWidgets);
    expect(find.text('Recent comparable sales'), findsOneWidget);
    expect(find.text(r'$1,443 - $2,257'), findsWidgets);
    expect(find.text('Mock market blend'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);

    await tester.reveal(find.text('Wishlist Status'));
    await tester.pump();
    expect(find.text('Wishlist Status'), findsOneWidget);
    await tester.tap(find.text('Wanted'));
    await tester.pumpAndSettle();
    expect(find.text('Wishlist status set to Wanted'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('wishlist_status_entries'),
      contains('"status":"wanted"'),
    );
    await tester.pump(const Duration(seconds: 4));

    await tester.reveal(find.text('Price History'));
    await tester.pump();
    expect(find.text('Price History'), findsOneWidget);
    expect(find.text('Current Value'), findsOneWidget);
    expect(find.text('6-month Change'), findsOneWidget);
    expect(find.text('Highest Value'), findsOneWidget);
    expect(find.text('Lowest Value'), findsOneWidget);
    expect(find.text(r'$1,200'), findsWidgets);
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Jun'), findsOneWidget);

    await tester.reveal(
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

    await tester.reveal(
      find.byKey(const ValueKey('collectible-detail-share-action')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-share-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sharing coming soon'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-favorite-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Added to favorites'), findsOneWidget);
    expect(find.text('Favorited'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete collectible?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Collectible Details'), findsOneWidget);

    await tester.reveal(find.text('Price Alerts'));
    await tester.pump();
    expect(find.text('Price Alerts'), findsOneWidget);
    expect(find.textContaining('Create a local alert below'), findsOneWidget);
    expect(find.text('Alert if value rises 10%'), findsOneWidget);
    expect(find.text('Alert if value drops 10%'), findsOneWidget);
    expect(find.text('Remind when pricing is stale'), findsOneWidget);

    await tester.tap(find.text('Alert if value rises 10%'));
    await tester.pumpAndSettle();
    expect(find.text('Price alert created'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Increases by 10%'), findsOneWidget);

    await tester.reveal(find.text('Similar Collectibles'));
    await tester.pumpAndSettle();
    expect(find.text('Similar Collectibles'), findsOneWidget);
  });

  for (final viewport in const [
    ('small phone', Size(360, 640)),
    ('large phone', Size(430, 932)),
  ]) {
    testWidgets('responsive smoke renders key screens on ${viewport.$1}', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = viewport.$2
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'portfolio_items':
            '[{"id":"responsive-card","title":"Responsive Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Hold safely.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000"}]',
      });

      await tester.pumpCollectIqApp();
      expect(find.text('Your Collection Hub'), findsOneWidget);
      expectNoFlutterError(tester);

      await tester.tap(find.text('Scan').last);
      await tester.pumpAndSettle();
      expect(find.text('AI Scanner'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scan-primary-Scan with Camera')),
        findsOneWidget,
      );
      expectNoFlutterError(tester);

      await tester.tap(find.text('Portfolio').last);
      await tester.pumpAndSettle();
      await tester.reveal(
        find.byKey(const ValueKey('portfolio-grid-item-responsive-card')),
      );
      expect(
        find.byKey(const ValueKey('portfolio-grid-item-responsive-card')),
        findsOneWidget,
      );
      expectNoFlutterError(tester);

      await tester.tap(
        find.byKey(const ValueKey('portfolio-grid-item-responsive-card')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Collectible Details'), findsOneWidget);
      expectNoFlutterError(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsOneWidget);
      await tester.reveal(find.text('Backup & Sync'));
      expect(find.text('Backup & Sync'), findsWidgets);
      expectNoFlutterError(tester);
    });
  }
}

void expectNoFlutterError(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) {
    return;
  }
  if (exception is FlutterError) {
    final details = exception.diagnostics
        .map((node) => node.toStringDeep())
        .join('\n');
    fail('$exception\n$details');
  }
  fail(exception.toString());
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
    ImageEnhancementService? imageEnhancementService,
    ImageQualityAssessmentService? imageQualityAssessmentService,
    EnvironmentConfig? environmentConfig,
    bool onboardingCompleted = true,
    OnboardingRepository? onboardingRepository,
    bool? demoSeedEnabled,
  }) async {
    final effectiveOnboardingRepository =
        onboardingRepository ??
        _FakeOnboardingRepository(completed: onboardingCompleted);
    await pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            effectiveOnboardingRepository,
          ),
          aiRecognitionServiceProvider.overrideWithValue(aiRecognitionService),
          analyzerConfigProvider.overrideWithValue(
            const AnalyzerConfig(
              retryPolicy: AnalyzerRetryPolicy(
                maxAttempts: 1,
                retryDelay: Duration.zero,
              ),
            ),
          ),
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
          if (imageEnhancementService != null)
            imageEnhancementServiceProvider.overrideWithValue(
              imageEnhancementService,
            ),
          if (imageQualityAssessmentService != null)
            imageQualityAssessmentServiceProvider.overrideWithValue(
              imageQualityAssessmentService,
            ),
          if (environmentConfig != null)
            environmentConfigProvider.overrideWithValue(environmentConfig),
          if (demoSeedEnabled != null)
            demoSeedEnabledProvider.overrideWithValue(demoSeedEnabled),
        ],
        child: const CollectIqApp(),
      ),
    );
    await pump();
    await pump(const Duration(milliseconds: 50));
    await pump(const Duration(milliseconds: 50));
  }

  Future<void> completeSampleScan() async {
    await tap(find.text('Scan').last);
    await pump();
    await reveal(find.byKey(const ValueKey('scan-secondary-Use Sample Scan')));
    await pump();
    await tap(find.byKey(const ValueKey('scan-secondary-Use Sample Scan')));
    await pump();
    await reveal(find.byKey(const ValueKey('scan-primary-Analyze Image')));
    await pump();
    widget<FilledButton>(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
    ).onPressed?.call();
    await pump();
    await pump(const Duration(seconds: 2));
    await pump();
    await reveal(find.text('AI Review'));
    await pump();
  }

  Future<void> pumpVisualAnalytics(Widget child) {
    return pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
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

  Future<void> acceptEnhancementPreview({
    ImageEnhancementPreset preset = ImageEnhancementPreset.original,
  }) async {
    await pumpUntilFound(
      find.byKey(const ValueKey('enhancement-preview-presets')),
    );
    if (preset != ImageEnhancementPreset.original) {
      widget<ChoiceChip>(
        find.byKey(ValueKey('enhancement-preview-${preset.id}')).last,
      ).onSelected?.call(true);
      await pump(const Duration(milliseconds: 500));
    }
    widget<FilledButton>(
      find.byKey(const ValueKey('enhancement-preview-use-photo')).last,
    ).onPressed?.call();
    await pump();
  }

  Future<void> openSettings() async {
    await tap(find.text('Settings'));
    await pumpAndSettle();
  }

  Future<void> enterSettingsAuthEmail(String email) async {
    final emailField = find.byKey(const ValueKey('settings-auth-email-field'));
    await reveal(emailField);
    await enterText(emailField, email);
    await pump();
  }

  Future<void> enterSettingsAuthCredentials({
    String email = 'collector@example.com',
    String password = 'password123',
  }) async {
    await enterSettingsAuthEmail(email);
    await enterText(
      find.byKey(const ValueKey('settings-auth-password-field')),
      password,
    );
    await pump();
  }

  Future<void> reveal(Finder finder) async {
    for (var attempt = 0; attempt < 20; attempt += 1) {
      await pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) {
        await ensureVisible(finder.first);
        await pump();
        return;
      }

      await drag(find.byType(Scrollable).first, const Offset(0, -360));
      await pump();
    }

    throw TestFailure('Could not reveal $finder');
  }

  Future<void> scrollToTop() async {
    for (var attempt = 0; attempt < 8; attempt += 1) {
      await drag(find.byType(Scrollable).first, const Offset(0, 520));
      await pump();
    }
  }
}

PortfolioSnapshot _visualSnapshot({required double value, required int day}) {
  final date = DateTime.utc(2026, 6, day);
  return PortfolioSnapshot(
    id: 'daily:$day',
    period: TrendSnapshotPeriod.daily,
    periodStart: date,
    capturedAt: date,
    totalPortfolioValue: value,
    totalItems: 2,
    averageValue: value / 2,
    categoryTotals: {
      for (final category in CollectorCategory.values) category: 0.0,
      CollectorCategory.cards: value * 0.75,
      CollectorCategory.coins: value * 0.25,
    },
    collectionScore: (value / 2).round().clamp(0, 1000).toInt(),
    itemValues: const {'card': 1000, 'coin': 400},
    itemTitles: const {'card': 'Charizard', 'coin': 'Silver Eagle'},
    itemCategories: const {'card': 'Trading Card', 'coin': 'Coin'},
  );
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

class _CapturingAiAnalysisProvider implements AiAnalysisProvider {
  AiAnalysisRequest? lastRequest;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    lastRequest = request;
    final now = DateTime.now();
    return AiAnalysisResult(
      recommendation: 'Captured provider recommendation.',
      scanResult: ScanResult(
        id: 'captured-${now.microsecondsSinceEpoch}',
        title: 'Captured Provider Collectible',
        category: 'Trading Card',
        estimatedValue: 42,
        confidence: 0.84,
        condition: 'Good',
        thumbnail: request.imagePath,
        scanDate: now,
        primaryMatch: 'Captured Provider Collectible',
        alternativeMatches: const [],
        confidenceExplanation: 'Captured request metadata.',
        detectionQuality: 'Good',
        aiReasoning: 'Captured provider reasoning.',
        pricing: PricingInfo(
          estimatedMarketValue: 42,
          lowEstimate: 35,
          highEstimate: 50,
          currency: 'AUD',
          pricingSource: 'Captured fixture',
          pricingConfidence: 0.7,
          lastUpdated: DateTime.parse('2026-07-08T00:00:00Z'),
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

class _LowConfidenceAiAnalysisProvider implements AiAnalysisProvider {
  const _LowConfidenceAiAnalysisProvider();

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    final now = DateTime.now();

    return AiAnalysisResult(
      recommendation: 'Review before saving.',
      scanResult: ScanResult(
        id: 'low-${now.microsecondsSinceEpoch}',
        title: '',
        category: '',
        estimatedValue: 0,
        confidence: 0.58,
        condition: '',
        thumbnail: request.imagePath,
        scanDate: now,
        primaryMatch: '',
        alternativeMatches: const [],
        confidenceExplanation: 'Image details are unclear.',
        detectionQuality: 'Needs clearer photo.',
        aiReasoning: 'Not enough visible detail for a strong match.',
        pricing: PricingInfo(
          estimatedMarketValue: 0,
          lowEstimate: 0,
          highEstimate: 0,
          currency: 'AUD',
          pricingSource: 'Provider fixture',
          pricingConfidence: 0.2,
          lastUpdated: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
      ),
    );
  }
}

class _ValuationStatusAiAnalysisProvider implements AiAnalysisProvider {
  const _ValuationStatusAiAnalysisProvider(this.status);

  final ValuationStatus status;

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    final now = DateTime.now();
    final marketValue = status == ValuationStatus.marketEstimated ? 42.0 : 0.0;
    final aiValue = status == ValuationStatus.aiEstimated ? 37.0 : null;

    return AiAnalysisResult(
      recommendation: 'Review valuation status before saving.',
      scanResult: ScanResult(
        id: 'valuation-${status.wireValue}-${now.microsecondsSinceEpoch}',
        title: 'Hot Wheels 17 Audi RS 6 Avant',
        category: 'Die-cast Car',
        estimatedValue: marketValue > 0 ? marketValue : aiValue ?? 0,
        confidence: 0.92,
        condition: 'Packaged',
        thumbnail: request.imagePath,
        scanDate: now,
        primaryMatch: 'Hot Wheels 17 Audi RS 6 Avant',
        alternativeMatches: const [],
        confidenceExplanation: 'Visible packaging supports the match.',
        detectionQuality: 'Good',
        aiReasoning: 'The card art and vehicle silhouette match the Audi RS 6.',
        pricing: PricingInfo(
          estimatedMarketValue: marketValue,
          lowEstimate: marketValue,
          highEstimate: marketValue,
          currency: 'AUD',
          pricingSource: status == ValuationStatus.providerNotConfigured
              ? 'not_configured'
              : 'test_pricing',
          pricingConfidence: marketValue > 0 ? 0.82 : 0,
          lastUpdated: now,
          valuationStatus: status,
          valuationSource: status == ValuationStatus.providerNotConfigured
              ? 'not_configured'
              : 'test_pricing',
          aiEstimatedValue: aiValue,
        ),
        estimatedMarketValue: marketValue > 0 ? marketValue : null,
        valuationStatus: status,
        valuationSource: status == ValuationStatus.providerNotConfigured
            ? 'not_configured'
            : 'test_pricing',
        aiEstimatedValue: aiValue,
      ),
    );
  }
}

class _LongTitleAiAnalysisProvider implements AiAnalysisProvider {
  const _LongTitleAiAnalysisProvider();

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    final now = DateTime.now();

    return AiAnalysisResult(
      recommendation: 'Review long title display.',
      scanResult: ScanResult(
        id: 'long-${now.microsecondsSinceEpoch}',
        title:
            'Extremely Long Collector Variant With Multiple Editions And Packaging Notes',
        category: 'Trading Card',
        estimatedValue: 485,
        confidence: 0.86,
        condition: 'Excellent',
        thumbnail: request.imagePath,
        scanDate: now,
        primaryMatch:
            'Extremely Long Collector Variant With Multiple Editions And Packaging Notes',
        alternativeMatches: const [],
        confidenceExplanation: 'Visible details support the match.',
        detectionQuality: 'Good',
        aiReasoning: 'Identified from visible category and edition details.',
        pricing: PricingInfo(
          estimatedMarketValue: 485,
          lowEstimate: 420,
          highEstimate: 540,
          currency: 'AUD',
          pricingSource: 'Provider fixture',
          pricingConfidence: 0.82,
          lastUpdated: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
        year: '2024',
        brand: 'PackLox',
      ),
    );
  }
}

class _DelayedAiAnalysisProvider implements AiAnalysisProvider {
  const _DelayedAiAnalysisProvider();

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const _CustomAiAnalysisProvider().analyze(request);
  }
}

class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository({required this.completed});

  bool completed;

  @override
  Future<bool> hasCompletedOnboarding() async {
    return completed;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    this.completed = completed;
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
  Future<void> resendEmailConfirmation({required String email}) {
    throw const AuthException('Auth unavailable during local save test.');
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
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
  _InteractiveAuthRepository({
    AppUser? initialUser,
    this.signInError,
    this.signUpError,
    this.resendError,
    this.passwordResetError,
  }) : _user = initialUser;

  AppUser? _user;
  final Object? signInError;
  final Object? signUpError;
  final Object? resendError;
  final Object? passwordResetError;
  var signInCalls = 0;
  var signUpCalls = 0;
  var resendCalls = 0;
  var passwordResetCalls = 0;
  String? lastResendEmail;
  String? lastPasswordResetEmail;

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
    signInCalls += 1;
    final error = signInError;
    if (error != null) {
      throw error;
    }
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
    signUpCalls += 1;
    final error = signUpError;
    if (error != null) {
      throw error;
    }
    return signInWithEmailPassword(email: email, password: password);
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {
    resendCalls += 1;
    lastResendEmail = email;
    final error = resendError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    passwordResetCalls += 1;
    lastPasswordResetEmail = email;
    final error = passwordResetError;
    if (error != null) {
      throw error;
    }
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

Future<void> _openGalleryDetail(
  WidgetTester tester, {
  String itemId = 'gallery-detail',
}) async {
  await tester.tap(find.text('Portfolio').last);
  await tester.pump();
  await tester.pump();
  await tester.reveal(find.byKey(ValueKey('portfolio-grid-item-$itemId')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('portfolio-grid-item-$itemId')));
  await tester.pumpAndSettle();
}

Map<String, Object?> _portfolioGalleryItemJson({
  String id = 'gallery-detail',
  String title = 'Gallery Hot Wheels',
  String imagePath = 'sample://front',
  List<Map<String, Object?>> galleryImages = const [
    {
      'path': 'sample://front',
      'role': 'front',
      'source': 'sample',
      'isPrimary': true,
    },
    {
      'path': 'sample://back',
      'role': 'back',
      'source': 'sample',
      'isPrimary': false,
    },
    {
      'path': 'sample://detail',
      'role': 'barcode',
      'source': 'sample',
      'isPrimary': false,
    },
  ],
}) {
  return {
    'id': id,
    'title': title,
    'category': 'Toy Car',
    'estimatedValue': 25,
    'confidence': 0.91,
    'condition': 'Packaged',
    'recommendation': 'Keep complete photo set.',
    'imagePath': imagePath,
    'galleryImages': galleryImages,
    'createdAt': '2026-07-07T00:00:00.000',
    'brand': 'Hot Wheels',
    'series': 'HW Euro',
    'year': '2026',
    'primaryMatch': 'Hot Wheels Audi RS 6 Avant',
    'confidenceExplanation': 'Photos show the package and model clearly.',
  };
}

class _SelectedCameraService extends CameraService {
  @override
  Future<CameraCaptureFlowResult?> captureWithInAppCamera(
    BuildContext context, {
    String imageRole = 'front',
  }) async {
    return CameraCaptureFlowResult.image(
      XFile(_fixturePath('persistent-camera-card.jpg')),
    );
  }

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
  Future<CameraCaptureFlowResult?> captureWithInAppCamera(
    BuildContext context, {
    String imageRole = 'front',
  }) async {
    return CameraCaptureFlowResult.image(
      XFile(_fixturePath('persistent-camera-card.jpg')),
    );
  }

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
  Future<CameraCaptureFlowResult?> captureWithInAppCamera(
    BuildContext context, {
    String imageRole = 'front',
  }) async {
    return null;
  }

  @override
  Future<XFile?> pickImageFromCamera() async {
    return null;
  }
}

class _DeniedCameraService extends CameraService {
  @override
  Future<PermissionStatus> requestPermissionStatus() async {
    return PermissionStatus.denied;
  }
}

class _MissingCameraService extends CameraService {
  @override
  Future<CameraCaptureFlowResult?> captureWithInAppCamera(
    BuildContext context, {
    String imageRole = 'front',
  }) async {
    return CameraCaptureFlowResult.image(
      XFile(_fixturePath('missing-camera-card.jpg')),
    );
  }

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

class _FakeAIRecognitionService implements AIRecognitionService {
  const _FakeAIRecognitionService();

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) async {
    return RecognitionResult(
      success: true,
      filename: 'scan.png',
      imageUrl: 'http://192.168.0.81:8000/uploads/scan.png',
      title: '1999 PokÃ©mon Charizard',
      category: 'Trading Card',
      confidence: 0.94,
      description: 'Likely a PokÃ©mon Base Set Charizard.',
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

class _FakeImageEnhancementService extends ImageEnhancementService {
  const _FakeImageEnhancementService();

  @override
  Future<ImageEnhancementResult> enhance({
    required String originalPath,
    required ImageEnhancementPreset preset,
  }) async {
    return ImageEnhancementResult(
      originalPath: originalPath,
      activePath: originalPath,
      preset: preset,
      createdEnhancedFile: false,
    );
  }
}

class _FakeImageQualityAssessmentService extends ImageQualityAssessmentService {
  const _FakeImageQualityAssessmentService();

  @override
  Future<ImageQualityAssessment> assess(String imagePath) async {
    return const ImageQualityAssessment(
      recommendedPreset: ImageEnhancementPreset.textPackageClarity,
      readinessScore: 57,
      lighting: 0.44,
      sharpness: 0.35,
      glareRisk: 0.41,
      textClarity: 0.38,
      framingConfidence: 0.72,
      recommendationConfidence: 0.85,
      reason: 'Best for barcode and package text.',
      warnings: ['Slight blur detected', 'Glare may affect packaging text'],
    );
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
