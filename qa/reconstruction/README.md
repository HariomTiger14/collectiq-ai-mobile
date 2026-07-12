# PackLox frontend reconstruction baseline

Status: Sprint 01 frozen; Sprint 02 frozen; Sprint 03 frozen. Baselines: Flutter `c6bf0808360fbe58363737f212b842bc60ab0d05`, Product Language `PLX-PL-1.0` / `2995e1aae77eaee241e09eeb41625516eb61ff4f`.

This directory is the execution control set for a presentation-only reconstruction. Preserve business logic and route contracts; require runtime visual approval before freeze.

Architectural correction: PackLox entry is onboarding-driven, not authentication-driven. Onboarding owns the first runtime decision through `onboarding_completed_v1`; authentication remains an optional account capability and must not become an application-entry guard. Guest and signed-out users retain local access.

Sprint 01 is **App Bootstrap and Entry Routing Presentation** and is **Frozen** at `0f5c93c`. It preserves startup infrastructure and reconstructs only visible bootstrap/loading, onboarding-entry transition, recoverable startup error, first-run handoff, and returning-user handoff presentation. Router migration remained out of scope.

Sprint 02 is **Onboarding Presentation Reconstruction** and is **Frozen** at `725e895`. It preserves onboarding completion behaviour, the `onboarding_completed_v1` persistence key, guest/signed-out access, authentication separation, password-recovery behaviour, and the existing AppShell completion handoff. Router migration, authentication redesign, App Shell redesign, Home redesign, backend changes, permission prompts, speculative user-data collection, and artificial onboarding delay remained out of scope.

Sprint 03 is **App Shell Presentation Reconstruction** and is **Frozen** at `a39dddf`. It preserves frozen bootstrap entry behaviour, frozen onboarding completion behaviour, AppShell handoff, selected-tab ownership, active-destination-only shell lifecycle, guest access, existing Navigator usage, and business logic. It reconstructs only the post-onboarding frame and shell-level bottom navigation presentation. Home, Scanner, Portfolio, Settings, authentication redesign, backend changes, router migration, Search, Notifications, and all-tab retained shell lifecycle remained out of scope.

Next sprint: **Home Presentation Reconstruction**. It may own only Home screen presentation: Home visual hierarchy, approved Header and Hero composition, metric and summary presentation, quick actions, insight cards, empty/loading/error states, responsive behaviour, accessibility, motion/reduced-motion handling, and Home-specific runtime performance.

Sprint 04 must preserve frozen bootstrap behaviour, frozen onboarding behaviour, frozen App Shell navigation and lifecycle, selected-tab ownership, Home controllers, Home repositories, Home business logic, guest access, backend contracts, existing scanner entry action, and portfolio links. It must not reconstruct Scanner, Portfolio, Settings, Authentication, or App Shell. It must not include authentication redesign, router migration, backend changes, or shell lifecycle redesign unless a verified Home integration defect requires a minimal correction.

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
- [Full test suite baseline debt](full_test_suite_baseline_debt.md)
