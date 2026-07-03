import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Packlox web auth pages', () {
    test('reset password page contains password update flow', () {
      final html = File(
        'web/auth/reset-password/index.html',
      ).readAsStringSync();
      final script = File('web/auth/auth-page.js').readAsStringSync();
      final supabaseService = File(
        'lib/core/supabase/supabase_service.dart',
      ).readAsStringSync();

      expect(
        File('docs/SIT_REAL_APP_SETUP.md').readAsStringSync(),
        contains('https://packlox.com/auth/reset-password'),
      );
      expect(
        supabaseService,
        contains(
          "queryParameters: const {'redirect_to': passwordResetRedirectUri}",
        ),
      );
      expect(
        supabaseService,
        contains("'redirect_to': passwordResetRedirectUri"),
      );
      expect(
        supabaseService,
        contains("'redirectTo': passwordResetRedirectUri"),
      );
      expect(
        supabaseService,
        contains("'https://packlox.com/auth/reset-password'"),
      );
      expect(
        supabaseService,
        isNot(
          contains(
            "_passwordResetRedirectUri = 'collectiq-sit://auth/callback'",
          ),
        ),
      );
      expect(html, contains('Reset password'));
      expect(script, contains('updateUser({ password })'));
      expect(script, contains('Password updated successfully.'));
      expect(
        script,
        contains(
          'Return to the Packlox app and sign in with your new password.',
        ),
      );
      expect(script, contains('Passwords do not match.'));
    });

    test('callback page handles email confirmation', () {
      final html = File('web/auth/callback/index.html').readAsStringSync();
      final script = File('web/auth/auth-page.js').readAsStringSync();

      expect(
        File('docs/SIT_REAL_APP_SETUP.md').readAsStringSync(),
        contains('https://packlox.com/auth/callback'),
      );
      expect(html, contains('Email confirmation'));
      expect(script, contains('initCallbackPage'));
      expect(script, contains('Email confirmed. Open Packlox and sign in.'));
      expect(script, contains('verifyOtp'));
      expect(script, contains('setSession'));
    });

    test('web auth config does not commit Supabase secrets', () {
      final config = File('web/auth/config.js').readAsStringSync();

      expect(config, contains('supabaseUrl'));
      expect(config, contains('supabaseAnonKey'));
      expect(config, isNot(contains('eyJ')));
      expect(config, isNot(contains('https://')));
    });

    test('Android app does not intercept Packlox web recovery URLs', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains(r'android:scheme="${authRedirectScheme}"'));
      expect(manifest, isNot(contains('android:scheme="https"')));
      expect(manifest, isNot(contains('android:host="packlox.com"')));
    });
  });
}
