# Authentication Backend Sprint 05 - Supabase OTP Signup Capability Spike

Date: 2026-07-19
Branch: rebuild/product-language-v1
Status: Capability spike only; S02-S04 UI not wired.

## Goal

Determine whether the app can support the frozen PackLox signup UX:

1. S02 Create Account / Email Entry
2. S03 Verify Email / OTP Code
3. S04 Create Password / Finish Account
4. Authenticated App Entry / Home

## Decision Result

Option A is code-level feasible with the installed Supabase Dart/Flutter API surface and the current app architecture.

The spike adds backend-layer capability only. It does not wire S02, S03, or S04 widgets to production backend behavior yet.

Real SIT verification was not performed because no safe Supabase test credentials, test email inbox/OTP, or approved live SIT run configuration were provided for this sprint. The remaining decision gate is runtime verification that `/auth/v1/verify` for the app's email OTP flow returns a usable session for a newly created user before S04 calls password update.

## Supabase Methods Available

Installed package versions:

- `supabase_flutter`: `2.15.2`
- `supabase`: `2.13.2`
- `gotrue`: `2.23.0`

Local package API inspected:

- `GoTrueClient.signInWithOtp(...)`
- `GoTrueClient.verifyOTP(...)`
- `GoTrueClient.updateUser(...)`
- `OtpType.email`
- `OtpType.signup`
- `UserAttributes.password`

Existing app implementation remains REST-based rather than direct `Supabase.instance.client.auth` usage. The spike therefore adds equivalent REST gateway methods:

- `POST /auth/v1/otp` with `create_user: true`
- `POST /auth/v1/verify` with `type: email`
- `PUT /auth/v1/user` with authenticated bearer token and `password`

## Implemented Capability Path

Backend-only methods added:

- `SupabaseOtpSignupGateway.startEmailOtpSignup(email)`
- `SupabaseOtpSignupGateway.verifyEmailOtp(email, token)`
- `SupabaseOtpSignupGateway.createPasswordAfterOtp(password)`
- `OtpSignupAuthRepository.startEmailOtpSignup(email)`
- `OtpSignupAuthRepository.verifyEmailOtp(email, code)`
- `OtpSignupAuthRepository.createPasswordAfterOtp(password)`

Adapter behavior added:

- `AuthRepositoryBackendAdapter.startEmailSignup(...)` now uses `OtpSignupAuthRepository` when the underlying repository supports it.
- `AuthRepositoryBackendAdapter.verifyEmailOtp(...)` now uses the OTP-capable repository and maps invalid/expired OTP failures to UI-safe failure codes.
- `AuthRepositoryBackendAdapter.createPasswordAfterVerification(...)` now calls password creation only through the OTP-capable repository.
- Repositories without OTP support still return `capabilityUnavailable` instead of pretending the flow is supported.

Security guardrail:

- `createPasswordAfterOtp` requires an existing verified Supabase auth session. If OTP verification did not establish a session, password creation fails safely and maps to a verification-expired UI-safe state.

## Files Changed

Production backend/domain code:

- `lib/core/supabase/supabase_auth_response_normalizer.dart`
- `lib/core/supabase/supabase_service.dart`
- `lib/features/auth/data/repositories/auth_repository_backend_adapter.dart`
- `lib/features/auth/data/repositories/supabase_auth_repository.dart`
- `lib/features/auth/domain/repositories/auth_repository.dart`

Tests:

- `test/auth_backend_contract_test.dart`

QA/report:

- `qa/authentication_backend_sprint_05/SUPABASE_OTP_SIGNUP_CAPABILITY_SPIKE.md`

Files intentionally not changed:

- `lib/features/auth/presentation/screens/auth_screens.dart`
- S02-S04 Flutter UI wiring
- Backend/server code
- Supabase credentials/config
- Google/Apple provider gating
- S07/reset completion

## Test Coverage Added

New fake-backed tests cover:

- OTP-capable repository path through `AuthRepositoryBackendAdapter`
- Unsupported repository fallback to `capabilityUnavailable`
- Account-existence-safe signup-start failure mapping
- Invalid OTP mapping to `otpInvalid`
- Missing/expired verified session mapping before password creation
- Normalizer success states for OTP sent, OTP verified, and password updated

Existing contract tests still cover:

- 6-digit OTP state behavior through the app-side contract fake
- 5-attempt OTP limit
- S04 12+ character password policy with no composition requirement
- Guest mode never overriding authenticated session

## Product/Security Checks

- Account existence remains undisclosed at the adapter boundary.
- Password creation is blocked unless a verified session exists.
- S04 password policy remains app-side: 12+ characters, no composition requirement, spaces and symbols allowed.
- No auto-login logic was added to UI. If Supabase creates a session during OTP verify, that session is a provider mechanic and must be documented during S02-S04 wiring.
- Google/Apple provider gates are unchanged.
- S07 is not introduced.

## Remaining Risks

1. `type: email` vs `type: signup` must be verified against the configured Supabase Auth email template and project settings.
2. It must be confirmed that `verify` returns a usable session for new-user OTP signup in SIT.
3. If SIT verification does not return a session, S04 password creation cannot be completed client-side through `PUT /auth/v1/user`.
4. If client-only completion is blocked, the least disruptive fallback is a server/Edge Function mediated signup completion that preserves the frozen S02 -> S03 -> S04 UX without exposing privileged credentials in Flutter.
5. Supabase email templates must include OTP/code delivery, not only a magic link, for the frozen S03 code-entry screen.

## Real SIT Verification

Performed: No.

Blocked reason:

- No safe SIT Supabase test account/email inbox/OTP was supplied.
- No secrets were inspected or added.
- No live auth calls were run.

Required for final feasibility confirmation:

1. Provide a safe SIT Supabase config and test email inbox.
2. Call OTP start for that email.
3. Verify the received code in-app/API.
4. Confirm a valid Supabase session is established.
5. Call password update with a 12+ character passphrase.
6. Confirm current user/session restore works and guest mode does not override the authenticated session.

## Validation

Passed:

- `flutter analyze`
- `flutter test test/auth_backend_contract_test.dart`
- `flutter test test/domain_unit_test.dart --plain-name "Supabase foundation SupabaseAuthResponseNormalizer contract"`

Broad-suite note:

- `flutter test test/domain_unit_test.dart` was also run as a broader safety check and failed on two pre-existing/out-of-scope expectations unrelated to this auth spike:
  - `DioAiBackendApiService FastAPI detail error preserves analyzer error code`
  - `Supabase foundation SIT scripts pass required dart defines without hardcoded secrets`

## Conclusion

Option A is technically feasible at code level and should remain the recommended signup path, pending real SIT confirmation of the OTP-verify session behavior.

Next sprint recommendation:

- Run a controlled SIT OTP signup verification with safe test credentials.
- If successful, wire S02-S04 to `AuthBackendContractController` using these backend methods.
- If not successful, stop and implement the owner-approved server/Edge Function mediated fallback before UI wiring.