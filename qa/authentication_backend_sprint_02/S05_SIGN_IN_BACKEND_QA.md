# Authentication Backend Sprint 02 - S05 Sign In Backend QA

## Scope

- Sprint: Authentication Backend Sprint 02 - Wire S05 Sign In
- Screen: Authentication S05 - Sign In / Email + Password
- Branch: rebuild/product-language-v1
- Backend scope: Existing app-side auth contract and Supabase auth adapter only
- Explicit exclusions: S02-S04 signup/OTP/password wiring, S06 reset wiring, backend server changes, social provider SDK integration

## Implementation Summary

- S05 `Sign In` now calls `AuthBackendContractController.signInWithEmailPassword` when email/password validation passes.
- Loading state disables the primary CTA and changes the CTA label to `Signing In` while the contract call is running.
- Successful sign-in applies the returned cloud-backed user to the existing `AuthController` state so AppShell authenticated launch behavior can use the same `isSignedIn` source it already trusts.
- Invalid credentials and account-not-found style failures remain mapped to the frozen neutral copy: `Email or password is not correct.`
- Network/offline, provider-unavailable, rate-limit, capability, and unknown failures remain UI-safe through `AuthBackendFailure.safeMessage`.
- Google/Apple provider buttons remain hidden because provider gates are not enabled. Facebook is not rendered.
- Forgot Password still routes to S06. Create Account still routes to S02.

## Runtime / Backend Verification

- Connected device check: Samsung SM-E625F was detected by `flutter devices`.
- Real Supabase sign-in was not manually verified in this sprint.
- Reason: local test/config output reports Supabase disabled with missing URL and anon key; no valid SIT credentials were available in scope for a safe live sign-in attempt.
- Evidence path used instead: fake-backed widget tests and backend-contract tests.
- Screenshot/log evidence: no runtime screenshot captured for real backend sign-in because no configured SIT auth environment/credentials were available.

## Test Evidence

- `flutter analyze` - PASS, no issues found.
- `flutter test test/auth_backend_contract_test.dart` - PASS, 9 tests.
- `flutter test test/auth_presentation_test.dart` - PASS, 40 tests.
- `flutter test test/settings_phase6b_test.dart` - PASS, 6 tests.
- `flutter test test/bootstrap_entry_presentation_test.dart` - PASS, 16 tests.
- `flutter test test/app_shell_presentation_test.dart` - PASS, 11 tests.
- `flutter test test/onboarding_presentation_test.dart` - PASS, 10 tests.
- `flutter test test/web_auth_pages_test.dart` - PASS, 4 tests.
- `flutter test test/supabase_dev_sync_validation_test.dart` - PASS, 9 tests.
- `git diff --check` - PASS with line-ending normalization warnings only for existing CRLF/LF handling.

## QA Checks

| Check | Result | Notes |
| --- | --- | --- |
| S05 only wired | PASS | Signup, OTP/password finalization, and reset request remain unchanged. |
| Real backend path used for S05 | PASS | UI calls the app-side auth backend contract, which defaults to the Supabase auth adapter. |
| Loading state present | PASS | CTA disabled while sign-in is pending. |
| Neutral invalid copy preserved | PASS | `Email or password is not correct.` |
| Account-not-found not exposed | PASS | Fake-backed tests assert no `not found` / `sign up first` copy appears. |
| Authenticated state handoff | PASS | Successful fake sign-in updates `AuthController.isSignedIn`. |
| Guest mode precedence | PASS | Fake-backed S05 success leaves guest choice local while authenticated state remains signed in. Existing AppShell precedence tests cover authenticated session winning over guest mode. |
| Google/Apple provider gates | PASS | Provider block remains hidden when gates are unavailable. |
| Facebook deferred | PASS | Facebook is not rendered. |
| Backend server untouched | PASS | No backend server files changed. |

## Remaining Caveats

- Live Supabase sign-in still needs SIT runtime verification with configured `SUPABASE_ENABLED`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and a known test account.
- S02-S04 signup/OTP/password flow remains placeholder/local only by sprint rule.
- S06 reset request remains placeholder/local only by sprint rule.
- Google/Apple provider SDK wiring remains future work.