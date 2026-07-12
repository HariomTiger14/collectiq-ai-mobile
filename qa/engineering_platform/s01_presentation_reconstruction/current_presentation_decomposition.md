# Current S01 presentation decomposition

## A. Behavior/state retained

`ScanHubPage` state lifecycle, lost-picker recovery, active-session predicate, controller callbacks, auth greeting composition, and shell handoff are behavior. They remain in the page/controller layer.

## B. Presentation replaced

The page-owned scaffold/background composition, header row, greeting typography, notification placement, hero, option section, entry tiles, icon containers, spacing, and responsive sizing may be replaced from the approved source.

| Element | Current classification | Reconstruction decision |
|---|---|---|
| `ScannerFocusTheme` / `ScannerBackground` | Reusable and contract-compliant dark theme/background | Reuse. |
| `ScanHubPage` lifecycle/controller wiring | Behavior; unrelated to visual authority | Preserve. |
| Monolithic page column | Screen-specific and replaceable | Replace with `ScannerPageScaffold` and `ScannerOptionSection`. |
| `_ScanHubHeader` | Reusable idea, visually coupled to page | Replace with public small `ScannerHeader` + `DynamicGreeting` + `NotificationAction`. |
| `ScannerHeroCard` | Reusable but visually noncompliant implementation | Rebuild from reference anatomy. |
| Loose heading/three tile calls | Screen-specific composition | Replace with one option-section component. |
| `ScannerEntryTile` / icon container | Reusable idea, generic FilledButton anatomy | Rebuild as semantic Material/Ink surface matching the reference card. |
| `GlassBottomNavBar` / `AppShell` | Shared-shell owned | Verify only; do not replicate or move locally. |
| Scanner controller/services/analyzer/portfolio | Unrelated behavior | Untouched. |

The reconstruction lives in a dedicated S01 presentation file so the page is an orchestration layer rather than a design source.
