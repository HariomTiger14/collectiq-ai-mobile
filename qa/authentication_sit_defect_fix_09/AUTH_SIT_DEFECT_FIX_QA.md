# Authentication SIT Defect Fix 09 QA

Status: PASS for fake-backed/unit-widget validation. Manual SIT retest remains owner-run with safe Supabase credentials.

## Defects Addressed

- S02 Create Account now requires the backend contract to explicitly mark signup start as safe for account creation before routing to S03. The current Supabase OTP client path cannot prove that an email is not already registered, so it is blocked with safe copy until a server-side guard is supplied.
- S06 Forgot Password maps missing config, backend, and network-style failures to safe retryable copy. Raw messages such as missing anon-key/config diagnostics are not shown in UI.
- S05 authenticated success now selects the Home tab before unwinding the auth stack, so Settings-launched auth returns to authenticated Home/AppShell rather than the Settings tab.
- The web reset-password page now uses PackLox styling, the 12-character passphrase policy, safe invalid-token copy, and mobile app guidance instead of a broken Back to Sign In link.

## Server/Edge Function Requirement

Required before real create-account SIT happy-path can be fully enabled: a server-side signup-start guard or Edge Function that can safely determine whether an email is eligible for account creation without exposing account existence. The client must receive an explicit safe account-creation response before S02 routes to S03.

## Manual Retest Checklist

- Launch signed out, enter an already registered email on S02, and confirm it does not route to S03 or authenticate.
- Confirm S02 shows: "We couldn't start account creation for this email. Try signing in or resetting your password."
- Submit S06 Forgot Password with a non-existing email and confirm the generic confirmation remains unchanged when backend accepts the request.
- Disable/misconfigure SIT auth locally and confirm S06 shows only safe retryable copy, not config or anon-key details.
- Open Settings signed out, navigate to Sign In through S01, complete sign-in, and confirm Home/AppShell is shown.
- Open a reset-password email link and confirm the web page is PackLox-branded, uses 12-character policy copy, and has mobile app guidance instead of a Back to Sign In button.

## Validation

Passed:

- `flutter analyze`
- `flutter test test/auth_backend_contract_test.dart`
- `flutter test test/auth_presentation_test.dart`
- `flutter test test/settings_phase6b_test.dart`
- `flutter test test/bootstrap_entry_presentation_test.dart`
- `flutter test test/app_shell_presentation_test.dart`
- `flutter test test/web_auth_pages_test.dart`
- `git diff --check`

Notes:

- No secrets were added.
- No backend server code was changed.
- Real Supabase SIT retest was not run by Codex in this sprint; the checklist above is prepared for owner manual testing.
