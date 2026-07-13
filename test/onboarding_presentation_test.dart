import 'dart:async';

import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/onboarding/data/repositories/shared_preferences_onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('incomplete onboarding shows reconstructed initial stage', (
    tester,
  ) async {
    await tester.pumpOnboarding();

    expect(find.byKey(const ValueKey('onboarding-screen')), findsOneWidget);
    expect(find.text('Welcome to PackLox'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-next')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-back')), findsNothing);
    expect(find.text('Skip'), findsNothing);
    expect(find.textContaining('Sign in'), findsNothing);
    expect(find.textContaining('Create account'), findsNothing);
    expect(find.textContaining('Password'), findsNothing);
  });

  testWidgets('Next and Back move through stages without completing', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpOnboarding(onStartScanning: () => completions++);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.text('A simple collecting loop'), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-back')), findsOneWidget);
    expect(completions, 0);

    await tester.tap(find.byKey(const ValueKey('onboarding-back')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to PackLox'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(completions, 0);
  });

  testWidgets('final Start Scanning completion is one-shot under rapid taps', (
    tester,
  ) async {
    final completer = Completer<void>();
    var completions = 0;

    await tester.pumpOnboarding(
      onStartScanning: () {
        completions += 1;
        return completer.future;
      },
    );
    await tester.advanceToFinalOnboardingStage();

    final start = find.byKey(const ValueKey('onboarding-start-scanning'));
    await tester.tap(start);
    await tester.tap(start);
    await tester.pump();

    expect(completions, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Explore Dashboard handoff completes onboarding in AppShell', (
    tester,
  ) async {
    final repository = _MutableOnboardingRepository(completed: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
        child: const _Harness(child: AppShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.advanceToFinalOnboardingStage();

    await tester.tap(
      find.byKey(const ValueKey('onboarding-explore-dashboard')),
    );
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(repository.writeCalls, 1);
    expect(find.text('Your collection is waiting'), findsOneWidget);
    expect(find.text('Welcome to PackLox'), findsNothing);
  });

  testWidgets('persistence key remains unchanged', (tester) async {
    expect(
      SharedPreferencesOnboardingRepository.completedKey,
      'onboarding_completed_v1',
    );
  });

  testWidgets('no timer or artificial delay advances onboarding', (
    tester,
  ) async {
    await tester.pumpOnboarding();

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Welcome to PackLox'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
  });

  testWidgets('reduced motion path advances immediately', (tester) async {
    await tester.pumpOnboarding(disableAnimations: true);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();

    expect(find.text('A simple collecting loop'), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsOneWidget);
  });

  testWidgets('supports light and dark themes without overflow', (
    tester,
  ) async {
    await tester.pumpOnboarding(themeMode: ThemeMode.light);
    expect(find.text('Welcome to PackLox'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpOnboarding(themeMode: ThemeMode.dark);
    expect(find.text('Welcome to PackLox'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large narrow text scale does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpOnboarding(textScale: 2);

    expect(find.text('Welcome to PackLox'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back returns to previous onboarding stage', (
    tester,
  ) async {
    await tester.pumpOnboarding();

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Welcome to PackLox'), findsOneWidget);
  });
}

extension _OnboardingPump on WidgetTester {
  Future<void> pumpOnboarding({
    FutureOr<void> Function()? onStartScanning,
    FutureOr<void> Function()? onExploreDashboard,
    ThemeMode themeMode = ThemeMode.light,
    bool disableAnimations = false,
    double textScale = 1,
  }) {
    return pumpWidget(
      _Harness(
        themeMode: themeMode,
        disableAnimations: disableAnimations,
        textScale: textScale,
        child: OnboardingScreen(
          onStartScanning: onStartScanning ?? () {},
          onExploreDashboard: onExploreDashboard ?? () {},
        ),
      ),
    );
  }

  Future<void> advanceToFinalOnboardingStage() async {
    await tap(find.byKey(const ValueKey('onboarding-next')));
    await pumpAndSettle();
    await tap(find.byKey(const ValueKey('onboarding-next')));
    await pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
  }
}

class _Harness extends StatelessWidget {
  const _Harness({
    required this.child,
    this.themeMode = ThemeMode.light,
    this.disableAnimations = false,
    this.textScale = 1,
  });

  final Widget child;
  final ThemeMode themeMode;
  final bool disableAnimations;
  final double textScale;

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
          );
          return MediaQuery(data: mediaQuery, child: child);
        },
      ),
    );
  }
}

class _MutableOnboardingRepository implements OnboardingRepository {
  _MutableOnboardingRepository({required this.completed});

  bool completed;
  var writeCalls = 0;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    writeCalls += 1;
    this.completed = completed;
  }
}
