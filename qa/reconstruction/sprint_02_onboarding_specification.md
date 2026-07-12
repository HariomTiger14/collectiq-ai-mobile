# Sprint 02 onboarding reconstruction specification

## Scope

Sprint 02 reconstructs only the first-launch onboarding presentation and its direct handoff actions. It does not modify the frozen Sprint 01 bootstrap/entry routing contract, AppShell tab architecture, authentication, backend behavior, or the persisted onboarding key.

## Current-state inspection

### Files and ownership

- `lib/features/onboarding/presentation/onboarding_screen.dart`
  - Previously a single `StatelessWidget` composite screen.
  - Accepted `onStartScanning` and `onExploreDashboard` callbacks from `AppShell`.
  - Owned presentation copy and button layout only.
- `lib/core/navigation/app_shell.dart`
  - Watches `onboardingControllerProvider`.
  - Shows onboarding when completion is `false`.
  - Completes onboarding through `onboardingControllerProvider.notifier.complete()`.
  - Selects Scan after `Start Scanning` and Home after `Explore Dashboard`.
- `lib/features/onboarding/presentation/controllers/onboarding_controller.dart`
  - Preserves `AsyncNotifierProvider<OnboardingController, bool>`.
  - Loads and writes the onboarding repository.
- `lib/features/onboarding/data/repositories/shared_preferences_onboarding_repository.dart`
  - Preserves `SharedPreferencesOnboardingRepository.completedKey`.
  - Preserves key value `onboarding_completed_v1`.

### Previous presentation behavior

- Page/stage count: one scrollable composite screen.
- Content:
  - Hero: `Welcome to PackLox`.
  - Flow explanation: Scan, Analyze, Save, Track.
  - Local-first explanation: guest access, optional cloud sync, privacy note.
- Controls:
  - `Start Scanning`, keyed `onboarding-start-scanning`.
  - `Explore Dashboard`, keyed `onboarding-explore-dashboard`.
  - No Next, Back, Skip, or internal page index.
- Completion:
  - Buttons invoked callbacks supplied by `AppShell`.
  - `AppShell` called `onboardingControllerProvider.notifier.complete()`.
  - Completion persisted once through the repository and then handed off to Scan or Home.
- System back:
  - No onboarding route stack or internal handling.
  - Onboarding was shown inside `MaterialApp(home: AppShell)`.
- Animation/controller ownership:
  - No page controller.
  - No explicit animation ownership in onboarding.
- Orientation/responsiveness:
  - No orientation lock.
  - Single scroll view constrained to 720 px.
- Theme/text scale/semantics:
  - Used Material theme colors plus legacy design-system spacing.
  - Relied mostly on default text/button semantics.
  - No explicit progress semantics.
- Analytics:
  - No analytics calls.
- Assets:
  - No external assets; Material icons only.
- Coupling:
  - Coupled to AppShell only through two completion callbacks.
  - No auth dependency and no account gate.

## Reconstructed presentation contract

- Present a three-stage onboarding journey:
  1. Welcome and guest/local-first promise.
  2. PackLox collection loop: Scan, Analyze, Save, Track.
  3. Local-first trust and final destination choice.
- Use Product Language v1 tokens and approved hero/button vocabulary.
- Keep passive education cards non-interactive rather than using button-semantics entry tiles.
- Add explicit progress text and semantics: `Step X of 3`.
- Add `Next` and `Back` controls for staged education.
- Do not add `Skip`; the previous product behavior did not support a separate skip action.
- Keep existing final action keys:
  - `onboarding-start-scanning`
  - `onboarding-explore-dashboard`
- Gate rapid repeated final taps with an in-widget in-flight latch.
- Keep completion persistence and tab selection in `AppShell`.
- Use reduced-motion behavior by jumping pages when animations are disabled.
- Preserve guest/signed-out access: no login, signup, password, account, auth guard, backend requirement, or permission prompt.
- Preserve system-back behavior at the first stage; on later stages, system back moves back one onboarding stage without completing onboarding.

## Non-goals

- No router migration.
- No AppShell redesign.
- No Home redesign.
- No onboarding repository/controller/key changes.
- No backend dependency.
- No permission prompts.
- No artificial completion delay or timer-based routing.
- No speculative analytics or data collection.

## Required verification

- Focused onboarding presentation/widget tests.
- Existing Sprint 01 bootstrap/entry presentation tests.
- `flutter analyze`.
- Focused onboarding tests and full suite result recorded.
- Runtime evidence recorded under `qa/screenshots/reconstruction/sprint_02_onboarding/` when a device is available.
- Runtime comparison recorded in `qa/reconstruction/sprint_02_runtime_comparison.md`.
