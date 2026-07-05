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
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/usage_repository.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/network/network_exceptions.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
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

  testWidgets('bottom navigation switches all major tabs without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    expect(find.text('Your Collection Hub'), findsOneWidget);

    await tester.tap(find.text('Portfolio'));
    await tester.pumpAndSettle();
    expect(find.text('Total collection value'), findsOneWidget);
    expectNoFlutterError(tester);

    await tester.tap(find.text('Scan'));
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
    expect(find.text('AUD 0'), findsWidgets);
    expect(find.text('Ready to scan'), findsOneWidget);
    expect(find.text('Scan Item'), findsOneWidget);
    expect(find.text('Add Manually'), findsOneWidget);
    expect(find.text('Search Database'), findsOneWidget);
    expect(find.text('Import Collection'), findsOneWidget);
    expect(find.text('Soon'), findsWidgets);
    expect(find.text('Quick Actions'), findsOneWidget);
    await tester.reveal(find.text('Portfolio Snapshot'));
    expect(find.text('Portfolio Snapshot'), findsWidgets);
    expect(
      find.text('Your collection starts with your first scan.'),
      findsWidgets,
    );
    await tester.reveal(find.text('Recent Activity'));
    expect(
      find.text('Your latest discoveries will appear here.'),
      findsWidgets,
    );
    await tester.reveal(find.text('Starter Categories'));
    expect(find.text('Starter Categories'), findsWidgets);
    expect(find.text('Cards'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(find.text('Comics'), findsOneWidget);
    expect(find.text('Figures'), findsOneWidget);
    expect(find.text('Watches'), findsOneWidget);
    expect(find.text('Stamps'), findsOneWidget);
    await tester.reveal(find.text('AI Insight'));
    expect(find.text('AI Insight'), findsWidgets);
    expect(
      find.text(
        'Scan one collectible to unlock valuation, rarity clues, and collection recommendations.',
      ),
      findsOneWidget,
    );
    await tester.reveal(find.text('System Status'));
    expect(find.text('System Status'), findsWidgets);
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

    expect(find.text('Portfolio Snapshot'), findsWidgets);
    await tester.reveal(find.byKey(const ValueKey('home-recent-alert-card')));
    expect(find.text('Alert Charizard'), findsWidgets);
    await tester.reveal(find.text('Collection Value'));
    expect(find.text('Collection Value'), findsWidgets);
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

    await tester.reveal(find.text('Portfolio Snapshot'));
    expect(find.text('Portfolio Snapshot'), findsWidgets);
    expect(find.text('Dashboard Charizard'), findsWidgets);
    expect(find.text('Dashboard Silver Eagle'), findsWidgets);
    expect(find.text('Categories'), findsWidgets);
    expect(find.text('Top asset'), findsWidgets);
    await tester.reveal(find.text('AI Insight'));
    expect(find.text('AI Insight'), findsWidgets);
    await tester.reveal(find.text('Collection Value'));
    expect(find.text('Collection Value'), findsWidgets);
    expect(find.text('AUD 2,750'), findsWidgets);
    expect(find.text('Top asset: Dashboard Charizard'), findsOneWidget);
    await tester.reveal(find.text('System Status'));
    expect(find.text('System Status'), findsWidgets);
  });

  testWidgets('home dashboard updates after saving a scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan'));
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

    await tester.reveal(find.text('Portfolio Snapshot'));
    expect(find.text('Portfolio Snapshot'), findsWidgets);
    await tester.reveal(find.text('Recent Activity'));
    expect(find.text('Recent Activity'), findsWidgets);
    expect(find.textContaining('Charizard'), findsWidgets);
    await tester.reveal(find.text('Collection Value'));
    expect(find.text('Collection Value'), findsWidgets);
    await tester.reveal(find.text('System Status'));
    expect(find.text('System Status'), findsWidgets);
  });

  testWidgets('home scan button selects Scan tab', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan Item').first);
    await tester.pumpAndSettle();

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
  });

  testWidgets('shell recreation returns to Home and Scan still works', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan Item').first);
    await tester.pumpAndSettle();
    expect(find.text('AI Scanner'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpCollectIqApp();
    await tester.pumpAndSettle();

    expect(find.text('AI Scanner'), findsNothing);
    expect(find.text('Quick Actions'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.text('AI Scanner'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scan-primary-Scan with Camera')),
      findsOneWidget,
    );
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

    await tester.tap(find.text('Portfolio'));
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
    expect(find.text('Price alert notifications'), findsOneWidget);
    expect(find.text('Notification permission'), findsOneWidget);

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

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Scan Item').first);
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

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Scan Item').first);
    await tester.pumpAndSettle();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
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

    await tester.tap(find.text('Scan'));
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
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsNothing,
    );
  });

  testWidgets('camera missing image path shows error without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _MissingCameraService());

    await tester.tap(find.text('Scan'));
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
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsNothing,
    );
  });

  testWidgets('gallery missing image path shows error without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(galleryService: _MissingGalleryService());

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
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
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsNothing,
    );
  });

  testWidgets('scanner sample scan shows fake AI result', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan'));
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
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
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

    expect(
      find.text(
        'AI backend is not reachable. Check your internet/backend setup.',
      ),
      findsOneWidget,
    );
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

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Scan'));
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
      aiRecognitionService: const _DelayedAIRecognitionService(),
      galleryService: _SelectedGalleryService(),
    );

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
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

    await tester.reveal(find.text('Analysis Result'));
    await tester.pump();

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('Estimated market value'), findsOneWidget);
    expect(find.textContaining('Estimated value range'), findsOneWidget);
    expect(find.text('Trust summary'), findsOneWidget);
    expect(find.text('Pricing source'), findsOneWidget);
    expect(find.text('Freshness'), findsOneWidget);
    expect(find.text('Pricing confidence'), findsOneWidget);
    expect(find.textContaining('Mock pricing blend'), findsWidgets);
    expect(
      find.textContaining('AI estimates are a starting point'),
      findsOneWidget,
    );
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
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('scan-secondary-Use Sample Scan')),
      findsOneWidget,
    );
  });

  testWidgets('saves scanner result to portfolio', (WidgetTester tester) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Portfolio'));
    await tester.pumpAndSettle();
    await tester.reveal(find.textContaining('Charizard'));

    expect(find.textContaining('Charizard'), findsWidgets);
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

    await tester.tap(find.text('Portfolio'));
    await tester.pumpAndSettle();
    await tester.reveal(find.textContaining('Charizard'));

    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('AUD 1,850'), findsWidgets);
  });

  testWidgets('saved scan resets after navigating away from Scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Scan'));
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
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Sample Sports Card'), findsNothing);
    expect(find.text('Analysis Complete'), findsNothing);
    expect(
      find.byKey(const ValueKey('scan-primary-Analyze Image')),
      findsNothing,
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

    await tester.tap(find.text('Scan'));
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
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Sample Sports Card'), findsOneWidget);
    expect(find.textContaining('Charizard'), findsWidgets);
    expect(find.text('Analysis Complete'), findsOneWidget);
  });

  testWidgets('home scan CTA starts clean after unsaved scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp(cameraService: _SelectedCameraService());

    await tester.tap(find.text('Scan'));
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
    await tester.tap(find.text('Scan Item').first);
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

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-secondary-Gallery')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scan-secondary-Gallery')));
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

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();

    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
    );
    expect(find.text('Persisted Charizard'), findsOneWidget);
    expect(find.text('AUD 1,850'), findsWidgets);
    expect(find.text('Trading Card'), findsOneWidget);
    expect(find.text('94%'), findsWidgets);
    expect(find.text('Stable'), findsWidgets);
  });

  testWidgets('portfolio empty state renders when no items exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
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

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-local-thumb')),
    );

    expect(find.text('Local Thumbnail Charizard'), findsOneWidget);
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

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
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

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'coin');
    await tester.pump();

    await tester.reveal(find.text('Silver Eagle'));
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

    tester
        .widget<ChoiceChip>(
          find.byKey(const ValueKey('portfolio-filter-cards')),
        )
        .onSelected!(true);
    await tester.pumpAndSettle();

    await tester.reveal(find.text('Charizard Holo'));
    expect(find.text('Charizard Holo'), findsOneWidget);
    expect(find.text('Silver Eagle'), findsNothing);
    expect(find.text('Amazing Spider-Man'), findsNothing);

    await tester.scrollToTop();
    tester
        .widget<ChoiceChip>(
          find.byKey(const ValueKey('portfolio-filter-coins')),
        )
        .onSelected!(true);
    await tester.pumpAndSettle();

    await tester.reveal(find.text('Silver Eagle'));
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

    await tester.reveal(find.text('Newest Low'));
    await tester.reveal(find.text('Old High Value'));
    expect(
      tester.getTopLeft(find.text('Newest Low')).dx,
      lessThan(tester.getTopLeft(find.text('Old High Value')).dx),
    );

    await tester.scrollToTop();
    await tester.tap(find.text('Value'));
    await tester.pumpAndSettle();

    await tester.reveal(find.text('Old High Value'));
    await tester.reveal(find.text('Newest Low'));
    expect(
      tester.getTopLeft(find.text('Old High Value')).dx,
      lessThan(tester.getTopLeft(find.text('Newest Low')).dx),
    );

    await tester.scrollToTop();
    await tester.tap(find.text('Confidence').first);
    await tester.pumpAndSettle();

    await tester.reveal(find.text('Best Confidence'));
    await tester.reveal(find.text('Old High Value'));
    expect(
      tester.getTopLeft(find.text('Best Confidence')).dx,
      lessThan(tester.getTopLeft(find.text('Old High Value')).dx),
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

    await tester.reveal(find.text('Newer Gallery Save'));
    await tester.reveal(find.text('Older Camera Save'));
    await tester.reveal(find.text('Missing Timestamp Import'));
    expect(
      tester.getTopLeft(find.text('Newer Gallery Save')).dx,
      lessThan(tester.getTopLeft(find.text('Older Camera Save')).dx),
    );
    expect(
      tester.getTopLeft(find.text('Older Camera Save')).dx,
      lessThan(tester.getTopLeft(find.text('Missing Timestamp Import')).dx),
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

    await tester.tap(find.text('Scan'));
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

    await tester.tap(find.text('Portfolio'));
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

    await tester.tap(find.text('Portfolio'));
    await tester.pump();
    await tester.pump();
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
    );
    await tester.pump();
    expect(find.text('Wanted'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collectible Details'), findsOneWidget);
    expect(find.text('Estimated market value'), findsOneWidget);
    expect(find.text('Wishlist Status'), findsOneWidget);
    expect(find.text('Why this match?'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
  });

  testWidgets('collectible detail handles missing optional fields safely', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'portfolio_items':
          '[{"id":"minimal-detail","title":"Minimal Silver Coin","category":"Coin","estimatedValue":120,"confidence":0.72,"condition":"Good","recommendation":"Store safely.","imagePath":"","createdAt":"2026-06-27T00:00:00.000"}]',
    });

    await tester.pumpCollectIqApp();

    await tester.tap(find.text('Portfolio'));
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
    expect(find.text('AUD 120'), findsWidgets);
    expect(find.text('Coin'), findsWidgets);
    expect(find.text('72% confidence'), findsOneWidget);
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

    await tester.tap(find.text('Portfolio'));
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
    expect(find.text('AUD 300'), findsWidgets);
    expect(find.text('US Mint'), findsOneWidget);
    expect(find.text('American Eagle'), findsOneWidget);
    expect(find.text('Edited local notes.'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    final encodedItems = preferences.getString('portfolio_items');
    expect(encodedItems, isNotNull);
    final decodedItems = jsonDecode(encodedItems!) as List<dynamic>;
    final savedItem = decodedItems.single as Map<String, dynamic>;
    expect(savedItem['title'], 'Edited Silver Eagle');
    expect(savedItem['category'], 'Coin');
    expect(savedItem['estimatedValue'], 300);
    expect(savedItem['imagePath'], 'test/fixtures/persistent-camera-card.jpg');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Edited Silver Eagle'), findsOneWidget);
    expect(find.text('Coin'), findsWidgets);
    expect(find.text('AUD 300'), findsWidgets);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.reveal(find.text('Collection Value'));
    expect(find.text('Collection Value'), findsWidgets);
    expect(find.text('AUD 300'), findsWidgets);
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
    await tester.reveal(find.text('Recent Scans'));
    await tester.pump();
    await tester.reveal(find.byKey(const ValueKey('scan-recent-scan-detail')));
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
    await tester.reveal(
      find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-persisted-1')),
    );
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
    expect(find.text('AUD 1,200'), findsWidgets);
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

    await tester.reveal(find.text('Re-analyze'));
    await tester.pump();
    await tester.tap(find.text('Re-analyze'));
    await tester.pumpAndSettle();
    expect(find.text('Re-analysis coming next'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

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

    await tester.reveal(find.text('Sell Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sell Item'));
    await tester.pumpAndSettle();
    expect(find.text('Marketplace listing coming next'), findsOneWidget);
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

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();
      expect(find.text('AI Scanner'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scan-primary-Scan with Camera')),
        findsOneWidget,
      );
      expectNoFlutterError(tester);

      await tester.tap(find.text('Portfolio'));
      await tester.pumpAndSettle();
      await tester.reveal(
        find.byKey(const ValueKey('portfolio-grid-item-responsive-card')),
      );
      expect(find.text('Responsive Charizard'), findsOneWidget);
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
    EnvironmentConfig? environmentConfig,
    bool onboardingCompleted = true,
    OnboardingRepository? onboardingRepository,
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
          if (environmentConfig != null)
            environmentConfigProvider.overrideWithValue(environmentConfig),
        ],
        child: const CollectIqApp(),
      ),
    );
    await pump();
    await pump(const Duration(milliseconds: 50));
    await pump(const Duration(milliseconds: 50));
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

class _FailingAiAnalysisProvider implements AiAnalysisProvider {
  const _FailingAiAnalysisProvider();

  @override
  Future<AiAnalysisResult> analyze(AiAnalysisRequest request) {
    throw const AiAnalysisException('Provider failed safely.');
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
