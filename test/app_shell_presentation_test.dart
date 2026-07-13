import 'dart:ui' as ui;

import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
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
    expect(find.text('Your collection starts here'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shell-destination-portfolio')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('shell-destination-scan')), findsNothing);
    expect(
      find.byKey(const ValueKey('shell-destination-settings')),
      findsNothing,
    );

    final navigation = tester.widget<GlassBottomNavBar>(
      find.byKey(const ValueKey('bottom-navigation')),
    );
    expect(navigation.currentIndex, AppShellTabController.homeTab);
  });

  testWidgets('primary destinations are present once and no extras are added', (
    tester,
  ) async {
    await tester.pumpShell();

    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-portfolio')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-scan')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-settings')), findsOneWidget);
    expect(find.text('Search'), findsNothing);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets(
    'selecting each destination displays the existing feature screen',
    (tester) async {
      await tester.pumpShell();

      await tester.tap(find.byKey(const ValueKey('nav-portfolio')));
      await tester.pumpTabSwitch();
      expect(
        find.byKey(const ValueKey('shell-destination-portfolio')),
        findsOneWidget,
      );

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
    expect(find.text('Your collection starts here'), findsOneWidget);
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
      find.descendant(
        of: find.byKey(const ValueKey('bottom-navigation-safe-area-surface')),
        matching: find.byType(SafeArea),
      ),
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
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            const _ImmediateOnboardingRepository(completed: true),
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
                key: ValueKey('nav-portfolio'),
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2_rounded,
                label: 'Portfolio',
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
