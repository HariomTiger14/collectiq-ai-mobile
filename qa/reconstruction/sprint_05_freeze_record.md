# Sprint 05 freeze record

## 1. Sprint identity

Sprint: Scanner Presentation Reconstruction

Branch: `rebuild/product-language-v1`

Freeze date: 2026-07-13

Frozen starting HEAD: `d0ad7f8165627cb9757c81776b417789e353079c`

Final Sprint 05 implementation/remediation HEAD before this governance commit: `5b3c9b42aea0675923c1c8ad06401573488ebe48`

This freeze-governance commit records the approval decision and does not alter production Dart or test source.

## 2. Complete Sprint commit chain

Sprint 05 commits:

- `42aa7a8` docs: specify scanner reconstruction sprint
- `350fc51` feat: reconstruct scanner presentation
- `ec9aa7d` test: validate scanner presentation and lifecycle
- `1673c74` fix: remove stale scanner workspace confidence
- `5dc94c1` chore: add scanner reconstruction runtime evidence
- `989f455` fix: resolve scanner reconstruction regressions
- `5b3c9b4` test: reconcile sprint 05 full-suite baseline

## 3. Approved scope

Sprint 05 reconstructed only Scanner presentation and scanner-specific presentation states.

Approved ownership:

- idle Scan hub entry;
- active scanner workspace;
- capture guidance;
- multi-image filmstrip;
- active preview;
- Original and AI Enhance confirmation presentation;
- analysis handoff presentation;
- result handoff presentation;
- genuine scanner loading, permission, and error presentation;
- scanner responsive, accessibility, motion, and lifecycle-safe presentation for tested paths.

Sprint 05 did not reconstruct Portfolio, Detail, Settings, Authentication, App Shell, Home, backend services, Supabase contracts, analyzer providers, routing, or frozen Sprint 01-04 behaviour.

## 4. Canonical Scanner architecture

Final Scanner architecture is approved.

Canonical runtime owners:

- `ScanHubPage` remains the canonical idle scanner entry.
- `ScannerScreen` remains the canonical active flow owner.
- `CameraCapturePage` remains camera-capture presentation and permission/lifecycle UI.
- `ImageEnhancementPreviewPage` remains Original/AI Enhance confirmation.
- `ScanWorkspaceScreen` remains workspace and review presentation.
- `ScanResultScreen` remains analysis-result handoff presentation.

Controller and service ownership remain outside rebuilt presentation components.

## 5. Canonical runtime journey

Canonical tested journey:

1. Frozen Home or frozen App Shell selects Scan.
2. `ScanHubPage` renders the approved idle entry.
3. Camera/gallery/sample actions transition into active scanner flow.
4. Accepted image state enters `ScannerState.captureImages`, `selectedImagePath`, and scan session records.
5. Workspace shows active preview, inspectable filmstrip, guidance, and one clear Analyze action.
6. Analysis runs only through `ScannerController.analyzeWithAi()`.
7. Result handoff renders `ScanResultScreen`.
8. Save-to-portfolio remains owned by the existing controller/repository path.
9. Leaving and returning through frozen App Shell keeps Scanner within the tested active-destination lifecycle.

## 6. Controller and provider ownership

`scannerControllerProvider` remains the scanner workflow owner. Presentation may call public controller methods and read state, but it does not duplicate scanner state machines.

Final state ownership:

- `ScannerState.captureImages` is the ordered multi-image authority.
- `selectedImagePath` is the active-preview authority.
- `primaryImagePath` is the primary-image intent.
- `photoSlots` stores the latest slot by role and does not replace the ordered list.
- Analyzer payload preserves intended non-sample images.
- Portfolio handoff preserves intended gallery images.
- Camera/controller ownership remains outside new presentation components.

Preserved providers include scanner services, analyzer services, portfolio controller, subscription state, cloud registry, and `appShellTabControllerProvider`.

## 7. Camera lifecycle ownership

Camera lifecycle ownership is approved for tested paths.

`CameraCapturePage` owns camera permission request, camera initialization, live preview, capture locking, flash/flip/gallery controls, capture review, pause/resume handling, and disposal.

`CameraService` owns camera discovery, controller operations, capture, external picker lost-data retrieval, picker cache cleanup, and image persistence helpers.

`ScannerScreen` may observe lifecycle for lost-picker recovery only. It does not retain camera resources off tab.

## 8. Multi-image, active-preview, and primary-image contracts

Multi-image contract:

- accepted images append to `ScannerState.captureImages`;
- ordering is preserved;
- filmstrip/gallery presentation remains inspectable;
- analyzer requests include all intended non-sample captured images with role/source metadata;
- no presentation layer may collapse the ordered list into only the newest image.

Active-preview contract:

- `selectedImagePath` owns the active preview;
- selecting a captured photo updates active role, image, path, title, and status;
- visual selected state must not rely on color alone.

Primary-image contract:

- `primaryImagePath` owns primary-image intent;
- primary fallback ordering remains controller-owned;
- portfolio handoff uses result gallery primary, first gallery image, front slot, or result thumbnail according to existing rules.

## 9. Original and AI Enhance contract

Original maps to `ImageEnhancementPreset.original`, `selectedEnhancement: original`, and `enhanced: false`.

AI Enhance maps to `ImageEnhancementPreset.autoEnhance`, `selectedEnhancement: aiEnhance`, and `enhanced: true`.

Sprint 05 preserved the confirmation page contract: full image, cancel, retake, Original, AI Enhance, and Use Photo. It did not add sliders, fake compare modes, readiness scores, warning clutter, or a Use Anyway action.

## 10. Analyzer, result, and portfolio handoff

Analyzer handoff:

- `analyzeWithAi()` remains the only analysis trigger.
- It preserves active image path, selected image, non-sample captured images, roles, sources, image count, enhancement metadata, quality metadata, scan goal, and session metadata.
- Backend endpoint, provider factory, pricing, enrichment, Supabase, and analyzer contracts were unchanged.

Result handoff:

- Analyzer output maps through the existing analysis/enrichment path into `ScanResult`.
- `ScanResultScreen` receives the result, active slot, save flags, scan-another callback, and optional portfolio callback.

Portfolio handoff:

- `saveScanResultToPortfolio()` remains the owner of `CollectibleItem` construction.
- Primary and gallery images are preserved through existing result/gallery/slot fallback rules.
- Portfolio repository, controller, sync, and Detail navigation were not reconstructed.

## 11. Permission and error presentation

Permission presentation remains owned by `CameraCapturePage` and `CameraService`.

Recoverable scanner states remain honest and controller-backed: permission denied, permanently denied permission with settings path, camera initialization failure, capture failure, gallery cancellation, unsupported or missing image, quality warning/blocker, enhancement cancellation, analysis not ready, subscription/usage failure, analyzer failure, network/backend unavailable, and save failure.

No retry button, fake loading state, fake backend status, or speculative recovery path was added where the controller/service contract does not support it.

## 12. Capture System classification and Product Language mapping

Capture System v1 status: **C. Candidate awaiting approval**.

Sprint 05 did not promote Capture System v1. Scanner used frozen Product Language components and approved primitives where applicable. Scanner-specific reusable treatments remain candidates.

Product Language mapping:

- A. Existing approved components: `PackLoxHeader`, `PackLoxHero`, `PackLoxEntryTile`, and `PackLoxButton` on the idle hub and standard actions.
- B. Composition of approved primitives: scanner workspace scaffold, guidance, honest status/error strips, selected image treatments, result handoff clarifications, safe-area layouts, responsive spacing, semantics, and motion.
- C. Candidate treatments: capture shutter, camera toolbar, camera permission family, camera guidance panel, filmstrip, active preview, photo review controls, Original/AI Enhance segmented choice, scanner capture loop, analysis progress surface, and scanner result handoff composition.

No C candidate is promoted or frozen by this sprint.

## 13. Product-honesty correction

Sprint 05 removed stale sample-workspace metadata:

- `Auto Detect`
- `Confidence`
- `55%`

The metadata appeared before analysis, was not backed by completed analyzer output, and was misleading presentation metadata. It was removed as a presentation-honesty correction.

Analyzer contracts were unchanged. Genuine post-analysis metadata remains supported where real analyzer output exists. No readiness/confidence model was restored during remediation. Stale confidence/readiness UI remains removed.

## 14. Lost-picker duplicate recovery fix

During test regression remediation, duplicate lost-picker recovery could append the same recovered image twice when Scan hub startup and Scanner screen startup both recovered the same persisted image.

Fix:

- implemented in `lib/features/scanner/presentation/controllers/scanner_controller.dart`;
- de-duplicates same-path recovered images;
- preserves ordered `captureImages`;
- preserves `selectedImagePath` and `primaryImagePath` contracts;
- keeps lost-picker recovery navigation on the Scan tab;
- changes no camera, analyzer, backend, or portfolio contract.

Classification: Scanner state-integrity correction.

## 15. Regression-safety approval

Regression safety is approved.

Reference: `qa/reconstruction/sprint_05_test_regression_analysis.md`.

The eight broad widget failures reconciled against actual Sprint 05 contracts were:

- `scanner camera capture shows preview`
- `scanner slot updates after captured front image`
- `camera return shows preparing image bridge before preview`
- `lost Android camera data recovers to Scan tab`
- `scanner sample scan shows fake AI result`
- `camera completion remains on Scan tab`
- `gallery completion from Home CTA remains on Scan tab`
- `home scan CTA starts clean after unsaved scan`

One genuine production defect was found: duplicate lost-picker recovery. The remaining target failures were stale presentation expectations. Updated assertions use stable state, semantic, and key contracts. No frozen Sprint contract was weakened, and stale confidence/readiness presentation was not restored.

Full-suite history:

- Sprint 04 remediated: 531 passed, 19 failed.
- Sprint 05 pre-remediation: 526 passed, 24 failed.
- Sprint 05 remediated: 534 passed, 16 failed.

The full suite must not be described as entirely passing.

## 16. Performance approval

Performance is approved for the tested Scanner/App Shell sequence.

Runtime evidence covered Scan entry, Scan hub, sample workspace, analysis result, tab switching, scrolling/stress, return to Scanner, and Android log capture. No fatal app crash signatures were found in the captured logs.

This record does not claim all possible camera, lifecycle, gallery, or background/foreground risk is permanently eliminated. Approval is limited to the tested paths.

## 17. Visual and runtime approval

Visual fidelity and runtime behaviour are approved from Samsung physical-device evidence.

Runtime comparison: `qa/reconstruction/sprint_05_runtime_comparison.md`

Evidence directory: `qa/screenshots/reconstruction/sprint_05_scanner/`

Device:

- Samsung SM E625F
- Android 13 / API 33
- Device ID `RZ8R213M8ZL`
- Package `com.collectiq.ai.local`

Physically evidenced paths:

- Scanner entry from Home/App Shell;
- Scan Hub;
- sample workspace;
- corrected `CaptureWorkspace`;
- capture/filmstrip presentation;
- selected image state;
- analysis trigger;
- analysis result;
- tab switching;
- scrolling/stress;
- return to Scanner;
- Android log scan;
- no `FATAL EXCEPTION`, no `E AndroidRuntime`, and no app crash stanza in focused log scan.

Do not claim physically verified states that were not reproduced.

## 18. Android device evidence and log findings

Evidence files include:

- `09_fresh_home_after_onboarding.png`
- `10_fresh_scan_hub.png`
- `11_fresh_sample_workspace.png`
- `11_fresh_sample_workspace.xml`
- `12_fresh_analysis_result.png`
- `13_fresh_tab_scroll_stress.png`
- `14_fresh_runtime_logcat.txt`

Android log findings:

- no fatal app crash signatures;
- scanner flow logs showed sample workspace build and analysis result transitions;
- no observed route lock, input lock, or blank final scanner frame in the tested sequence.

## 19. Accessibility and responsive approval

Accessibility and responsive behaviour are approved for freeze based on combined source tracing, focused widget tests, and default-device runtime evidence.

Evidence supports:

- semantic/key-based scanner actions in tests;
- selected image and tab-state contracts;
- narrow/default Android portrait runtime;
- scroll stress and tab switching on the connected Samsung device.

Physical evidence does not cover every accessibility and device variant listed in the specification.

## 20. Tests and validation

Focused validation:

- eight target tests individually passed;
- eight target tests together passed;
- focused Scanner suite: 51 passed;
- frozen Sprint 01-04 suite: 45 passed;
- `flutter analyze`: passed.

Full-suite validation:

- Sprint 05 remediated full suite: 534 passed, 16 failed.

The remaining 16 failures are documented baseline debt and remain outside Sprint 05 freeze governance.

## 21. Known limitations

Physical evidence:

- default Samsung SM E625F portrait runtime;
- Scan hub;
- sample workspace;
- analysis result;
- tab switch and scroll stress;
- Android log scan.

Widget-test evidence:

- camera return and preparing bridge;
- lost Android data recovery to Scan tab;
- camera and gallery completion tab retention;
- sample scan result flow;
- Home CTA clean scanner start;
- multi-image and widget-level scanner behaviours covered by focused scanner tests.

Source tracing:

- controller/provider ownership;
- analyzer payload ownership;
- portfolio handoff ownership;
- primary-image fallback;
- camera lifecycle ownership.

Not physically verified in this freeze:

- real camera permission denial;
- permanently denied permission;
- real multi-photo capture;
- retake;
- primary-image selection;
- gallery import;
- lost-picker recovery on physical device;
- AI Enhance processing;
- analysis failure/timeout;
- portfolio gallery handoff;
- background/foreground lifecycle;
- dark mode;
- large text;
- reduced motion;
- landscape.

These scenarios must not be described as physically reproduced.

## 22. Explicitly excluded work

Explicitly excluded:

- Portfolio reconstruction;
- Detail reconstruction;
- Settings reconstruction;
- Authentication redesign;
- Scanner redesign beyond Sprint 05 approved scope;
- Home redesign;
- App Shell redesign;
- backend changes;
- Supabase changes;
- analyzer provider/backend contract changes;
- router migration;
- auth guard;
- Capture System promotion;
- fabricated readiness/confidence/pricing states;
- Sprint 06 implementation.

## 23. Rollback boundary

Rollback is limited to:

- Sprint 05 specification;
- scanner presentation files changed by Sprint 05;
- focused scanner tests and broad scanner expectation reconciliation;
- stale-confidence presentation correction;
- lost-picker duplicate recovery fix;
- Sprint 05 runtime comparison;
- Sprint 05 runtime evidence;
- Sprint 05 regression analysis;
- full-suite baseline history;
- this freeze record.

Rollback does not require data migration, backend rollback, analyzer rollback, portfolio repository rollback, Supabase rollback, auth rollback, router rollback, App Shell rollback, Home rollback, or frozen Sprint 01-04 rollback.

## 24. Sprint 06 boundary

Next sprint: Portfolio Presentation Reconstruction.

Sprint 06 may own only Portfolio presentation:

- Portfolio header and hierarchy;
- collection summary;
- search, filter, and sort presentation;
- portfolio grid/list;
- primary-image thumbnails;
- gallery-image indicators;
- empty collection;
- no-results state;
- partial valuation;
- existing loading/error states that genuinely exist;
- item menus/actions;
- navigation to existing Detail screen;
- responsiveness;
- accessibility;
- performance.

Sprint 06 must preserve:

- `portfolioControllerProvider`;
- repositories and sync;
- item identity;
- ordering;
- sorting/filtering semantics;
- valuation semantics;
- multi-image gallery data;
- primary-image ownership;
- scanner-to-portfolio handoff;
- existing Detail navigation;
- guest/local behaviour;
- backend/Supabase contracts;
- frozen App Shell lifecycle.

Sprint 06 must not include Detail reconstruction, Settings reconstruction, Authentication redesign, Scanner redesign, Home redesign, App Shell redesign, backend changes, or router migration unless separately approved.

Sprint 06 is not started by this freeze record.

## 25. Freeze declaration

Sprint 05, Scanner Presentation Reconstruction, is frozen at `5b3c9b42aea0675923c1c8ad06401573488ebe48` pending this governance commit.

Approved statuses:

- Architecture: approved.
- Scanner data flow: approved.
- Camera lifecycle: approved for tested paths.
- Product honesty: approved.
- Regression safety: approved.
- Performance: approved for tested Scanner/App Shell sequence.
- Visual fidelity: approved from physical-device evidence.
- Runtime behaviour: approved.
- Accessibility and responsive behaviour: approved for tested/source-traced paths.
- Capture System v1: C. Candidate awaiting approval.
- Overall: frozen.
