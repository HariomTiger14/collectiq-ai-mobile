import 'dart:ui' as ui;

import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/guest_mode_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/guest_mode_controller.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(find.text('Search is being prepared.'), findsOneWidget);

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

  testWidgets('selected semantics are announced by shell navigation', (
    tester,
  ) async {
    await tester.pumpShell();

    await tester.tap(find.byKey(const ValueKey('nav-scan')));
    await tester.pumpTabSwitch();

    final semantics = tester.getSemantics(find.bySemanticsLabel('Scan'));
    expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
  });

  testWidgets(
    'Settings Home preview selection returns to Home with nav visible',
    (tester) async {
      await tester.pumpShell(
        environmentConfig: const EnvironmentConfig(
          environment: AppEnvironment.sit,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('nav-settings')));
      await tester.pumpTabSwitch();
      await tester.revealFinder(
        find.byKey(const ValueKey('settings-home-state-preview')),
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-home-state-preview')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home State Preview'), findsWidgets);
      expect(
        find.byKey(const ValueKey('home-preview-scenario-picker')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('home-action-preview-defaultData')),
      );
      await tester.pumpAndSettle();

      final navigation = tester.widget<GlassBottomNavBar>(
        find.byKey(const ValueKey('bottom-navigation')),
      );
      expect(navigation.currentIndex, AppShellTabController.homeTab);
      expect(
        find.byKey(const ValueKey('shell-destination-home')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
      await tester.revealText('Collection value');
      expect(find.text('Collection value'), findsOneWidget);
      expect(find.text('\$2,275'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-preview-scenario-picker')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Settings Portfolio preview selection returns to Portfolio with nav visible',
    (tester) async {
      await tester.pumpShell(
        environmentConfig: const EnvironmentConfig(
          environment: AppEnvironment.sit,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('nav-settings')));
      await tester.pumpTabSwitch();
      await tester.revealFinder(
        find.byKey(const ValueKey('settings-portfolio-state-preview')),
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-portfolio-state-preview')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Portfolio State Preview'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('home-action-portfolio-preview-partial')),
      );
      await tester.pumpAndSettle();

      final navigation = tester.widget<GlassBottomNavBar>(
        find.byKey(const ValueKey('bottom-navigation')),
      );
      expect(navigation.currentIndex, AppShellTabController.portfolioTab);
      expect(
        find.byKey(const ValueKey('shell-destination-portfolio')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
      await tester.revealText('Needs value');
      expect(find.text('Needs value'), findsOneWidget);
      expect(find.byType(DropdownButton), findsNothing);
    },
  );
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
}

extension _ShellPump on WidgetTester {
  Future<void> pumpShell({
    ThemeMode themeMode = ThemeMode.light,
    EnvironmentConfig? environmentConfig,
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          if (environmentConfig != null)
            environmentConfigProvider.overrideWithValue(environmentConfig),
          onboardingRepositoryProvider.overrideWithValue(
            const _ImmediateOnboardingRepository(completed: true),
          ),
          authRepositoryProvider.overrideWithValue(_ShellAuthRepository()),
          guestModeRepositoryProvider.overrideWithValue(
            const _ImmediateGuestModeRepository(chosen: true),
          ),
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

  Future<void> revealText(String text) async {
    await revealFinder(find.text(text), description: text);
  }

  Future<void> revealFinder(Finder finder, {String? description}) async {
    for (var attempt = 0; attempt < 24; attempt += 1) {
      if (finder.evaluate().isNotEmpty) {
        await ensureVisible(finder.first);
        await pump();
        return;
      }
      for (final element in find.byType(Scrollable).evaluate()) {
        if (element is! StatefulElement || element.state is! ScrollableState) {
          continue;
        }
        final position = (element.state as ScrollableState).position;
        if (!position.hasPixels || position.maxScrollExtent <= 0) {
          continue;
        }
        position.jumpTo(
          (position.pixels + 420).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      }
      await pumpAndSettle();
    }
    fail('Could not reveal "${description ?? finder}" in AppShell.');
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

class _ImmediateGuestModeRepository implements GuestModeRepository {
  const _ImmediateGuestModeRepository({required this.chosen});

  final bool chosen;

  @override
  Future<bool> hasChosenGuestMode() async => chosen;

  @override
  Future<void> setGuestModeChosen(bool chosen) async {}
}

class _ShellAuthRepository implements AuthRepository {
  @override
  Future<AppUser?> currentUser() async => null;

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
