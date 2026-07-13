# Core Screen Visual Remediation Program

Date: 2026-07-13
Branch: rebuild/product-language-v1
Scope: coordinated implementation plan only. No production Dart or tests are changed by this document.

## Program Principles

- Approved Design Bible composition controls visual conformance.
- Product Language components are implementation tools, not whole-screen approval.
- Architecture, backend, auth, router, repositories, and business/data freezes remain valid unless a future approved visual change proves a narrow conflict.
- Shared foundation changes must be isolated before screen-specific remediation.
- Every phase ends with focused tests, physical-device evidence, side-by-side comparison, and freeze-amendment notes.

## Phase 0 - Shared Foundations And Contract Clarifications

| Field | Plan |
|---|---|
| Objective | Establish non-behavioural visual foundations and decision gates before screen rewrites. |
| Exact screens/files | Cross-screen docs; likely future files include `lib/core/theme/app_theme.dart`, `lib/core/design_system/design_system.dart`, `lib/core/ui/product_language/product_language_tokens.dart`, `lib/core/ui/product_language/packlox_header.dart` only if configuration support is needed, and screen-local wrappers. |
| Approved authorities | Volumes 02, 03, 06, 07 plus `core_visual_contract_clarifications.md`. |
| Dependencies | None for docs; product answers required before Search tab, notifications, bulk/export/share, Capture System promotion, or new async states. |
| Prohibited changes | No Search tab addition, no Product Language redesign, no backend/router/auth changes, no screen-specific Dart rewrites beyond shared foundations. |
| Test plan | Token/surface assertions, Header rendering smoke tests, sheet/dialog dark-surface checks if wrappers are added, existing App Shell navigation tests. |
| Runtime evidence plan | Shared before/after screenshots for surfaces, sheets/dialogs, safe-area, bottom-nav clearance, and logs under `qa/screenshots/approved_authority_remediation/shared/`. |
| Commit plan | `fix: align shared visual foundations with approved authority`; `test: validate shared visual foundations`; `chore: add shared remediation evidence`; `docs: record phase 0 visual foundation decisions`. |
| Rollback boundary | Revert shared foundation commits only; no screen-specific remediation should depend on unreviewed changes. |
| Acceptance criteria | Clarification list is resolved or explicitly deferred; shared surfaces are dark-board compatible; App Shell behaviour remains unchanged; no full-screen visual freeze is claimed. |

## Phase 1 - Home Authority Alignment

| Field | Plan |
|---|---|
| Objective | Align Home S01-S10 hierarchy, especially S02 empty first viewport, while preserving local-first Home behaviour. |
| Exact screens/files | `lib/features/home/presentation/pages/home_page.dart`, possible Home widget files, focused Home tests. |
| Approved authorities | Volume_02_Home master and S01-S10 crops. |
| Dependencies | Phase 0 surface/spacing rules; decisions on sample action, notifications, loading/offline/sync, and four-tab App Shell exception. |
| Prohibited changes | No scanner engine changes, no portfolio repository changes, no backend/auth/router changes, no App Shell tab-count change unless separately approved. |
| Test plan | Empty Home order, Scan/import/portfolio handoff, populated fixture, no-valuation fixture, accessibility/focus order, first-viewport assertion. |
| Runtime evidence plan | Empty, populated, no-valuation if implemented, full scroll, XML, device metadata, logcat, side-by-side comparisons under `home/`. |
| Commit plan | `fix: align home structure with approved authority`; `fix: align home visual tokens and spacing`; `test: validate approved home visual contract`; `chore: add home remediation evidence`; `docs: amend home visual freeze`. |
| Rollback boundary | Revert Home presentation commits only; keep shared Phase 0 commits unless proven faulty. |
| Acceptance criteria | HVD-001 through HVD-010 closed, accepted, or explicitly deferred; S02 first viewport matches approved hierarchy; callbacks remain stable. |

## Phase 2 - Portfolio Authority Alignment

| Field | Plan |
|---|---|
| Objective | Align Portfolio summary, search/filter/sort, item cards, empty/no-results, and scroll policy against Volume_06. |
| Exact screens/files | `lib/features/portfolio/presentation/portfolio_screen.dart`, `lib/features/portfolio/presentation/widgets/portfolio_widgets.dart`, focused Portfolio tests. |
| Approved authorities | Volume_06_Portfolio master and S01-S10 crops. |
| Dependencies | Phase 0 shared surfaces/sheets; decisions on empty search, favorite/wishlist, gallery count, bulk/export/share states; Home callback stability. |
| Prohibited changes | No Detail reconstruction in this phase, no repository/sync changes, no Search tab addition unless approved. |
| Test plan | Empty order/surface, populated grid fixture, search/no-results, filter/sort, valuation unavailable/zero, scroll entry/return, Detail navigation smoke. |
| Runtime evidence plan | Empty, populated, search active, no-results, sort, filter, post-filter, post-sort, gallery/missing-image/unavailable valuation, XML and comparisons under `portfolio/`. |
| Commit plan | `fix: align portfolio structure with approved authority`; `fix: align portfolio cards and controls with approved authority`; `fix: align portfolio scroll and state presentation`; `test: validate approved portfolio visual contract`; `chore: add portfolio remediation evidence`; `docs: amend portfolio visual freeze`. |
| Rollback boundary | Revert Portfolio presentation commits only; keep local-first data and Detail route handoff. |
| Acceptance criteria | PVD-001 through PVD-012 closed, accepted, or deferred; populated evidence captured; unavailable value no longer reads as confident zero. |

## Phase 3 - Detail Authority Alignment

| Field | Plan |
|---|---|
| Objective | Replace the long-scroll Detail presentation with approved compact Detail states/tabs while preserving Portfolio entry/return and item actions. |
| Exact screens/files | `lib/features/portfolio/presentation/pages/collectible_detail_page.dart`, `lib/features/portfolio/presentation/widgets/portfolio_local_image.dart`, `lib/core/ui/item_details/item_details_ui.dart`, focused Detail/Portfolio tests. |
| Approved authorities | Volume_07_Collectible_Detail master and S01-S10 crops. |
| Dependencies | Phase 0 shared surfaces/dialog policy; Phase 2 valuation and image-card semantics; decisions on tabs, share, missing-image, missing-AI, true zero. |
| Prohibited changes | No Home/Scanner redesign, no backend/router/auth/cloud changes, no destructive-action behaviour weakening. |
| Test plan | Detail tab order, first viewport, gallery switching, gallery review, use-primary, delete safeguards, notes persistence, favorite/share feedback, unavailable/zero valuation, missing image, Portfolio return. |
| Runtime evidence plan | S01-S10 states, gallery review, delete confirmation, unavailable valuation, missing image, XML, logcat, comparisons under `detail/`. |
| Commit plan | `fix: align detail structure with approved authority`; `fix: align detail gallery and valuation presentation`; `fix: align detail metadata and actions`; `test: validate approved detail visual contract`; `chore: add detail remediation evidence`; `docs: amend detail visual freeze`. |
| Rollback boundary | Revert Detail presentation commits only; preserve Portfolio grid/search/filter work. |
| Acceptance criteria | DET-001 through DET-015 closed, accepted, or deferred; Detail no longer uses duplicate generic header or single long-scroll-only structure; action safeguards pass. |

## Phase 4 - Scanner Authority Alignment

| Field | Plan |
|---|---|
| Objective | Align Scanner full flow S01-S10 while preserving controller ownership, camera lifecycle, capture data, analysis, and save handoff. |
| Exact screens/files | `scan_hub_page.dart`, `camera_capture_page.dart`, `image_enhancement_preview_page.dart`, `scan_workspace_screen.dart`, `scan_result_screen.dart`, `capture_workspace.dart`, `analyze_animation.dart`, `camera_overlay.dart`, focused Scanner tests. |
| Approved authorities | Volume_03_Scanner master and S01-S10 crops. |
| Dependencies | Phase 0 Capture System policy; camera-ready evidence; device permission plan; shared image/valuation semantics from Portfolio/Detail where relevant. |
| Prohibited changes | No camera ownership migration, no analyzer contract changes, no fake confidence/readiness, no Portfolio repository changes. |
| Test plan | Scan Hub, camera permission/ready, pause/resume, gallery fallback, review Original/AI Enhance, multi-image workspace, analysis, result, save confirmation, tab return. |
| Runtime evidence plan | S01-S10, camera-ready after permission, review path, multi-image, save confirmation, XML, logcat, comparisons under `scanner/`. |
| Commit plan | `fix: align scanner hub and camera structure with approved authority`; `fix: align scanner filmstrip and review presentation`; `fix: align scanner confirmation and analysis presentation`; `test: validate approved scanner visual contract`; `chore: add scanner remediation evidence`; `docs: amend scanner visual freeze`. |
| Rollback boundary | Revert Scanner presentation commits only; retain Sprint 05 data/lifecycle fixes. |
| Acceptance criteria | SCN-001 through SCN-012 closed, accepted, or deferred; no stale Auto Detect/confidence/readiness returns; camera lifecycle is stable. |

## Phase 5 - Cross-Screen Integration QA

| Field | Plan |
|---|---|
| Objective | Validate that shared foundations and all remediated screens work together before amending visual freezes. |
| Exact screens/files | QA docs, evidence folders, freeze records, no production code unless a verified regression fix is approved. |
| Approved authorities | Volumes 02, 03, 06, 07 and final phase evidence. |
| Dependencies | Phases 0-4 complete or explicitly deferred. |
| Prohibited changes | No new features, no Search/Notifications/Settings implementation, no backend/router/auth changes. |
| Test plan | Focused screen tests, App Shell navigation, full-suite baseline from current `540 passed, 16 failed`, regression triage, accessibility/focus, scroll/inset, logcat crash scan. |
| Runtime evidence plan | Integration before/after comparisons, tab switching, scroll stress, device matrix, logs under `integration/`. |
| Commit plan | `test: validate core visual remediation integration`; `chore: add core visual remediation evidence`; `docs: amend core screen visual freezes`. |
| Rollback boundary | Revert the most recent offending screen/shared commit; do not roll back unrelated stable phases. |
| Acceptance criteria | No Critical/High visual deviations remain unaccepted; full-suite status is recorded honestly; each screen has amended freeze record and physical-device evidence. |
