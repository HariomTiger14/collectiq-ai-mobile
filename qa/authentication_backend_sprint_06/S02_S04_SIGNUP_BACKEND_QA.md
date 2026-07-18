# Authentication Backend Sprint 06 - S02-S04 Signup Wiring QA

Date: 2026-07-19

Scope: Authentication S02-S04 signup path only.

## Implementation Summary

- S02 Create Account / Email Entry now calls `AuthBackendContractController.startEmailSignup`.
- S02 shows a loading state while signup start is pending and routes to S03 only after the backend contract returns `verificationSent`.
- S02 failure copy remains neutral and does not reveal whether an account exists.
- S03 Verify Email / OTP Code now calls `AuthBackendContractController.verifyEmailOtp`.
- S03 preserves 6-digit digits-only OTP input, no auto-submit, 30-second resend cooldown, and 5-attempt local lockout.
- S03 Resend code now calls `AuthBackendContractController.resendVerificationCode`.
- S04 Create Password / Finish Account now calls `AuthBackendContractController.createPasswordAfterVerification`.
- S04 preserves the frozen password policy: minimum 12 characters, no composition requirement, spaces and symbols allowed, confirm password must match.
- S04 applies authenticated app state only when the backend contract returns `signedIn` with a cloud-backed user.
- S04 does not fake auth success on missing-session or capability failure.
- S05 sign-in and S06 reset request wiring remain preserved.

## Account Enumeration Review

No signup UI copy exposes account existence. Signup start, OTP verification, resend, and password creation failures use UI-safe contract messages. Account-not-found and existing-account style backend detail is not rendered in S02-S04.

## Local/Fake-Backed Evidence

Widget and contract tests use `InMemoryAuthBackendRepository`; no network or Supabase credentials are used.

Covered behavior:

- S02 valid email calls fake signup start and routes to S03.
- S02 signup failure shows safe retryable copy.
- S02 loading disables Continue.
- S03 Verify calls fake OTP verification.
- S03 invalid OTP decrements attempts and locks after 5 attempts until resend.
- S03 success routes to S04.
- S03 resend calls fake backend after cooldown.
- S04 create password calls fake backend.
- S04 success updates authenticated app state when fake backend returns a signed-in user.
- S04 capability failure stays on S04, shows safe copy, and does not mark auth success.
- S04 loading disables Finish Account.
- Existing S05/S06 backend tests remain passing.

## Real SIT Signup Verification

Status: Blocked / not manually verified.

Reason: Local validation output reports Supabase disabled and no URL or anon key configured:

- Supabase enabled: false
- Supabase URL configured: false
- Supabase anon key configured: false

No safe SIT test inbox, OTP delivery path, or credentials were available in this environment. Real signup happy-path verification on a Samsung device is pending.

## Validation Results

- `flutter analyze`: Passed, no issues found.
- `flutter test test/auth_backend_contract_test.dart`: Passed, 13 tests.
- `flutter test test/auth_presentation_test.dart`: Passed, 48 tests.
- `flutter test test/settings_phase6b_test.dart`: Passed, 6 tests.
- `flutter test test/bootstrap_entry_presentation_test.dart`: Passed, 16 tests.
- `flutter test test/onboarding_presentation_test.dart`: Passed, 10 tests.
- `flutter test test/app_shell_presentation_test.dart`: Passed, 11 tests.
- `git diff --check`: Passed. Git reported line-ending normalization warnings only.

## Remaining Risks

- Real Supabase OTP delivery and verification must be verified with safe SIT configuration.
- Supabase post-OTP password creation depends on a verified session being available after OTP verification; if SIT proves that session is missing, a server-side fallback or auth callback amendment will be needed.
- Google/Apple provider signup remains provider-gated and unchanged.
- S07 reset completion remains out of scope.
