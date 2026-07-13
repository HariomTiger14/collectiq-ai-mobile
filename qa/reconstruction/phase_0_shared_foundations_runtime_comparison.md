# Phase 0 Shared Foundations Runtime Comparison

Runtime validation was performed on RZ8R213M8ZL, SM E625F, Android 13 API 33, using the local debug APK built from this working tree.

Commands completed:
- `adb devices -l`: RZ8R213M8ZL reported as `device`.
- `flutter devices`: Android device discovered as android-arm64.
- `flutter build apk --debug --flavor local`: built `build/app/outputs/flutter-apk/app-local-debug.apk`.
- `adb install -r`: install succeeded.
- App launched as `com.collectiq.ai.local`.
- Home, Portfolio, Scan, Settings, Home scroll stress, hierarchy dumps, and logcat were captured.

Evidence:
- `qa/screenshots/approved_authority_remediation/shared/after/phase0_home_initial.png`
- `qa/screenshots/approved_authority_remediation/shared/after/phase0_home_scroll_stress.png`
- `qa/screenshots/approved_authority_remediation/shared/after/phase0_portfolio_tab.png`
- `qa/screenshots/approved_authority_remediation/shared/after/phase0_portfolio_relaunch.png`
- `qa/screenshots/approved_authority_remediation/shared/after/phase0_scan_tab.png`
- `qa/screenshots/approved_authority_remediation/shared/after/phase0_settings_tab.png`
- `qa/screenshots/approved_authority_remediation/shared/logs/phase0_runtime_logcat.txt`

Result:
- No crash was observed during install, launch, tab switching, or Home scroll stress.
- App-level background and system bars rendered dark on the non-scanner shell.
- Bottom navigation retained bottom clearance above the Android navigation area.
- Portfolio screen-owned light panels remain a known screen-specific deviation and are deferred outside Phase 0.
- Runtime sheet/dialog capture was not retained because the attempted sheet tap missed the app. Shared sheet/dialog defaults are validated by targeted widget tests.
