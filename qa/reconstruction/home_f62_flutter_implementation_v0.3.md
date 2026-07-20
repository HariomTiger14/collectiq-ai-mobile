# Home F62 Flutter Implementation v0.3

Status: implemented for reconstruction review

## Frozen Authority Used

- Design package: `packlox-design-platform/incoming_authority/home_reconstruction_f62_v0.3/`
- Frozen status: `FROZEN / APPROVED FOR FLUTTER IMPLEMENTATION`
- Dimensions: 1080 x 2400 px
- Source docs: `HOME_ENGINEERING_SPECIFICATION_v0.3.md`, `HOME_COMPONENT_BLUEPRINT_v0.3.md`, `HOME_FREEZE_RECORD_v0.3.md`, and `HOME_FREEZE_READINESS_AUDIT_v0.3.md`

Only v0.3 was used. v0.1 and v0.2 are superseded and were not used as implementation authority.

## Current Home Files Audited

- `lib/features/home/presentation/home_screen.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/home/presentation/widgets/home_shared_components.dart`
- `lib/features/portfolio/presentation/controllers/portfolio_controller.dart`
- `lib/core/navigation/app_shell.dart`
- `test/home_page_test.dart`
- `test/home_shared_components_test.dart`

## Available Data Fields

Home binds to the existing `portfolioControllerProvider` and `CollectorDashboardAnalyticsService` only:

- saved portfolio items
- ordered recent items
- item count
- estimated values when an item has a displayable valuation status
- category distribution/category count
- most recent saved item timestamp
- portfolio loading state
- portfolio error message

## Unavailable Data Fields

These v0.3 authority concepts are not currently backed by dedicated Home contracts:

- market trend history
- alert inbox/count
- remote sync progress surface
- guest-specific Home content beyond existing AppShell guest access
- dedicated Market Insights route

The implementation does not fabricate those values. It shows only real saved portfolio data and documents unsupported route/state gaps here.

## State Mapping

- Default/signed-in: portfolio has saved items. The page shows the v0.3 brand lockup, Home title/subtitle, hero CTA, real collection item count, real displayable collection value when present, and action rows.
- Empty/new collector: portfolio has zero saved items. The page shows the empty hero and first-item action rows with no metrics.
- Loading: portfolio is loading with no items. The page shows skeleton blocks and no sample values.
- Error/retry: portfolio has an error with no items. The page shows the existing safe error message and calls `PortfolioController.loadItems` on retry.
- Partial data: portfolio has saved items and at least one item without a displayable valuation. The page preserves real values, shows a state-driven alert affordance, and adds a valuation action row.
- Guest fallback: existing AppShell supports guest entry after onboarding. There is no separate Home guest content contract, so a guest sees the same data-bound empty/default Home states based on local portfolio data.

## AppShell Ownership

The v0.3 PNG includes bottom navigation for context. Flutter Home does not render bottom navigation. AppShell continues to own the bottom navigation and injects Home callbacks for scan/import/portfolio navigation.

## Intentional Omissions

- Status bar graphics are not implemented; Android/iOS own system chrome.
- Flow-board and design-review labels are not implemented in Flutter UI.
- Fake portfolio values, item counts, trends, alerts, and recent scans are not implemented.
- Dedicated Market Insights navigation is not invented; the visible row uses the existing portfolio handoff when available.

## Test Plan

Focused tests cover loading, error/retry, empty, default, partial valuation, absence of fake metrics, primary scan callback, AppShell bottom-nav ownership, approved emblem usage, and absence of authority annotation text.

## Runtime QA Plan

Build the SIT APK, install on Android, and compare Home against the frozen v0.3 hierarchy while verifying real local portfolio data drives all metric and recent-item surfaces.