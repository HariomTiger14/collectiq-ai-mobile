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
      final authorityEmblem = File(
        'web/assets/brand/packlox_emblem_authority.png',
      ).readAsBytesSync();

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
      expect(html, contains('PACKLOX_RESET_PAGE_VERSION'));
      expect(html, contains('20260720-authority-emblem-fix'));
      expect(
        html,
        contains(
          '/auth/reset-password/styles.css?v=20260720-authority-emblem-fix',
        ),
      );
      expect(
        html,
        contains(
          '/auth/reset-password/reset-password.js?v=20260720-boundary-password-fix',
        ),
      );
      expect(
        html,
        contains(
          '/assets/brand/packlox_emblem_authority.png?v=20260720-authority-emblem-fix',
        ),
      );
      expect(html, contains('class="brand-icon"'));
      expect(html, contains('class="brand-name"'));
      expect(html, contains('class="brand-name-accent"'));
      expect(html, isNot(contains('/assets/brand/packlox_emblem.svg')));
      expect(html, isNot(contains('/assets/brand/packlox_app_icon.png')));
      expect(html, isNot(contains('/assets/brand/packlox_logo_authority.svg')));
      expect(html, isNot(contains('/assets/brand/packlox_logo_latest.png')));
      expect(
        html,
        isNot(contains('/assets/brand/packlox_logo_horizontal_v1.svg')),
      );
      expect(html, isNot(contains('6 characters')));
      expect(html, isNot(contains('8 characters')));
      expect(html, contains('12 characters'));
      expect(
        html,
        contains(
          'Your password has been updated. You can now return to the PackLox app and sign in with your new password.',
        ),
      );
      expect(html, isNot(contains('Return to Login')));
      expect(html, isNot(contains('return-button')));
      expect(html, isNot(contains('/auth/login')));
      expect(html, isNot(contains('@supabase/supabase-js@2')));
      expect(html, isNot(contains('Identify. Value. Protect.')));
      expect(html, contains('/auth/reset-password/vendor/supabase-js-v2.js'));
      expect(html, contains('/auth/reset-password/supabaseClient.v2.js'));
      expect(html, contains('toggle-password'));
      expect(html, contains('togglePassword'));
      expect(html, contains('toggleConfirmPassword'));
      expect(html, contains('strength-bar'));
      expect(styles, contains('@keyframes shake'));
      expect(styles, contains('@keyframes fadeIn'));
      expect(styles, contains('brand-icon'));
      expect(styles, contains('brand-name'));
      expect(styles, contains('.submit-button.loading .spinner'));
      expect(styles, contains('display: inline-block'));
      expect(styles, contains('margin-left: 10px'));
      expect(styles, isNot(contains('.submit-button.loading .button-label')));
      expect(styles, contains('--brand-blue: #1ea7ff'));
      expect(styles, contains('--surface-dark: #0b111a'));
      expect(styles, isNot(contains('brand-logo')));
      expect(styles, isNot(contains('brand-emblem')));
      expect(styles, isNot(contains('brand-wordmark')));
      expect(styles, isNot(contains('return-button')));
      expect(authorityEmblem.take(8).toList(), <int>[
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
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
      expect(script, contains('PACKLOX_RESET_PAGE_VERSION'));
      expect(script, contains('20260720-boundary-password-fix'));
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
      expect(script, contains('evaluatePasswordPolicy'));
      expect(script, contains('resetPasswordFormState'));
      expect(script, contains('canSubmit'));
      expect(script, contains('passwordScore'));
      expect(script, isNot(contains('Math.min(score, 4)')));
      expect(script, contains('password.length >= PASSWORD_MIN_LENGTH'));
      expect(script, isNot(contains('passwordPolicyLength')));
      expect(script, contains('/[a-z]/.test(password)'));
      expect(script, contains('/[A-Z]/.test(password)'));
      expect(script, contains('/\\d/.test(password)'));
      expect(script, contains('/[^A-Za-z0-9]/.test(password)'));
      expect(script, isNot(contains('6 characters')));
      expect(script, isNot(contains('8 characters')));
      expect(script, contains('12 characters'));
      expect(script, contains("['input', 'change', 'paste', 'keyup']"));
      expect(script, contains('refreshValidationAfterBrowserFill'));
      expect(script, contains('peekPassword'));
      expect(script, contains('updateStrengthMeter'));
      expect(script, contains('extractTokenFromHash'));
      expect(script, contains('submitNewPassword'));
      expect(
        script,
        contains(
          "elements.buttonLabel.textContent = isBusy ? 'Updating...' : 'Update password'",
        ),
      );
      expect(
        script,
        contains("elements.submit.classList.toggle('loading', isBusy)"),
      );
      expect(script, contains('elements.password.disabled = isBusy'));
      expect(script, contains('elements.confirmPassword.disabled = isBusy'));
      expect(script, contains('attachPeekHandlers'));
      expect(script, contains('attachStrengthHandlers'));
      expect(script, contains('attachSubmitHandler'));
      expect(script, contains('Supabase not ready - handlers not attached'));
      expect(script, contains('clearRecoverySession'));
    });

    test('reset password policy examples drive submit state', () {
      for (final password in <String>[
        'Australia@10',
        'Australia@12',
        'Australia@100',
        'Australia@121',
      ]) {
        final valid = _resetPasswordState(password, password);
        expect(valid.canSubmit, isTrue, reason: password);
        expect(valid.passwordMessage, isEmpty, reason: password);
        expect(valid.confirmMessage, isEmpty, reason: password);
      }

      const invalidExamples = <String, String>{
        'Australia@1': 'too short',
        'australia@12': 'missing uppercase',
        'AUSTRALIA@12': 'missing lowercase',
        'Australia12': 'missing symbol',
        'Australia@Test': 'missing number',
      };

      for (final entry in invalidExamples.entries) {
        final state = _resetPasswordState(entry.key, entry.key);
        expect(state.canSubmit, isFalse, reason: entry.value);
        expect(
          state.passwordMessage,
          'Use at least 12 characters with uppercase, lowercase, number, and symbol.',
          reason: entry.value,
        );
      }

      final mismatch = _resetPasswordState('Australia@12', 'Australia@10');
      expect(mismatch.canSubmit, isFalse);
      expect(mismatch.confirmMessage, 'Passwords do not match.');
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

_ResetPasswordPolicyState _resetPasswordState(
  String password,
  String confirmPassword,
) {
  const minLength = 12;
  final checks = <bool>[
    password.length >= minLength,
    RegExp('[a-z]').hasMatch(password),
    RegExp('[A-Z]').hasMatch(password),
    RegExp(r'\d').hasMatch(password),
    RegExp(r'[^A-Za-z0-9]').hasMatch(password),
  ];
  final isValidPassword = checks.every((check) => check);
  final passwordMessage = password.isEmpty
      ? 'Please enter a new password.'
      : isValidPassword
      ? ''
      : 'Use at least 12 characters with uppercase, lowercase, number, and symbol.';
  final confirmMessage = confirmPassword.isEmpty
      ? 'Please confirm your new password.'
      : password == confirmPassword
      ? ''
      : 'Passwords do not match.';

  return _ResetPasswordPolicyState(
    passwordMessage: passwordMessage,
    confirmMessage: confirmMessage,
    canSubmit:
        isValidPassword &&
        confirmPassword.isNotEmpty &&
        password == confirmPassword,
  );
}

class _ResetPasswordPolicyState {
  const _ResetPasswordPolicyState({
    required this.passwordMessage,
    required this.confirmMessage,
    required this.canSubmit,
  });

  final String passwordMessage;
  final String confirmMessage;
  final bool canSubmit;
}
