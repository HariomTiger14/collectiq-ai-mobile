# Auth Phase 6A Legacy Test Migration

Date: 2026-07-14

Phase 6A removed the Settings-embedded authentication form. Legacy tests that interacted with `settings-auth-*` fields in Settings were obsolete because those fields are no longer reachable by design.

No legacy test was left skipped. The obsolete tests were deleted and replacement coverage was added to `test/auth_presentation_test.dart`.

| Removed legacy test | Old behavior | Replacement coverage |
| --- | --- | --- |
| `settings signs in with mocked email auth repository` | Submitted email/password inside Settings and expected Home tab reset | `Sign In success returns to previous destination`; `Settings signed-in summary and sign-out remain real` |
| `settings blocks empty Sign Up before repository call` | Validated Sign Up from Settings form | `validation remains real and prevents sign-in callback`; Sign Up route coverage |
| `settings blocks empty Sign In before repository call` | Validated Sign In from Settings form | `validation remains real and prevents sign-in callback` |
| `settings shows email confirmation message after Sign Up` | Rendered confirmation state inside Settings | `Sign Up confirmation state uses controller state only` |
| `settings resends confirmation only when confirmation required` | Resent confirmation from Settings | `Email verification resend invokes existing contract once` |
| `settings shows resend after unconfirmed Sign In` | Showed resend action in Settings after sign-in error | `human-readable auth error is rendered`; confirmation tests on auth route |
| `settings resend rate limit shows clear wait message` | Rendered resend rate-limit inside Settings | `Email verification resend rate limit is human-readable` |
| `settings sends password reset email` | Sent reset email from Settings | `Forgot Password route invokes recovery once and explains web flow` |
| `settings shows password reset rate-limit message` | Rendered reset rate-limit inside Settings | `Forgot Password rate limit and errors stay human-readable` |
| `settings shows password reset errors cleanly` | Rendered reset errors inside Settings | `Forgot Password rate limit and errors stay human-readable` |
| `settings does not show Sign Out for anonymous cloud session` | Verified anonymous Settings panel state | `Settings opens Sign In without embedding credential fields`; guest/local path remains covered |
| `settings shows account panel instead of auth form when signed in` | Verified signed-in Settings panel and absence of auth fields | `Settings signed-in summary and sign-out remain real` |

Settings retained coverage:

- `shows settings screen content` now asserts Settings exposes a `Sign In` row and does not expose legacy credential controls.
- `settings shows SIT resend diagnostics` remains because it covers diagnostic Settings content, not embedded credential submission.

Final disposition: migrated/deleted as unreachable legacy coverage. No Phase 6A skip remains.
