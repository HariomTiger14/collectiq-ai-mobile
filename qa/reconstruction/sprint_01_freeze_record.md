# Sprint 01 freeze record

## Sprint identity

Sprint: App Bootstrap and Entry Routing Presentation

Branch: `rebuild/product-language-v1`

Freeze date: 2026-07-13

Freeze HEAD: `0f5c93c39abdc747770205ff0eb51715d602b34e`

## Approved scope

Sprint 01 reconstructed only the visible presentation around application bootstrap and onboarding-state resolution. It did not redesign onboarding, change authentication, add an auth guard, migrate routing, redesign the App Shell, change Home, or touch backend/startup-service ownership.

## Final commit chain

- `500184f` docs: specify bootstrap and entry reconstruction sprint
- `6fedbd5` feat: reconstruct bootstrap and entry presentation
- `bcd3e07` test: validate bootstrap and entry state transitions
- `0f5c93c` chore: add bootstrap reconstruction runtime evidence

## Architecture approval

Architecture is approved. `MaterialApp(home: AppShell)` remains in place. `onboardingControllerProvider` remains the entry decision owner. `AppShell` still participates in onboarding entry resolution and post-onboarding shell presentation for Sprint 01.

Future consideration, not a defect: during the dedicated App Shell reconstruction sprint, evaluate whether responsibility should be separated into:

`PackLoxEntryGate` -> onboarding state resolution and destination selection

`AppShell` -> post-onboarding tab/navigation shell only

Do not perform that refactor before its own approved sprint.

## Runtime approval

Runtime behaviour is approved. First-run users enter the existing `OnboardingScreen`; returning users enter the existing `AppShell` with Home selected; guest and signed-out users retain local access.

No artificial delay, timer, debug pause, duplicate route push, duplicate startup initialization, or authentication gate was introduced.

## Product Language approval

Product Language compliance is approved. Sprint 01 uses existing foundations and approved primitives: `AppTheme`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppElevation`, `PackLoxTokens`, and `PackLoxButton`.

## Visual approval

Visual evidence is approved with a documented transient-state evidence limitation.

The bootstrap state is transient and resolves too quickly on the physical Samsung device for reliable static capture. No artificial delay was added. Static screenshots cover reachable destination states and theme presentation. Transition behaviour was validated through direct runtime observation and focused widget tests. The inability to create a stable loading screenshot is accepted because preserving honest startup speed has higher priority than manufacturing evidence.

## Preserved runtime contracts

- `main()`
- environment selection and feature flags
- `CloudServiceRegistry`
- `CloudAppStartup`
- Supabase initialization behaviour
- `ProviderScope`
- `AuthDeepLinkCoordinator`
- onboarding controller ownership
- `SharedPreferences` key `onboarding_completed_v1`
- existing `OnboardingScreen` completion callbacks
- current `AppShell` handoff
- guest and signed-out local access
- PackLox HTTPS password-recovery flow

## Components created or reused

Created:

- `PackLoxBootstrapSurface`
- `PackLoxEntryTransition`

Reused:

- `AppTheme`
- `AppTextStyles`
- `AppSpacing`
- `AppRadius`
- `AppElevation`
- `PackLoxTokens`
- `PackLoxButton`

## Tests and validation

- Sprint 01 focused tests: 12 passed
- Preserved focused regression set: 30 passed
- Full suite: 509 passed, 19 failed
- `flutter analyze`: passed
- `git diff --check`: passed

The full-suite failures are outside Sprint 01 changed files and are not resolved by this freeze. Do not describe the full test suite as passing.

## Runtime device evidence

Device evidence was captured on Samsung `SM E625F`, Android 13, device id `RZ8R213M8ZL`.

Evidence paths:

- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/first_run_onboarding_awake.png`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/first_run_onboarding_awake.xml`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/onboarding_actions.png`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/onboarding_actions.xml`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/returning_user_home.png`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/returning_user_home.xml`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/returning_launch_home.png`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/returning_launch_home.xml`

## Known limitations

- No stable physical-device bootstrap screenshot exists because the real loading state resolves too quickly.
- Dark mode, large text, and reduced motion were validated by focused widget tests instead of changing the connected device's global settings.
- Full-suite baseline has unrelated failures documented in `full_test_suite_baseline_debt.md`.

## Explicitly excluded work

- authentication redesign
- auth guard introduction
- router migration
- App Shell redesign
- Home redesign
- onboarding content redesign
- backend changes
- analyzer changes
- scanner engine changes
- portfolio logic changes
- native deep-link changes
- artificial startup delay

## Rollback boundary

Rollback is limited to the Sprint 01 specification, `PackLoxBootstrapSurface`, `PackLoxEntryTransition`, the `AppShell` entry-presentation integration, focused tests, runtime comparison, runtime evidence, and this freeze governance record.

No data migrations, service ownership changes, auth changes, backend changes, routing changes, or native configuration changes are part of the rollback boundary.

## Freeze declaration

Sprint 01 is frozen as App Bootstrap and Entry Routing Presentation. It is approved for architecture, runtime behaviour, Product Language compliance, visual evidence with the documented transient-state limitation, and overall freeze.
