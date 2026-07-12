# Sprint 02 freeze record

## 1. Sprint identity

Sprint: Onboarding Presentation Reconstruction

Branch: `rebuild/product-language-v1`

Freeze date: 2026-07-13

Starting HEAD: `6f16c59495014309427c1244ec20d8e0f555fd67`

Freeze HEAD before this governance commit: `725e8957a958bb2f6284699794bdb55b6c65eae6`

## 2. Starting and final implementation commits

Sprint 02 implementation commits:

- `a8cc3b8` docs: specify onboarding reconstruction sprint
- `12d440e` feat: reconstruct onboarding presentation
- `e6d846b` test: validate onboarding presentation and completion
- `725e895` chore: add onboarding reconstruction runtime evidence

## 3. Approved scope

Sprint 02 reconstructed only the onboarding presentation and its direct presentation-level handoff controls. It preserved the existing application-entry, onboarding-controller, persistence, and AppShell ownership contracts.

The sprint did not authorize authentication redesign, AppShell redesign, Home redesign, router migration, backend changes, permission prompts, speculative user-data collection, or artificial onboarding delay.

## 4. Original onboarding journey

Before Sprint 02, onboarding was a single scrollable composite screen:

- hero copy: `Welcome to PackLox`
- education section: Scan, Analyze, Save, Track
- local-first section: guest/local use, optional cloud sync, privacy note
- final actions always visible after scrolling:
  - `Start Scanning`
  - `Explore Dashboard`

There was no internal page controller, stage progress, Next, Back, Skip, analytics, permission prompt, or authentication gate.

## 5. Final three-stage onboarding journey

Sprint 02 replaces the single composite scroll screen with a three-stage explanatory presentation:

1. Stage 1: Welcome, guest access, and local-first positioning.
2. Stage 2: Scan / Analyze / Save / Track collection loop.
3. Stage 3: local-first privacy/cloud-optional trust copy and final destination choice.

The final stage keeps the preserved product actions:

- `Start Scanning`
- `Explore Dashboard`

No `Skip` action was added because the prior product behaviour did not include a separate skip flow.

## 6. Architecture approval

Architecture is approved.

Preserved contracts:

- `onboardingControllerProvider`
- `AsyncNotifierProvider<OnboardingController, bool>`
- `SharedPreferencesOnboardingRepository`
- `SharedPreferencesOnboardingRepository.completedKey`
- `onboarding_completed_v1`
- AppShell-owned onboarding completion and handoff
- guest and signed-out local access
- existing authentication behaviour
- existing password recovery behaviour
- frozen Sprint 01 bootstrap and entry-routing behaviour

Not introduced:

- auth guard
- login/signup requirement
- router migration
- backend dependency
- AppShell redesign
- Home redesign
- permission prompt
- speculative user-data collection
- artificial onboarding delay

## 7. Completion and persistence approval

Completion and persistence behaviour is approved.

`OnboardingScreen` remains a presentation component that receives completion callbacks. It does not read or write `SharedPreferences` directly. `AppShell` still invokes `onboardingControllerProvider.notifier.complete()` and then performs the selected destination handoff.

The persistence key remains `onboarding_completed_v1`.

## 8. AppShell handoff approval

AppShell handoff is approved.

The final onboarding actions preserve the existing destinations:

- `Start Scanning` completes onboarding and hands off to Scan.
- `Explore Dashboard` completes onboarding and hands off to Home.

The runtime journey verified the `Explore Dashboard` path from fresh first-run state to Home.

## 9. Product Language approval

Product Language compliance is approved for this sprint.

Reused approved Product Language pieces:

- `PackLoxHero` 1.0.1
- `PackLoxButton` 1.0.0
- `PackLoxTokens`
- shared spacing/radius foundations through `AppSpacing` and `AppRadius`

The onboarding education cards are passive screen-local compositions using approved tokens and foundations. `PackLoxEntryTile` was not reused for those cards because it carries interactive button semantics that would misrepresent passive explanatory content.

### Onboarding progress treatment classification

Classification: **B. A composition of approved Product Language foundation primitives**.

The progress treatment consists of:

- `PackLoxTokens.cyan` for the active indicator
- `PackLoxTokens.border` for inactive indicators and top divider
- `PackLoxTokens.surface` for the control surface
- `PackLoxTokens.textSecondary` for `Step X of 3`
- `AppSpacing` for control spacing
- `AppRadius.pill` for rounded indicator geometry
- Flutter `Semantics` wrapping for progress label/value
- `AnimatedContainer` for a small indicator-width transition, with zero duration when animations are disabled

It is not recorded as an existing approved Product Language component. It is also not promoted into the Product Language by this freeze. It remains a screen-level composition of approved primitives and can be revisited as a candidate reusable progress indicator if later screens need the same treatment.

## 10. Runtime approval

Runtime behaviour is approved.

Directly observed on device:

- fresh first-run state produced by clearing app data
- onboarding Stage 1
- Stage 2 after `Next`
- Stage 3 after `Next`
- `Explore Dashboard` completion action
- handoff to Home

The first APK build attempt failed because the local C: drive had about 0.27 GB free. A project-local `flutter clean` removed generated build artifacts, the APK was rebuilt successfully, and runtime validation proceeded.

## 11. Accessibility and responsive approval

Accessibility and responsive behaviour are approved for freeze based on the combined evidence set.

Direct evidence:

- Android hierarchy XML captured for onboarding Stage 1.
- Runtime screenshots show safe-area treatment and stable bottom action placement on Samsung SM E625F.

Widget-test validation:

- reduced-motion path advances immediately
- light and dark themes render without exceptions
- large narrow text scale does not overflow
- system back returns to the previous onboarding stage after Stage 1
- no authentication copy or Skip action appears on initial onboarding

Unverified on physical device:

- device-level dark mode screenshot
- device-level large-text screenshot
- device-level landscape screenshot
- device-level reduced-motion screenshot

Those states must not be described as physically captured for Sprint 02.

## 12. Components reused and created

Reused:

- `PackLoxHero`
- `PackLoxButton`
- `PackLoxTokens`
- `AppSpacing`
- `AppRadius`
- `onboardingControllerProvider`
- `SharedPreferencesOnboardingRepository`
- AppShell onboarding completion callbacks

Created:

- stage-based `OnboardingScreen` presentation structure
- screen-local passive onboarding cards
- screen-local progress indicator composition
- screen-local one-shot completion latch for rapid final-action taps

No new Product Language component was created or frozen by Sprint 02.

## 13. Tests and validation

Validation results recorded for Sprint 02:

- Sprint 01 bootstrap tests: 12 passed
- Sprint 02 onboarding tests: 10 passed
- `flutter analyze`: passed
- Android local debug build: passed
- full suite: 519 passed, 19 failed

The full suite must not be described as passing.

The failure count did not increase from the Sprint 01 baseline. The ten additional passing tests correspond to the new Sprint 02 onboarding coverage. The existing 19 failures remain outside the Sprint 02 onboarding changes and are recorded as baseline debt.

## 14. Runtime device evidence

Runtime evidence was captured on:

- device: Samsung SM E625F
- Android version: 13 / API 33
- device id: `RZ8R213M8ZL`
- package: `com.collectiq.ai.local`
- build: local debug APK

Evidence directory:

- `qa/screenshots/reconstruction/sprint_02_onboarding/`

Captured files:

- `stage_01_welcome.png`
- `stage_02_flow.png`
- `stage_03_local_first.png`
- `dashboard_handoff.png`
- `stage_01_hierarchy.xml`

Evidence limitations:

- `adb uninstall` returned `DELETE_FAILED_INTERNAL_ERROR`; clean first-run state was created by `adb shell pm clear com.collectiq.ai.local`.
- Light, dark, large-text, landscape, and reduced-motion device screenshots were not captured.
- The Samsung Edge panel handle is visible along the left edge of screenshots and is not part of the app UI.

## 15. Known limitations

- The full test suite still has 19 known failures outside Sprint 02.
- The onboarding progress indicator remains a screen-level composition, not a frozen reusable Product Language component.
- Physical-device evidence covers the default device theme/orientation/text scale only.

## 16. Explicitly excluded work

- authentication redesign
- auth guard introduction
- login/signup requirement
- password recovery redesign
- router migration
- backend changes
- AppShell redesign
- Home redesign
- Scanner reconstruction
- Portfolio reconstruction
- Settings reconstruction
- permission prompts
- speculative user-data collection
- artificial onboarding delay
- Product Language component extraction for progress

## 17. Rollback boundary

Rollback is limited to the Sprint 02 specification, `OnboardingScreen` presentation reconstruction, focused onboarding tests, updated onboarding expectations in existing entry/widget tests, runtime comparison, runtime evidence, and this freeze governance record.

No data migration, repository/controller ownership change, auth behaviour change, password-recovery behaviour change, backend change, router change, AppShell redesign, Home redesign, or native configuration change is part of the Sprint 02 rollback boundary.

## 18. Freeze declaration

Sprint 02 is frozen as Onboarding Presentation Reconstruction.

Approved:

- architecture
- completion and persistence behaviour
- Sprint 01 bootstrap regression safety
- AppShell handoff
- runtime journey
- Product Language compliance
- visual evidence with the documented progress-treatment classification
- full-suite status accepted with the existing 19-failure baseline debt

Sprint 03 may be planned next as App Shell Presentation Reconstruction, but no Sprint 03 implementation is authorized by this freeze record.
