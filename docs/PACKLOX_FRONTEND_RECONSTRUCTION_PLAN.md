# PackLox frontend reconstruction plan

Authoritative execution controls live in [`qa/reconstruction/README.md`](../qa/reconstruction/README.md).

Baseline: preserve the product engine at Flutter commit `c6bf080`; use Product Language release `PLX-PL-1.0` (`2995e1a`). Reconstruct presentation in runtime dependency order: bootstrap/entry -> onboarding -> shell/shared states -> authentication/account access -> Home -> Scanner S02-S10 (S01 remains the validated reference) -> analysis/results -> portfolio/detail -> search/notifications/settings.

Authentication is not currently an entry gate. First-run onboarding owns entry through `onboarding_completed_v1`; account access lives in Settings. Guest and signed-out users retain local access. The first sprint is therefore bootstrap and entry-routing presentation, not Sign-In and not Scanner S02.

The revised implementation order is:

1. App Bootstrap and Entry Routing
2. Onboarding
3. App Shell
4. Authentication and Account Access
5. Home
6. Scanner
7. Portfolio
8. Detail
9. Search
10. Notifications
11. Settings

Sprint 01 is **App Bootstrap and Entry Routing Presentation** and is **Frozen** at `0f5c93c`. It preserves `main()`, environment selection, feature flags, `CloudServiceRegistry`, `CloudAppStartup`, Supabase initialization behaviour, `ProviderScope`, `AuthDeepLinkCoordinator`, onboarding controller ownership, the `SharedPreferences` key `onboarding_completed_v1`, guest and signed-out local access, password-recovery behaviour, and the current `AppShell` handoff.

Sprint 01 may reconstruct only visible bootstrap/loading presentation, onboarding-entry transition presentation, recoverable startup error presentation, first-run handoff presentation, and returning-user handoff presentation. Router migration is out of scope unless implementation evidence proves the existing navigation structure prevents safe reconstruction.

Sprint 02 is **Onboarding Presentation Reconstruction** and is **Frozen** at `725e895`. It preserves `onboardingControllerProvider`, `AsyncNotifierProvider<OnboardingController, bool>`, `SharedPreferencesOnboardingRepository`, `onboarding_completed_v1`, AppShell-owned completion and handoff, guest/signed-out local access, authentication separation, password-recovery behaviour, and the frozen Sprint 01 bootstrap/entry behaviour.

Sprint 02 reconstructed only onboarding presentation into a three-stage explanatory journey. It did not add an auth guard, login/signup requirement, router migration, backend dependency, AppShell redesign, Home redesign, permission prompt, speculative user-data collection, or artificial onboarding delay.

Asset validation capability: **Declared but not implemented.** The asset validator must not be treated as an operational validation gate until it actually inspects asset references, missing files, dimensions, duplication, naming, and release eligibility.

No production UI, backend, Supabase contract, deep-link identifier or storage/schema configuration is authorized by this plan. Each screen uses the screen contract, focused commit and explicit visual freeze gate.

Next sprint: **App Shell Presentation Reconstruction**. Scope is limited to the post-onboarding application frame and shell-level navigation composition: bottom navigation presentation, selected and unselected tab states, safe-area and system-inset handling, shell-level background and surface composition, tab-switch presentation, accessibility semantics, responsive behaviour, and shell performance/retained-state behaviour.

Sprint 03 must preserve frozen bootstrap entry behaviour, frozen onboarding completion behaviour, AppShell handoff, existing selected-tab behaviour, controllers and navigation state, guest access, and business logic. It must not reconstruct the individual contents of Home, Scanner, Portfolio, or Settings. Those screens remain functionally present but visually outside Sprint 03 except for minimal integration required by the shell. Sprint 03 must not include authentication redesign, scanner reconstruction, portfolio reconstruction, backend changes, or router migration unless separately approved through evidence.
