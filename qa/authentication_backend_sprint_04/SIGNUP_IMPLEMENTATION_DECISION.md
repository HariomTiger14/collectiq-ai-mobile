# Authentication Backend Sprint 04 - Signup Implementation Decision

Date: 2026-07-19
Branch: rebuild/product-language-v1
Scope: Decision report only; no production Dart files changed; no signup wiring added.

## Decision Summary

Recommendation: Option A, keep the frozen S02-S04 UX exactly, but do not wire production UI until a small Supabase capability spike proves the implementation path.

The frozen authority says signup is:

1. S02 Create Account / Email Entry
2. S03 Verify Email / OTP Code, 6 digits, 10-minute lifetime, 30-second resend cooldown, 5 attempts, no auto-submit
3. S04 Create Password / Finish Account, 12-character minimum, no composition requirement, spaces and symbols allowed
4. Authenticated App Entry / Home

The current app-side contract can express this flow, but the production Supabase adapter intentionally returns `capabilityUnavailable` for staged signup start, OTP verification, and post-OTP password creation. Existing mobile Supabase code supports email/password signup, confirmation resend, password reset request, sign-in, sign-out, session restore, and callback completion. It does not yet expose mobile OTP send/verify or password creation after OTP.

Design contracts do not need amendment if Option A is implemented. If the owner chooses Option B, C, or D instead, frozen S03/S04 contracts must be amended before code is wired.

## Recommendation

Proceed with Option A as the product-safe path:

- Preserve S02 -> S03 -> S04 exactly.
- Add a contained implementation spike before UI wiring:
  - Add Supabase gateway/repository methods for email OTP start and verify.
  - Verify whether the Supabase Dart/mobile flow can produce a valid authenticated session after email OTP verification for a newly created user.
  - If it can, complete S04 by calling a password update method against that authenticated session.
  - If it cannot, implement a server/Edge Function mediated signup completion that keeps service-role authority off the device.
- Keep account-enumeration responses neutral at every UI/controller boundary.
- Keep Google/Apple provider bypass behavior separate from this email OTP signup path.

This is safer than adapting the UX to existing email/password signup because S01-S06 are frozen design authority and S03 is specifically an in-app OTP verification screen, not a check-email/link screen.

## Local Code Evidence

Files inspected:

- `lib/features/auth/presentation/screens/auth_screens.dart`
- `lib/features/auth/domain/repositories/auth_backend_repository.dart`
- `lib/features/auth/domain/entities/auth_backend_contract.dart`
- `lib/features/auth/data/repositories/auth_repository_backend_adapter.dart`
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/data/repositories/supabase_auth_repository.dart`
- `lib/core/supabase/supabase_service.dart`
- `lib/core/supabase/supabase_config.dart`
- `lib/features/auth/domain/entities/auth_callback_result.dart`
- `lib/features/auth/services/auth_deep_link_service.dart`
- `web/auth/auth-page.js`
- `web/auth/reset-password/reset-password.js`
- `test/auth_backend_contract_test.dart`
- `test/auth_presentation_test.dart`
- `test/web_auth_pages_test.dart`
- `qa/authentication_backend_alignment/AUTH_BACKEND_ALIGNMENT_AUDIT.md`
- `qa/authentication_backend_alignment/AUTH_CONTROLLER_CONTRACT_RECONCILIATION.md`
- PackLox reset authority freeze records for S02, S03, and S04 in `packlox-design-platform/incoming_authority/reset_2026_07_18/`

Findings:

- S02 currently validates email locally and routes to S03. It does not call backend signup.
- S03 currently uses local OTP placeholder behavior, including accepted local code `123456`; it does not call Supabase OTP verification.
- S04 currently validates a 12+ character matching passphrase locally and shows a local completion message; it does not create a Supabase account, set a password, create a session, or navigate authenticated users home.
- `AuthBackendRepository` already defines `startEmailSignup`, `verifyEmailOtp`, and `createPasswordAfterVerification`.
- `AuthRepositoryBackendAdapter` returns `capabilityUnavailable` for all three staged signup methods.
- `SupabaseAuthGateway` and `SupabaseService` expose email/password signup via `/auth/v1/signup`, confirmation resend via `/auth/v1/resend`, reset request via `/auth/v1/recover`, password sign-in via `/auth/v1/token?grant_type=password`, callback completion, and sign-out.
- Mobile `SupabaseService` does not expose `signInWithOtp`, `verifyOtp`, or `updateUser`/password update methods.
- Web auth pages already use Supabase JS `verifyOtp`, `setSession`, and `updateUser` for link/callback and recovery flows.
- `AuthCallbackParser` currently ignores recovery callbacks and treats signup/email/magiclink/token-hash callbacks as confirmed-without-session unless access and refresh tokens are present.
- Supabase env is controlled by `SUPABASE_ENABLED`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY`; no secrets were inspected or added.

## Supabase Capability References

Official Supabase Dart/Flutter references checked:

- Signup: https://supabase.com/docs/reference/dart/auth-signup
- Email OTP sign-in: https://supabase.com/docs/reference/dart/auth-signinwithotp
- OTP verification: https://supabase.com/docs/reference/dart/auth-verifyotp
- User update/password update: https://supabase.com/docs/reference/dart/auth-updateuser
- Edge Functions overview: https://supabase.com/docs/guides/functions

Relevant capability interpretation:

- Supabase supports email/password signup.
- Supabase exposes OTP send and OTP verification APIs in the Dart auth surface.
- Supabase password update is user-session oriented, so the client-only Option A path depends on whether email OTP verification for a new signup can safely produce the session needed by S04.
- If client-only OTP-to-password completion cannot satisfy the frozen flow, a server/Edge Function mediated completion is the least disruptive way to keep the frozen UX without shipping privileged credentials to the app.

## Option Comparison

### Option A - Keep Frozen UX Exactly

Flow: S02 email -> S03 in-app OTP -> S04 create password.

UX impact: Best match. No visible contract changes.

Supabase feasibility: Partial but plausible. Official Dart auth has OTP send/verify capability, but current app mobile service does not implement it. The unresolved question is post-OTP password setup for a new user without collecting password at S02. This needs a capability spike.

Security/account-enumeration risks: Manageable if all responses remain neutral and raw Supabase statuses stay behind controller-safe result types. Server-mediated fallback must keep service-role credentials off-device.

Code churn: Medium. Requires data-source/repository/controller additions and S02-S04 wiring. May require Edge Function/server support if client-only password-after-OTP is not viable.

Testability: High with the existing fake `AuthBackendRepository`, plus integration tests behind SIT Supabase config when safe credentials exist.

Design contract amendment: No, if the capability spike confirms client or server-mediated support.

Decision: Recommended.

### Option B - Adapt to Supabase Email/Password Signup

Flow: S02 email -> S04 password -> Supabase signup -> email confirmation/link screen.

UX impact: Significant deviation. S03 would no longer be the frozen in-app OTP screen and S04 would move before verification.

Supabase feasibility: Highest with current code. Existing `signUpWithEmailPassword` already maps to `/auth/v1/signup`.

Security/account-enumeration risks: Manageable but raw already-registered/email-confirmation states must be normalized. Link-based confirmation must avoid exposing account existence.

Code churn: Low to medium because existing email/password signup exists, but tests/routes must be revised.

Testability: High.

Design contract amendment: Yes. Frozen S03 and S04 would need revision and owner reapproval.

Decision: Not recommended unless owner explicitly chooses to revise the frozen signup UX.

### Option C - Hybrid Link Confirmation

Flow: S02 email -> S03 check email/link confirmation -> S04 password after callback.

UX impact: Medium to high deviation. S03 changes from in-app OTP code entry to check-email/link confirmation. Callback state becomes part of the signup ceremony.

Supabase feasibility: Moderate. Existing web auth pages and mobile callback parser already recognize token-hash and session callbacks, but recovery handling is separate and mobile callback behavior would need careful expansion.

Security/account-enumeration risks: Higher than A because links, callback parsing, expired links, and session transfer increase edge cases. Must avoid leaking whether an address exists.

Code churn: Medium to high across callback parsing, route state, repository methods, and tests.

Testability: Medium. Deep-link and callback tests become central.

Design contract amendment: Yes. S03 and possibly S04 must be amended and reapproved.

Decision: Not recommended for Sprint 04.

### Option D - Temporary MVP Deviation

Flow: Implement email/password signup now and leave OTP for later.

UX impact: Highest deviation. It bypasses frozen S03 and changes the approved signup sequence.

Supabase feasibility: High with current code.

Security/account-enumeration risks: Manageable only with explicit deviation handling and neutral copy; higher product risk because placeholder UX and final UX diverge.

Code churn: Low initially, higher later when reverting to OTP.

Testability: High initially, but future migration cost is likely.

Design contract amendment: Yes. Requires explicit deviation record before implementation.

Decision: Not recommended unless owner approves a time-boxed MVP exception.

## Exact Files That Would Need Changes For Recommended Option A

Production code likely needed after the spike:

- `lib/core/supabase/supabase_service.dart`
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/data/repositories/supabase_auth_repository.dart`
- `lib/features/auth/data/repositories/auth_repository_backend_adapter.dart`
- `lib/features/auth/presentation/controllers/auth_backend_contract_controller.dart`
- `lib/features/auth/presentation/screens/auth_screens.dart`
- `lib/features/auth/domain/entities/auth_backend_contract.dart`, only if the current result model needs extra verification/session context
- `test/support/in_memory_auth_backend_repository.dart`
- `test/auth_backend_contract_test.dart`
- `test/auth_presentation_test.dart`
- `test/bootstrap_entry_presentation_test.dart`, if successful signup updates launch/auth handoff

Backend/server code may be needed only if client-only OTP verification cannot safely support S04 password creation:

- Supabase Edge Function or equivalent backend endpoint for staged signup completion
- New tests/docs for that backend path

No backend/server file should be touched until the spike proves it is required and the owner approves that implementation sprint.

## Tests To Add Before Coding Signup Wiring

Before production S02-S04 wiring:

- Gateway/repository unit tests for OTP start success, invalid email, rate limit, network failure, and neutral account-existence behavior.
- Gateway/repository tests for OTP verify success, invalid code, expired code, max attempts, malformed response, and session/no-session outcomes.
- Controller tests for S02 loading/error/success, S03 6-digit verification, 30-second resend cooldown, 5-attempt lockout, S04 12+ character policy, confirm match, and authenticated handoff.
- Widget tests proving S02/S03/S04 call the fake backend contract rather than local placeholder logic.
- Bootstrap/AppShell tests proving real signup success enters authenticated Home and guest mode does not override the authenticated session.
- Regression tests confirming no account-enumeration copy leaks through signup, OTP, or password setup errors.

## Decision Gate For Next Sprint

Next recommended implementation sprint: Authentication Backend Sprint 04A - Supabase OTP Signup Capability Spike.

Scope for that spike:

- No production S02-S04 UI wiring at first.
- Add or prototype repository/gateway support behind tests for OTP start and verify.
- Prove whether verified OTP creates a session that can update password under the project's Supabase configuration.
- If yes, proceed to S02-S04 wiring using Option A client-side.
- If no, stop and choose between a server/Edge Function mediated Option A or an owner-approved contract amendment.

## Final Answer To The Decision Question

Recommended option: A. Keep frozen UX exactly, with a capability spike before wiring.

Design contracts must be amended: No for Option A. Yes if choosing B, C, or D.

Do not wire S02-S04 yet: the current production adapter intentionally marks staged signup unavailable, and password-after-OTP remains unresolved.

## Validation

Commands run:

- `flutter analyze` - passed, no issues found.
- `git diff --check` - passed, no whitespace errors.

Production Dart files changed: No.
Backend server files changed: No.
Signup wired: No.
