import 'dart:async';

import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_bootstrap_surface.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/guest_mode_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/guest_mode_controller.dart';
import 'package:collectiq_ai/features/auth/data/repositories/shared_preferences_guest_mode_repository.dart';
import 'package:collectiq_ai/features/onboarding/data/repositories/shared_preferences_onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unresolved onboarding state shows bootstrap presentation', (
    tester,
  ) async {
    final repository = _CompleterOnboardingRepository();

    await tester.pumpEntry(repository: repository);

    expect(find.byKey(const ValueKey('packlox-bootstrap')), findsOneWidget);
    expect(find.text('Preparing your collection workspace'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('packlox-bootstrap-progress')),
      findsOneWidget,
    );
    expect(find.textContaining('Sign in'), findsNothing);
    expect(repository.loadCalls, 1);
  });

  testWidgets('completed onboarding state shows AppShell Home', (tester) async {
    await tester.pumpEntry(
      repository: _ImmediateOnboardingRepository(completed: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(find.text('Scan any collectible'), findsNothing);
  });

  testWidgets(
    'incomplete onboarding state shows reconstructed OnboardingScreen',
    (tester) async {
      await tester.pumpEntry(
        repository: _ImmediateOnboardingRepository(completed: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan any collectible'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding-next')), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    },
  );

  testWidgets('unauthenticated non-guest launch shows S01 welcome', (
    tester,
  ) async {
    await tester.pumpEntry(
      repository: _ImmediateOnboardingRepository(completed: false),
      guestRepository: _ImmediateGuestModeRepository(chosen: false),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsOneWidget);
    expect(find.text('Identify. Value. Protect.'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-screen')), findsNothing);
    expect(find.byKey(const ValueKey('app-shell')), findsNothing);
  });

  testWidgets('first authenticated launch shows onboarding before Home', (
    tester,
  ) async {
    final repository = _MutableOnboardingRepository(completed: false);

    await tester.pumpEntry(
      repository: repository,
      authRepository: _EntryAuthRepository(
        user: _cloudUser('collector@example.com'),
      ),
      guestRepository: _ImmediateGuestModeRepository(chosen: false),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsNothing);
    expect(find.byKey(const ValueKey('onboarding-screen')), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('onboarding-explore-dashboard')),
    );
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-screen')), findsNothing);
  });

  testWidgets('Explore as Guest opens onboarding before guest Home', (
    tester,
  ) async {
    final onboardingRepository = _MutableOnboardingRepository(completed: false);
    final guestRepository = _MutableGuestModeRepository(chosen: false);

    await tester.pumpEntry(
      repository: onboardingRepository,
      guestRepository: guestRepository,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('auth-welcome-explore-guest')));
    await tester.pumpAndSettle();

    expect(guestRepository.chosen, isTrue);
    expect(find.byKey(const ValueKey('onboarding-screen')), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('onboarding-explore-dashboard')),
    );
    await tester.pumpAndSettle();

    expect(onboardingRepository.completed, isTrue);
    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-screen')), findsNothing);
  });

  testWidgets('bootstrap does not insert authentication', (tester) async {
    final repository = _CompleterOnboardingRepository();

    await tester.pumpEntry(repository: repository);

    expect(find.byKey(const ValueKey('packlox-bootstrap')), findsOneWidget);
    expect(find.textContaining('Sign in'), findsNothing);
    expect(find.textContaining('Create account'), findsNothing);
    expect(find.textContaining('Password'), findsNothing);
  });

  testWidgets('no artificial timer controls destination', (tester) async {
    final repository = _CompleterOnboardingRepository();

    await tester.pumpEntry(repository: repository);
    await tester.pump(const Duration(seconds: 3));

    expect(find.byKey(const ValueKey('packlox-bootstrap')), findsOneWidget);
    expect(find.text('Scan any collectible'), findsNothing);

    repository.complete(false);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('packlox-bootstrap')), findsNothing);
    expect(find.text('Scan any collectible'), findsOneWidget);
  });

  testWidgets('state resolution does not invoke duplicate onboarding loads', (
    tester,
  ) async {
    final repository = _CompleterOnboardingRepository();

    await tester.pumpEntry(repository: repository);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.loadCalls, 1);

    repository.complete(true);
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
  });

  testWidgets('reduced-motion path disables entry transition duration', (
    tester,
  ) async {
    await tester.pumpEntry(
      repository: _ImmediateOnboardingRepository(completed: true),
      disableAnimations: true,
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
    expect(switcher.reverseDuration, Duration.zero);
  });

  testWidgets('bootstrap presentation supports light theme', (tester) async {
    await tester.pumpBootstrap(themeMode: ThemeMode.light);

    expect(find.byKey(const ValueKey('packlox-bootstrap')), findsOneWidget);
    expect(find.text('PackLox'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bootstrap presentation supports dark theme', (tester) async {
    await tester.pumpBootstrap(themeMode: ThemeMode.dark);

    expect(find.byKey(const ValueKey('packlox-bootstrap')), findsOneWidget);
    expect(find.text('PackLox'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text scale does not overflow bootstrap presentation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpBootstrap(textScale: 2);

    expect(find.byKey(const ValueKey('packlox-bootstrap')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recoverable onboarding error can retry provider resolution', (
    tester,
  ) async {
    final repository = _FailOnceOnboardingRepository(
      completedAfterRetry: false,
    );

    await tester.pumpEntry(repository: repository);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('packlox-bootstrap-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('packlox-bootstrap-retry')),
      findsOneWidget,
    );
    expect(repository.loadCalls, 1);

    await tester.tap(find.byKey(const ValueKey('packlox-bootstrap-retry')));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(find.text('Scan any collectible'), findsOneWidget);
  });

  test('onboarding persistence key remains unchanged', () {
    expect(
      SharedPreferencesOnboardingRepository.completedKey,
      'onboarding_completed_v1',
    );
  });

  test('guest mode persistence key remains unchanged', () {
    expect(
      SharedPreferencesGuestModeRepository.chosenKey,
      'auth_guest_mode_chosen_v1',
    );
  });
}

extension _EntryPump on WidgetTester {
  Future<void> pumpEntry({
    required OnboardingRepository repository,
    AuthRepository? authRepository,
    GuestModeRepository? guestRepository,
    bool disableAnimations = false,
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            authRepository ?? _EntryAuthRepository(),
          ),
          guestModeRepositoryProvider.overrideWithValue(
            guestRepository ?? _ImmediateGuestModeRepository(chosen: true),
          ),
        ],
        child: _MediaWrappedApp(
          disableAnimations: disableAnimations,
          child: const AppShell(),
        ),
      ),
    );
  }

  Future<void> pumpBootstrap({
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
  }) {
    return pumpWidget(
      _MediaWrappedApp(
        themeMode: themeMode,
        textScale: textScale,
        child: const Scaffold(body: PackLoxBootstrapSurface.loading()),
      ),
    );
  }
}

class _MediaWrappedApp extends StatelessWidget {
  const _MediaWrappedApp({
    required this.child,
    this.disableAnimations = false,
    this.themeMode = ThemeMode.light,
    this.textScale = 1,
  });

  final Widget child;
  final bool disableAnimations;
  final ThemeMode themeMode;
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

class _ImmediateOnboardingRepository implements OnboardingRepository {
  const _ImmediateOnboardingRepository({required this.completed});

  final bool completed;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}
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

class _CompleterOnboardingRepository implements OnboardingRepository {
  final _completer = Completer<bool>();
  var loadCalls = 0;

  @override
  Future<bool> hasCompletedOnboarding() {
    loadCalls += 1;
    return _completer.future;
  }

  void complete(bool completed) {
    _completer.complete(completed);
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}
}

class _FailOnceOnboardingRepository implements OnboardingRepository {
  _FailOnceOnboardingRepository({required this.completedAfterRetry});

  final bool completedAfterRetry;
  var loadCalls = 0;

  @override
  Future<bool> hasCompletedOnboarding() async {
    loadCalls += 1;
    if (loadCalls == 1) {
      throw StateError('preference unavailable');
    }
    return completedAfterRetry;
  }

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

class _MutableGuestModeRepository implements GuestModeRepository {
  _MutableGuestModeRepository({required this.chosen});

  bool chosen;
  var writeCalls = 0;

  @override
  Future<bool> hasChosenGuestMode() async => chosen;

  @override
  Future<void> setGuestModeChosen(bool chosen) async {
    writeCalls += 1;
    this.chosen = chosen;
  }
}

class _EntryAuthRepository implements AuthRepository {
  _EntryAuthRepository({this.user});

  final AppUser? user;

  @override
  Future<AppUser?> currentUser() async => user;

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
    return _cloudUser(email);
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw const AuthException('Sign up is out of scope for entry routing.');
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

AppUser _cloudUser(String email) {
  return AppUser(
    id: 'cloud-user',
    displayName: email,
    email: email,
    provider: AuthProviderType.emailPassword,
  );
}
