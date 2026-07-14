import 'dart:async';

import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sign In is a separate screen with approved header and fields', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-packlox-header')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-sign-in-email-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings-auth-email-field')), findsNothing);
  });

  testWidgets('Settings opens Sign In without embedding credential fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpAuthScreen(const SettingsScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-auth-email-field')), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Sign In').first,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sign In').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-sign-in-email-field')), findsOneWidget);
  });

  testWidgets('password visibility toggles on Sign In and Sign Up', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    TextField password = tester.widget(
      _textFieldIn(const ValueKey('auth-sign-in-password-field')),
    );
    expect(password.obscureText, isTrue);

    await tester.tap(find.byKey(const ValueKey('auth-sign-in-password-visibility')));
    await tester.pump();

    password = tester.widget(
      _textFieldIn(const ValueKey('auth-sign-in-password-field')),
    );
    expect(password.obscureText, isFalse);

    await tester.ensureVisible(find.byKey(const ValueKey('auth-open-sign-up')));
    await tester.tap(find.byKey(const ValueKey('auth-open-sign-up')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-sign-up-password-visibility')));
    await tester.pump();

    password = tester.widget(
      _textFieldIn(const ValueKey('auth-sign-up-password-field')),
    );
    expect(password.obscureText, isFalse);
  });

  testWidgets('validation remains real and prevents sign-in callback', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository();
    await tester.pumpAuthRoute(repository: repository);

    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pump();

    expect(find.text('Enter an email address.'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('Sign In callback invokes once and loading blocks rapid taps', (
    tester,
  ) async {
    final completer = Completer<AppUser>();
    final repository = _InteractiveAuthRepository(signInCompleter: completer);
    await tester.pumpAuthScreen(const AuthSignInScreen(), repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')), warnIfMissed: false);
    await tester.pump();

    expect(repository.signInCalls, 1);

    completer.complete(_cloudUser('collector@example.com'));
    await tester.pumpAndSettle();
    expect(repository.signInCalls, 1);
  });

  testWidgets('Sign In success returns to previous destination', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository();
    await tester.pumpAuthRoute(repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsNothing);
    expect(find.byKey(const ValueKey('open-auth-route')), findsOneWidget);
  });

  testWidgets('human-readable auth error is rendered', (tester) async {
    await tester.pumpAuthScreen(
      const AuthSignInScreen(),
      repository: _InteractiveAuthRepository(
        signInError: const AuthException('Invalid email or password.'),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.textContaining('Supabase Auth returned'), findsNothing);
  });

  testWidgets('Sign Up is separate and can return to Sign In', (tester) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    await tester.ensureVisible(find.byKey(const ValueKey('auth-open-sign-up')));
    await tester.tap(find.byKey(const ValueKey('auth-open-sign-up')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-up-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-sign-up-email-field')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('auth-return-sign-in')));
    await tester.tap(find.byKey(const ValueKey('auth-return-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
  });

  testWidgets('Sign Up confirmation state uses controller state only', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository(
      signUpError: const SupabaseEmailConfirmationSentException(),
    );
    await tester.pumpAuthScreen(const AuthSignUpScreen(), repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-up-email-field')),
      'verify@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-up-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-up-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Check Your Email'), findsOneWidget);
    expect(find.text('verify@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-resend-confirmation')), findsOneWidget);
  });

  testWidgets('Email verification resend invokes existing contract once', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository(
      signUpError: const SupabaseEmailConfirmationRequiredException(),
    );
    await tester.pumpAuthScreen(const AuthSignUpScreen(), repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-up-email-field')),
      'verify@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-up-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-up-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-resend-confirmation')));
    await tester.pumpAndSettle();

    expect(repository.signUpCalls, 1);
    expect(repository.resendCalls, 1);
    expect(repository.lastResendEmail, 'verify@example.com');
    expect(find.text(AuthMessages.confirmationEmailSent), findsOneWidget);
  });

  testWidgets('Email verification resend rate limit is human-readable', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository(
      signUpError: const SupabaseEmailConfirmationRequiredException(),
      resendError: const SupabaseConfirmationRateLimitedException(
        cooldown: Duration(minutes: 5),
        cooldownSource: 'fallback',
      ),
    );
    await tester.pumpAuthScreen(const AuthSignUpScreen(), repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-up-email-field')),
      'verify@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-up-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-up-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-resend-confirmation')));
    await tester.pumpAndSettle();

    expect(repository.resendCalls, 1);
    expect(find.text(AuthMessages.confirmationRateLimited), findsOneWidget);
  });

  testWidgets('Forgot Password route invokes recovery once and explains web flow', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository();
    await tester.pumpAuthScreen(
      const AuthForgotPasswordScreen(),
      repository: repository,
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-email-field')),
      'reset@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
    await tester.pumpAndSettle();

    expect(repository.passwordResetCalls, 1);
    expect(repository.lastPasswordResetEmail, 'reset@example.com');
    expect(find.byKey(const ValueKey('auth-recovery-web-handoff')), findsOneWidget);
    expect(find.textContaining('secure web link'), findsOneWidget);
  });

  testWidgets('Forgot Password rate limit and errors stay human-readable', (
    tester,
  ) async {
    final rateLimitedRepository = _InteractiveAuthRepository(
      passwordResetError: const SupabasePasswordResetRateLimitedException(
        cooldown: Duration(minutes: 5),
        cooldownSource: 'fallback',
      ),
    );
    await tester.pumpAuthScreen(
      const AuthForgotPasswordScreen(),
      repository: rateLimitedRepository,
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-email-field')),
      'reset@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
    await tester.pumpAndSettle();

    expect(rateLimitedRepository.passwordResetCalls, 1);
    expect(find.text(AuthMessages.passwordResetRateLimited), findsOneWidget);

    final failingRepository = _InteractiveAuthRepository(
      passwordResetError: const AuthException(
        'Unable to reach Supabase. Check your internet connection.',
      ),
    );
    await tester.pumpAuthScreen(
      const AuthForgotPasswordScreen(),
      repository: failingRepository,
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-email-field')),
      'reset@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
    await tester.pumpAndSettle();

    expect(failingRepository.passwordResetCalls, 1);
    expect(
      find.text('Unable to reach Supabase. Check your internet connection.'),
      findsOneWidget,
    );
  });

  testWidgets('Guest return remains available without auth guard', (tester) async {
    await tester.pumpAuthRoute();

    expect(find.byKey(const ValueKey('auth-continue-guest')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-guest-access-note')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('auth-continue-guest')));
    await tester.tap(find.byKey(const ValueKey('auth-continue-guest')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsNothing);
  });

  testWidgets('Settings signed-in summary and sign-out remain real', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _InteractiveAuthRepository(
      initialUser: _cloudUser('collector@example.com'),
    );
    await tester.pumpAuthScreen(const SettingsScreen(), repository: repository);
    await tester.pumpAndSettle();

    expect(find.text('collector@example.com'), findsWidgets);
    expect(find.byKey(const ValueKey('settings-auth-email-field')), findsNothing);
    expect(find.byKey(const ValueKey('settings-auth-sign-in-button')), findsNothing);
    expect(find.text('Sign Out'), findsOneWidget);

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
  });

  test('AuthController can rebuild without replacing session state', () async {
    final repository = _InteractiveAuthRepository(
      initialUser: _cloudUser('collector@example.com'),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).loadCurrentUser();
    expect(container.read(authControllerProvider).isSignedIn, isTrue);

    container.invalidate(authControllerProvider);
    await container.read(authControllerProvider.notifier).loadCurrentUser();

    final state = container.read(authControllerProvider);
    expect(state.isSignedIn, isTrue);
    expect(state.user?.email, 'collector@example.com');
    expect(repository.currentUserCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('auth screens fit 320px and large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpAuthScreen(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
        child: const AuthSignInScreen(),
      ),
    );

    expect(find.byKey(const ValueKey('auth-scroll-view')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark and light themes render auth presentation', (tester) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);

    await tester.pumpAuthScreen(const AuthSignInScreen(), themeMode: ThemeMode.light);
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
  });
}

extension on WidgetTester {
  Future<void> pumpAuthScreen(
    Widget child, {
    AuthRepository? repository,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            repository ?? _InteractiveAuthRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: Scaffold(body: child),
        ),
      ),
    );
    await pump();
  }

  Future<void> pumpAuthRoute({
    AuthRepository? repository,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            repository ?? _InteractiveAuthRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey('open-auth-route'),
                  onPressed: () => Navigator.of(context).push(
                    AuthSignInScreen.route(),
                  ),
                  child: const Text('Open auth'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await pump();
    await tap(find.byKey(const ValueKey('open-auth-route')));
    await pumpAndSettle();
  }
}

Finder _textFieldIn(Key key) {
  return find.descendant(of: find.byKey(key), matching: find.byType(TextField));
}

class _InteractiveAuthRepository implements AuthRepository {
  _InteractiveAuthRepository({
    AppUser? initialUser,
    this.signInError,
    this.signUpError,
    this.resendError,
    this.passwordResetError,
    this.signInCompleter,
  }) : _user = initialUser;

  AppUser? _user;
  final Object? signInError;
  final Object? signUpError;
  final Object? resendError;
  final Object? passwordResetError;
  final Completer<AppUser>? signInCompleter;
  var currentUserCalls = 0;
  var signInCalls = 0;
  var signUpCalls = 0;
  var resendCalls = 0;
  var passwordResetCalls = 0;
  var signOutCalls = 0;
  String? lastResendEmail;
  String? lastPasswordResetEmail;

  @override
  Future<AppUser?> currentUser() async {
    currentUserCalls += 1;
    return _user;
  }

  @override
  Future<AppUser> signIn() => signInAnonymously();

  @override
  Future<AppUser> signInAnonymously() async {
    _user = const AppUser(
      id: 'local-user',
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
    if (signInError != null) {
      throw signInError!;
    }
    final completer = signInCompleter;
    if (completer != null) {
      _user = await completer.future;
      return _user!;
    }
    _user = _cloudUser(email);
    return _user!;
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    if (signUpError != null) {
      throw signUpError!;
    }
    _user = _cloudUser(email);
    return _user!;
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {
    resendCalls += 1;
    lastResendEmail = email;
    if (resendError != null) {
      throw resendError!;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    passwordResetCalls += 1;
    lastPasswordResetEmail = email;
    if (passwordResetError != null) {
      throw passwordResetError!;
    }
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException('Google sign-in is not enabled.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException('Apple sign-in is not enabled.');
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    _user = null;
  }
}

AppUser _cloudUser(String email) {
  return AppUser(
    id: 'cloud-user',
    displayName: email,
    email: email,
    provider: AuthProviderType.emailPassword,
  );
}
