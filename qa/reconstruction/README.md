# PackLox frontend reconstruction baseline

Status: audit complete; implementation not started. Baselines: Flutter `c6bf0808360fbe58363737f212b842bc60ab0d05`, Product Language `PLX-PL-1.0` / `2995e1aae77eaee241e09eeb41625516eb61ff4f`.

This directory is the execution control set for a presentation-only reconstruction. Preserve business logic and route contracts; require runtime visual approval before freeze.

Architectural correction: PackLox entry is onboarding-driven, not authentication-driven. Onboarding owns the first runtime decision through `onboarding_completed_v1`; authentication remains an optional account capability and must not become an application-entry guard. Guest and signed-out users retain local access.

Sprint 01 is **App Bootstrap and Entry Routing Presentation**. It preserves startup infrastructure and may only reconstruct visible bootstrap/loading, onboarding-entry transition, recoverable startup error, first-run handoff, and returning-user handoff presentation. Router migration is out of scope unless implementation evidence proves the existing navigation structure prevents safe reconstruction.

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
