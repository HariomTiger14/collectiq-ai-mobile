# Auth Phase 6A Runtime Comparison

Date: 2026-07-14
Branch: `rebuild/product-language-v1`
Device: Samsung SM-E625F, `RZ8R213M8ZL`
Build: local debug APK, `com.collectiq.ai.local`

## Commands

- `C:\Users\hario\Desktop\flutter\bin\flutter.bat build apk --debug --flavor local --dart-define=APP_ENV=local`: passed, built `build\app\outputs\flutter-apk\app-local-debug.apk`.
- `C:\Users\hario\Desktop\flutter\bin\flutter.bat install -d RZ8R213M8ZL --debug --flavor local`: passed.
- `adb shell pm clear com.collectiq.ai.local`: passed.
- `adb shell monkey -p com.collectiq.ai.local -c android.intent.category.LAUNCHER 1`: passed.

## Captured Evidence

- `qa/screenshots/approved_authority_remediation/auth/after/phase6a_shell_home_runtime.png`
- `qa/screenshots/approved_authority_remediation/auth/after/phase6a_settings_signed_out_runtime.png`
- `qa/screenshots/approved_authority_remediation/auth/after/phase6a_sign_in_runtime.png`
- `qa/screenshots/approved_authority_remediation/auth/after/phase6a_sign_up_runtime.png`
- `qa/screenshots/approved_authority_remediation/auth/after/phase6a_forgot_password_runtime.png`
- `qa/screenshots/approved_authority_remediation/auth/hierarchy/phase6a_settings_signed_out.xml`
- `qa/screenshots/approved_authority_remediation/auth/hierarchy/phase6a_sign_in.xml`
- `qa/screenshots/approved_authority_remediation/auth/hierarchy/phase6a_sign_up.xml`
- `qa/screenshots/approved_authority_remediation/auth/hierarchy/phase6a_forgot_password.xml`
- `qa/screenshots/approved_authority_remediation/auth/logs/phase6a_auth_logcat_focused.txt`
- `qa/screenshots/approved_authority_remediation/auth/logs/phase6a_auth_window_dump.txt`
- `qa/screenshots/approved_authority_remediation/auth/comparison/phase6a_auth_authority_vs_runtime.png`

## Runtime Findings

- Clean app state still enters onboarding before the main shell; no auth guard was introduced.
- After normal onboarding completion, Settings shows a signed-out account entry with a `Sign In` row and no embedded credential fields.
- Tapping Settings `Sign In` opens the separate Authentication route.
- Sign In contains email, password, forgot-password, create-account, and continue-as-guest controls.
- Create Account is a separate route with email/password only and guest access still explained.
- Forgot Password is a separate route and explicitly keeps reset completion in the existing web/email flow.
- Foreground window remained `com.collectiq.ai.local/com.collectiq.ai.MainActivity`.
- Log scan found no app-attributable `FATAL EXCEPTION`, `ANR in com.collectiq.ai.local`, `Process: com.collectiq.ai.local`, `E/flutter`, `RenderFlex`, overflow, or `LateInitializationError`.

## Authority Comparison

`phase6a_auth_authority_vs_runtime.png` compares the approved authority crops for Sign In, Create Account, and Forgot Password with the captured Samsung runtime states. Differences are classified as responsive/product-contract adaptations:

- Runtime omits social sign-in buttons because those providers remain unimplemented in the current contract.
- Runtime Create Account omits name and richer password-rule checklist because the backend contract supports email/password only with a six-character minimum.
- Runtime Forgot Password sends the existing reset email flow instead of adding an in-app reset-password form.
