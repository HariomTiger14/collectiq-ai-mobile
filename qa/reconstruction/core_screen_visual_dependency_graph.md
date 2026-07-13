# Core Screen Visual Dependency Graph

Date: 2026-07-13
Scope: planning dependency graph only.

## Ordered Dependencies

1. Product/design clarification gate.
2. Shared dark surface, radius, elevation, and spacing rules.
3. Shared safe-area and bottom-clearance rules.
4. Shared sheet/dialog policy.
5. Shared valuation unavailable/zero semantics.
6. Home remediation.
7. Portfolio remediation.
8. Detail remediation.
9. Scanner remediation.
10. Cross-screen integration QA and freeze amendments.

## Must Happen First

| Dependency | Reason | Blocks |
|---|---|---|
| Search-tab clarification | App Shell change would affect all screen first viewports and navigation tests | Any App Shell tab-count change |
| Capture System classification | Scanner visual work must not promote candidate authority by accident | Scanner S02-S10 remediation |
| Shared surface rules | All four boards are dark; light/generic Material surfaces recur | Home/Portfolio/Detail/Scanner fine styling |
| Valuation semantics | Portfolio and Detail both risk user-trust defects | Portfolio cards, Detail Market & Value, Home no-valuation |
| Sheet/dialog policy | Portfolio sort/filter and Detail delete/gallery need consistent dark treatment | Portfolio Phase 2 and Detail Phase 3 overlays |

## Can Run Independently After Phase 0

| Workstream | Independence condition |
|---|---|
| Home structure | Can proceed once sample action and four-tab shell exception are decided or deferred |
| Scanner Scan Hub tuning | Can proceed independently, but full Scanner requires camera evidence and Capture System policy |
| Portfolio populated evidence setup | Can proceed without Detail implementation, but should preserve Detail handoff |
| Detail data fixture planning | Can proceed before Detail implementation, but visual code should wait for Portfolio valuation/image semantics |

## Must Wait

| Fix | Waits for |
|---|---|
| Adding Search as bottom nav destination | Search/App Shell product decision |
| Full Notifications routing | Notifications product scope |
| Home loading/offline/sync visuals with real behavior | Architecture/product decision on Home-owned async state |
| Portfolio bulk/export/share/backup states | Product decision and feature scope |
| Capture System promotion | Separate approval beyond Scanner board |
| Detail share implementation | Product decision and share capability |

## Multi-Screen Fixes

| Fix | Affects | Cherry-pick as shared commit? |
|---|---|---|
| Dark sheet/dialog wrapper or theme | Portfolio, Detail, possibly future screens | Yes, if implemented as a wrapper or theme correction |
| Valuation unavailable/zero display helpers | Portfolio, Detail, Home | Yes, with tests before screen rewrites |
| Safe-area/bottom-clearance policy | Home, Portfolio, Detail, Scanner | Yes, if centralized without changing App Shell behavior |
| Image placeholder policy | Portfolio, Detail, Scanner | Maybe, only if shared loader owns it |
| Header composition rules | Home, Portfolio, Detail | No global redesign; use screen-local commits unless a configuration gap is proven |

## Recommended Cherry-Pick Commits

1. Shared dark surfaces and sheet/dialog wrapper, if approved by Phase 0.
2. Shared valuation semantics helper/tests, if a central helper already exists.
3. Shared evidence/test harness updates for screenshot naming and device metadata.
4. App Shell Search change only as a standalone product-approved commit, never bundled into a screen remediation.
