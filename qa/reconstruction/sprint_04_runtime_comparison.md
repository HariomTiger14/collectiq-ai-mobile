# Sprint 04 Home runtime comparison

Status: completed from source inspection, widget/runtime-adjacent tests, analyzer, and attempted Android build/device checks. Android device QA could not be completed because Flutter build and device discovery commands hung without usable output.

## Intended Product Language composition

- Header: `PackLoxHeader` v1.0.1.
- Hero: `PackLoxHero` v1.0.1.
- Primary action: `PackLoxButton` v1.0.0 through the approved Hero action slot.
- Quick actions: `PackLoxEntryTile` v1.0.0 for Import photo and Open portfolio.
- Snapshot, recent content, valuation note: B-level local compositions from Product Language/design-system tokens.

## Actual runtime composition

Home renders a single safe-area `CustomScrollView` with:

1. Approved Header using fallback identity `Collector`.
2. Approved Hero with populated or empty-state copy.
3. Two approved Entry Tiles for import and portfolio.
4. Collection snapshot with displayable aggregate value, counts, last scan, and top/latest item.
5. Recent collectibles when real items exist.
6. Grounded valuation note when saved items lack display valuations.

The Hero primary action is the approved Hero action slot, which internally instantiates the approved `PackLoxButton`. There is no Home-specific replacement button.

## First viewport assessment

The first viewport now prioritizes Header, Hero, and the single primary Scan action. The old custom greeting/hero, oversized standalone scan card, and duplicate first-viewport action-card hierarchy were removed. At narrow test widths, content remains scrollable and no overflow was observed in focused widget tests.

## Section comparison

| Area | Previous state | Sprint 04 state |
|---|---|---|
| Header | Home-specific greeting surface | Approved `PackLoxHeader` |
| Hero | Elastic/parallax custom hero | Approved `PackLoxHero` |
| Primary action | Bespoke Home CTA | Approved Hero action using `PackLoxButton` |
| Secondary actions | Custom action cards | Approved `PackLoxEntryTile` |
| Metrics | Duplicated custom panels | Snapshot with real collection value/count/category/last scan |
| Recent content | Animated reveal rows | Bounded real rows without reveal/stagger wrappers |
| Unsupported actions | Some planned/soon affordances existed historically | No unsupported actions presented as functional |

## Data-integrity findings

Home still watches `portfolioControllerProvider` and reads `orderedItems`. It derives dashboard analytics through `CollectorDashboardAnalyticsService.build(items)`. Display-only shaping remains in `_HomeViewData`.

Displayed values:

- Collection value: sum of items with displayable valuation status/value; shown as whole-dollar display text.
- Item count: `items.length`.
- Category count: positive buckets from `CollectorDashboardAnalytics.categoryDistribution`.
- Last scan: `CollectorDashboardAnalytics.mostRecentItem.createdAt`, formatted relatively.
- Top/latest collectible: highest displayable-value item, otherwise latest real item.
- Recent collectibles: first four ordered real items.
- Needs valuation: count of saved items without displayable valuation.

Null/unavailable values are not displayed as confirmed zero. A zero-valued market estimate remains displayable as `$0`; an unavailable zero value displays `Value unavailable`.

## Empty and partial-data findings

Empty state is informational: Hero says the collection starts here and the snapshot offers the existing scan action. No fabricated totals, trends, or retry states are shown.

Partial-value state preserves valid collection content. Valued items still contribute to the aggregate; unvalued items remain visible in recent/top/latest content and trigger the grounded valuation note.

## Loading, error, and retry

Home has no independent loading, error, or retry contract. Focused tests assert no fake `CircularProgressIndicator`, Retry copy, or Home-specific load/error panel is introduced. Existing portfolio controller states remain owned by the portfolio feature.

## Responsive and accessibility findings

Focused widget tests covered:

- light and dark theme rendering,
- 320px width,
- large text scale,
- reduced motion media setting,
- empty, loaded, unavailable, zero-value, and partial-value data.

No Flutter overflow exception was observed in the focused Home suite.

## Performance findings

Sprint 04 removed Home `MotionElasticHero`, `MotionParallax`, and local `MotionReveal`/stagger wrappers. Home remains bounded to at most four recent rows and one top/latest preview. No continuous Home animation controller, artificial delay, chart, blur, or scroll-time transformation was added.

## Android log and device findings

Android QA was attempted but not completed:

- `flutter build apk --debug --flavor local` hung without output for several minutes and was stopped by terminating only the launched build process tree.
- `flutter devices` also hung without output and was stopped by terminating only the launched devices process tree.
- Because no debug APK was produced and device discovery did not complete, install/run QA on SM E625F was not verified.
- No Android logcat stress-switch evidence was captured.

## Corrections made during validation

- Removed remaining local reveal/stagger wrappers from Home sections and recent rows.
- Rebuilt `test/home_page_test.dart` around Sprint 04 composition and data-integrity contracts.
- Updated frozen-sprint regression assertions that referenced removed Home headline copy while preserving their original shell/onboarding/bootstrap intent.
- Removed generated desktop plugin registrant churn caused by Flutter tooling.

## Evidence paths

- Focused Home validation: `test/home_page_test.dart`.
- Regression validation: `test/bootstrap_entry_presentation_test.dart`, `test/onboarding_presentation_test.dart`, `test/app_shell_presentation_test.dart`, `test/widget_test.dart`.
- Evidence directory reserved for device/runtime captures: `qa/screenshots/reconstruction/sprint_04_home/`.

No Android screenshots or logs were captured because build/device discovery did not complete.

## Verified scenarios

- Approved Header/Hero/Button/Entry Tile composition.
- Loaded data display.
- Empty state.
- Unavailable value behavior.
- Zero-value market-estimate behavior.
- Partial-value behavior.
- Scan action handoff.
- Portfolio action handoff.
- Detail navigation from top/latest and recent rows.
- Guest/no-auth Home access in shell tests.
- Light/dark, narrow, large-text, and reduced-motion widget paths.
- No fake Home loading/error/retry UI.

## Unverified scenarios

- Android install/run on SM E625F.
- Real device Home entry after onboarding.
- Real device stress-switch passes.
- Real device light/dark/large-text/reduced-motion checks.
- Android logcat review.
- Screenshot evidence.
