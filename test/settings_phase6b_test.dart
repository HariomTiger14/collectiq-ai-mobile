import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Phase 6B Settings uses approved section order', (tester) async {
    await tester.pumpSettings();

    for (final label in const [
      'Account & Profile',
      'Preferences',
      'Notifications',
      'Privacy & Security',
      'Backup & Sync',
      'Support & Help',
      'About PackLox',
      'Legal',
      'Danger Zone',
    ]) {
      await tester.revealText(label);
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('signed-out account entry opens separate auth screen', (
    tester,
  ) async {
    await tester.pumpSettings();

    expect(
      find.byKey(const ValueKey('settings-auth-email-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-password-field')),
      findsNothing,
    );
    expect(find.text('Guest mode'), findsOneWidget);

    await tester.revealText('Sign In');
    await tester.tap(find.text('Sign In').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsNothing);
    expect(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('auth-welcome-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      findsOneWidget,
    );
  });

  testWidgets('signed-in account summary uses real data and signs out once', (
    tester,
  ) async {
    final repository = _SettingsAuthRepository(
      initialUser: _cloudUser('collector@example.com'),
    );
    await tester.pumpSettings(repository: repository);

    expect(find.text('collector@example.com'), findsWidgets);
    expect(find.text('Signed in'), findsWidgets);

    await tester.revealText('Sign Out');
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.text('Guest mode'), findsOneWidget);
  });

  testWidgets('backup and notification states do not fabricate support', (
    tester,
  ) async {
    await tester.pumpSettings();

    await tester.revealText('Marketing notifications');
    expect(find.text('Marketing notifications'), findsOneWidget);
    expect(find.text('Unavailable'), findsWidgets);

    await tester.revealText('Backup & Sync');
    expect(
      find.text('Signed out. Your collection remains local on this device.'),
      findsOneWidget,
    );
    expect(find.textContaining('Last synced'), findsNothing);
    expect(find.textContaining('Today, 9:41 AM'), findsNothing);
  });

  testWidgets('danger zone confirms supported destructive actions only', (
    tester,
  ) async {
    await tester.pumpSettings();

    await tester.revealText('Delete Account');
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Unavailable'), findsWidgets);

    await tester.tap(find.text('Reset Onboarding'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Onboarding?'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-danger-confirm-button')),
      findsOneWidget,
    );
  });

  testWidgets('Settings renders at 320px with large text in light and dark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final themeMode in [ThemeMode.dark, ThemeMode.light]) {
      await tester.pumpSettings(
        themeMode: themeMode,
        mediaQueryData: const MediaQueryData(
          textScaler: TextScaler.linear(1.3),
        ),
      );
      expect(find.text('Settings'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Home State Preview is hidden in production settings', (
    tester,
  ) async {
    await tester.pumpSettings(
      environmentConfig: const EnvironmentConfig(
        environment: AppEnvironment.prod,
      ),
    );

    expect(find.text('Home State Preview'), findsNothing);
  });

  testWidgets('Home State Preview opens selector from SIT developer surfaces', (
    tester,
  ) async {
    await tester.pumpSettings(
      environmentConfig: const EnvironmentConfig(
        environment: AppEnvironment.sit,
      ),
    );

    await tester.revealText('Home State Preview');
    expect(find.text('Home State Preview'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-home-state-preview')));
    await tester.pumpAndSettle();

    expect(find.text('Home State Preview'), findsWidgets);
    expect(find.text('Empty/new collector'), findsOneWidget);
    expect(find.text('Default/signed-in'), findsOneWidget);
    await tester.revealText('Clear preview / return to real data');
    expect(find.text('Clear preview / return to real data'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-preview-scenario-picker')),
      findsNothing,
    );
  });
}

extension on WidgetTester {
  Future<void> pumpSettings({
    AuthRepository? repository,
    EnvironmentConfig? environmentConfig,
    ThemeMode themeMode = ThemeMode.dark,
    MediaQueryData? mediaQueryData,
  }) async {
    final settings = mediaQueryData == null
        ? const SettingsScreen()
        : MediaQuery(data: mediaQueryData, child: const SettingsScreen());
    await pumpWidget(
      ProviderScope(
        overrides: [
          if (environmentConfig != null)
            environmentConfigProvider.overrideWithValue(environmentConfig),
          authRepositoryProvider.overrideWithValue(
            repository ?? _SettingsAuthRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: settings,
        ),
      ),
    );
    await pump();
  }

  Future<void> revealText(String text) async {
    final scrollable = find.byType(Scrollable).first;
    for (var attempt = 0; attempt < 24; attempt += 1) {
      if (find.text(text).evaluate().isNotEmpty) {
        await ensureVisible(find.text(text).first);
        await pump();
        return;
      }
      await drag(scrollable, const Offset(0, -320));
      await pump();
    }
    fail('Could not reveal "$text" in Settings.');
  }
}

class _SettingsAuthRepository implements AuthRepository {
  _SettingsAuthRepository({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;
  var signOutCalls = 0;

  @override
  Future<AppUser?> currentUser() async => _user;

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
    _user = _cloudUser(email);
    return _user!;
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw const AuthException('Sign up is covered by auth presentation tests.');
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
