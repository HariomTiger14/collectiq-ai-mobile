# Flutter component mapping

| Approved component | Previous candidate | Compliance / reuse risk | Action |
| --- | --- | --- | --- |
| Header 1.0.1 | `ScannerHeader` in screen-local presentation | Wrong name scale, truncation, no unread/loading API | Replace with reusable `PackLoxHeader` |
| Hero 1.0.1 | `ScannerHeroCard` | Scanner-only, old copy, fixed geometry, no variants/actions | Replace with reusable `PackLoxHero` |
| Entry Tile 1.0.0 | `ScannerEntryTile` | 72 px Material FilledButton, scanner-local, missing states | Replace with reusable `PackLoxEntryTile` |
| Button 1.0.0 | Ad-hoc Material buttons | Styling leakage and no controlled family | Add reusable `PackLoxButton` |
| Shared shell/navigation | `AppShell` / `GlassBottomNavBar` | Behaviorally compatible; navigation language deferred | Leave untouched |

Existing Home, Portfolio, Analysis and Settings heroes remain untouched because migrating other screens is outside S01 scope.
