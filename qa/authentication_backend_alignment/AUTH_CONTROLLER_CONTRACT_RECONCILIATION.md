# Auth Controller Contract Reconciliation

Date: 2026-07-18
Repo: C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction
Branch: rebuild/product-language-v1
Sprint: Authentication Backend Sprint 01 - Auth Controller Contract Reconciliation and Test Harness
Status: Contract foundation added / UI not wired to live Supabase

## Scope

This sprint created the app-side auth contract and fake-backed tests needed before wiring Authentication S02-S06 UI to real backend behavior.

No visual UI changes were made. S02-S06 submit handlers remain local/placeholder-only. No backend server code was changed.

## Files Added

- `lib/features/auth/domain/entities/auth_backend_contract.dart`
- `lib/features/auth/domain/repositories/auth_backend_repository.dart`
- `lib/features/auth/data/repositories/auth_repository_backend_adapter.dart`
- `lib/features/auth/presentation/controllers/auth_backend_contract_controller.dart`
- `test/support/in_memory_auth_backend_repository.dart`
- `test/auth_backend_contract_test.dart`
- `qa/authentication_backend_alignment/AUTH_CONTROLLER_CONTRACT_RECONCILIATION.md`

## Contract Decisions

### New Backend-Facing Contract

A new `AuthBackendRepository` contract was added beside the existing `AuthRepository`. It covers:

- current user/session restore
- email/password sign-in
- email signup start
- OTP/email verification
- password creation after verification
- resend verification code/email
- password reset request
- sign-out

This keeps S01-S06 UI decoupled from live Supabase wiring until the backend path is fully reconciled.

### Controller Foundation

A new `AuthBackendContractController` and `authBackendContractControllerProvider` were added. The controller models backend-facing states without becoming the active UI controller yet:

- idle
- restoring session
- signed out
- signing in
- signed in
- starting signup
- verification sent
- verifying OTP
- OTP verified
- creating password
- requesting password reset
- password reset confirmation
- signing out
- failure

### UI-Safe Result and Failure Types

The new contract uses `AuthBackendResult<T>` and `AuthBackendFailure` rather than raw exceptions at the controller boundary.

Failure categories include:

- invalid credentials neutral error
- account existence not disclosed
- email not verified
- provider unavailable
- network/offline
- cooldown/rate-limit
- invalid OTP
- expired OTP
- OTP attempt limit reached
- password policy mismatch
- capability unavailable
- unknown

The neutral sign-in message is fixed to:

`Email or password is not correct.`

The generic password reset confirmation is fixed to:

`If an account exists for this email, reset instructions have been sent.`

### Password Policy

The frozen S04 password policy is represented as `AuthPasswordPolicy.frozenS04`:

- minimum 12 characters
- no required letter/number/symbol/uppercase/lowercase composition
- spaces allowed
- symbols allowed
- confirm password must match

The controller validates this policy before calling password creation, so invalid local input does not call the backend contract.

### Existing Repository Adapter

`AuthRepositoryBackendAdapter` adapts existing `AuthRepository` behavior into the new contract where current capabilities already exist:

- current user
- email/password sign-in
- resend email confirmation
- password reset request
- sign-out

Unsupported staged-signup methods intentionally return `capabilityUnavailable`:

- mobile email OTP signup start
- mobile OTP verify
- post-OTP password creation

This explicitly preserves the known S03/S04 Supabase gap instead of pretending it is solved.

## Test Harness Added

`InMemoryAuthBackendRepository` was added under `test/support/` for fake-backed contract tests. It supports:

- registered and unknown accounts
- email/password sign-in success and neutral failure
- email-not-verified failure
- signup start with OTP-code delivery
- OTP verification with expected code `123456`
- 5-attempt OTP limit
- resend verification resetting attempt count
- password creation after verified OTP
- generic password reset confirmation for any email
- sign-out
- optional network-offline failures

## Tests Added

`test/auth_backend_contract_test.dart` covers:

- sign-in success stores a cloud user
- sign-in failure uses neutral copy and hides account existence
- signup start creates the email verification placeholder path
- OTP verify failure exposes remaining attempts safely
- OTP verify success reaches OTP-verified state
- OTP attempt limit requires resend before continuing
- S04 password policy requires 12+ characters and allows symbols/spaces
- password creation backend is not called when policy fails
- password reset request returns identical generic confirmation for registered and unknown emails
- guest mode never overrides an authenticated session
- authenticated session wins AppShell launch routing before the guest branch

Existing tests were not changed.

## Supabase Capability Gaps Remaining

The core unresolved backend gap remains S03/S04:

- mobile `SupabaseService` does not expose `signInWithOtp`
- mobile `SupabaseService` does not expose `verifyOtp`
- mobile `AuthRepository` does not support email -> OTP -> password staged signup
- current Supabase email/password signup expects a password before email confirmation, while frozen PackLox UX collects password after OTP verification
- mobile recovery completion/S07 remains unimplemented and recovery callbacks are still ignored by the mobile deep-link parser
- Google/Apple provider SDK integration remains unavailable and gated off

Least disruptive path remains:

1. Keep S02-S04 route sequence frozen: email -> 6-digit OTP -> password -> authenticated Home.
2. Implement or spike Supabase OTP send/verify in a repository/data-source layer first.
3. If Supabase cannot safely support password creation after OTP from the client, use a server/edge-function mediated signup flow.
4. Preserve neutral account-enumeration behavior at the controller boundary.
5. Wire S05 sign-in or S06 reset request first if the staged signup path needs owner/backend resolution.

## Validation

Commands run:

- `flutter analyze` - PASS, no issues found.
- `flutter test test/auth_backend_contract_test.dart` - PASS, 9 tests.
- `flutter test test/auth_backend_contract_test.dart test/auth_presentation_test.dart test/bootstrap_entry_presentation_test.dart test/settings_phase6b_test.dart test/app_shell_presentation_test.dart` - PASS, 78 tests.
- `flutter test test/web_auth_pages_test.dart test/supabase_dev_sync_validation_test.dart` - PASS, 13 tests.

`git diff --check` - PASS.

## Ready For Next Sprint

Recommended next implementation sprint:

Authentication Backend Sprint 02 - Wire S05 Sign In Through AuthBackendContractController

Rationale:

S05 maps cleanly to existing Supabase email/password sign-in capabilities. It can prove the controller/repository/UI handoff with lower risk than staged S02-S04 signup, while preserving the neutral error rules and authenticated AppShell routing. S06 reset request is the next-lowest-risk backend wiring candidate. S02-S04 should wait until the Supabase OTP/password setup path is resolved.
