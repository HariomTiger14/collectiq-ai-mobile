# Sprint 01 runtime comparison

## Product Language composition

Sprint 01 uses a shared `PackLoxBootstrapSurface` composed from existing PackLox Product Language foundations:

- typography from `AppTheme` / `AppTextStyles`
- spacing, radius, and elevation from `AppSpacing`, `AppRadius`, and `AppElevation`
- brand colour and gradient treatment from `PackLoxTokens`
- retry action from the approved `PackLoxButton`

The entry transition remains state-driven by `onboardingControllerProvider`; it does not introduce named routes, auth gates, timers, or startup service calls.

## Runtime result

Samsung device QA used `SM E625F` / Android 13 (`RZ8R213M8ZL`) with the debug prod-flavour build from this worktree.

Captured states:

- first-run onboarding handoff after app-data clear
- onboarding action area with Start Scanning and Explore Dashboard
- immediate Home handoff after Explore Dashboard
- returning launch to Home after force-stop/relaunch

The bootstrap loading state was validated in widget tests. It could not be captured reliably on-device without adding artificial delay, because the onboarding `AsyncNotifier` resolves from local `SharedPreferences` too quickly. No delay was added.

## Differences found

Initial implementation used `AnimatedSwitcher` with the default layout behaviour, which temporarily retained the outgoing bootstrap child. That could obscure follow-up interactions and violated the "no retained bootstrap after handoff" rule.

## Corrections made

`PackLoxEntryTransition` now uses a layout builder that keeps only the current resolved child in layout. This preserves a short fade-in for the active state while preventing the previous bootstrap surface from remaining interactive or visible after handoff. Reduced-motion settings still force zero-duration transitions.

## Remaining limitations

- Physical-device bootstrap screenshot is not captured because the real unresolved state is too brief.
- Dark mode, large text, and reduced motion were validated by widget tests rather than changing global settings on the user's connected device.
- Full Flutter suite still has unrelated analyzer/scanner/portfolio failures outside Sprint 01 changed files.

## Evidence

- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/first_run_onboarding_awake.png`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/first_run_onboarding_awake.xml`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/onboarding_actions.png`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/onboarding_actions.xml`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/returning_user_home.png`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/returning_user_home.xml`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/returning_launch_home.png`
- `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/returning_launch_home.xml`
