# Sprint 03 app shell reconstruction specification

## 1. Current shell architecture

The app uses `MaterialApp(home: AppShell)` with Riverpod-owned onboarding and selected-tab state. `AppShell` currently owns both entry-state resolution and the post-onboarding tab scaffold.

Current shell file:

- `lib/core/navigation/app_shell.dart`

Current tab-state file:

- `lib/core/navigation/app_shell_controller.dart`

Current bottom navigation file:

- `lib/core/ui/navigation/glass_bottom_nav_bar.dart`

There is no named-route table, GoRouter setup, auth route guard, or shell-level nested navigator.

## 2. Current destination inventory

Primary destinations are exactly:

| Index | Label | Current icon | Widget factory | State owner | Lifecycle/resource sensitivity |
|---:|---|---|---|---|---|
| 0 | Home | `Icons.home_rounded` | `HomeScreen(onScanPressed, onImportPhotoPressed, onPortfolioPressed)` | Home presentation plus portfolio/scanner providers | Scrollable dashboard; should not be retained as an expensive inactive tree |
| 1 | Portfolio | `Icons.inventory_2_rounded` | `PortfolioScreen(onScanPressed)` | `portfolioControllerProvider` and local scroll/filter presentation | Scrollable/grid/list content; should not be retained as an expensive inactive tree |
| 2 | Scan | `Icons.camera_alt_rounded` | `ScanHubPage(onViewPortfolio)` | `scannerControllerProvider`, camera/gallery services | Resource-sensitive; inactive Scanner must not keep camera work alive |
| 3 | Settings | `Icons.settings_rounded` | `SettingsScreen()` | auth/settings controllers plus local form/scroll state | Account/auth controls reachable here; not an app-entry gate |

No Search or Notifications primary tab exists. Sprint 03 must not add them.

## 3. Current selected-tab ownership

Selected tab state is owned by:

- `appShellTabControllerProvider`
- `AppShellTabController`

Stable indices:

- Home: `0`
- Portfolio: `1`
- Scan: `2`
- Settings: `3`

The default selected destination is Home.

## 4. Current screen lifecycle strategy

Current strategy: active-destination-only construction.

`AppShell._buildActiveTab(selectedIndex)` creates only the selected destination widget. It does not use `IndexedStack`, `Offstage`, `TickerMode`, nested navigators, or eager construction of every tab tree.

Inactive destination widgets are disposed when switching away. Meaningful state is expected to survive through providers, repositories, `PageStorageKey` scroll positions where applicable, and feature controllers rather than retained widget trees.

## 5. Historical ANR risk

PackLox previously experienced a release-only Android ANR associated with retaining all major tab trees in an `IndexedStack`. The reported failure involved input-dispatch timeout during repeated Home scrolling and Home/Portfolio switching.

Sprint 03 must not reintroduce unconditional all-tab retention. Any state preservation must be selective and evidence-based.

## 6. Required state-preservation behaviour

Preserve:

- selected-tab provider ownership
- Home default selection
- Scanner controller state while an active scan exists
- Portfolio repository/controller state
- Settings authentication state
- pushed feature routes through the existing Navigator
- existing `PageStorageKey` scroll-position behavior where it already works

Do not preserve by keeping all major feature widget trees mounted.

If local widget state is lost on tab switch, prefer controller/provider ownership in the relevant feature sprint rather than retaining expensive shell children in Sprint 03.

## 7. Proposed shell architecture

Use a small, declarative shell presentation:

- destination descriptors define tab index, label, icon, selected icon, and builder
- a shell body host builds only the selected destination
- a Product Language-aligned navigation surface renders the primary destinations
- the shell remains a plain `Scaffold`
- bottom navigation remains hidden during active Scanner capture before a result, matching current behavior

No router migration, nested navigator, or `IndexedStack` is proposed.

## 8. Product Language composition

Shell navigation classification: **B. A composition of approved Product Language foundation primitives**.

The shell navigation uses:

- `PackLoxTokens.background`
- `PackLoxTokens.surface`
- `PackLoxTokens.surfaceRaised`
- `PackLoxTokens.border`
- `PackLoxTokens.blue`
- `PackLoxTokens.cyan`
- `PackLoxTokens.textPrimary`
- `PackLoxTokens.textSecondary`
- `AppSpacing`
- `AppRadius`
- Flutter `Semantics`
- Flutter `SafeArea`

It is not promoted into Product Language during Sprint 03. If future screens reuse the same navigation treatment, it can become a candidate Product Language component through a later review.

## 9. Navigation presentation

The navigation surface must:

- render exactly four primary destinations
- expose selected state clearly
- keep unselected labels readable
- keep touch targets accessible
- respect bottom system insets
- avoid per-tab custom visual exceptions
- preserve Scan as a normal primary destination, not a floating action pattern

## 10. Selected-tab treatment

Selected tabs use:

- raised/filled pill surface
- clear border/accent treatment
- stronger foreground text
- selected semantics
- icon and label grouped under one semantic destination

## 11. Unselected-tab treatment

Unselected tabs use:

- calm transparent or low-emphasis surface
- readable label/icon color
- no decorative per-tab gradients
- same layout geometry as selected tabs

## 12. Tab-switch rules

- Tapping an unselected tab changes exactly one selected destination.
- Tapping the selected tab follows the existing no-op behavior.
- Rapid taps must not push routes or duplicate destination state.
- Tab switching must not introduce artificial delay.
- Tab switching must not create a blank frame or stale overlay.

## 13. Back-navigation rules

Current behavior is preserved:

- On Home, system back follows the root app behavior.
- From non-default tabs, there is currently no shell-specific back-to-Home policy.
- Nested feature routes continue to rely on existing Navigator stack behavior.
- Onboarding and bootstrap must not reappear through shell back navigation after completion.

Sprint 03 does not invent a new back policy.

## 14. Deep-link rules

Deep-link handling remains outside the shell:

- email confirmation callbacks remain handled by `AuthDeepLinkCoordinator`
- password recovery remains the existing web redirect contract
- no shell route is added for auth callbacks
- deep-link behavior must not duplicate shell state

## 15. Scanner lifecycle rules

Scanner is resource-sensitive.

Rules:

- Scanner destination is built only when Scan is selected.
- Inactive Scanner widget tree is not retained.
- When leaving Scan after a saved result, current `resetAfterSaved()` behavior remains.
- Scanner controller continues to own scan state.
- Camera ownership remains in scanner/camera pages and services.
- AppShell does not directly control camera resources.
- Bottom navigation remains hidden during active scanner capture before a result.

## 16. Safe-area and inset rules

- Bottom navigation owns its bottom `SafeArea`.
- Top safe-area behavior stays with feature screens unless shell-caused.
- Bottom navigation must not be obscured by gesture or three-button navigation.
- Child feature screens receive normal scaffold body bounds.
- Avoid double SafeArea padding between shell and child screens.

## 17. Keyboard rules

Settings authentication fields and other feature inputs must not be permanently distorted by shell navigation. Sprint 03 keeps normal `Scaffold` resize behavior and does not add shell-level keyboard handling unless a shell-caused defect is found.

## 18. Responsive rules

- Navigation supports narrow phones.
- Labels remain readable at supported text scales.
- Touch targets remain at least 48 px high.
- Large phones do not create excessive shell spacing.
- Light and dark themes render consistently.

## 19. Accessibility rules

- Primary navigation exposes a meaningful semantic role.
- Each tab exposes one semantic label.
- Selected state is announced.
- Icons are not redundantly announced apart from labels.
- Focus order is Home, Portfolio, Scan, Settings.
- Touch targets meet accessibility minimums.
- Reduced-motion users do not receive delayed destination availability.

## 20. Motion and reduced-motion rules

- Navigation state animation is decorative and short.
- When `MediaQuery.disableAnimations` or `accessibleNavigation` is active, navigation state changes use zero-duration animation.
- Tab content availability is immediate; no timer controls tab switching.
- Inactive destinations do not retain tickers through shell retention.

## 21. Performance budget

Performance strategy:

- active destination only
- no unconditional all-tab `IndexedStack`
- no eager construction of Home, Portfolio, Scan, and Settings together
- no shell-level continuous decorative animation
- no production logging added for the shell

Runtime validation should stress:

- repeated Home/Portfolio switching
- repeated Home/Scan switching
- rapid sequential tab taps
- Home scrolling followed by switching
- Portfolio scrolling followed by switching
- Scanner activation and deactivation
- Android logs for ANR/input-dispatch warnings

## 22. Allowed files

Allowed production files:

- `lib/core/navigation/app_shell.dart`
- `lib/core/navigation/app_shell_controller.dart` only if selected-tab ownership needs documentation-preserving additions
- `lib/core/navigation/app_shell_destination.dart`
- `lib/core/ui/navigation/glass_bottom_nav_bar.dart`
- new shell/navigation presentation files under `lib/core/ui/navigation/`

Allowed test/docs/evidence:

- focused shell tests under `test/`
- `qa/reconstruction/sprint_03_app_shell_specification.md`
- `qa/reconstruction/sprint_03_runtime_comparison.md`
- `qa/screenshots/reconstruction/sprint_03_app_shell/`

## 23. Prohibited files

Do not modify:

- backend files
- analyzer files
- feature domain/data/repository/service logic
- authentication logic
- startup services
- onboarding presentation except a narrowly required shell handoff correction
- Home content
- Scanner content
- Portfolio content
- Settings content
- routing framework/native deep-link configuration
- secrets/environment files
- generated build output
- original dirty worktree

## 24. Test plan

Focused tests must cover:

- frozen Sprint 01 bootstrap tests
- frozen Sprint 02 onboarding tests
- default Home selection
- exactly four primary destinations
- each primary tab displays the expected existing feature screen
- selected state changes exactly once
- repeated selected-tab taps are no-ops
- rapid taps do not push routes or duplicate tab buttons
- no Search or Notifications primary tab
- no authentication destination
- system back behavior per current contract
- selected semantics
- light/dark rendering
- large/narrow rendering without overflow
- bottom inset handling
- reduced-motion tab switching
- no artificial timer
- no unconditional eager construction of all expensive feature screens

## 25. Runtime evidence plan

Use Samsung SM E625F, Android 13, device id `RZ8R213M8ZL` if available.

Capture:

- default Home shell
- selected Portfolio
- selected Scan
- selected Settings
- rapid/stress-switch Android logs
- hierarchy XML for shell navigation

Record what is captured, observed, widget-tested, and unverified.

## 26. Rollback boundary

Rollback is limited to Sprint 03 specification, shell destination descriptors, shell navigation presentation, AppShell integration, focused shell tests, runtime comparison, runtime evidence, and Sprint 03 documentation.

No data migration, auth change, backend change, router change, feature-screen reconstruction, or native configuration change is included.

## 27. Explicit non-goals

- no feature-screen reconstruction
- no auth redesign
- no auth guard
- no router migration
- no backend changes
- no artificial tab-switch delay
- no unconditional all-tab `IndexedStack` unless later evidence proves it safe
- no screen-specific shell styles
- no Home redesign
- no Scanner redesign
- no Portfolio redesign
- no Settings redesign
- no Search or Notifications primary tabs
