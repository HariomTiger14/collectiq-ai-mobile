# Sprint 05 Test Regression Analysis

Date: 2026-07-13
Branch: `rebuild/product-language-v1`
Starting HEAD: `5dc94c123dab54eaabdfae4eebac1415ee8bc86e`

## Baseline

The Sprint 05 freeze validation full suite regressed from the Sprint 04 ceiling of 19 failures to:

- `flutter test --reporter=compact`: 526 passed, 24 failed

Eight failures were identified as the Sprint 05 remediation target:

1. `scanner camera capture shows preview`
2. `scanner slot updates after captured front image`
3. `camera return shows preparing image bridge before preview`
4. `lost Android camera data recovers to Scan tab`
5. `scanner sample scan shows fake AI result`
6. `camera completion remains on Scan tab`
7. `gallery completion from Home CTA remains on Scan tab`
8. `home scan CTA starts clean after unsaved scan`

Each failed individually before remediation, so the failures were not caused by cross-test order alone.

## Findings

Most failures were stale broad widget expectations from the pre-Sprint 05 scanner surface. They expected the reconstructed scanner to hide the selected capture label after camera, gallery, lost-data, or sample selection. Sprint 05 intentionally shows an honest capture workspace after selection, with a filmstrip, active preview, selected title/status, and an enabled Analyze CTA.

The production contracts traced for these cases are:

- Camera capture selects the Scan tab, stores one captured image, sets `selectedImagePath`, and exposes `Captured image`.
- Front-slot capture records one `ScannerPhotoSlot` with role `front`.
- Camera return keeps the preparing bridge visible before the selected preview replaces it.
- Gallery and Home CTA picker returns remain on Scan tab index `2`.
- Sample scan selects `sample://sports-card`, shows `Sample Sports Card`, and still produces the mock analysis result after Analyze.
- Home CTA cleanup clears the previous unsaved sample result before starting a fresh camera scan.

One genuine Sprint 05 defect was found while strengthening the lost Android data test: redundant lost-picker recovery calls from the Scan hub and Scanner screen could append the same recovered persistent image twice. The controller now treats same-path `recovered` images idempotently, preserving the recovered selection without duplicating the slot.

## Remediation

Production:

- `lib/features/scanner/presentation/controllers/scanner_controller.dart`
  - De-duplicates repeated lost-picker recovery for the same recovered persistent image path.

Tests:

- `test/widget_test.dart`
  - Replaced stale negative text assertions with provider/key contracts.
  - Asserted `scannerControllerProvider` state for image count, selected path, title/status, role, and preparing state.
  - Asserted `appShellTabControllerProvider == 2` for camera, gallery, lost recovery, and Home CTA return flows.
  - Kept UI coverage through stable keys such as `scan-primary-Analyze Image`, `workspace-filmstrip`, and `workspace-primary-photo-highlight`.

## Validation

Focused remediation:

- All eight tests passed individually after remediation.
- Eight-test regex group passed: 8 passed.

Regression suites:

- Focused Scanner suite passed: 51 passed.
- Frozen Sprint 01-04 suite passed: 45 passed.
- `flutter analyze`: no issues found.
- Full suite after remediation: 534 passed, 16 failed.

The final full-suite result is below the approved Sprint 04 ceiling of 19 failures. Remaining failures are outside the eight-failure remediation target and were not expanded in this pass.
