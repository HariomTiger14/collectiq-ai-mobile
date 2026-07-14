# Phase 5 Performance And Runtime Report

Date: 2026-07-14
Device: Samsung SM-E625F, Android 13/API 33
Package: com.collectiq.ai.local

## Runtime Result

Passed for Phase 5 visual-freeze validation. Cold launch, onboarding completion, core tab switching, scanner sample flow, portfolio save, detail open/back, scroll, background, and foreground completed without app-attributable crash, blank screen, or ANR in the captured ADB runtime path.

## Log Evidence

- Full logcat: `qa/screenshots/approved_authority_remediation/integration/logs/phase5_integration_logcat.txt`
- Broad marker scan: `qa/screenshots/approved_authority_remediation/integration/logs/phase5_logcat_marker_scan.txt`
- App-focused marker scan: `qa/screenshots/approved_authority_remediation/integration/logs/phase5_logcat_app_marker_scan.txt`

No app-attributable `FATAL EXCEPTION`, `E/flutter`, ANR, OOM, or `Process: com.collectiq.ai.local` crash stanza was observed. Broad scan terms matched unrelated Android services and monkey/uiautomator process exits; these were not classified as CollectIQ runtime failures.

## Tooling Note

`flutter run` and APK build commands temporarily hung during Phase 5, so runtime evidence used the installed local debug package via ADB. Flutter test/analyze tooling later recovered and completed focused and full-suite validation.
