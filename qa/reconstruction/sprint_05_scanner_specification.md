# Sprint 05 Scanner specification

Status: specification only. No production, test, runtime-evidence, or design implementation is authorized until this document is committed.

Branch: `rebuild/product-language-v1`

Starting frozen HEAD: `d0ad7f8165627cb9757c81776b417789e353079c`

Sprint title: Scanner Presentation Reconstruction

Authoritative Product Language release: `PLX-PL-1.0`

Sprint 01, Sprint 02, Sprint 03, and Sprint 04 remain frozen. This sprint owns only Scanner presentation and Scanner-specific presentation states.

## 1. Current Scanner architecture

The Scan tab is selected through the frozen App Shell destination at index 2 and renders `ScanHubPage`. `ScanHubPage` is the canonical idle scanner entry and S01 visual baseline. It watches `scannerControllerProvider`; when scanner state contains a result, captured image, selected image, loading/preparing state, or error, it hands off to `ScannerScreen`.

`ScannerScreen` is the current active-session coordinator. It observes app lifecycle, triggers lost-picker recovery, computes capture-plan guidance from `ScanCapturePlanService`, opens the initial camera when no active workspace image exists, renders `ScanWorkspaceScreen` for captured-photo workspace state, renders `_SnapchatScanSurface` for capture-loop state, and renders `ScanResultScreen` after analysis succeeds.

`CameraCapturePage` owns the real in-app camera page, camera permission UI, camera initialization/disposal, capture locking, flash/flip/gallery controls, and post-capture review through `ImageEnhancementPreviewSurface`.

`ScannerController` owns workflow state and business handoffs. It depends on `CameraService`, `GalleryService`, `AnalyzerService`, `ScanResultEnrichmentService`, `ImageEnhancementService`, `ImageQualityAssessmentService`, `ScanCapturePlanService`, `ScanQualityGateService`, telemetry, subscription state, portfolio state, image sync, cloud registry, and frozen App Shell tab selection preservation.

## 2. Runtime flow map

1. Frozen Home or frozen App Shell selects Scan.
2. App Shell builds only the active Scan destination.
3. `ScanHubPage` performs one-shot lost-picker recovery and renders S01 idle entry if scanner state is idle.
4. Camera tile calls `ScannerController.startCameraScan(context, imageRole: 'front')`.
5. Gallery tile calls `ScannerController.pickImageFromGallery(context: context, imageRole: 'front')`.
6. Sample tile calls `ScannerController.useSampleScan()`.
7. Camera capture pushes `CameraCapturePage` through `CameraService.captureWithInAppCamera`.
8. Camera permission and camera controller lifecycle run inside `CameraCapturePage`.
9. A captured image opens `ImageEnhancementPreviewSurface` for Original or AI Enhance selection.
10. Accepted camera/gallery images are persisted into app-owned storage, quality-gated, appended to `ScannerState.captureImages`, mirrored into `photoSlots`, and added to `ScanSession.capturedImages`.
11. Workspace renders captured images, active preview, next role guidance, add/capture/analyze actions, and genuine errors.
12. Analyze uses `AnalyzerRequest` with the active image and all non-sample captured images.
13. Analysis response is mapped/enriched into `ScanResult`, including gallery image metadata.
14. Result screen saves to portfolio through `ScannerController.saveScanResultToPortfolio()`.
15. Portfolio save constructs `CollectibleItem`, preserves primary/gallery images, saves through `portfolioControllerProvider`, enqueues image sync, and optionally cloud-syncs.
16. Leaving Scan after a saved result preserves frozen App Shell `resetAfterSaved()` behaviour.

## 3. State-machine inventory

Idle hub: no selected image, no capture images, no result, no loading/preparing state, no scanner error.

Picker/camera opening: `isLoading == true`, `_isPickerActive == true`, App Shell tab is kept on Scan.

Camera permission/init: local `CameraCapturePage` state `_isInitializing`, `_errorMessage`, `_isPermissionPermanentlyDenied`, `_isCapturing`, `_capturedImage`.

Capture review: `CameraCapturePage` shows `ImageEnhancementPreviewSurface` after `_capturedImage` is set.

Preparing image: controller sets `isPreparingImage == true`, selected title/status to preparing copy, then persists/quality-gates.

Workspace ready: `captureImages.isNotEmpty`, `selectedImagePath` points to active image, `scanSession.capturePlan` owns readiness.

Capture loop: `_showCaptureLoopScan` is local to `ScannerScreen` and temporarily shows `_SnapchatScanSurface` for next camera/gallery action.

Analysis blocked: controller refuses analysis while busy, without selected image, with unmet capture plan, with subscription failure, or invalid image path.

Analysis in progress: `isLoading == true`, pipeline status marked ready, analyzer request active.

Analysis failed: `errorMessage` is set, result cleared, images preserved.

Analysis succeeded: `scanResult` and `aiRecommendation` set, `scanSession` completed.

Saving to portfolio: `isSavingToPortfolio == true`.

Saved: `isSavedToPortfolio == true`; View Portfolio may be available.

Reset: `resetScan()` clears selected image, slots, images, session, result, recommendation, errors, and saved flags.

## 4. Controller/provider ownership

`scannerControllerProvider` is the scanner state owner. Presentation may call public controller methods but must not duplicate state machines in widgets beyond local UI-only affordances such as transient overlays.

`cameraServiceProvider`, `galleryServiceProvider`, `scanCapturePlanServiceProvider`, `scanQualityGateServiceProvider`, `smartScanGuidanceServiceProvider`, `imageEnhancementServiceProvider`, `imageQualityAssessmentServiceProvider`, market providers, `analyzerServiceProvider`, `portfolioControllerProvider`, subscription providers, cloud providers, and `appShellTabControllerProvider` remain unchanged.

## 5. Camera lifecycle ownership

`CameraCapturePage` owns camera permission request, camera initialization, live camera preview, capture locking, flash/flip, app pause disposal, resume reinitialization, capture result, review handoff, exit disposal, and back interception.

`CameraService` owns the `CameraController`, available camera discovery, flash support, `takePicture`, switch cameras, app settings opening, image-picker lost-data recovery, image persistence, and cache clearing before external pickers.

`ScannerScreen` may observe lifecycle only to request lost-picker recovery; it must not own or retain camera resources off-tab.

## 6. Image ownership

`ScannerPhotoSlot` is the presentation/controller image slot: role, label, active path, source, `XFile`, original path, enhancement preset, enhanced path, quality metadata, and capture time.

`CapturedScanImage` is the session/analyzer image record: path, role, source, original path, enhancement preset, and quality metadata.

`CollectibleImage` is the result/portfolio gallery image record and owns `isPrimary` for portfolio/gallery handoff.

No widget may truncate or replace these data owners for visual convenience.

## 7. Multi-image contract

`ScannerState.captureImages` is ordered and authoritative for active scan photos. New accepted images append through `_appendCaptureImage`. `photoSlots` stores the latest slot per role but cannot replace the ordered list. Analyzer payload iterates all non-sample `captureImages`. Result gallery uses `_galleryImagesFromSlots()`. Portfolio save uses result gallery images or the current slots fallback.

The UI must keep multiple images inspectable, selectable, and deletable. It must not show only the newest image while hiding the rest.

## 8. Role-assignment contract

Roles are normalized through `ScanCaptureRole.fromId`. Capture-plan roles come from `ScanCapturePlanService`, with front required and category/goal-specific optional roles. `selectCaptureRole`, `selectCapturedImage`, `selectCapturedPhoto`, `_photoSlotFor`, `_updatedSessionWithImage`, and `_capturedImageFromSlot` preserve role identity.

Presentation may describe roles in friendlier language but must not alter role IDs or analyzer metadata.

## 9. Active-image contract

The active preview is owned by `selectedImagePath` and the selected slot. `selectCapturedPhoto` updates active role, image, path, title, and status. `_activeScanSlot` resolves the active slot by selected path and falls back to the latest image.

The visual selected state must use more than color alone and must announce which image is active.

## 10. Primary-image contract

`primaryImagePath` is the explicit primary image owner. `useCapturedPhotoAsPrimary` sets it. Delete fallback moves primary to the next selected slot when the primary is deleted. `_orderedSlotsForPrimary` places primary first, then front, back, selected, and remaining slots. `_primaryImagePathFor` uses result primary gallery image, first gallery image, front slot, then result thumbnail.

Sprint 05 may expose or clarify the primary action, but it must not change the underlying ordering/selection rules without separate approval.

## 11. Confirmation contract

Confirmation is the full-screen `ImageEnhancementPreviewPage` / `ImageEnhancementPreviewSurface`. It uses a minimal dark presentation, full image, cancel, retake, Original, AI Enhance, and Use Photo. Camera capture embeds the surface after capture; gallery import pushes the page before persistence.

No sliders, press-and-hold Original, compare mode, readiness score, warning clutter, or Use Anyway action is approved by this specification.

## 12. Original/AI Enhance contract

Original maps to `ImageEnhancementPreset.original` and metadata `selectedEnhancement: original`, `enhanced: false`.

AI Enhance maps to `ImageEnhancementPreset.autoEnhance` and metadata `selectedEnhancement: aiEnhance`, `enhanced: true`. The preview warms/caches enhancement, updates active path only when selected, and does not falsely label an unenhanced image as enhanced. Controller-side `applyEnhancementToPhoto` preserves original path, enhanced path, preset, quality metadata, selected image, active role, session images, and saved/result invalidation.

Enhancement logic must stay in services/controller paths, not inside rebuilt widgets.

## 13. Analysis contract

`analyzeWithAi()` is the only analysis trigger. It ignores busy/preparing states, requires a selected image, respects `ScanCapturePlan.isMinimumReadyForAnalyze`, checks subscription permission, validates the selected image path, sets `isLoading`, logs analyzer runtime config, and calls `_analyzerService.analyze(AnalyzerRequest(...))`.

The request must preserve active image path, `selectedImage`, all non-sample captured images with role/source/image, image count, image roles, capture category/manual flag, active original/enhanced metadata, selected enhancement, quality metadata, scan goal, session ID, scanner UX version, and confidence target/achieved metadata.

No analyzer contract, backend endpoint, provider factory, Supabase config, pricing, or enrichment behavior may be changed in Sprint 05.

## 14. Result handoff contract

Analyzer response maps to `AiAnalysisResult`, then `ScanResultEnrichmentService.enrich`, then `ScanResult` with photos used, photo roles, and gallery images. `ScanResultScreen` receives `result`, active slot, save flags, save callback, scan-another callback, and optional view-portfolio callback.

Sprint 05 may improve scanner result presentation only as part of scanner handoff clarity; it must not reconstruct Portfolio or Detail.

## 15. Portfolio handoff contract

`saveScanResultToPortfolio()` builds `CollectibleItem` from the current result, recommendation, `_primaryImagePathFor(result)`, gallery images, pricing, market summary, matches, confidence explanation, detection quality, AI reasoning, category fields, valuation status/source, and AI estimate. It saves through `portfolioControllerProvider.notifier.saveItem`, enqueues image sync, optionally cloud-syncs, and sets saved flags.

No portfolio repository, controller, cloud sync, Supabase, image sync, Portfolio screen, or Detail screen reconstruction is allowed.

## 16. Permission states

Camera permission is owned by `CameraCapturePage` through `CameraService.requestPermissionStatus()`. Denied permission shows a camera message and Try Again. Permanently denied permission shows Settings copy and calls `openAppSettings`.

Permission presentation may be refined only within `CameraCapturePage`/scanner presentation, preserving retry/settings ownership and copy safety.

## 17. Loading states

Supported loading states are picker/camera opening (`isLoading`), image persistence/preparation (`isPreparingImage`), camera initialization (`_isInitializing`), capture in progress (`_isCapturing`), AI Enhance warming/selection, analysis in progress (`isLoading` during analyzer call), saving to portfolio (`isSavingToPortfolio`), and lost-picker recovery debug state.

No artificial capture, startup, analysis, or save delay may be added for animation or evidence.

## 18. Recoverable error states

Recoverable states include camera permission denied, camera initialization failure with Try Again, capture failure, gallery cancellation, gallery empty path/missing file/unsupported type/too large, selected-image missing path/file, quality warning accepted by the service, image decode warning accepted by the service, enhancement cancellation, analysis plan not ready, subscription/usage failure, analyzer failure, network/backend unavailable, and save failure propagated from portfolio save.

Presentation must preserve local images when analysis fails and must expose only safe user messages.

## 19. Unrecoverable error states

Unrecoverable or blocked states include no camera available, permanently denied permission until settings change, unusable image quality blocker, missing selected file after persistence, unsupported picker lost-data exception that cannot recover a file, and unexpected analyzer/backend exceptions when no safe retry path is available.

Do not invent retry buttons where the existing controller/service contract does not support a safe retry.

## 20. Lost-picker recovery

Lost-picker recovery is invoked once in `ScanHubPage` startup, again in `ScannerScreen` startup, and on app resume from `ScannerScreen`. `ScannerController.recoverLostPickerData()` is guarded by disposed, picker-active, and recovery-active flags. It retrieves lost data through `CameraService.retrieveLostImage()`, validates/persists/evaluates it through gallery and quality services, appends it as source `recovered`, keeps Scan selected, and preserves a safe error message on failure.

The UI may surface recovered image context but must not duplicate recovery logic.

## 21. Current visual hierarchy

Idle hub uses approved Scanner S01: `PackLoxHeader`, `PackLoxHero(scanner)`, section heading, three `PackLoxEntryTile(scanner)` actions.

Active capture currently has competing hierarchy: automatic camera launch, a full-screen camera page, `_SnapchatScanSurface`, `ScanWorkspaceScreen`, legacy `CaptureWorkspace`, and shared `core/ui/scan` widgets. Workspace currently prioritizes an image hero, horizontal filmstrip, metadata card with detected category/confidence/photos, capture guide, capture/add/analyze actions, and error card.

The active Scanner hierarchy currently exposes internal-looking or derived confidence/category values before analyzer result. Sprint 05 must avoid fabricating readiness/confidence/pricing/analysis states.

## 22. Legacy presentation duplication

Current canonical runtime:

- `lib/features/scanner/presentation/pages/scan_hub_page.dart`
- `lib/features/scanner/presentation/widgets/scan_hub_presentation.dart`
- `lib/features/scanner/presentation/pages/scanner_screen.dart`
- `lib/features/scanner/presentation/pages/camera_capture_page.dart`
- `lib/features/scanner/presentation/pages/image_enhancement_preview_page.dart`
- `lib/features/scanner/presentation/pages/scan_workspace_screen.dart`
- `lib/features/scanner/presentation/pages/scan_result_screen.dart`

Tracked but duplicate/legacy/candidate scanner presentation:

- `lib/features/scanner/presentation/widgets/capture_workspace.dart`, covered by tests but not directly referenced by the current `ScannerScreen` runtime.
- `lib/core/ui/scan/scan_ui.dart`, shared scanner-style widgets with legacy confidence/status/action treatments and no current runtime import found in Scanner pages.
- `lib/features/scanner/presentation/widgets/scanner_widgets.dart`, `scan_goal_card.dart`, `capture_role_guide.dart`, `camera_overlay.dart`, `capture_suggestions.dart`, `enhance_button.dart`, `exposure_slider.dart`, `analyze_animation.dart`, and `scanner_visual_theme.dart`, each requiring runtime reference checks before modification.
- `lib/features/scanner/presentation/pages/scanner_screen.dart` is canonical; `lib/features/scanner/presentation/scanner_screen.dart` is only an export shim.

Do not delete legacy files in Sprint 05 unless reachability is proven and removal is separately justified.

## 23. Capture System status

Evidence inspected:

- `qa/reconstruction/product_language_gap_analysis.md`: camera controls and capture guidance beyond S01 are gaps requiring Studio composition, responsive/accessibility specification, implementation package, runtime evidence, and approval.
- `qa/engineering_platform/product_language_v1_s01_validation/remaining_variances.md`: S01 visual composition is approved and Product Language composition validated; full native camera/gallery E2E is deferred until scanner release-readiness validation; S02 has not started.
- `qa/engineering_platform/product_language_v1_s01_validation/s01_composition_report.md`: S01 composition approved; S02 not started.
- `qa/engineering_platform/s01_visual_language_refinement/recommendation.md`: S01 may be the canonical implementation baseline for S02-S10 optical rhythm, but this is not Capture System v1 approval.
- `qa/reconstruction/screen_inventory.md`: SCN-02 camera, SCN-03 guidance, SCN-04 review, SCN-05 workspace, SCN-06 add photos, SCN-07 ready, SCN-08 analyzing, SCN-09 result, and SCN-10 save confirmation are listed as candidate/embedded/duplicate or gap states, not approved Capture System.

Classification: **C. Candidate awaiting approval**.

No formal approved/frozen Capture System v1 record was found in the repo. Sprint 05 may use approved Product Language primitives and the approved Scanner S01 visual baseline, but must not treat Capture System v1 as a frozen implementation authority or automatically promote it.

## 24. Proposed information hierarchy

First priority is the camera or active preview region. Second priority is concise guidance for the next capture. Third priority is captured-image visibility and active image state. Fourth priority is one clear primary action. Fifth priority is error/status copy only when genuine state exists.

Technical labels, internal confidence, readiness scores, duplicated instructions, competing primary buttons, hidden filmstrip, tiny thumbnails, and Analyze placement that risks accidental activation are prohibited.

## 25. Product Language composition

A. Existing approved Product Language components:

- `PackLoxHeader` v1.0.1 for idle hub only unless a scanner substate genuinely needs header treatment.
- `PackLoxHero` v1.0.1 for idle hub only; active camera/workspace should prioritize capture content.
- `PackLoxEntryTile` v1.0.0 for hub actions.
- `PackLoxButton` v1.0.0 where standard actions fit.

B. Composition of approved primitives:

- Scanner workspace scaffold, guidance text, honest status/error strips, selected image treatments, result scanner handoff clarifications, safe-area layouts, and responsive spacing can compose tokens, typography, radius, border, elevation, iconography, semantics, and motion primitives.

C. New Product Language candidates requiring Design Studio review:

- capture shutter
- camera toolbar
- camera permission state family
- camera guidance panel
- filmstrip
- active preview
- photo review controls
- Original/AI Enhance segmented choice
- scanner capture loop
- analysis progress surface
- scanner result handoff composition

No C candidate is promoted by this sprint.

## 26. First-viewport strategy

Idle hub remains S01 unless runtime testing reveals a genuine Sprint 05 defect.

Active Scanner first viewport must show: active camera/preview, next capture guidance, inspectable image count/filmstrip, selected image cue, and one obvious next action. It should not put a large card above the camera or bury captured images below the fold.

Every first-viewport element must either help the user capture, review, select, analyze, or recover from a genuine state.

## 27. Camera-region strategy

The camera region must be stable, full-width, safe-area aware, and resource honest. It should show live camera only from `CameraCapturePage` when `CameraController` is initialized. Empty/placeholder preview in scanner workspace must not pretend to be a live camera.

The camera region must survive initialization, capture-in-progress, permission, and unavailable states without blank or route-locked frames.

## 28. Filmstrip strategy

The filmstrip must bind to `ScannerState.captureImages` and preserve ordering. It must remain visible/inspectable for multiple images, provide selected state independent of color, expose role/source/enhancement where useful, and support selection without changing underlying image data.

It must not hide older images, shrink to unusable thumbnails, or rebuild full-resolution images unnecessarily.

## 29. Active-preview strategy

The active preview must resolve from `selectedImagePath` and `_activeScanSlot` semantics. It should show the active image at useful size, support broken/missing image presentation honestly, and not infer enhancement state unless `ScannerPhotoSlot.isEnhanced` is true.

## 30. Guidance strategy

Guidance should come from `ScanCapturePlan.userGuidance` and `nextRecommendedRole`, plus current permission/error state. It must be brief and actionable: what to capture next, whether analysis is available, and what failed.

Do not display internal confidence target/delta/readiness metadata as user-facing guidance.

## 31. Primary-action strategy

There must be one dominant action per state:

- idle hub: Take a photo
- live camera: capture shutter
- captured workspace with required photo ready: Analyze
- adding optional photo: Capture next/Add photo as secondary
- analyzing: no duplicate analyzer trigger
- result: Add to Portfolio or saved/View Portfolio

Analyze must be separated from shutter enough to avoid accidental activation.

## 32. Review strategy

Review must preserve full image, retake, cancel, Original, AI Enhance, and Use Photo. Existing tap-to-zoom support should be preserved if present; no new compare/sliders/use-anyway pattern is approved. Retake must use the current camera/gallery contract and must not orphan the original image state.

## 33. Confirmation strategy

Confirmation copy must distinguish Original and AI Enhance without implying enhancement has happened before it has. Selection state must be semantically announced. Use Photo returns `ImageEnhancementPreviewResult` with original image, active image, preset, metadata, and assessment.

## 34. Analysis-state strategy

Analysis state may show honest progress copy and motion while `isLoading` is true for analyzer work. It must preserve images, disable duplicate analysis triggers, and show safe recoverable errors when analysis fails.

No fake progress percentages, fake readiness/confidence, fake pricing, fake backend status, speculative provider names, or artificial analysis delay is allowed.

## 35. Responsive rules

Validate narrow Android phone, typical phone, large phone, portrait, display cutout, gesture navigation inset, three-button navigation inset, and large text. Landscape remains supported only where current contracts already support it.

Shutter and primary action must stay reachable. Filmstrip must remain visible. Text may wrap but not overlap controls. No control may sit behind system navigation.

## 36. Accessibility rules

Scanner controls need button semantics, labels, selected state, disabled state, and logical order. Announce active image, image count, image role, capture in progress, analysis in progress, errors, and saved state. Decorative grids/overlays/flash effects must be excluded from semantics. Touch targets must meet minimum size, and color must not be the only selected-state cue.

## 37. Motion and reduced-motion rules

Motion may clarify capture feedback, selection, or analysis state, but state must not depend on animation. Existing `PackLoxMotionTheme` and motion widgets must be respected. Reduced-motion mode should disable or shorten nonessential repeats, especially scan waves, flash/suggestion effects, and entry animations.

No timers may create artificial capture or analysis latency.

## 38. Camera/performance budget

Camera initialization must not repeat on every minor rebuild. Camera resources must dispose on close, capture review, app pause, and off-tab disposal. Scanner must not keep camera active while off-tab under frozen App Shell active-destination-only lifecycle.

Repeated capture taps must be locked by `_isCapturing` and `_isPickerActive`. Image cache clearing before external picker must remain. Full-resolution images should not be retained in multiple widget layers. Filmstrip thumbnails should avoid forcing expensive full-size rebuilds where feasible.

## 39. Allowed files

Allowed for specification commit:

- `qa/reconstruction/sprint_05_scanner_specification.md`

Potentially allowed after spec commit, subject to smallest safe implementation:

- `lib/features/scanner/presentation/pages/scanner_screen.dart`
- `lib/features/scanner/presentation/pages/camera_capture_page.dart`
- `lib/features/scanner/presentation/pages/image_enhancement_preview_page.dart`
- `lib/features/scanner/presentation/pages/scan_workspace_screen.dart`
- `lib/features/scanner/presentation/pages/scan_result_screen.dart`
- `lib/features/scanner/presentation/widgets/camera_overlay.dart`
- `lib/features/scanner/presentation/widgets/capture_suggestions.dart`
- `lib/features/scanner/presentation/widgets/enhance_button.dart`
- `lib/features/scanner/presentation/widgets/exposure_slider.dart`
- `lib/features/scanner/presentation/widgets/analyze_animation.dart`
- `lib/features/scanner/presentation/widgets/capture_workspace.dart`, only if runtime reachability or test migration justifies it
- focused scanner tests under `test/`
- runtime evidence under `qa/screenshots/reconstruction/sprint_05_scanner/`
- `qa/reconstruction/sprint_05_runtime_comparison.md`

`scan_hub_page.dart` and `scan_hub_presentation.dart` are allowed only for a genuine Sprint 05 defect, because S01 is already the validated hub baseline.

## 40. Prohibited files

Prohibited unless separately approved:

- scanner engine/domain/data contract rewrites
- `lib/features/scanner/domain/**`
- `lib/features/scanner/services/**`, except no-op import cleanup forced by presentation compile errors
- analyzer providers/models/services
- backend, Supabase, cloud, feature flags, API constants, native config, signing, schema/migrations
- portfolio repository/controller/screen/detail reconstruction
- authentication, auth guards, onboarding, bootstrap, App Shell lifecycle, Home, Settings, router migration
- original dirty worktree `C:\Users\hario\Desktop\projects\collectiq_ai`

## 41. Test plan

Run baseline and focused validation:

- `flutter analyze`
- Sprint 01 bootstrap tests
- Sprint 02 onboarding tests
- Sprint 03 App Shell tests
- Sprint 04 Home tests
- `test/scan_hub_page_test.dart`
- `test/camera_capture_page_test.dart`
- `test/scanner_widgets_test.dart`
- `test/scanner_volume_03_structure_test.dart`
- `test/scan_image_processing_service_test.dart`
- `test/smart_scan_guidance_service_test.dart`
- analyzer and portfolio handoff tests touched by scanner expectations
- full suite with the 19-failure baseline debt separated

Focused coverage must include: Scan renders in frozen App Shell; camera-ready and permission-denied states; capture invokes controller once; rapid capture taps do not duplicate capture; captured images appear in filmstrip; multiple images remain visible; thumbnail selection updates active preview; delete removes only selected image; retake follows contract; primary image persists; gallery import follows contract; review displays images; Original and AI Enhance work; unenhanced image is not falsely labelled enhanced; analysis trigger uses controller; analysis progress renders; success/failure preserve handoffs; analyzer payload retains all intended images; portfolio handoff retains gallery images; scanner deactivation stops camera where testable; no auth gate/router change; light/dark/large-text/narrow/reduced-motion; no artificial delays; no fabricated readiness/confidence.

## 42. Runtime evidence plan

Device: Samsung SM E625F, Android 13 / API 33, device id `RZ8R213M8ZL`.

Evidence directory:

- `qa/screenshots/reconstruction/sprint_05_scanner/`

Required runtime flow: ADB device authorization, Flutter device discovery, Android local debug build, install, launch, Scanner entry from frozen Home and App Shell, camera initialization, permission handling where safely available, first capture, repeated capture, multi-image filmstrip, active preview, thumbnail selection, delete, retake, primary image, gallery import, full-screen review, Original, AI Enhance, analysis trigger/progress/success/failure where safely reproducible, result handoff, portfolio gallery handoff, leave/return Scanner, Home <-> Scanner, Portfolio <-> Scanner, app background/foreground, rapid tab switching, no blank frame, no route/input lock, no ANR, no camera leak, no frozen sprint regression.

Capture Android logs during camera and tab-switch stress. Create `qa/reconstruction/sprint_05_runtime_comparison.md`. Do not fabricate unavailable states.

## 43. Rollback boundary

Rollback is limited to Sprint 05 scanner presentation files, focused scanner tests, this specification, runtime comparison, runtime evidence, and any scanner-specific presentation-state test updates.

Rollback must not require data migration, backend rollback, analyzer rollback, portfolio rollback, auth rollback, router rollback, App Shell rollback, Home rollback, or frozen Sprint 01-04 rollback.

## 44. Explicit non-goals

- no Scanner engine rewrite
- no analyzer contract change
- no backend change
- no Supabase change
- no Portfolio reconstruction
- no Detail reconstruction
- no Settings reconstruction
- no Authentication redesign
- no auth guard
- no router migration
- no App Shell redesign
- no Home redesign
- no Onboarding redesign
- no Bootstrap redesign
- no portfolio repository/controller rewrite
- no camera service rewrite
- no capture-plan logic rewrite
- no capture-session state rewrite
- no multi-image truncation
- no image-role mutation
- no active-preview ownership change
- no primary-image ownership change
- no artificial capture delay
- no artificial analysis delay
- no fabricated readiness values
- no fabricated confidence values
- no fabricated pricing state
- no fabricated analysis state
- no speculative 3D or photogrammetry implementation
- no automatic Capture System promotion
- no push
- no merge
- no Sprint 06 work
