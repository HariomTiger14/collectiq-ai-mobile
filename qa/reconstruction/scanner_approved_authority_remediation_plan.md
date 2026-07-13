# Scanner Approved Authority Remediation Plan

Date: 2026-07-13
Scope: future implementation only. No implementation occurred in this recovery task.

## Likely Files

- `lib/features/scanner/presentation/pages/scan_hub_page.dart`
- `lib/features/scanner/presentation/pages/camera_capture_page.dart`
- `lib/features/scanner/presentation/pages/image_enhancement_preview_page.dart`
- `lib/features/scanner/presentation/pages/scan_workspace_screen.dart`
- `lib/features/scanner/presentation/pages/scan_result_screen.dart`
- `lib/features/scanner/presentation/widgets/capture_workspace.dart`
- `lib/features/scanner/presentation/widgets/analyze_animation.dart`
- `lib/features/scanner/presentation/widgets/camera_overlay.dart`
- focused scanner widget tests

## Shared Scanner Components

Keep shared controller/service contracts intact. Treat Capture System widgets as screen-specific candidates unless separately approved.

## Scan Hub Changes

Retain current Scan Hub architecture and tune only spacing, typography, and proportions against S01.

## Camera Viewport Changes

After safely granting camera permission in a test pass, capture camera-ready state and align viewfinder, shutter, secondary controls, and safe-area placement to S02/S03.

## Guidance And Shutter Changes

Map guidance checklist and shutter controls directly from S02/S03. Preserve camera lifecycle ownership in `CameraCapturePage`.

## Filmstrip And Preview Changes

Rebuild workspace filmstrip, selected thumbnail, image count, active preview, add-photo tile, and capture progress around S05-S07. Preserve `captureImages`, `selectedImagePath`, `primaryImagePath`, and role metadata.

## Review Changes

Capture and align `ImageEnhancementPreviewPage` to S04. Preserve Retake, Original, AI Enhance, Use Photo, enhancement metadata, and quality assessment.

## Analysis And Result Changes

Replace the current analyzing overlay with S08 visual treatment. Align `ScanResultScreen` to S09 and S10 while preserving analyzer output and portfolio save semantics.

## Permission And Error Changes

Keep OS permission prompts as allowed adaptations. Style app-owned permission denied, camera unavailable, analysis failure, and lost-picker states honestly; do not fabricate readiness/confidence.

## Token, Surface, Spacing, Accessibility

Apply approved dark Scanner surfaces beyond Scan Hub. Reduce long-scroll spacing where the board is compact. Preserve semantics, selected state, text scaling, and tap targets.

## Camera Lifecycle Risks

Do not move initialization/disposal out of camera owner classes. Test pause/resume, permission denial, gallery fallback, and tab switching.

## Image/Data-Flow Risks

Avoid collapsing image order, role metadata, selected image, primary image, or enhancement metadata. Run analyzer payload and portfolio handoff tests.

## Tests And Runtime Evidence

Add focused tests for S01-S10 structure, camera permission/ready, review Original/AI Enhance, workspace multi-image, analysis, result, save confirmation, and tab return. Capture physical Android screenshots/XML and logcat.

## Commit Plan

1. `fix: align scanner hub and camera structure with approved authority`
2. `fix: align scanner filmstrip and review presentation`
3. `fix: align scanner confirmation and analysis presentation`
4. `test: validate approved scanner visual contract`
5. `chore: add approved scanner authority evidence`
6. `docs: amend scanner visual freeze`

## Rollback Plan

Rollback visual implementation commits only. Preserve authority evidence docs. Do not revert controller/data-flow/lifecycle fixes unless a targeted regression proves they caused the issue.

## Acceptance Checklist

- S01 Scan Hub matches approved reference
- S02 Camera viewport captured and matched
- S03 Guidance matched
- S04 Review Photo/Original/AI Enhance matched
- S05-S07 workspace, add-photo, ready states matched
- S08 analysis progress matched
- S09 result matched
- S10 save confirmation matched
- OS permission state documented as adaptation
- No stale confidence/readiness returns
- Focused tests pass
- Runtime logcat has no app crash signature
