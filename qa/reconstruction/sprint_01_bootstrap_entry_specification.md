# Sprint 01 bootstrap and entry specification

## Scope

Sprint 01 reconstructs only the visible presentation around application startup and onboarding-state resolution. It does not redesign onboarding content, change authentication, add an auth guard, migrate routing, add artificial delay, or rewrite backend/startup services.

## Current runtime behaviour

The entry chain remains `main()` -> environment and feature flags -> `CloudServiceRegistry` -> unawaited `CloudAppStartup` / conditional Supabase initialization -> `ProviderScope` -> `CollectIqApp` -> `AuthDeepLinkCoordinator.start()` -> `MaterialApp(home: AppShell)` -> `onboardingControllerProvider` -> `SharedPreferencesOnboardingRepository.completedKey`.

`onboardingControllerProvider` is an `AsyncNotifierProvider<OnboardingController, bool>`. `OnboardingController.build()` asynchronously calls `OnboardingRepository.hasCompletedOnboarding()`. The concrete repository is `SharedPreferencesOnboardingRepository`, which reads `onboarding_completed_v1` and defaults to `false`.

Resolved states:

- `AsyncValue.loading`: onboarding preference is unresolved.
- `AsyncValue.data(false)`: show the existing `OnboardingScreen`.
- `AsyncValue.data(true)`: show the existing `AppShell` with Home selected by default.
- `AsyncValue.error`: existing runtime exposes a recoverable onboarding-resolution error and previously fell back to Home.

## Preserved behaviour

- `main()`, error hooks, image-picker setup, environment resolution, feature flags, `CloudServiceRegistry`, `CloudAppStartup`, Supabase initialization behaviour, `ProviderScope`, and `AuthDeepLinkCoordinator.start()` remain unchanged.
- Authentication remains separate from entry. Guest and signed-out users retain local access.
- Password recovery remains the PackLox HTTPS web flow.
- The `SharedPreferences` key remains `onboarding_completed_v1`.
- `OnboardingScreen` callbacks still complete onboarding before selecting Scan or Home.
- `MaterialApp(home: AppShell)` remains the routing architecture.

## Presentation ownership

The bootstrap and recoverable error presentation belongs to shared Product Language UI because it is not screen-specific. Entry-state integration belongs to `AppShell`, where the onboarding `AsyncValue` is already watched.

## Allowed files

- `lib/core/ui/product_language/**` for shared presentation primitives.
- `lib/core/navigation/app_shell.dart` for entry-state integration only.
- Focused tests under `test/**`.
- Sprint documentation under `qa/reconstruction/**`.
- Runtime evidence under `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/**` if captured.

## Prohibited files

Do not edit backend, analyzer, Supabase contracts, native deep-link identifiers, repositories, authentication logic, scanner logic, portfolio logic, onboarding content, AppShell tab content, or routing framework files. If those become necessary, stop and document the reason.

## Unresolved-state behaviour

While onboarding state is unresolved, show an honest bootstrap presentation with PackLox identity, a real indeterminate progress indicator, and semantics that say the app is preparing the collection workspace. The presentation must disappear as soon as the provider resolves. There is no fixed-duration splash delay or timer-based navigation.

## Error-state behaviour

If onboarding resolution returns `AsyncValue.error`, show a recoverable bootstrap error surface. The action may retry only by invalidating the existing onboarding provider; it must not alter persistence data, auth state, or startup services. The previous Home fallback remains available through the shell scaffold and bottom navigation structure.

## Transition rules

- Transitions follow provider state only.
- No duplicate route push.
- No named route migration.
- No authentication screen insertion.
- No brief display of AppShell before onboarding.
- No brief display of onboarding before AppShell.
- No retained bootstrap screen after handoff.
- Reduced-motion preferences disable visual cross-fades.

## Reduced motion

When `MediaQuery.disableAnimations` or `MediaQuery.accessibleNavigation` is true, entry-state transitions use zero duration. Otherwise transitions may use a short Product Language transition. Animation must not delay destination selection or continue after handoff.

## Accessibility requirements

- Provide a meaningful semantic startup label.
- Do not announce false progress percentages.
- Maintain contrast in light and dark themes.
- Support large text without overflow.
- Keep progress and error states screen-reader understandable.
- Avoid decorative infinite animation beyond the active loading indicator.

## Test plan

- Unresolved onboarding state shows bootstrap presentation.
- Completed onboarding state shows AppShell.
- Incomplete onboarding state shows existing `OnboardingScreen`.
- Bootstrap does not insert authentication.
- No artificial timer controls destination.
- State resolution does not invoke duplicate startup initialization.
- Reduced-motion path works.
- Bootstrap supports light and dark themes.
- Large text scale does not overflow.
- Retry is covered only for the genuine onboarding `AsyncValue.error` state.
- The onboarding persistence key remains unchanged.
- Existing entry/auth/navigation/cloud tests remain green.

## Runtime evidence plan

Capture evidence under `qa/screenshots/reconstruction/sprint_01_bootstrap_entry/` for bootstrap, onboarding handoff, returning-user shell handoff, light/dark mode, large text and reduced motion where practical, and absence of an auth gate. If device capture is unavailable, record that limitation without fabricating screenshots.

## Rollback boundary

The sprint can be rolled back by reverting the Sprint 01 documentation, the shared bootstrap presentation primitive, the `AppShell` entry integration, focused tests, and any runtime evidence. No data migrations, service ownership changes, auth changes, or routing changes are part of this sprint.
