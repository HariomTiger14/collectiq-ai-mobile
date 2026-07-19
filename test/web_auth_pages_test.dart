import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Packlox web auth pages', () {
    test('reset password page contains password update flow', () {
      final html = File(
        'web/auth/reset-password/index.html',
      ).readAsStringSync();
      final script = File(
        'web/auth/reset-password/reset-password.js',
      ).readAsStringSync();
      final styles = File(
        'web/auth/reset-password/styles.css',
      ).readAsStringSync();
      final supabaseClient = File(
        'web/auth/reset-password/supabaseClient.v2.js',
      ).readAsStringSync();
      final supabaseBundle = File(
        'web/auth/reset-password/vendor/supabase-js-v2.js',
      ).readAsStringSync();
      final supabaseService = File(
        'lib/core/supabase/supabase_service.dart',
      ).readAsStringSync();
      final logo = File(
        'web/assets/brand/packlox_logo_horizontal_v1.svg',
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
      expect(html, contains('Reset your password'));
      expect(html, contains('Password updated successfully'));
      expect(html, contains('/assets/brand/packlox_logo_horizontal_v1.svg'));
      expect(html, contains('class="brand-logo"'));
      expect(
        html,
        contains(
          'Your password has been updated. You can now return to the PackLox app and sign in with your new password.',
        ),
      );
      expect(html, isNot(contains('return-button')));
      expect(html, isNot(contains('/auth/login')));
      expect(html, isNot(contains('@supabase/supabase-js@2')));
      expect(html, contains('/auth/reset-password/styles.css'));
      expect(html, contains('/auth/reset-password/vendor/supabase-js-v2.js'));
      expect(html, contains('/auth/reset-password/supabaseClient.v2.js'));
      expect(html, contains('/auth/reset-password/reset-password.js'));
      expect(html, contains('toggle-password'));
      expect(html, contains('togglePassword'));
      expect(html, contains('toggleConfirmPassword'));
      expect(html, contains('strength-bar'));
      expect(styles, contains('@keyframes shake'));
      expect(styles, contains('@keyframes fadeIn'));
      expect(styles, contains('brand-logo'));
      expect(styles, contains('success-icon span'));
      expect(styles, contains('--brand-blue: #1ea7ff'));
      expect(styles, contains('--surface-dark: #0b111a'));
      expect(styles, isNot(contains('return-button')));
      expect(logo, contains('PackLox horizontal logo'));
      expect(supabaseBundle, contains('createClient'));
      expect(
        supabaseClient,
        contains(
          "import { createClient } from '/auth/reset-password/vendor/supabase-js-v2.js'",
        ),
      );
      expect(supabaseClient, contains('export { supabase }'));
      expect(supabaseClient, contains('createClient'));
      expect(supabaseClient, contains('detectSessionInUrl: false'));
      expect(supabaseClient, contains('persistSession: false'));
      expect(
        script,
        contains("import { supabase } from './supabaseClient.v2.js'"),
      );
      expect(script, contains('params.get(\'token\')'));
      expect(script, contains('verifyOtp'));
      expect(script, contains('setSession'));
      expect(script, contains('updateUser({'));
      expect(script, contains('password: elements.password.value'));
      expect(script, contains('showSuccessScreen'));
      expect(script, isNot(contains('window.location.assign')));
      expect(script, contains('Passwords do not match.'));
      expect(script, contains('Request a new password reset email.'));
      expect(
        script,
        contains('Your new password cannot be the same as your old password.'),
      );
      expect(script, contains('passwordScore'));
      expect(script, contains('peekPassword'));
      expect(script, contains('updateStrengthMeter'));
      expect(script, contains('extractTokenFromHash'));
      expect(script, contains('submitNewPassword'));
      expect(script, contains('attachPeekHandlers'));
      expect(script, contains('attachStrengthHandlers'));
      expect(script, contains('attachSubmitHandler'));
      expect(script, contains('Supabase not ready - handlers not attached'));
      expect(script, contains('clearRecoverySession'));
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
