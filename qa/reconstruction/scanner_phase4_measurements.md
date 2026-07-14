# Scanner Phase 4 Measurements

Date: 2026-07-14

Authority: `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_03_Scanner\images\scanner_flow_master.png`

Authority SHA-256: `84bd893396f1ce6673f93ed3a5dbe45db39949857f04a47e068644c0a06ff263`

## Implemented Measurements

- S02 camera uses a bounded authority viewfinder keyed `camera-authority-viewfinder`, with bottom shutter controls outside the preview plane.
- Camera shutter remains `78 x 78` logical pixels through `ScannerCameraShutter`.
- Camera guidance remains below the bounded viewport and above the shutter row.
- Workspace active preview changed from `16:9` to `4:3`.
- Workspace filmstrip rail changed from `172` to `132` logical pixels high.
- Captured filmstrip tiles changed from `124` to `96` logical pixels wide.
- Empty filmstrip role tiles changed from `116` to `92` logical pixels wide.
- Add-photo tile changed from `104` to `84` logical pixels wide.
- Review surface now uses the Scanner dark authority surface key `review-photo-authority-surface`.

## Verification

- `test/camera_capture_page_test.dart` asserts bounded camera viewfinder placement, camera guidance, and shutter size.
- `test/scanner_widgets_test.dart` asserts compact filmstrip sizing, workspace filmstrip presence, review carousel controls, and absence of fabricated `Auto Detect`, `55%`, and `readiness` presentation copy.
- `test/scanner_volume_03_structure_test.dart` asserts the shared shutter contract and camera viewfinder source contract.

## Notes

Measurement assertions are intentionally structural and bounded rather than pixel snapshots. The approved authority is a composite design board, not a runtime pixel-perfect device capture.
