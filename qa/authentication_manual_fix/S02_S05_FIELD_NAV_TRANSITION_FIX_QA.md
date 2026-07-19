# Authentication Manual Fix QA - S02/S05 Field, Navigation, Transition

Date: 2026-07-19
Branch: `rebuild/product-language-v1`

## Scope

Manual SIT follow-up for:

- S02 focused email field label overlap.
- S02 Sign In / S05 Create Account repeated route stacking.
- Auth route transition flash/flicker.

No backend/server code was changed. No Supabase wiring behavior was changed. No secrets were added.

## UI Field Fix

Result: Fixed in shared auth field presentation.

`AuthTextField` no longer uses `InputDecoration.labelText` for auth email/password/reset fields. It now renders a compact visible label above the field and keeps the hint inside the input. The field wrapper preserves the accessibility label.

Affected shared-field surfaces include:

- S02 Create Account email.
- S05 Sign In email.
- S05 Sign In password.
- S04 Create Password password.
- S04 Create Password confirm password.
- S06 Forgot Password email.

Test coverage confirms the shared field decoration has:

- `labelText == null`
- `floatingLabelBehavior == FloatingLabelBehavior.never`
- correct hint text retained

The S02 focused/typed state was also tested with keyboard view inset simulated.

## Navigation Stack Fix

Result: Fixed for S02/S05 bridge switching.

Navigation strategy:

- S01 continues to push the first auth branch route.
- S02 Sign In bridge uses replacement navigation to S05.
- S05 Create Account bridge uses replacement navigation to S02.
- S05 Forgot Password still pushes S06 so back returns to S05.
- S03 Change email still returns to S02.
- S04 Back to verification still returns to S03.

Test coverage confirms repeated S02 -> S05 -> S02 -> S05 switching does not retain duplicate S02/S05 route copies, and Android back returns toward the legitimate S01 entry.

## Route Transition Fix

Result: Fixed for auth routes S01-S06.

Transition strategy:

- Auth route factories now use a shared `PageRouteBuilder`.
- Transition duration: 220 ms.
- Reverse transition duration: 180 ms.
- Animation: fade plus subtle horizontal slide.
- Curve: `easeOutCubic`; reverse uses `easeInCubic`.
- Route page and transition are wrapped in the PackLox dark background to avoid white flash.
- Reduced-motion/platform animation disable is respected by skipping the slide/fade transition.

Test coverage confirms all S01-S06 auth route factories use the custom transition route.

## Runtime QA

SIT APK rebuild/install: Not performed.

Reason: local SIT Supabase config remains unavailable:

- `config/sit.env` present: false
- `SUPABASE_ENABLED` environment variable present: false
- `SUPABASE_URL` environment variable present: false
- `SUPABASE_ANON_KEY` environment variable present: false

Building/installing without this config would not verify the same SIT auth runtime environment from the manual report. Runtime screenshots are therefore blocked until local SIT config is supplied.

## Validation Results

- `flutter analyze`: Passed, no issues found.
- `flutter test test/auth_presentation_test.dart`: Passed, 53 tests.
- `flutter test test/settings_phase6b_test.dart`: Passed, 6 tests.
- `flutter test test/bootstrap_entry_presentation_test.dart`: Passed, 16 tests.
- `flutter test test/app_shell_presentation_test.dart`: Passed, 11 tests.
- `git diff --check`: Passed. Git reported CRLF normalization warnings only.

## Remaining Runtime Evidence Needed

After `config/sit.env` is supplied locally, rebuild/install SIT APK and capture:

- S02 focused email field with keyboard open.
- S02 <-> S05 repeated bridge switching.
- Auth route transition with no white flash/flicker.

## QA Conclusion

Status: Code-level fix and widget/regression validation passed.

Runtime device evidence: blocked by missing local SIT Supabase config.
