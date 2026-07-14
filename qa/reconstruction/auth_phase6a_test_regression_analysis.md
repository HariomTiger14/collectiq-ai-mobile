# Auth Phase 6A Test Regression Analysis

Date: 2026-07-14
Branch: `rebuild/product-language-v1`
Starting HEAD: `62b8412920a6baebc3bf003a33c76dc633ac6a0d`

## Summary

Phase 6A initially introduced one new full-suite failure beyond the accepted nine-failure baseline:

- `test/widget_test.dart`: `shows settings screen content`

Root cause: the test still expected Settings to embed the old authentication form and a `Password` settings row. Phase 6A intentionally moves email/password auth to separate Authentication screens, so the Settings test was stale rather than product debt.

Remediation:

- Updated the Settings smoke test to expect the signed-out `Sign In` row.
- Added absence assertions for legacy `settings-auth-*` credential controls in Settings.
- Deleted obsolete Settings-embedded auth tests rather than skipping them.
- Added replacement auth presentation coverage in `test/auth_presentation_test.dart`.

Current full-suite result:

- `C:\Users\hario\Desktop\flutter\bin\flutter.bat test --reporter=compact`
- Result: 580 passed, 0 skipped, 9 failed.
- Captured in `qa/reconstruction/auth_phase6a_full_test_output.txt`.

## Current Failure Set

| File | Test | Classification | Phase 6A action |
| --- | --- | --- | --- |
| `test/analyzer_service_test.dart` | `MockAnalyzerProvider consumes the backend analyzer contract when configured` | Existing backend analyzer contract debt | Unchanged |
| `test/domain_unit_test.dart` | `DioAiBackendApiService FastAPI detail error preserves analyzer error code` | Existing backend error-message mapping debt | Unchanged |
| `test/domain_unit_test.dart` | `Supabase foundation SIT scripts pass required dart defines without hardcoded secrets` | Existing SIT script config debt | Unchanged |
| `test/widget_test.dart` | `camera denied UI shows friendly message` | Existing stale scanner expectation | Unchanged |
| `test/widget_test.dart` | `gallery import confirms enhancement before adding photo` | Existing stale enhancement-preview expectation | Unchanged |
| `test/widget_test.dart` | `gallery import follows review workspace analyze result portfolio flow` | Existing stale review-workspace expectation | Unchanged |
| `test/widget_test.dart` | `enhancement preview shows only Original and Enhanced` | Existing stale enhancement-preview expectation | Unchanged |
| `test/widget_test.dart` | `enhancement preview can switch Enhanced back to Original` | Existing stale enhancement-preview expectation | Unchanged |
| `test/widget_test.dart` | `saving enhanced scan preserves portfolio gallery metadata` | Existing stale enhancement metadata expectation | Unchanged |

## Fixed New Failure

| File | Test | Previous failure | Current status |
| --- | --- | --- | --- |
| `test/widget_test.dart` | `shows settings screen content` | Expected `Password` and embedded Settings auth controls after those controls moved to Authentication routes | Passes in focused run and full suite |

Focused command:

- `C:\Users\hario\Desktop\flutter\bin\flutter.bat test test\widget_test.dart --reporter=compact --plain-name "shows settings screen content"`: pass.

## No Skips

`rg "skip:" test -n` returned no matches. No Phase 6A test is skipped.

## Controller Lifecycle Verification

The `AuthController` repository field remains mutable because Riverpod can rerun Notifier `build` on the same notifier instance. The new focused test `AuthController can rebuild without replacing session state` verifies provider invalidation reloads the current user without a `LateInitializationError` and without replacing the auth ownership model.

## Focused Auth Coverage

`test/auth_presentation_test.dart` now covers:

- Separate Sign In route and approved header/field structure.
- Settings opening Sign In without embedded credential fields.
- Password visibility on Sign In and Sign Up.
- Validation and duplicate submit blocking.
- Successful sign-in returning to the previous destination.
- Human-readable auth errors.
- Sign Up navigation, confirmation-required state, resend success, and resend rate limit.
- Forgot Password success, rate limit, and error messages.
- Continue as Guest.
- Real signed-in Settings summary and sign-out.
- AuthController rebuild lifecycle.
- 320 px / large text fit and light/dark theme rendering.
