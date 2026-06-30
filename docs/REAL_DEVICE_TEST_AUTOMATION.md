# CollectIQ AI Real-Device Test Automation

This document describes the automated and semi-automated production test harness.
All automated UI tests run in mock/default mode and do not call OpenAI, eBay, or
other paid provider APIs.

## Test Scripts

```powershell
scripts\run_all_tests.ps1 -DeviceId RZ8R213M8ZL
scripts\run_device_ui_tests.ps1 -DeviceId RZ8R213M8ZL
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
