# CollectIQ AI Real-Device Test Automation

This document describes the automated and semi-automated production test harness.
All automated UI tests run in mock/default mode and do not call OpenAI, eBay, or
other paid provider APIs.

## Test Scripts

```powershell
scripts\run_master_qa.ps1 -DeviceId RZ8R213M8ZL
scripts\run_master_qa.ps1 -DeviceId RZ8R213M8ZL -SkipDeviceUi
scripts\run_flutter_quality.ps1
scripts\run_backend_quality.ps1
scripts\run_all_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_device_ui_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_camera_gallery_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_persistence_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_stress_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_backend_tests.ps1
scripts\run_android_builds.ps1
```

All scripts write logs and summaries under:

```text
build/test_reports/
```

## Automated UI Coverage

The integration test suite covers:

- app launch and bottom navigation
- Home empty dashboard state
- Home dashboard metrics
- collector intelligence
- smart insights
- recommendations
- recent activity detail navigation
- Scan layout
- camera/gallery button visibility
- sample fixture scan injection
- mock analyze flow
- analyze-to-result transition
- premium result fields
- Save to Portfolio
- View Portfolio
- usage limit blocking error
- Portfolio list
- newest-order seeded data
- search
- category filter
- detail page
- delete action path
- Settings account/sync/provider/plan diagnostics

On the current Samsung SM E625F test device, the raw Flutter attached-device
runner (`flutter test integration_test -d RZ8R213M8ZL`) built and installed the
debug APK, then timed out waiting for test results. The local/widget coverage is
still automated through `flutter test`; native picker and real-device relaunch
checks remain semi-automated until the host/device integration runner is stable.

## Master QA Coverage Matrix

| Area | Status | Runner |
| --- | --- | --- |
| App launch and bottom nav | Fully automated in widget tests; attached-device runner currently blocked | `flutter test`, `run_device_ui_tests.ps1` |
| Home dashboard, intelligence, insights, recommendations | Fully automated in widget tests; attached-device runner currently blocked | `flutter test`, `run_device_ui_tests.ps1` |
| Scan sample fixture, analyze, result, save, usage-limit error | Fully automated in widget tests; attached-device runner currently blocked | `flutter test`, `run_device_ui_tests.ps1` |
| Camera native picker | Semi-automated | `run_camera_gallery_tests.ps1` plus manual picker steps |
| Gallery native picker | Semi-automated | `run_camera_gallery_tests.ps1` plus manual picker steps |
| Permission allowed/denied | Manual-only for OEM dialogs | `run_camera_gallery_tests.ps1` captures logs |
| Portfolio list, search, filters, detail, delete | Fully automated in widget tests; attached-device runner currently blocked | `flutter test`, `run_device_ui_tests.ps1` |
| Persistence after force-stop | Semi-automated | `run_persistence_tests.ps1` |
| Offline/local-first behavior | Fully automated foundations, manual airplane-mode validation | `flutter test` |
| Cloud sync queue states | Fully automated foundations, manual Supabase validation | `flutter test` |
| Subscription/usage | Fully automated in widget tests; attached-device runner currently blocked | `flutter test`, `run_device_ui_tests.ps1` |
| Backend health/analyze/error contracts | Fully automated | `run_backend_quality.ps1` |
| Performance timing logs | Semi-automated | COLLECTIQ/Scanner/backend logs |
| Accessibility/layout smoke | Fully automated foundations | stable keys plus widget/integration tests |
| Crash/log monitoring | Semi-automated | `run_camera_gallery_tests.ps1` |
| Android builds | Fully automated | `run_android_builds.ps1` |

## Native Picker Manual Coverage

Android camera/gallery pickers are native UI outside Flutter widget automation.
Use the existing filtered log helper while manually validating picker return:

```powershell
scripts\android_scan_flow_logs.ps1 -DeviceId RZ8R213M8ZL
```

Manual picker steps:

1. Launch the app on the Android device.
2. Open Scan.
3. Tap Camera.
4. Capture a photo and confirm.
5. Verify the app remains on Scan and preview appears.
6. Tap Gallery.
7. Select an image.
8. Verify the app remains on Scan and preview appears.
9. Confirm no `AndroidRuntime`, `FATAL EXCEPTION`, `PlatformException`, or
   `image_picker` errors appear in the filtered log.

## Backend Smoke Coverage

Automated backend tests validate:

- health/analyze endpoint contracts
- mock analyze success and error responses
- OpenAI provider errors mocked safely
- eBay provider and fallback behavior mocked safely
- pricing aggregation/cache/rate-limit foundations
- validation toolkit response parsing

For a manual local smoke test:

```powershell
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Then open:

```text
http://127.0.0.1:8000/health
```

Real provider validation remains manual/local only and is documented in
`docs/AI_PRICING_VALIDATION.md`.
