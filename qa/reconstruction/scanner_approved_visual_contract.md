# Scanner Approved Visual Contract

Date: 2026-07-13
Authority: `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_03_Scanner/images/scanner_flow_master.png`
Runtime evidence: `qa/screenshots/approved_authority_recovery/scanner/current_runtime/`

## 1. Authority Identity

Scanner authority is Design Bible v1.0 `Volume_03_Scanner`, master `scanner_flow_master.png`, imported 2026-07-11, dimensions 1402x1122, SHA256 `84bd893396f1ce6673f93ed3a5dbe45db39949857f04a47e068644c0a06ff263`.

## 2. Approval And Freeze Evidence

`Volume_03_Scanner/visual_inventory.md` marks the references Approved contractual reference. `Volume_03_Scanner/qa/golden_mapping.md` records the master board as the contractual source. The v1.0 release manifest freezes the master and extracted screens.

## 3. State Coverage

Approved states are S01 Scan Hub, S02 Camera, S03 Guidance, S04 Review Photo, S05 Workspace, S06 Add More Photos, S07 Workspace Ready, S08 Analyzing, S09 Result, and S10 Save Confirmation. Android permission, camera unavailable, lost-picker recovery, and failure variants are not separately shown.

## 4. Target Viewport

Approved crops are 124x315 except S10 at 145x315. Runtime was captured at 1080x2400 with density 450. Remediation must preserve proportions, hierarchy, and state placement after scaling.

## 5. Root Background

Approved Scanner uses dark product surfaces. Runtime Scan Hub is dark and close to S01; workspace/result screens use generic `colorScheme.surface`/Material surfaces. Non-hub states must adopt approved dark Scanner surfaces.

## 6. Safe Areas

Runtime status bar height is 92px and bottom navigation occupies the bottom shell region. Approved safe-area treatment must remain visible without compressing camera controls or filmstrip.

## 7. Scan Hub Structure

S01 requires greeting, Scanner hero/entry card, option label, and photo source choices. Runtime Scan Hub matches this broad structure and remains strongest conformance.

## 8. Scan Hub Header

Runtime uses `ScannerPageScaffold` and disabled notifications. Preserve header semantics but ensure typography and spacing match S01.

## 9. Scan Hub Actions

Runtime actions are Take a photo, Choose from gallery, Try a sample scan. These are behaviourally correct and visually close, though exact tile proportions must be revalidated.

## 10. Camera Viewport Placement

S02 controls camera viewport placement. Runtime captured only Android permission prompt. Camera-ready state must be captured after permission and compared before freeze closure.

## 11. Camera Viewport Dimensions

Use S02 proportions for viewfinder bounds. Do not rely only on `CameraPreview` natural aspect ratio.

## 12. Guidance Placement

S03 controls guidance placement. Runtime workspace guidance appears as metadata/recommendation below preview; it is not proven equivalent.

## 13. Guidance Copy Hierarchy

Approved guidance hierarchy must drive capture guidance. Runtime copy such as `Enough to identify` and `Add a back/package photo...` is honest but must be visually mapped.

## 14. Shutter Placement

Approved S02 controls shutter placement. Runtime physical shutter was not captured; future validation must capture it after permission.

## 15. Shutter Dimensions

Measure from S02 and map to Product Language/Capture primitives only if approved. Candidate shutter treatments are not frozen.

## 16. Secondary Camera Controls

Flash, flip, gallery fallback, and close controls must match S02/S03 where visible and preserve `CameraCapturePage` lifecycle safety.

## 17. Analyse/Done Placement

Approved S07/S08 controls analysis-ready and analyzing placement. Runtime puts `Analyze 1 photo` high in workspace. Reconcile with S07 before freezing.

## 18. Filmstrip Placement

Approved S05-S07 controls filmstrip placement. Runtime filmstrip and role chips are lower in a long scroll. Needs board alignment.

## 19. Filmstrip Dimensions

Runtime thumbnails are large horizontal cards. Approved crop dimensions should drive final thumbnail and strip heights.

## 20. Thumbnail Dimensions

Runtime selected photo card is approximately `[87,1552][436,2035]` on 1080x2400. S05/S06 require compact board proportions.

## 21. Selected-Thumbnail Treatment

Runtime marks selection with selected accessibility state and visual treatment. Retain non-color-only selected state while restyling to board.

## 22. Image Count

Runtime displays `1 photo ready` and role counts. Approved progress/count treatment must be taken from S05-S07.

## 23. Active Preview

Runtime active preview is a large workspace card. Approved preview treatment must follow S05/S07.

## 24. Primary-Image State

Primary image state is controller-owned through `primaryImagePath`; visual primary treatment was not separately captured. Future evidence must validate it without changing data flow.

## 25. Multi-Image State

Runtime physically captured only a sample one-image state. Approved S06/S07 represent add-more/workspace-ready states; multi-image needs a future safe fixture or physical capture.

## 26. Full-Screen Review

S04 Review Photo is approved. Runtime Original/AI Enhance review was not freshly captured in this pass; prior Sprint 05 source confirms the page exists but conformance is unproven.

## 27. Retake

Retake is owned by `ImageEnhancementPreviewPage`/camera review. Future evidence must compare to S04.

## 28. Delete

Runtime workspace exposes Delete photo in the filmstrip. Its behavior should be retained and visual treatment aligned to S05-S07.

## 29. Use As Primary

Scanner primary intent is data-owned; approved visual treatment is not clearly separate. Do not invent an unapproved primary badge.

## 30. Original Selection

Runtime Original maps to `ImageEnhancementPreset.original`. Visual treatment must match S04 once captured.

## 31. AI Enhance Selection

Runtime AI Enhance maps to `ImageEnhancementPreset.autoEnhance`. Candidate enhancement UI must not be promoted without S04 comparison.

## 32. Confirmation Presentation

S10 Save Confirmation is approved. Runtime after Add to Portfolio is functional but visually needs direct S10 alignment.

## 33. Analysis-Ready State

Runtime `Analyze 1 photo` is ready state. It must align with S07 Workspace Ready and avoid misleading confidence/readiness.

## 34. Analysis-Progress State

Runtime overlay says `Analyzing collectible`; approved S08 contains analysis progress ring. Replace/reconfigure overlay to match S08 without changing `analyzeWithAi()`.

## 35. Analysis-Success State

Runtime success is `Analysis Complete` result. Approved S09 controls result surface and hierarchy.

## 36. Analysis-Failure State

No genuine failure was captured. Use controller-backed error only; do not fabricate.

## 37. Result Presentation

Runtime result uses a long Material result screen with confidence/progress/value. Approved S09 is more compact. Remediation should restyle result without changing analyzer output.

## 38. Permission States

Runtime captured genuine Android permission prompt. This is an allowed OS adaptation, not a Design Bible screen.

## 39. Camera-Unavailable State

Not reproduced. Must remain controller-backed and not fabricated.

## 40. Lost-Picker Recovery Presentation

Not reproduced physically in this pass. Sprint 05 data/lifecycle contract remains valid.

## 41. First-Viewport Hierarchy

Scan Hub first viewport is close. Workspace/result first viewports diverge by using standard AppBar, long scroll, and oversized body sections.

## 42. Typography

Use board-visible Scanner typography; runtime generic Material headings/body labels are not sufficient for non-hub states.

## 43. Colour/Token Mapping

Use approved dark Scanner palette. Candidate Capture System colors are not authority unless they match the board.

## 44. Surface Mapping

Scan Hub uses Product Language surfaces. Workspace/result must move from generic Material cards to approved Scanner surfaces.

## 45. Radius

Use board radius proportions. Do not inherit oversized cards if not visible in S05-S10.

## 46. Elevation

Approved Scanner appears flatter/darker. Runtime elevation/shadows must be reduced or remapped where needed.

## 47. Iconography

Camera/gallery/sample icons are acceptable only where visually equivalent. Camera controls must match S02/S04.

## 48. Spacing

Runtime workspace/result spacing is tall and scroll-heavy. Approved compact crop spacing is controlling.

## 49. Alignment/Grid

Approved Scanner is compact and state-specific. Runtime workspace/result use a single-column app-page grid.

## 50. Responsive Rules

Mobile portrait is controlling. Larger devices may adapt only after mobile conformance passes.

## 51. Accessibility

Preserve labels, roles, selected state, and minimum tap targets while changing visuals.

## 52. Motion/Reduced Motion

Analysis animation must respect reduced motion and S08 visual hierarchy.

## 53. Camera Lifecycle Constraints

Do not move camera ownership out of `CameraCapturePage`/`CameraService`. Visual changes must not retain camera resources off tab.

## 54. Approved Components

Approved visible components: Scan entry card, Photo source option, Camera viewfinder, Shutter button, Camera control, Guidance checklist, Photo quality checklist, Retake button, Photo thumbnail, Capture progress bar, Add-photo tile, Analysis progress ring, Confidence indicator, Result summary card, Save confirmation.

## 55. Primitive Compositions

Product Language primitives may implement the approved components only when the resulting composition matches S01-S10.

## 56. Candidate Components

Capture shutter, camera toolbar, permission family, guidance panel, filmstrip, active preview, review controls, Original/AI Enhance, capture loop, analysis progress, and result handoff remain candidate treatments until matched to the board.

## 57. Prohibited Legacy Elements

Do not restore stale `Auto Detect`, pre-analysis `Confidence`, `55%`, fake readiness, fake backend status, or unsupported recovery controls.

## 58. Prohibited Readiness/Confidence Presentation

Pre-analysis confidence/readiness must stay removed unless backed by real analyzer/quality data and approved visually.

## 59. Allowed Runtime Adaptations

Allowed: OS permission prompt, camera capability variance, safe-area handling, sample/demo path, local image placeholders, honest missing/error states.

## 60. Non-Negotiable Visual Requirements

Use the Design Bible Scanner master and crops as whole-flow authority. Scan Hub alone is insufficient for full Scanner freeze.

## 61. Behavioural Contracts Preserved

Preserve controller ownership, camera lifecycle, captureImages order, selectedImagePath, primaryImagePath, Original/AI Enhance metadata, analyzeWithAi, result handoff, and save-to-portfolio path.

## 62. Evidence Requirements

Future remediation must capture S01-S10 runtime, camera-ready after permission, review/Original/AI Enhance, multi-image, save confirmation, XML, logcat, and focused tests.

## 63. Acceptance Criteria

Scanner visual freeze can remain only for S01. Full Scanner visual freeze requires S02-S10 board-to-runtime conformance or explicit approved adaptations for missing authority states.
