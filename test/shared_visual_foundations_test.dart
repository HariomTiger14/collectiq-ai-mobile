import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shared visual foundation theme', () {
    test('dark Scaffold background uses approved token', () {
      expect(AppTheme.dark.scaffoldBackgroundColor, PackLoxTokens.background);
      expect(AppTheme.dark.colorScheme.surface, PackLoxTokens.background);
    });

    test('light Scaffold background uses approved app canvas token', () {
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.canvas);
      expect(AppTheme.light.colorScheme.surface, AppColors.canvas);
    });

    test('raised surfaces do not resolve to default white in dark theme', () {
      final theme = AppTheme.dark;
      expect(theme.cardTheme.color, PackLoxTokens.surfaceRaised);
      expect(
        theme.colorScheme.surfaceContainerHighest,
        PackLoxTokens.surfaceRaised,
      );
      expect(theme.cardTheme.color, isNot(Colors.white));
    });

    test('modal sheet and dialog use approved dark surfaces', () {
      final theme = AppTheme.dark;
      expect(
        theme.bottomSheetTheme.backgroundColor,
        PackLoxTokens.surfaceRaised,
      );
      expect(
        theme.bottomSheetTheme.modalBackgroundColor,
        PackLoxTokens.surfaceRaised,
      );
      expect(theme.dialogTheme.backgroundColor, PackLoxTokens.surfaceRaised);
    });

    test('dark Material defaults do not leak white surfaces', () {
      final theme = AppTheme.dark;
      final colors = <Color?>{
        theme.canvasColor,
        theme.cardColor,
        theme.dialogTheme.backgroundColor,
        theme.bottomSheetTheme.backgroundColor,
        theme.bottomSheetTheme.modalBackgroundColor,
        theme.colorScheme.surface,
        theme.colorScheme.surfaceContainerHighest,
      };
      expect(colors, isNot(contains(Colors.white)));
    });
  });

  group('shared header and shell insets', () {
    testWidgets('Header does not double-apply SafeArea', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(top: 44)),
            child: Scaffold(
              body: PackLoxHeader(
                firstName: 'Collector',
                onNotifications: null,
              ),
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(PackLoxHeader),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
    });

    testWidgets('Header remains aligned when parent owns top inset', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(top: 44)),
            child: Scaffold(
              body: SafeArea(
                child: PackLoxHeader(
                  firstName: 'Collector',
                  onNotifications: null,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.getTopLeft(find.byType(PackLoxHeader)).dy, 44);
    });

    testWidgets('bottom navigation clearance preserves gesture inset', (
      tester,
    ) async {
      await tester.pumpNavigationOnly(
        viewPadding: const EdgeInsets.only(bottom: 16),
      );

      final safeArea = tester.widget<SafeArea>(
        find.descendant(
          of: find.byKey(const ValueKey('bottom-navigation-safe-area-surface')),
          matching: find.byType(SafeArea),
        ),
      );
      expect(safeArea.top, isFalse);
      expect(safeArea.minimum.bottom, AppSpacing.sm);
    });

    testWidgets('bottom navigation clearance preserves three-button inset', (
      tester,
    ) async {
      await tester.pumpNavigationOnly(
        viewPadding: const EdgeInsets.only(bottom: 48),
      );

      final surface = tester.widget<ColoredBox>(
        find.byKey(const ValueKey('bottom-navigation-safe-area-surface')),
      );
      expect(surface.color, PackLoxTokens.background);
      expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('App Shell keeps four destinations and dark system surfaces', (
      tester,
    ) async {
      await tester.pumpShell();

      expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-portfolio')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-scan')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-settings')), findsOneWidget);
      expect(find.text('Search'), findsNothing);
      expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
    });
  });

  group('shared sheet and dialog rendering', () {
    testWidgets('modal sheet paints approved dark surface', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const SizedBox(
                        key: ValueKey('shared-foundation-sheet-body'),
                        height: 80,
                      ),
                    ),
                    child: const Text('Open sheet'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.backgroundColor, PackLoxTokens.surfaceRaised);
      expect(
        find.byKey(const ValueKey('shared-foundation-sheet-body')),
        findsOneWidget,
      );
    });

    testWidgets('dialog paints approved dark surface and handles large text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete collectible?'),
                          content: const Text(
                            'This dialog remains usable with larger text.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Open dialog'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete collectible?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widgetList<Material>(find.byType(Material))
            .map((material) => material.color),
        contains(PackLoxTokens.surfaceRaised),
      );
    });
  });
}

extension _SharedVisualFoundationPump on WidgetTester {
  Future<void> pumpShell({
    EdgeInsets viewPadding = EdgeInsets.zero,
    double textScale = 1,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            const _ImmediateOnboardingRepository(completed: true),
          ),
        ],
        child: _Harness(
          viewPadding: viewPadding,
          textScale: textScale,
          child: const AppShell(),
        ),
      ),
    );
    await pumpAndSettle();
  }

  Future<void> pumpNavigationOnly({
    EdgeInsets viewPadding = EdgeInsets.zero,
    double textScale = 1,
  }) {
    return pumpWidget(
      _Harness(
        viewPadding: viewPadding,
        textScale: textScale,
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
    this.textScale = 1,
    this.viewPadding = EdgeInsets.zero,
  });

  final Widget child;
  final double textScale;
  final EdgeInsets viewPadding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PackLox',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context).copyWith(
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
