import 'dart:convert';
import 'dart:ui' as ui;

import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/home_dashboard_providers.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/wishlist/presentation/controllers/wishlist_providers.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('default shell destination remains Home', (tester) async {
    await tester.pumpShell();

    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shell-destination-home')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('shell-destination-portfolio')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('shell-destination-scan')), findsNothing);
    expect(
      find.byKey(const ValueKey('shell-destination-search')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('shell-destination-settings')),
      findsNothing,
    );

    final navigation = tester.widget<GlassBottomNavBar>(
      find.byKey(const ValueKey('bottom-navigation')),
    );
    expect(navigation.currentIndex, AppShellTabController.homeTab);
  });

  testWidgets('primary destinations follow F62 five item order', (
    tester,
  ) async {
    await tester.pumpShell();

    final navigation = tester.widget<GlassBottomNavBar>(
      find.byKey(const ValueKey('bottom-navigation')),
    );
    expect(navigation.items.map((item) => item.label), [
      'Home',
      'Scan',
      'Portfolio',
      'Search',
      'Settings',
    ]);
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-scan')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-portfolio')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-settings')), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets(
    'foreground resume re-syncs the portfolio (throttle-elapsed) without disrupting the shell',
    (tester) async {
      await tester.pumpShell();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );

      // Pretend the last auto-sync was long ago so the resume isn't throttled.
      final longAgo = DateTime.now().subtract(const Duration(minutes: 10));
      container.read(homeLastAutoSyncProvider.notifier).mark(longAgo);

      // App returns to the foreground.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // The resume handler ran a fresh sync (advanced the shared marker past the
      // stale time) and the shell is intact — no exception, nav preserved.
      final marker = container.read(homeLastAutoSyncProvider);
      expect(marker, isNotNull);
      expect(marker!.isAfter(longAgo), isTrue);
      expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
    },
  );

  testWidgets(
    'selecting each destination displays the existing feature screen',
    (tester) async {
      await tester.pumpShell();

      await tester.tap(find.byKey(const ValueKey('nav-scan')));
      await tester.pumpTabSwitch();
      expect(
        find.byKey(const ValueKey('shell-destination-scan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scan-hub-capture-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('nav-portfolio')));
      await tester.pumpTabSwitch();
      expect(
        find.byKey(const ValueKey('shell-destination-portfolio')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('nav-search')));
      await tester.pumpTabSwitch();
      expect(
        find.byKey(const ValueKey('shell-destination-search')),
        findsOneWidget,
      );
      expect(find.text('Discover'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('discover-search-field')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('nav-settings')));
      await tester.pumpTabSwitch();
      expect(
        find.byKey(const ValueKey('shell-destination-settings')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'selected state updates once and repeated selected taps are no-op',
    (tester) async {
      await tester.pumpShell();

      await tester.tap(find.byKey(const ValueKey('nav-portfolio')));
      await tester.tap(find.byKey(const ValueKey('nav-portfolio')));
      await tester.pumpTabSwitch();

      final navigation = tester.widget<GlassBottomNavBar>(
        find.byKey(const ValueKey('bottom-navigation')),
      );
      expect(navigation.currentIndex, AppShellTabController.portfolioTab);
      expect(
        find.byKey(const ValueKey('shell-destination-portfolio')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('shell-destination-home')),
        findsNothing,
      );
    },
  );

  testWidgets('rapid sequential tab taps leave one selected destination', (
    tester,
  ) async {
    await tester.pumpShell();

    await tester.tap(find.byKey(const ValueKey('nav-portfolio')));
    await tester.tap(find.byKey(const ValueKey('nav-scan')));
    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpTabSwitch();

    final navigation = tester.widget<GlassBottomNavBar>(
      find.byKey(const ValueKey('bottom-navigation')),
    );
    expect(navigation.currentIndex, AppShellTabController.homeTab);
    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
  });

  testWidgets('inactive Scanner destination is not retained off tab', (
    tester,
  ) async {
    await tester.pumpShell();

    await tester.tap(find.byKey(const ValueKey('nav-scan')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('scan-hub-capture-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpTabSwitch();

    expect(find.byKey(const ValueKey('shell-destination-scan')), findsNothing);
    expect(find.byKey(const ValueKey('scan-hub-capture-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('shell-destination-home')),
      findsOneWidget,
    );
  });

  testWidgets('analysis result hides shell bottom navigation', (tester) async {
    await tester.pumpShell(
      scannerController: _ShellResultScannerController.new,
    );

    await tester.tap(find.byKey(const ValueKey('nav-scan')));
    await tester.pumpTabSwitch();

    expect(find.text('Analysis Complete'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('result-primary-add-to-portfolio')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bottom-navigation')), findsNothing);
    await tester.pump(const Duration(milliseconds: 320));
  });

  testWidgets('selected semantics are announced by shell navigation', (
    tester,
  ) async {
    await tester.pumpShell();

    await tester.tap(find.byKey(const ValueKey('nav-scan')));
    await tester.pumpTabSwitch();

    final semantics = tester.getSemantics(find.bySemanticsLabel('Scan'));
    expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
  });

  testWidgets('normal SIT settings hides developer preview shortcuts', (
    tester,
  ) async {
    await tester.pumpShell(
      environmentConfig: const EnvironmentConfig(
        environment: AppEnvironment.sit,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.pumpTabSwitch();

    expect(
      find.byKey(const ValueKey('shell-destination-settings')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-home-state-preview')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('settings-portfolio-state-preview')),
      findsNothing,
    );
    expect(find.text('Developer Tools'), findsNothing);
  });
  testWidgets('light and dark shell navigation render without overflow', (
    tester,
  ) async {
    await tester.pumpShell(themeMode: ThemeMode.light);
    expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpShell(themeMode: ThemeMode.dark);
    expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text and narrow width do not overflow shell navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpNavigationOnly(textScale: 2);

    expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom inset is owned by navigation safe area', (tester) async {
    await tester.pumpShell(viewPadding: const EdgeInsets.only(bottom: 32));

    final safeArea = tester.widget<SafeArea>(
      find.byKey(const ValueKey('bottom-navigation-safe-area-surface')),
    );
    expect(safeArea.top, isFalse);
    expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
  });

  testWidgets('reduced-motion tab switching has no artificial timer', (
    tester,
  ) async {
    await tester.pumpShell(disableAnimations: true);

    await tester.tap(find.byKey(const ValueKey('nav-portfolio')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('shell-destination-portfolio')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(
      find.byKey(const ValueKey('shell-destination-portfolio')),
      findsOneWidget,
    );
  });

  testWidgets(
    'signing out wipes local user data so the next account on this device '
    'starts clean (real bug: SharedPreferences keys were not namespaced by '
    'user id, so a second sign-up on a shared device would silently inherit '
    'the previous account\'s portfolio/wishlist/alerts/profile/subscription '
    'state)',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'portfolio_items': jsonEncode([
          {
            'id': 'user-a-item',
            'title': 'User A Charizard',
            'category': 'Trading Card',
            'estimatedValue': 250.0,
            'confidence': 0.9,
            'condition': 'Near Mint',
            'recommendation': 'Keep tracking.',
            'imagePath': 'sample://user-a-item',
            'createdAt': DateTime.now().toIso8601String(),
            'valuationStatus': 'market_estimated',
          },
        ]),
        'wishlist_status_entries': jsonEncode([
          {
            'itemId': 'user-a-item',
            'status': 'wanted',
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ]),
        'packlox.profile.display_name': 'User A',
        'packlox.profile.preferred_currency': 'EUR',
        'subscription_active_plan': 'pro',
        'subscription_scans_used_month': 9,
      });

      await tester.pumpShell();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );

      // User A is signed in (the shell test harness auto-signs-in) and their
      // locally-cached data is loaded.
      expect(container.read(authControllerProvider).isSignedIn, isTrue);
      await container.read(portfolioControllerProvider.notifier).loadItems();
      expect(container.read(portfolioControllerProvider).items, hasLength(1));

      // User A signs out.
      await container.read(authControllerProvider.notifier).signOut();
      // Not pumpAndSettle: an unrelated background FX-rate retry loop never
      // quiesces in this harness. One frame is enough to flush the
      // post-frame-scheduled cache clear and provider invalidation.
      await tester.pump();

      expect(container.read(authControllerProvider).isSignedIn, isFalse);

      final preferences = await SharedPreferences.getInstance();
      for (final key in [
        'portfolio_items',
        'wishlist_status_entries',
        'packlox.profile.display_name',
        'packlox.profile.preferred_currency',
        'subscription_active_plan',
        'subscription_scans_used_month',
      ]) {
        expect(
          preferences.containsKey(key),
          isFalse,
          reason: '"$key" should be cleared on sign-out',
        );
      }

      // A brand-new account on this device must not see User A's data.
      final freshPortfolio = await container
          .read(portfolioRepositoryProvider)
          .getItems();
      expect(freshPortfolio, isEmpty);
      final freshWishlist = await container.read(
        wishlistRepositoryProvider,
      ).getEntries();
      expect(freshWishlist, isEmpty);
    },
  );
}

extension _ShellPump on WidgetTester {
  Future<void> pumpShell({
    ThemeMode themeMode = ThemeMode.light,
    EnvironmentConfig? environmentConfig,
    ScannerController Function()? scannerController,
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          if (environmentConfig != null)
            environmentConfigProvider.overrideWithValue(environmentConfig),
          if (scannerController != null)
            scannerControllerProvider.overrideWith(scannerController),
          onboardingRepositoryProvider.overrideWithValue(
            const _ImmediateOnboardingRepository(completed: true),
          ),
          authRepositoryProvider.overrideWithValue(_ShellAuthRepository()),
        ],
        child: _Harness(
          themeMode: themeMode,
          disableAnimations: disableAnimations,
          textScale: textScale,
          viewPadding: viewPadding,
          child: const AppShell(),
        ),
      ),
    );
    await pumpAndSettle();
  }

  Future<void> pumpTabSwitch() async {
    await pump();
    await pump(const Duration(milliseconds: 180));
  }

  Future<void> pumpNavigationOnly({
    ThemeMode themeMode = ThemeMode.light,
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) {
    return pumpWidget(
      _Harness(
        themeMode: themeMode,
        disableAnimations: disableAnimations,
        textScale: textScale,
        viewPadding: viewPadding,
        child: Scaffold(
          bottomNavigationBar: GlassBottomNavBar(
            key: const ValueKey('bottom-navigation'),
            currentIndex: AppShellTabController.homeTab,
            onTap: (_) {},
            items: const [
              NavBarItem(
                key: ValueKey('nav-home'),
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Home',
                isActive: false,
              ),
              NavBarItem(
                key: ValueKey('nav-scan'),
                icon: Icons.camera_alt_outlined,
                selectedIcon: Icons.camera_alt_rounded,
                label: 'Scan',
                isActive: false,
              ),
              NavBarItem(
                key: ValueKey('nav-portfolio'),
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2_rounded,
                label: 'Portfolio',
                isActive: false,
              ),
              NavBarItem(
                key: ValueKey('nav-search'),
                icon: Icons.search_outlined,
                selectedIcon: Icons.search_rounded,
                label: 'Search',
                isActive: false,
              ),
              NavBarItem(
                key: ValueKey('nav-settings'),
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: 'Settings',
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Harness extends StatelessWidget {
  const _Harness({
    required this.child,
    this.themeMode = ThemeMode.light,
    this.disableAnimations = false,
    this.textScale = 1,
    this.viewPadding = EdgeInsets.zero,
  });

  final Widget child;
  final ThemeMode themeMode;
  final bool disableAnimations;
  final double textScale;
  final EdgeInsets viewPadding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PackLox',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
            viewPadding: viewPadding,
            padding: viewPadding,
          );
          return MediaQuery(data: mediaQuery, child: child);
        },
      ),
    );
  }
}

class _ImmediateOnboardingRepository implements OnboardingRepository {
  const _ImmediateOnboardingRepository({required this.completed});

  final bool completed;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}
}

class _ShellResultScannerController extends ScannerController {
  @override
  ScannerState build() {
    final now = DateTime(2026, 7, 24);
    return ScannerState(
      selectedImagePath: 'sample://shell-result',
      scanResult: ScanResult(
        id: 'shell-result',
        title: 'Shell Test Collectible',
        category: 'Trading Card',
        estimatedValue: 120,
        confidence: 0.86,
        condition: 'Good',
        thumbnail: 'sample://shell-result',
        scanDate: now,
        primaryMatch: 'Shell Test Collectible',
        alternativeMatches: const [],
        confidenceExplanation: 'Shell test confidence.',
        detectionQuality: 'Good',
        aiReasoning: 'Shell test reasoning.',
        pricing: PricingInfo(
          estimatedMarketValue: 120,
          lowEstimate: 100,
          highEstimate: 140,
          currency: 'AUD',
          pricingSource: 'Shell test',
          pricingConfidence: 0.8,
          lastUpdated: now,
        ),
      ),
    );
  }

  @override
  Future<void> recoverLostPickerData({String reason = 'startup'}) async {}

  @override
  void resetAfterSaved() {}
}

class _ShellAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> currentUser() async {
    return const AppUser(
      id: 'shell-user',
      displayName: 'Shell Collector',
      email: 'shell@example.com',
      provider: AuthProviderType.emailPassword,
    );
  }

  @override
  Future<AppUser> signIn() => signInAnonymously();

  @override
  Future<AppUser> signInAnonymously() async {
    return const AppUser(
      id: 'local-user',
      displayName: 'Local Collector',
      email: null,
      isAnonymous: true,
      isLocalOnly: true,
      provider: AuthProviderType.localAnonymous,
    );
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return AppUser(
      id: 'cloud-user',
      displayName: email,
      email: email,
      provider: AuthProviderType.emailPassword,
    );
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw const AuthException('Sign up is out of scope for shell tests.');
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException('Google sign-in is not enabled.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException('Apple sign-in is not enabled.');
  }

  @override
  Future<void> signOut() async {}
}
