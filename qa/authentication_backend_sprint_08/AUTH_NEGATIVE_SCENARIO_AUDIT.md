# Authentication Backend Sprint 08 - Negative Scenario Audit

Date: 2026-07-19
Branch: rebuild/product-language-v1
Scope: Fake-backed/unit/widget hardening before owner manual SIT auth testing

## Result

Status: READY FOR OWNER MANUAL SIT TESTING WITH KNOWN REAL-BACKEND CASES

This sprint did not touch backend/server code, secrets, Supabase config, package IDs, auth routes, or the frozen S01-S06 product flow. The work tightened fake-backed negative coverage and hardened the in-memory test backend so local tests cannot accidentally model unsafe signup behavior.

## Defensive Fixes Made

- `InMemoryAuthBackendRepository.startEmailSignup` now fails safely when the email already exists in the fake account store.
- Existing-email signup returns `accountExistenceNotDisclosed` with neutral signup copy: `If this email can be used, a verification code has been sent.`
- Existing-email signup does not create a pending signup, does not sign in, and does not permit the fake password creation path to overwrite the existing account.
- `InMemoryAuthBackendRepository` now supports a configurable `otpVerifyFailure`, allowing fake-backed expired/reused OTP tests without network or real inbox access.

## Coverage Added

- Backend contract test: existing-email signup fails neutrally, does not authenticate, and does not overwrite password state.
- Backend contract test: expired/reused OTP maps to safe retry state and does not authenticate.
- Backend contract test: create-password requires verified backend state before the repository password update is called.
- Widget test: S02 existing registered email stays on S02, shows neutral copy, does not navigate to S03, and does not authenticate.
- Widget test: S03 successful OTP verification routes to S04 but does not mark the app authenticated.
- Widget test: S03 expired OTP shows safe copy, blocks Verify, and requires resend.
- Widget test: S05 loading state prevents duplicate submit while sign-in is in flight.

## Existing Coverage Confirmed

- S02 invalid/empty email disables Continue.
- S02 backend failure uses safe retryable copy and does not expose account existence.
- S03 OTP length remains `8`, digits-only, no auto-submit.
- S03 Verify is enabled only after exactly 8 digits.
- S03 invalid OTP decrements attempts and five attempts require resend.
- S03 resend respects the 30-second cooldown.
- S04 password policy remains 12+ characters, no composition rule, spaces/symbols allowed.
- S04 confirm password must match.
- S04 capability/missing-session style failure does not fake auth success.
- S05 wrong email/password uses neutral copy: `Email or password is not correct.`
- S05 account-not-found is not exposed.
- S05 successful sign-in authenticates only through backend-contract result.
- S06 existing and unknown reset emails show the same generic confirmation.
- S06 reset failure copy is safe and retryable.
- S06 resend respects cooldown and the five-request local limit.
- Authenticated session wins over guest mode in AppShell routing.
- Guest mode remains local-only and never becomes authenticated state.

## Owner Manual SIT Cases Remaining

- S02 existing registered email against real Supabase: verify no account-existence disclosure and no silent sign-in.
- S02 provider-only email against real Supabase: verify no disclosure of provider-only account state.
- S03 real Supabase 8-digit OTP happy path.
- S03 invalid, expired, reused, and too-many-attempt OTP behavior with real Supabase.
- S03 resend delivery and cooldown behavior with real email delivery.
- S04 password creation after verified OTP: verify backend session is present before app enters Home.
- S04 password update failure/missing-session behavior: verify app remains blocked and does not fake authentication.
- S05 real wrong-password and missing-email behavior: verify only neutral copy appears.
- S05 real success: verify cloud session wins over guest mode after relaunch.
- S06 real reset request for existing and non-existing emails: verify identical confirmation copy and no enumeration.

## Validation

- `flutter analyze`: PASS, no issues found
- `flutter test test/auth_backend_contract_test.dart`: PASS, 16 tests
- `flutter test test/auth_presentation_test.dart`: PASS, 57 tests
- `flutter test test/settings_phase6b_test.dart`: PASS, 6 tests
- `flutter test test/bootstrap_entry_presentation_test.dart`: PASS, 16 tests
- `flutter test test/app_shell_presentation_test.dart`: PASS, 11 tests
- `git diff --check`: PASS, no whitespace errors; Git reported existing LF-to-CRLF working-copy warnings only
