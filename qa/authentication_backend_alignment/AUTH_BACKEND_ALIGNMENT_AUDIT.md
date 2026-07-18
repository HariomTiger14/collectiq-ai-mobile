# Authentication Backend Alignment Audit

Date: 2026-07-18
Repo: C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction
Branch: rebuild/product-language-v1
HEAD at audit start: f83d32346a9ae783cae96f4cc248afa63db36b84
Scope: read-only audit of existing Flutter/Supabase auth implementation before wiring frozen Authentication S01-S06 to real backend behavior.

## Audit Result

Status: PASS FOR PLANNING / NOT READY TO WIRE WITHOUT CONTRACT RECONCILIATION

The repository already has a real Supabase email/password auth foundation, session restore, sign-out, confirmation resend, password reset email request, callback handling for signup/email confirmation, and cloud-sync auth services. The newly implemented reset Authentication S01-S06 UI is intentionally local/placeholder-only and is not currently wired to the feature auth controller or Supabase repository.

The main backend alignment gap is S03. The frozen UX requires a 6-digit in-app OTP after email entry and before password creation. The current mobile Supabase layer supports email/password signup and email confirmation links, but it does not expose sign-in-with-OTP, verify-OTP, or post-OTP password creation/update methods for the mobile S02 -> S03 -> S04 flow.

## Files Inspected

Feature auth:
- lib/features/auth/presentation/screens/auth_screens.dart
- lib/features/auth/presentation/controllers/auth_controller.dart
- lib/features/auth/domain/repositories/auth_repository.dart
- lib/features/auth/data/repositories/supabase_auth_repository.dart
- lib/features/auth/data/repositories/mock_auth_repository.dart
- lib/features/auth/services/auth_deep_link_service.dart
- lib/features/auth/domain/entities/auth_callback_result.dart
- lib/features/auth/domain/entities/app_user.dart
- lib/features/auth/domain/entities/auth_exception.dart

Supabase and cloud auth:
- lib/core/supabase/supabase_service.dart
- lib/core/supabase/supabase_config.dart
- lib/core/supabase/supabase_auth_response_normalizer.dart
- lib/core/cloud/supabase/supabase_bootstrap.dart
- lib/core/cloud/supabase/supabase_auth_service.dart
- lib/core/cloud/services/auth_service.dart
- lib/core/cloud/cloud_service_registry.dart
- lib/core/config/feature_flags.dart
- lib/core/config/environment_config.dart

Routing, guest mode, settings:
- lib/core/navigation/app_shell.dart
- lib/features/auth/domain/repositories/guest_mode_repository.dart
- lib/features/auth/data/repositories/shared_preferences_guest_mode_repository.dart
- lib/features/auth/presentation/controllers/guest_mode_controller.dart
- lib/features/settings/presentation/settings_screen.dart

Tests and QA evidence:
- test/auth_presentation_test.dart
- test/bootstrap_entry_presentation_test.dart
- test/settings_phase6b_test.dart
- test/app_shell_presentation_test.dart
- test/supabase_dev_sync_validation_test.dart
- test/web_auth_pages_test.dart
- qa/authentication_sprint_01/
- qa/authentication_sprint_02/
- qa/authentication_sprint_03/
- qa/authentication_sprint_04/
- qa/authentication_sprint_05/
- qa/authentication_sprint_06/
- qa/authentication_entry_routing/
- qa/authentication_mvp/AUTH_MVP_IMPLEMENTATION_AUDIT.md

## Existing Backend Pieces

### Feature-level auth repository and controller

Existing pieces:
- `AuthRepository` defines `currentUser`, anonymous sign-in, email/password sign-in, email/password sign-up, resend email confirmation, password reset email request, Google sign-in, Apple sign-in, and sign-out.
- `AuthController` owns `AuthState`, session restore, email/password sign-in, email/password sign-up, confirmation resend, password reset email, email-confirmation callback application, and sign-out.
- `SupabaseAuthRepository` is the real repository adapter for the feature auth layer.
- `MockAuthRepository` is used when Supabase is unavailable and returns a local anonymous user for local mode; email/password and provider auth throw user-safe unsupported messages.

Important mismatch with frozen reset contracts:
- `AuthController` still has older account-access defaults: 60-second resend cooldown, max 3 confirmation resends per 15 minutes, 60-second password reset cooldown, and 6-character minimum validation in the controller helper.
- Frozen reset contracts require S03 30-second resend cooldown, 5 verification attempts then resend, S04 12-character password minimum, and S06 30-second resend cooldown with 5 requests per email/device window.
- These mismatches are currently not visible in reset S01-S06 because those screens use local widget state, not `AuthController`, for the new flow.

### Supabase REST service

`SupabaseService` currently supports:
- `currentSession()` with memory and SharedPreferences cache under `supabase_auth_session`.
- `signInAnonymously()` via `POST /auth/v1/signup` with anonymous metadata.
- `signInWithPassword()` via `POST /auth/v1/token?grant_type=password`.
- `signUpWithPassword()` via `POST /auth/v1/signup` with email, password, and `display_name` metadata.
- `resendEmailConfirmation()` via `POST /auth/v1/resend` with `type: signup`.
- `resetPasswordForEmail()` via `POST /auth/v1/recover` with `https://packlox.com/auth/reset-password` redirect.
- `completeAuthCallback()` by loading `/auth/v1/user` with callback access token and saving the session.
- `signOut()` via `POST /auth/v1/logout`.

Not present in the mobile Supabase service:
- No mobile `signInWithOtp` method.
- No mobile `verifyOtp` method for signup/email OTP.
- No mobile method to create or update password after OTP verification.
- No mobile S07/reset completion screen or mobile recovery completion flow.
- No Google/Apple SDK or OAuth wiring; repository methods throw coming-soon messages.

### Supabase configuration and flags

Existing pieces:
- `SupabaseConfig.fromEnvironment()` reads `SUPABASE_ENABLED`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY`.
- `FeatureFlags.fromEnvironment()` reads `USE_CLOUD_AUTH`, `USE_CLOUD_PORTFOLIO_SYNC`, `USE_CLOUD_IMAGE_STORAGE`, and legacy `COLLECTIQ_*` aliases.
- `EnvironmentConfig` defaults to local with all cloud flags false.
- `SupabaseBootstrap` initializes `supabase_flutter` only when environment and feature flags allow cloud services and URL/key are present.
- `CloudServiceRegistry` selects no-op services unless cloud flags are enabled.

### Deep links and web reset

Existing pieces:
- `AuthDeepLinkCoordinator` handles signup/email confirmation callbacks and applies signed-in or confirmed-without-session state.
- `AuthCallbackParser` ignores `type=recovery` callbacks in mobile.
- `web/auth/reset-password/` contains a separate web password update flow that uses Supabase `verifyOtp`, `setSession`, and `updateUser`.
- `test/web_auth_pages_test.dart` verifies the web reset page and callback page contracts.

## Current Authenticated Launch Detection

`AppShell` currently decides entry in this order:
1. Wait for `authControllerProvider` session restore and `guestModeControllerProvider` resolution.
2. If `authState.isSignedIn`, show authenticated AppShell/Home.
3. If not signed in and guest mode has not been chosen, show `AuthWelcomeScreen` S01.
4. If guest mode has been chosen, use existing onboarding completion state.
5. If onboarding incomplete, show onboarding; if complete, show AppShell/Home as guest.

This is a good shape for real backend wiring because authenticated state is checked before guest mode. The main integration risk is making sure real sign-in/sign-up success invalidates or supersedes guest mode without accidentally marking onboarding complete.

## Guest Mode Implementation

Existing pieces:
- `GuestModeRepository` exposes `hasChosenGuestMode()` and `setGuestModeChosen(bool)`.
- `SharedPreferencesGuestModeRepository` stores `auth_guest_mode_chosen_v1`.
- `GuestModeController.chooseGuestMode()` sets only guest mode. It does not mark onboarding complete.
- `AppShell` calls `chooseGuestMode()` only from S01 Explore as Guest.
- Onboarding completion remains owned by the existing onboarding controller/repository.

Risk level: LOW if real backend wiring preserves the current entry order and does not set the guest flag during sign-in/sign-up.

## Current S01-S06 Route Flow

Route names in `AuthRouteNames`:
- `auth/welcome`
- `auth/create-account/email`
- `auth/create-account/verify-email`
- `auth/create-account/create-password`
- `auth/sign-in`
- `auth/forgot-password/email`
- `app/guest-home`

Current implementation behavior:
- S01 Create Account pushes S02.
- S01 Sign In pushes S05.
- S01 Explore as Guest invokes the AppShell guest-mode callback or pops when shown from Settings.
- S02 validates email locally and pushes S03 with the entered email.
- S03 masks email, accepts 6 digits, has no auto-submit, uses local 30-second resend cooldown, and routes to S04 only when local code is `123456`.
- S04 validates a local 12+ character passphrase and matching confirmation, then shows a local completion message: `Account ready. Authenticated Home handoff is pending backend account creation.`
- S05 validates email/password locally, then shows neutral local failure copy: `Email or password is not correct.`
- S05 Forgot Password pushes S06 with valid email prefill.
- S06 validates email locally, shows generic confirmation copy, stays on S06, supports local resend cooldown, and uses a local 5-request neutral rate-limit state.

## What Is Placeholder / Local Only

Placeholder or local-only pieces:
- S02 does not call signup, OTP start, account existence check, or provider auth.
- S03 does not call Supabase OTP verification; the accepted code is local `123456`.
- S03 attempt count and resend cooldown are widget-local only.
- S04 does not create a Supabase account, update password, create a session, or clear guest mode.
- S04 success does not navigate to authenticated Home.
- S05 does not call `AuthController.signInWithEmailPassword`; it always shows local neutral invalid sign-in copy once submitted.
- S06 does not call `AuthController.sendPasswordResetEmail`; it always shows local generic confirmation and local cooldown/limit states.
- Google/Apple provider gates are hardcoded false in S02/S05; Facebook is not rendered.
- Mobile recovery completion/S07 is not implemented.

## Files Needed For Real Signup

Minimum files likely needing changes:
- `lib/features/auth/presentation/screens/auth_screens.dart`
  - Wire S02/S3/S4 submission/loading/error states to controller methods or a dedicated signup-flow controller.
  - Preserve live UI and route names.
  - Pass pending email/session state between S02/S03/S04 without exposing raw secrets.
- `lib/features/auth/presentation/controllers/auth_controller.dart`
  - Reconcile frozen signup policy: OTP start, OTP verify, 5 attempts, 30-second resend cooldown, S04 12-character passphrase policy, success handoff.
  - Consider extracting a dedicated `SignupFlowController` to avoid overloading the existing settings/auth-access controller.
- `lib/features/auth/domain/repositories/auth_repository.dart`
  - Add methods if the chosen path requires OTP start/verify and post-verification password creation.
- `lib/features/auth/data/repositories/supabase_auth_repository.dart`
  - Implement new repository methods through Supabase gateway.
- `lib/core/supabase/supabase_service.dart`
  - Add Supabase REST calls for `signInWithOtp`/send OTP, `verifyOtp`, and either password update or server-mediated user creation if required.
- `lib/core/supabase/supabase_auth_response_normalizer.dart`
  - Add normalized statuses for OTP sent, OTP invalid, OTP expired, attempts exceeded, and account-linking conflicts.
- `lib/features/auth/data/repositories/mock_auth_repository.dart`
  - Mirror new repository contract for tests/local fallback.
- `lib/features/auth/domain/entities/auth_exception.dart`
  - Add typed exceptions if current generic exceptions are too coarse.
- `lib/core/navigation/app_shell.dart`
  - Only if backend success requires clearing guest mode or forcing route replacement to Home.
- `test/auth_presentation_test.dart`
  - Update S02/S03/S04 tests from local placeholder behavior to mocked controller/repository outcomes.
- `test/domain_unit_test.dart`
  - Add repository/controller unit coverage for OTP signup and password creation.
- `test/bootstrap_entry_presentation_test.dart`
  - Add post-signup authenticated launch/handoff checks.

## Files Needed For Real Sign-In

Minimum files likely needing changes:
- `lib/features/auth/presentation/screens/auth_screens.dart`
  - Wire S05 Sign In CTA to `AuthController.signInWithEmailPassword` or equivalent, with loading and neutral error handling.
  - Route signed-in success to AppShell/Home via session state, not local placeholder navigation.
- `lib/features/auth/presentation/controllers/auth_controller.dart`
  - Ensure errors from Supabase are transformed into frozen S05 copy rules: no explicit account-not-found, neutral invalid sign-in copy, email-not-verified only after password is confirmed correct.
- `lib/features/auth/data/repositories/supabase_auth_repository.dart`
  - Existing `signInWithEmailPassword` is present; may need richer typed errors to distinguish email-not-verified safely.
- `lib/core/supabase/supabase_service.dart`
  - Existing password grant call is present; may need neutralized error mapping and metadata for email-not-verified.
- `lib/core/supabase/supabase_auth_response_normalizer.dart`
  - Existing statuses include invalid credentials, email not registered, and email not confirmed; S05 wiring must avoid exposing account-not-found.
- `lib/features/auth/data/repositories/mock_auth_repository.dart`
  - Update if tests need a successful local mock sign-in path.
- `lib/core/navigation/app_shell.dart`
  - Verify signed-in state beats guest state after successful sign-in.
- `test/auth_presentation_test.dart`
  - Add S05 submit loading/success/error tests and route handoff tests.
- `test/bootstrap_entry_presentation_test.dart`
  - Add authenticated launch after sign-in state restore.
- `test/settings_phase6b_test.dart`
  - Verify Settings reflects real signed-in state and sign-out after S05 login.

## Files Needed For Password Reset

Minimum files likely needing changes:
- `lib/features/auth/presentation/screens/auth_screens.dart`
  - Wire S06 send/resend to a controller while preserving generic confirmation and no account enumeration.
- `lib/features/auth/presentation/controllers/auth_controller.dart`
  - Reconcile S06 policy: 30-second resend cooldown and 5 requests per email/device window.
  - Ensure all account-existence, provider-only, and Supabase errors map to neutral copy.
- `lib/features/auth/domain/repositories/auth_repository.dart`
  - Existing request method is present; add reset-completion methods only when S07 is designed.
- `lib/features/auth/data/repositories/supabase_auth_repository.dart`
  - Existing request method is present.
- `lib/core/supabase/supabase_service.dart`
  - Existing `/auth/v1/recover` request is present.
  - Mobile S07 would need `verifyOtp`, `setSession`, and `updateUser` equivalents, or continue to hand off recovery completion to web.
- `lib/features/auth/services/auth_deep_link_service.dart`
  - Currently ignores `type=recovery`; update only if mobile will own reset completion.
- `lib/features/auth/domain/entities/auth_callback_result.dart`
  - Currently ignores recovery callbacks; update only with S07/reset-completion contract approval.
- `web/auth/reset-password/*`
  - Existing web reset completion flow is already present; keep as authority if product chooses web completion instead of mobile S07.
- `test/web_auth_pages_test.dart`
  - Existing web reset tests pass; extend only if redirect behavior changes.
- `test/auth_presentation_test.dart`
  - Add S06 real request/resend/rate-limit tests with no enumeration.
- `test/domain_unit_test.dart`
  - Add controller/repository tests for generic reset behavior and rate-limit mapping.

## S03 OTP vs Current Supabase Capability

Answer: PARTIAL MATCH ONLY.

What matches:
- Supabase supports OTP-style email flows through Auth APIs generally, and the existing web auth pages already use `verifyOtp` for callback/reset flows.
- The app has callback parsing and web reset assets that prove the project has already considered Supabase token-based auth flows.

What does not match the current mobile implementation:
- The mobile `AuthRepository` and `SupabaseAuthGateway` do not expose OTP send/verify methods.
- The mobile `SupabaseService` does not implement `signInWithOtp` or `verifyOtp`.
- Current feature signup is email + password first, while frozen reset UX is email -> OTP -> password.
- Supabase email/password signup normally wants a password at signup time; frozen S04 asks for password only after S03 OTP verification.

Least disruptive implementation path:
1. Preserve the frozen UI and route sequence: S02 email -> S03 6-digit OTP -> S04 password -> authenticated Home.
2. Add a dedicated staged signup controller, or carefully extend `AuthController`, so S01-S06 do not embed backend logic directly in widgets.
3. Add repository/gateway methods for `startEmailOtpSignup(email)`, `verifyEmailOtp(email, code)`, and `completeEmailOtpSignup(email, password, verificationContext)`.
4. First try Supabase native OTP endpoints from mobile: send OTP with email, verify OTP with `type: email` or signup-equivalent type, then complete password setup if Supabase returns a session.
5. If Supabase cannot create the exact email -> OTP -> password flow client-side without weakening security or needing a password too early, add a server/edge-function mediated signup transaction that sends/verifies OTP and creates the Supabase user after S04.
6. Keep existing web reset completion unchanged until S07 is designed; do not retrofit recovery callbacks into mobile during S06 wiring.
7. Keep all account-enumeration responses neutral at the controller boundary, even when Supabase exposes more specific statuses.

Do not switch S03 to a magic-link/check-email screen without owner approval because that would contradict the frozen S03 v0.2 contract.

## Tests To Add Before Backend Coding

Before real signup wiring:
- Unit tests for staged signup controller: valid email starts OTP, invalid email does not call backend, resend has 30-second cooldown, invalid OTP decrements attempts, 5 failed attempts require resend, expired OTP shows recovery state, valid OTP advances to S04, and S04 creates/finishes account only with 12+ matching passphrase.
- Repository/gateway tests for OTP send/verify success, invalid code, expired code, rate-limit, network failure, and malformed Supabase responses.
- Widget tests for S02/S03/S04 loading/error/success states using fake controller/repository responses.
- Bootstrap test confirming completed real signup launches authenticated Home and does not mark onboarding complete or guest mode chosen.

Before real sign-in wiring:
- S05 widget tests for submit loading, success, invalid credentials neutral copy, email-not-verified recovery to S03 only after password is confirmed correct, and no explicit account-not-found copy.
- Controller tests ensuring `emailNotRegistered` and `invalidCredentials` normalize to `Email or password is not correct.` for S05.
- Bootstrap/AppShell tests confirming authenticated state wins over guest mode and launches Home.
- Settings tests confirming signed-in summary/sign-out still works after S05 login.

Before real password reset wiring:
- S06 widget/controller tests proving success and unknown account responses show identical generic confirmation.
- Tests for 30-second resend cooldown, 5-request neutral rate-limit, offline/network failure, and neutral provider-only guidance.
- Repository tests for `/auth/v1/recover` success, rate-limit, config missing, and network failure.
- Deep-link/web tests only if product chooses to implement mobile S07/reset completion.

Provider tests:
- S02/S05 provider block hidden when provider gates are false.
- Google/Apple render only when enabled by config/platform.
- Facebook never renders until a future contract explicitly approves it.

## Risks To Guest Mode And Authenticated Launch Routing

Risks:
- Guest mode is local-only and currently checked after authenticated state, which is correct. Real sign-in/sign-up must not let a stale guest flag suppress authenticated launch.
- Real sign-in/sign-up success should probably reset or ignore guest mode, but must not mark onboarding completed automatically.
- Session restore can race with guest/onboarding state resolution. Existing tests cover the current order, but backend wiring should add tests with delayed auth restore.
- S04 success must not create a fake local authenticated state; it should be driven by a real Supabase session or a clearly mocked test repository.
- Account-enumeration rules can regress if raw Supabase errors are shown directly in S05/S06.
- Existing Settings auth panel/controller has older password/cooldown rules. Wiring reset auth screens through the same controller without reconciliation could reintroduce old policy.
- Recovery links are currently web-owned; adding mobile S07 later must avoid breaking the existing web reset page and Android intent-filter behavior.

## Recommended Next Implementation Sprint

Recommended next sprint: Authentication Backend Sprint 01 - Auth Controller Contract Reconciliation and Test Harness.

Purpose:
- Do not wire live Supabase calls into S01-S06 first.
- First create the controller/repository contract that can express the frozen S02-S06 states without exposing old policy.
- Add tests for real-backend outcomes with fake repositories.
- Decide and spike the Supabase OTP path for S03 before changing production widget submit handlers.

Sprint deliverables:
- A staged signup/auth flow controller or reconciled `AuthController` API for S02-S06.
- Repository interface extensions for OTP and staged password completion if confirmed necessary.
- Fake repository tests covering signup, sign-in, reset, provider gates, neutral error mapping, and AppShell handoff.
- No UI redesign.
- No backend schema or Supabase console change unless the OTP spike proves client-only Supabase is insufficient.

## Validation Run

Commands run:
- `flutter analyze` -> PASS, no issues found.
- `flutter test test/auth_presentation_test.dart` -> PASS, 36 tests.
- `flutter test test/bootstrap_entry_presentation_test.dart` -> PASS, 16 tests.
- `flutter test test/settings_phase6b_test.dart` -> PASS, 6 tests.
- `flutter test test/app_shell_presentation_test.dart` -> PASS, 11 tests.
- `flutter test test/web_auth_pages_test.dart` -> PASS, 4 tests.
- `flutter test test/supabase_dev_sync_validation_test.dart` -> PASS, 9 tests.
- `git diff --check` -> PASS.

## Audit Conclusion

- Existing auth backend pieces: YES, foundational Supabase email/password, confirmation, password reset request, session restore, callback handling, cloud auth, and sign-out exist.
- Current reset S01-S06 backend wiring: NO, S02-S06 are local/placeholder-only by design.
- Real signup readiness: NOT YET. S03 OTP and S04 post-OTP password creation need repository/controller alignment.
- Real sign-in readiness: PARTIAL. Supabase sign-in exists, but S05 must be wired with neutral-copy and launch-routing safeguards.
- Password reset readiness: PARTIAL. S06 request can use existing Supabase recover endpoint, but policy/cooldown/neutral copy must be reconciled; reset completion remains web-owned until S07 is designed.
- Recommended next sprint: build the auth controller/repository contract and tests first, then wire S05 or S06 before staged S02-S04 signup if the OTP strategy is still unresolved.
