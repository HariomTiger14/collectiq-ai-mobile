# Core Screen Authority Recovery Summary

Date: 2026-07-13
Branch: rebuild/product-language-v1

| Screen | Authority path | Approved state coverage | Freeze reassessment | Critical | High | Medium | Low |
|---|---|---|---|---:|---:|---:|---:|
| Home | `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_02_Home/images/home_screen_flow_master.png` | 10 Home states | Visual freeze requires major remediation | 1 | 4 | 4 | 1 |
| Portfolio | `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_06_Portfolio/images/portfolio_flow_master.png` | 10 Portfolio states | Visual freeze requires major remediation | 1 | 5 | 6 | 0 |
| Detail | `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_07_Collectible_Detail/images/collectible_detail_flow_master.png` | 10 Detail states | Visual freeze requires major remediation | 2 | 7 | 5 | 1 |
| Scanner | `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_03_Scanner/images/scanner_flow_master.png` | 10 Scanner states | Visual freeze requires major remediation | 2 | 6 | 3 | 1 |

## Shared Product Language Issues

Product Language primitives were often treated as enough to reconstruct whole screens. The recovered authorities show that component approval does not equal screen composition approval. Shared Header, Hero, EntryTile, Button, surfaces, cards, dialogs, sheets, and navigation need screen-level mapping before future freeze claims.

## Shared Surface And Token Issues

Home, Portfolio, Detail, and Scanner all show cases where runtime surfaces use generic Material/Product Language compositions that do not match the approved board surfaces. Dark-board screens especially need screen-specific surface/radius/elevation mapping.

## Shared Hierarchy Issues

The largest recurring issue is hierarchy drift: approved compact board states became long-scroll Flutter pages or locally composed dashboards. Screen structure must be corrected before fine token work.

## App Shell And Navigation Clarifications

App Shell behaviour remains useful and should be preserved. However, bottom navigation count/selection and screen entry context must be verified against each approved board. Scanner Scan Hub and Portfolio/Detail handoff should be preserved while visuals are remediated.

## Coordinated Remediation Order

1. Establish shared dark surface/radius/elevation rules from approved boards.
2. Remediate Home first because it is the primary landing surface.
3. Remediate Scanner Scan Hub deltas and then full Scanner S02-S10, preserving camera lifecycle.
4. Remediate Portfolio list/search/filter/sort and item grid.
5. Remediate Detail after Portfolio because Detail depends on Portfolio handoff and shared image/valuation treatment.
6. Add cross-screen regression evidence and then amend visual freezes.

## Shared Fixes

Shared fixes should include token mapping, dark surface primitives, dialog/sheet styling, image placeholder policy, valuation unavailable/zero semantics, and accessibility/focus conventions.

## Screen-Specific Fixes

Home section order, Scanner camera lifecycle/review/analysis, Portfolio collection/search/filter/grid, and Detail tabs/gallery/value/AI/notes/actions must remain screen-specific.

## Implementation Dependency Order

Shared tokens and surfaces should land before screen-specific visual rewrites. Scanner camera/data-flow code should remain stable while only presentation is reworked. Portfolio should precede Detail where shared collectible card/image/valuation patterns are involved.
