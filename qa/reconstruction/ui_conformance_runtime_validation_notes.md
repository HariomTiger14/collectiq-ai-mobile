# Runtime Validation Notes

Date: 2026-07-13
Device: RZ8R213M8ZL, SM_E625F
Branch: rebuild/product-language-v1

## Commands

- adb devices -l: passed; RZ8R213M8ZL reported as device.
- flutter build apk --debug --flavor local --dart-define=APP_ENV=local: passed.
- adb install -r build/app/outputs/flutter-apk/app-local-debug.apk: passed.
- Android runtime capture: completed for Bootstrap first observable, Onboarding, App Shell, Home, Scanner, Portfolio, Detail, and shared states.
- adb logcat -d -v time: captured to shared_states/current_runtime/android_logcat_ui_conformance.txt.
- flutter analyze: passed; no issues found.
- flutter test: failed; 540 passing, 16 failing.

## Flutter Test Failure Summary

The test run is not clean. The first visible failures include:

- test/analyzer_service_test.dart: MockAnalyzerProvider consumes the backend analyzer contract when configured.
- test/domain_unit_test.dart: DioAiBackendApiService FastAPI detail error preserves analyzer error code.
- test/domain_unit_test.dart: Supabase foundation SIT scripts pass required dart defines without hardcoded secrets.
- test/widget_test.dart: camera denied UI shows friendly message.
- test/widget_test.dart: scan capture flashes and shows next capture suggestion.
- test/widget_test.dart: workspace capture next opens camera for the back photo.
- test/widget_test.dart: capture review acceptance returns to updated workspace.
- test/widget_test.dart: full workspace scan review analyze loop uses updated photo list.
- test/widget_test.dart: portfolio carousel edit updates image enhancement metadata.

The command reported 12 additional failures beyond the first four listed by Flutter. Because this pass is audit-only, no production or test remediation was performed.

## Audit Interpretation

Runtime visual capture succeeded, but regression validation is not fully green. The audit commit should therefore be treated as conformance evidence plus gap reporting, not as a full freeze approval.
