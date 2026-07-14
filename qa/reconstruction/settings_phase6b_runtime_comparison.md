# Settings Phase 6B Runtime Comparison

Date: 2026-07-14

## Runtime Evidence

Device: Samsung SM E625F, Android 13 / API 33, serial `RZ8R213M8ZL`.

Build command:

```powershell
C:\Users\hario\Desktop\flutter\bin\flutter.bat build apk --debug --flavor local -v
```

Result: passed in 41.8s. APK:

```text
C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction\build\app\outputs\flutter-apk\app-local-debug.apk
```

Install and launch:

```powershell
adb install -r C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction\build\app\outputs\flutter-apk\app-local-debug.apk
adb shell monkey -p com.collectiq.ai.local -c android.intent.category.LAUNCHER 1
```

Foreground activity confirmed as `com.collectiq.ai.local/com.collectiq.ai.MainActivity`.

## Captured Evidence

Evidence root: `qa/screenshots/approved_authority_remediation/settings/`.

- Screenshots: `after/phase6b_settings_first_viewport.png`, `phase6b_auth_signin_route.png`, `phase6b_settings_preferences_notifications.png`, `phase6b_settings_backup_sync_detail.png`, `phase6b_settings_support_about.png`, `phase6b_settings_about_visible.png`, `phase6b_about_packlox_route.png`, `phase6b_settings_danger_zone_bottom.png`, `phase6b_settings_danger_confirm_dialog.png`, `phase6b_settings_after_tab_return.png`.
- Hierarchies: matching XML captures under `hierarchy/`.
- Logs: `logs/phase6b_build_diagnostics.txt`, `logs/phase6b_flutter_build_local_debug_verbose.txt`, `logs/phase6b_settings_runtime_logcat.txt`, `logs/phase6b_logcat_failure_scan.txt`.
- Comparison PNG: `comparison/phase6b_settings_authority_vs_runtime.png`.

## Supported-State Classification

| State | Classification | Notes |
| --- | --- | --- |
| Settings Home hierarchy | MATCH | Header, signed-out Account & Profile, four-tab shell, and bottom nav clearance reproduced on device. |
| Account/Profile | MATCH | Guest/local account state is visible; no credential fields are embedded in Settings. |
| Preferences / Appearance | ACCEPTABLE RESPONSIVE ADAPTATION | System language, default units, Scanner-owned scan mode/enhancement, and system theme are honest supported rows. |
| Notifications | ACCEPTABLE RESPONSIVE ADAPTATION | Real price-alert notification state and permission wording are shown; unsupported marketing delivery is unavailable. |
| Backup & Sync | ACCEPTABLE RESPONSIVE ADAPTATION | Signed-out/local state is honest; no fabricated cloud success, last-sync, or health state. |
| Support/About | ACCEPTABLE RESPONSIVE ADAPTATION | Help/report/feedback destinations remain `Soon`; About route opens real version/build. |
| Legal | DEFERRED PRODUCT CONTRACT | Terms destination is not configured; privacy/local and license rows remain honest. |
| Danger Zone | ACCEPTABLE RESPONSIVE ADAPTATION | Confirmation dialog reproduced and cancelled; account deletion remains unavailable. |
| Separate-auth handoff | MATCH | `Sign In` opens the separate AuthSignInScreen; Back returns to Settings. |
| Surfaces, spacing, safe areas | ACCEPTABLE RESPONSIVE ADAPTATION | Samsung viewport scrolls top-to-bottom without overflow; bottom nav remains clear. |

## Runtime Findings

- First launch entered onboarding honestly; guest/local onboarding path was completed without clearing data or using credentials.
- Settings opened from the frozen App Shell.
- Sign In opened the separate authentication route, where email/password controls live.
- Back navigation, About navigation, tab switch away/return, and background/foreground all returned without route lock or input lock.
- Logcat app-specific scan found no PackLox `FATAL EXCEPTION`, `E/flutter`, ANR, input dispatch timeout, uncaught exception, force-finish, or PackLox process death.
- One global process-death line belonged to `com.samsung.android.networkdiagnostic`, outside the app under test.

No material supported-state mismatch remains. Phase 6B Settings physical runtime evidence is reproduced and accepted for freeze.
