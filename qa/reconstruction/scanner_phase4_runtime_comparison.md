# Scanner Phase 4 Runtime Comparison

Date: 2026-07-14

Device: Samsung SM-E625F (`RZ8R213M8ZL`)

Build exercised: current working tree, local debug flavor, package `com.collectiq.ai.local`.

## Evidence

Evidence directory: `qa/screenshots/reconstruction/phase_04_scanner_authority/`

- `phase4_scanner_authority_vs_runtime.png` compares the approved Scanner master against current Android Scan Hub runtime.
- `08_current_build_scan_hub.png` captures S01 Scan Hub on the current build.
- `09_current_build_workspace.png` captures sample Workspace on the current build.
- `10_current_build_result.png` captures Result on the current build.
- `11_current_build_save_area.png` captures Result save action area.
- `12_current_build_saved_confirmation.png` captures post-save state.
- `13_current_build_camera.png` captures the first-run Android camera permission dialog after reinstall.
- `14_current_build_camera_granted.png` captures the current-build Camera surface after granting permission.
- `window_current_*.xml` files record the Android UI hierarchy for the captured runtime states.

## Reproduced Flow

1. Installed and ran current local debug build with `flutter run --debug --flavor local -d RZ8R213M8ZL`.
2. Navigated Home to Scan tab.
3. Captured Scan Hub.
4. Opened sample scan and captured Workspace.
5. Ran Analyze and captured Result.
6. Scrolled to save action, saved to Portfolio, and captured post-save state.
7. Returned to Scan Hub, opened Camera, granted camera permission, and captured Camera surface.

## Runtime Notes

- The Camera runtime evidence confirms the current-build camera surface exposes `Close camera`, `Position the item in the frame`, `Choose from gallery`, `Take photo`, and `Flip camera`.
- The sample Workspace runtime evidence confirms `Analyze 1 photo`, compact filmstrip, and role controls remain reachable.
- The current-build result save path confirms `save tapped` and `portfolio updated` in the Flutter run log.
- A Home startup layout assertion appeared in debug mode before Scanner navigation. It is outside Phase 4 Scanner ownership and was not remediated here.
