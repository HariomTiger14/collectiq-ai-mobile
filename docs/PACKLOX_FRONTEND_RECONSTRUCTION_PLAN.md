# PackLox frontend reconstruction plan

Authoritative execution controls live in [`qa/reconstruction/README.md`](../qa/reconstruction/README.md).

Baseline: preserve the product engine at Flutter commit `c6bf080`; use Product Language release `PLX-PL-1.0` (`2995e1a`). Reconstruct presentation in runtime dependency order: bootstrap/entry -> onboarding -> shell/shared states -> authentication/account access -> Home -> Scanner S02-S10 (S01 remains the validated reference) -> analysis/results -> portfolio/detail -> search/notifications/settings.

Authentication is not currently an entry gate. First-run onboarding owns entry through `onboarding_completed_v1`; account access lives in Settings. Guest and signed-out users retain local access. The first sprint is therefore bootstrap and entry-routing presentation, not Sign-In and not Scanner S02.

The revised implementation order is:

1. App Bootstrap and Entry Routing
2. Onboarding
3. App Shell
4. Home
5. Scanner
6. Portfolio
7. Detail
8. Search
9. Notifications
10. Settings

Sprint 01 is **App Bootstrap and Entry Routing Presentation** and is **Frozen** at `0f5c93c`. It preserves `main()`, environment selection, feature flags, `CloudServiceRegistry`, `CloudAppStartup`, Supabase initialization behaviour, `ProviderScope`, `AuthDeepLinkCoordinator`, onboarding controller ownership, the `SharedPreferences` key `onboarding_completed_v1`, guest and signed-out local access, password-recovery behaviour, and the current `AppShell` handoff.

Sprint 01 may reconstruct only visible bootstrap/loading presentation, onboarding-entry transition presentation, recoverable startup error presentation, first-run handoff presentation, and returning-user handoff presentation. Router migration is out of scope unless implementation evidence proves the existing navigation structure prevents safe reconstruction.

Sprint 02 is **Onboarding Presentation Reconstruction** and is **Frozen** at `725e895`. It preserves `onboardingControllerProvider`, `AsyncNotifierProvider<OnboardingController, bool>`, `SharedPreferencesOnboardingRepository`, `onboarding_completed_v1`, AppShell-owned completion and handoff, guest/signed-out local access, authentication separation, password-recovery behaviour, and the frozen Sprint 01 bootstrap/entry behaviour.

Sprint 02 reconstructed only onboarding presentation into a three-stage explanatory journey. It did not add an auth guard, login/signup requirement, router migration, backend dependency, AppShell redesign, Home redesign, permission prompt, speculative user-data collection, or artificial onboarding delay.

Sprint 03 is **App Shell Presentation Reconstruction** and is **Frozen** at `a39dddf`. It preserves frozen Sprint 01 bootstrap/entry behaviour, frozen Sprint 02 onboarding completion behaviour, `AppShell` handoff, selected-tab ownership, active-destination-only shell lifecycle, guest access, existing Navigator usage, and business logic.

Sprint 03 reconstructed only the post-onboarding app frame and bottom navigation presentation. It records the shell navigation treatment as a composition of approved Product Language foundation primitives, not as an official standalone Product Language component. It did not add Search or Notifications, did not retain all tab trees, did not introduce an unconditional `IndexedStack`, did not redesign Home, Scanner, Portfolio, or Settings, did not add an auth guard, and did not migrate routing.

Sprint 04 is **Home Presentation Reconstruction** and is **Frozen** at `625b9ca`. It preserves frozen Sprint 01 bootstrap/entry behaviour, frozen Sprint 02 onboarding completion behaviour, frozen Sprint 03 App Shell navigation/lifecycle, selected-tab ownership, Home controller/provider ownership, local-first portfolio data flow, guest access, existing scanner entry action, portfolio links, backend contracts, and business logic.

Sprint 04 reconstructed only Home presentation: approved Header, approved Hero, approved primary Scan action through the Hero action slot and Button System, approved Entry Tiles, collection snapshot, recent real items, honest empty state, valuation note, responsive/accessibility behaviour, and validated Home/App Shell runtime performance. It did not move repository/service ownership into presentation, did not add a Home loading/error/retry contract, did not fabricate data, did not redesign Scanner/Portfolio/Settings/Auth/App Shell, did not add an auth guard, did not change backend contracts, and did not migrate routing.

Sprint 05 is **Scanner Presentation Reconstruction** and is **Frozen** at `5b3c9b4`. It preserves frozen Sprint 01 bootstrap behaviour, frozen Sprint 02 onboarding behaviour, frozen Sprint 03 App Shell navigation and lifecycle, frozen Sprint 04 Home presentation, scanner engine, scanner controllers, capture-plan logic, capture-session state, controller/provider ownership, multi-image data, analyzer contracts, portfolio gallery handoff, category and scan-mode behaviour, image ownership, backend integration, and frozen App Shell lifecycle.

Sprint 05 reconstructed only Scanner presentation and scanner-specific states: Scan Hub, active workspace, capture guidance, multi-image filmstrip, active preview, Original/AI Enhance confirmation presentation, analysis handoff, result handoff, genuine scanner loading/error/permission presentation, and tested Scanner/App Shell runtime behaviour. It removed stale pre-analysis sample-workspace confidence metadata, fixed duplicate same-image lost-picker recovery, did not promote Capture System v1 beyond **C. Candidate awaiting approval**, did not redesign Portfolio/Detail/Settings/Auth/App Shell/Home, did not add an auth guard, did not change backend contracts, and did not migrate routing.

Asset validation capability: **Declared but not implemented.** The asset validator must not be treated as an operational validation gate until it actually inspects asset references, missing files, dimensions, duplication, naming, and release eligibility.

No production UI, backend, Supabase contract, deep-link identifier or storage/schema configuration is authorized by this plan. Each screen uses the screen contract, focused commit and explicit visual freeze gate.

Next sprint: **Portfolio Presentation Reconstruction**. Scope is limited to Portfolio presentation reconstruction: Portfolio header and hierarchy, collection summary, search/filter/sort presentation, portfolio grid/list, primary-image thumbnails, gallery-image indicators, empty collection, no-results state, partial valuation, loading/error states that genuinely exist, item menus/actions, navigation to the existing Detail screen, responsiveness, accessibility, and performance.

Sprint 06 must preserve `portfolioControllerProvider`, repositories and sync, item identity, ordering, sorting/filtering semantics, valuation semantics, multi-image gallery data, primary-image ownership, scanner-to-portfolio handoff, existing Detail navigation, guest/local behaviour, backend/Supabase contracts, and frozen App Shell lifecycle.

Sprint 06 must not include Detail reconstruction, Settings reconstruction, Authentication redesign, Scanner redesign, Home redesign, App Shell redesign, backend changes, or router migration unless separately approved.

Do not begin Sprint 06 until its specification is written and approved.
