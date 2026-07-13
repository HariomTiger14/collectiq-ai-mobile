# PackLox frontend reconstruction baseline

Status: Sprint 01 frozen; Sprint 02 frozen; Sprint 03 frozen; Sprint 04 frozen; Sprint 05 frozen; Sprint 06 frozen. Baselines: Flutter `c6bf0808360fbe58363737f212b842bc60ab0d05`, Product Language `PLX-PL-1.0` / `2995e1aae77eaee241e09eeb41625516eb61ff4f`.

This directory is the execution control set for a presentation-only reconstruction. Preserve business logic and route contracts; require runtime visual approval before freeze.

Architectural correction: PackLox entry is onboarding-driven, not authentication-driven. Onboarding owns the first runtime decision through `onboarding_completed_v1`; authentication remains an optional account capability and must not become an application-entry guard. Guest and signed-out users retain local access.

Sprint 01 is **App Bootstrap and Entry Routing Presentation** and is **Frozen** at `0f5c93c`. It preserves startup infrastructure and reconstructs only visible bootstrap/loading, onboarding-entry transition, recoverable startup error, first-run handoff, and returning-user handoff presentation. Router migration remained out of scope.

Sprint 02 is **Onboarding Presentation Reconstruction** and is **Frozen** at `725e895`. It preserves onboarding completion behaviour, the `onboarding_completed_v1` persistence key, guest/signed-out access, authentication separation, password-recovery behaviour, and the existing AppShell completion handoff. Router migration, authentication redesign, App Shell redesign, Home redesign, backend changes, permission prompts, speculative user-data collection, and artificial onboarding delay remained out of scope.

Sprint 03 is **App Shell Presentation Reconstruction** and is **Frozen** at `a39dddf`. It preserves frozen bootstrap entry behaviour, frozen onboarding completion behaviour, AppShell handoff, selected-tab ownership, active-destination-only shell lifecycle, guest access, existing Navigator usage, and business logic. It reconstructs only the post-onboarding frame and shell-level bottom navigation presentation. Home, Scanner, Portfolio, Settings, authentication redesign, backend changes, router migration, Search, Notifications, and all-tab retained shell lifecycle remained out of scope.

Sprint 04 is **Home Presentation Reconstruction** and is **Frozen** at `625b9ca`. It preserves frozen bootstrap behaviour, frozen onboarding behaviour, frozen App Shell navigation and lifecycle, selected-tab ownership, Home controller/provider ownership, local-first data flow, guest access, existing scanner entry action, portfolio links, backend contracts, and business logic. It reconstructs only Home presentation: approved Header, approved Hero, approved Hero action/Button, approved Entry Tiles, collection snapshot, recent real items, empty state, valuation note, responsive/accessibility behaviour, and validated Home/App Shell runtime performance.

Sprint 05 is **Scanner Presentation Reconstruction** and is **Frozen** at `5b3c9b4`. It preserves frozen bootstrap, frozen onboarding, frozen App Shell navigation/lifecycle, frozen Home presentation, scanner controller/provider ownership, camera lifecycle ownership, capture-session state, analyzer integration, ordered multi-image data, active-preview ownership, primary-image intent, portfolio handoff, backend contracts, capture-plan logic, category and scan-mode behaviour, and existing scanner provider ownership.

Sprint 05 reconstructed only Scanner presentation and scanner-specific presentation states: Scan Hub, active workspace, capture guidance, multi-image filmstrip, active preview, Original/AI Enhance confirmation presentation, analysis handoff, result handoff, and genuine scanner loading/error/permission presentation. It removed stale pre-analysis `Auto Detect` / `Confidence` / `55%` sample-workspace metadata, fixed duplicate lost-picker recovery for the same recovered image, and did not promote Capture System v1 beyond **C. Candidate awaiting approval**.

Sprint 06 is **Portfolio Presentation Reconstruction** and is **Frozen** at `fe66cae`. It preserves frozen bootstrap, frozen onboarding, frozen App Shell navigation/lifecycle, frozen Home presentation, frozen Scanner presentation, `portfolioControllerProvider`, repositories and sync, item identity, ordering, sorting/filtering semantics, valuation semantics, multi-image gallery data, primary-image ownership, scanner-to-portfolio handoff, existing Detail navigation, guest/local behaviour, backend/Supabase contracts, and frozen App Shell lifecycle.

Sprint 06 reconstructed only Portfolio presentation and Portfolio-specific presentation states: compact header, collection summary, search, filter/sort presentation, grid/item cards, primary-image thumbnails, gallery fallback, empty and no-results states, partial valuation cues, item menus/actions, Add Item handoff, existing Detail navigation handoff, responsiveness, accessibility, and runtime performance for tested paths. It did not promote Portfolio candidate treatments into frozen Product Language.

Next sprint proposal: **Detail Presentation Reconstruction**. It may own only the existing Detail screen presentation if separately approved. It must preserve Portfolio item identity, image/gallery data, edit/delete behaviours, notes/favorite actions, repository/controller ownership, scanner handoff data, backend/Supabase contracts, and frozen Sprint 01-06 behaviour.

Asset validation capability: **Declared but not implemented.** Do not count the asset validator as an operational platform gate until it inspects asset references, missing files, dimensions, duplication, naming, and release eligibility.

## Documents

- [Repository baseline](baseline_repository_state.md)
- [Entry trace](app_entry_route_trace.md)
- [Screen inventory](screen_inventory.md)
- [Behavior preservation](behavior_preservation_matrix.md)
- [Presentation classification](presentation_rebuild_matrix.md)
- [Routing audit](route_and_navigation_audit.md)
- [Authentication/onboarding audit](authentication_onboarding_audit.md)
- [Product Language gaps](product_language_gap_analysis.md)
- [Execution order](reconstruction_order.md)
- [Approval gates](visual_approval_gates.md)
- [Git strategy](git_strategy.md)
- [Legacy inventory](legacy_presentation_inventory.md)
- [Screen sprint template](screen_reconstruction_template.md)
- [First sprint](proposed_first_sprint.md)
- [Sprint 01 specification](sprint_01_bootstrap_entry_specification.md)
- [Sprint 01 runtime comparison](sprint_01_runtime_comparison.md)
- [Sprint 01 freeze record](sprint_01_freeze_record.md)
- [Sprint 02 specification](sprint_02_onboarding_specification.md)
- [Sprint 02 runtime comparison](sprint_02_runtime_comparison.md)
- [Sprint 02 freeze record](sprint_02_freeze_record.md)
- [Sprint 03 specification](sprint_03_app_shell_specification.md)
- [Sprint 03 runtime comparison](sprint_03_runtime_comparison.md)
- [Sprint 03 freeze record](sprint_03_freeze_record.md)
- [Sprint 04 specification](sprint_04_home_specification.md)
- [Sprint 04 runtime comparison](sprint_04_runtime_comparison.md)
- [Sprint 04 test regression analysis](sprint_04_test_regression_analysis.md)
- [Sprint 04 device diagnostics](sprint_04_device_diagnostics.md)
- [Sprint 04 freeze record](sprint_04_freeze_record.md)
- [Full test suite baseline debt](full_test_suite_baseline_debt.md)
- [Sprint 05 specification](sprint_05_scanner_specification.md)
- [Sprint 05 runtime comparison](sprint_05_runtime_comparison.md)
- [Sprint 05 test regression analysis](sprint_05_test_regression_analysis.md)
- [Sprint 05 freeze record](sprint_05_freeze_record.md)
- [Sprint 06 specification](sprint_06_portfolio_specification.md)
- [Sprint 06 runtime comparison](sprint_06_runtime_comparison.md)
- [Sprint 06 test regression analysis](sprint_06_test_regression_analysis.md)
- [Sprint 06 freeze record](sprint_06_freeze_record.md)
- [Sprint 07 proposal](sprint_07_detail_proposal.md)
