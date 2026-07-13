# Sprint 05 Scanner Runtime Comparison

Date: 2026-07-13
Branch: `rebuild/product-language-v1`
Device: `RZ8R213M8ZL` / `SM_E625F`
Package: `com.collectiq.ai.local`

## Device Gate

- `adb devices -l` reported `RZ8R213M8ZL` as `device`.
- Flutter device discovery via `flutter devices --device-timeout 30` hung without output and was stopped after ADB had already confirmed the device.

## Build And Install

- `flutter build apk --debug --flavor local` produced an APK during the first pass but the Flutter wrapper did not exit cleanly.
- After the runtime defect fix, the stale APK was deleted and the fresh build was produced with:
  - `android\gradlew.bat :app:assembleLocalDebug`
  - `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`
- Fresh APK installed successfully with:
  - `adb -s RZ8R213M8ZL install -r build\app\outputs\flutter-apk\app-local-debug.apk`

## Runtime Finding And Fix

Initial runtime validation found a real Sprint 05 scanner defect:

- `05_sample_workspace.png` / `05_sample_workspace.xml` showed stale workspace metadata:
  - `Auto Detect`
  - `Confidence`
  - `55%`

Remediation:

- Removed the stale `Auto Detect` and pre-analysis confidence rows from `ScanWorkspaceScreen`.
- Added a source guard in `test/scanner_volume_03_structure_test.dart` so the stale workspace cannot reintroduce those labels.

## Post-Fix Runtime Evidence

Fresh runtime evidence after reinstall:

- `09_fresh_home_after_onboarding.png`: clean Home after first-launch onboarding.
- `10_fresh_scan_hub.png`: Scan hub renders approved scanner entry copy/actions.
- `11_fresh_sample_workspace.png`: sample workspace renders `CaptureWorkspace` controls with `Analyze 1 photo`, role chips, filmstrip, and recommended next capture.
- `11_fresh_sample_workspace.xml`: no `Auto Detect`, no `55%`, no `workspace-metadata-confidence`.
- `12_fresh_analysis_result.png`: sample analysis reached `Analysis Complete`.
- `13_fresh_tab_scroll_stress.png`: tab-switch and scroll stress returned to a coherent scanner result state.
- `14_fresh_runtime_logcat.txt`: captured Android logs for the fresh run.

Focused log scan:

- No `FATAL EXCEPTION`.
- No `E AndroidRuntime`.
- No `Process: com.collectiq.ai.local` crash stanza.
- Scanner flow logs show sample workspace build and analysis result state transitions.

## Validation Commands

- `flutter analyze` passed.
- Focused scanner tests passed:
  - `test\scan_hub_page_test.dart`
  - `test\camera_capture_page_test.dart`
  - `test\scanner_widgets_test.dart`
  - `test\scanner_volume_03_structure_test.dart`
  - `test\scan_image_processing_service_test.dart`
  - `test\smart_scan_guidance_service_test.dart`
- Android local debug build passed via Gradle.
- Android install, launch, Home, Scan hub, sample workspace, analysis result, tab switching, scrolling, screenshot capture, hierarchy capture, and log capture completed on `RZ8R213M8ZL`.
