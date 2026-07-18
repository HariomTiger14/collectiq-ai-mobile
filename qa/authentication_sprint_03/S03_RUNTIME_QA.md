# Authentication Sprint 03 - S03 Runtime QA

Date: 2026-07-18
Device: Samsung device `RZ8R213M8ZL`
App package: `com.collectiq.ai`
Build: `flutter build apk --debug --flavor prod`
Scope: Authentication S03 - Verify Email / OTP Code only

## Authority

- `incoming_authority/reset_2026_07_18/authentication_mvp_handoff/`
- `incoming_authority/reset_2026_07_18/S03_email_verification_working/`

## Implementation Scope Verified

- S02 `Continue` with a valid email routes to S03 using local route state only.
- No backend signup or OTP verification call is made in this sprint.
- S03 renders compact Brand v2 identity, title, masked email copy, OTP input, Verify CTA, Resend code, Change email, expiry text, and attempts text.
- OTP input accepts digits only and is limited to 6 digits.
- Verify is disabled for empty/partial code and enabled only for 6 digits.
- Auto-submit is not implemented.
- Resend code starts with a 30-second cooldown and returns to available state.
- Five-attempt UI state is implemented locally and requires resend after the limit.
- Change email routes back to S02.
- No S04-S06 screen implementation was added.
- No backend/Supabase files were modified.

## Automated Validation

| Command | Result |
| --- | --- |
| `flutter analyze` | PASS |
| `flutter test test/auth_presentation_test.dart` | PASS, 26 tests |
| `git diff --check` | PASS; Git reported an LF-to-CRLF working-copy warning for `auth_screens.dart` only |

## Runtime QA

Runtime setup:

- Built `app-prod-debug.apk`.
- Installed with `adb install -r build/app/outputs/flutter-apk/app-prod-debug.apk`.
- Cleared app state with `adb shell pm clear com.collectiq.ai`.
- Launched `com.collectiq.ai/.MainActivity`.
- Navigated S01 `Create Account` -> S02.
- Entered `collector@example.com`.
- Tapped S2 `Continue`.

| Check | Evidence | Result |
| --- | --- | --- |
| S03 route opens from S02 Continue | UI tree showed `Verify your email` after valid S02 email and Continue | PASS |
| Masked email renders | UI tree and screenshot show `c***@example.com` | PASS |
| OTP hierarchy renders | UI tree showed `Verification code, 6-digit code`, `Verify`, `Resend code`, `Change email`, expiry, and attempts text | PASS |
| Verify disabled before code entry | UI tree showed `Verify` disabled with empty code | PASS |
| Resend cooldown exists | UI tree captured `Resend code available in 1 seconds`; screenshot captured available `Resend code` after cooldown elapsed | PASS |
| No S04-S06 UI surfaced | UI tree did not show S04-S06 route markers during S03 runtime path | PASS |

Screenshot:

- `screenshots/S03_VERIFY_EMAIL_RUNTIME_F62.png`

## Notes

- Current Verify behavior is local placeholder validation only and does not call backend verification or advance to S04.
- Android screenshots may show a narrow Samsung edge handle on the far left. It is not present in the Flutter UI tree and is treated as a device/system capture artifact, not app UI.

## QA Conclusion

PASS. S03 is implemented as the frozen v0.2 component-contract screen with local route state from S02, OTP input behavior, resend cooldown UI, attempt-limit UI, and Change Email navigation. Backend OTP verification and S04 transition remain out of scope for this sprint.
