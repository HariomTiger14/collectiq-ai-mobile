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

Sprint 01 is **App Bootstrap and Entry Routing Presentation**. It must preserve `main()`, environment selection, feature flags, `CloudServiceRegistry`, `CloudAppStartup`, Supabase initialization behaviour, `ProviderScope`, `AuthDeepLinkCoordinator`, onboarding controller ownership, the `SharedPreferences` key `onboarding_completed_v1`, guest and signed-out local access, password-recovery behaviour, and the current `AppShell` handoff.

Sprint 01 may reconstruct only visible bootstrap/loading presentation, onboarding-entry transition presentation, recoverable startup error presentation, first-run handoff presentation, and returning-user handoff presentation. Router migration is out of scope unless implementation evidence proves the existing navigation structure prevents safe reconstruction.

Asset validation capability: **Declared but not implemented.** The asset validator must not be treated as an operational validation gate until it actually inspects asset references, missing files, dimensions, duplication, naming, and release eligibility.

No production UI, backend, Supabase contract, deep-link identifier or storage/schema configuration is authorized by this plan. Each screen uses the screen contract, focused commit and explicit visual freeze gate.
