# Sprint 04 Home runtime comparison

Status: completed from source inspection, widget/runtime-adjacent tests, analyzer, full-suite remediation, Android build/install, physical-device Home validation, screenshots, hierarchy captures, and logcat review.

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

Android QA completed on Samsung `SM E625F`, Android 13 / API 33, device id `RZ8R213M8ZL`.

- Initial ADB gate on this pass: `RZ8R213M8ZL device product:f62ins model:SM_E625F device:f62`.
- Flutter CLI diagnosis: sandboxed direct Flutter tooling could not open `C:\Users\hario\Desktop\flutter\bin\cache\lockfile`; rerunning Flutter outside the sandbox resolved the previous apparent CLI hangs.
- `flutter devices --device-timeout 30`: detected `SM E625F` plus desktop/web targets.
- Build: `flutter build apk --debug --flavor local -v` succeeded. Gradle completed `assembleLocalDebug` in 37s.
- APK: `build\app\outputs\flutter-apk\app-local-debug.apk`.
- Install: `flutter install -d RZ8R213M8ZL --debug --flavor local` passed.
- Launch: `adb shell monkey -p com.collectiq.ai.local -c android.intent.category.LAUNCHER 1` launched `com.collectiq.ai.local/com.collectiq.ai.MainActivity`.
- Foreground check after launch and after stress retained `MainActivity`.
- Stress sequence covered Home -> Portfolio, Home -> Scan, Home scroll, rapid tab switching, and return to Home.
- No ANR, input-dispatch timeout, Flutter framework exception, `E/flutter`, uncaught app exception, blank final frame, route lock, or foreground loss was observed during the known Home/shell stress sequence.
- Logcat contained unrelated device/service noise, including Bluetooth scan lines, Google Play/Auth warnings, and system `NullBinder`/`TransactionTooLargeException` entries. App-specific lines were normal input/window traces plus expected Scanner lost-picker recovery logs when visiting Scan.

Detailed diagnostics are recorded in `qa/reconstruction/sprint_04_device_diagnostics.md`.

## Corrections made during validation

- Removed remaining local reveal/stagger wrappers from Home sections and recent rows.
- Rebuilt `test/home_page_test.dart` around Sprint 04 composition and data-integrity contracts.
- Updated frozen-sprint regression assertions that referenced removed Home headline copy while preserving their original shell/onboarding/bootstrap intent.
- Remediated six broad Home-related `test/widget_test.dart` regressions caused by stale expectations for the removed Home custom hero/CTA surface.
- Removed generated desktop plugin registrant churn caused by Flutter tooling.

## Final validation

- `flutter analyze`: passed.
- `flutter test test\bootstrap_entry_presentation_test.dart --reporter=compact`: passed.
- `flutter test test\onboarding_presentation_test.dart --reporter=compact`: passed.
- `flutter test test\app_shell_presentation_test.dart --reporter=compact`: passed.
- `flutter test test\home_page_test.dart --reporter=compact`: passed.
- Full suite before remediation: 525 passed, 25 failed; captured in `qa/reconstruction/sprint_04_full_test_output.txt`.
- Full suite after remediation: 531 passed, 19 failed.

The remaining 19 full-suite failures are documented as baseline debt, not Sprint 04 Home regressions.

## Evidence paths

- Focused Home validation: `test/home_page_test.dart`.
- Regression validation: `test/bootstrap_entry_presentation_test.dart`, `test/onboarding_presentation_test.dart`, `test/app_shell_presentation_test.dart`, `test/widget_test.dart`.
- Physical-device evidence directory: `qa/screenshots/reconstruction/sprint_04_home/`.
- Empty Home first viewport: `qa/screenshots/reconstruction/sprint_04_home/empty_home_first_viewport.png` and `.xml`.
- Empty Home lower content: `qa/screenshots/reconstruction/sprint_04_home/empty_home_lower_content.png`.
- Scan action handoff: `qa/screenshots/reconstruction/sprint_04_home/scan_action_handoff.png` and `.xml`.
- Portfolio action handoff: `qa/screenshots/reconstruction/sprint_04_home/portfolio_action_handoff.png` and `.xml`.
- Post-stress Home: `qa/screenshots/reconstruction/sprint_04_home/home_after_tab_scroll_stress.png` and `.xml`.
- Android logcat stress capture: `qa/screenshots/reconstruction/sprint_04_home/tab_scroll_stress_logcat.txt`.

## Verified scenarios

- Approved Header/Hero/Button/Entry Tile composition.
- Empty Home state on physical device.
- Empty state.
- Home entry through frozen App Shell on physical device.
- Unavailable value behavior.
- Zero-value market-estimate behavior.
- Partial-value behavior.
- Scan action handoff on physical device.
- Portfolio action handoff on physical device.
- Home -> Portfolio switching on physical device.
- Home -> Scanner switching on physical device.
- Home scrolling followed by tab switching on physical device.
- Rapid tab switching on physical device.
- No observed overflow, blank frame, route flicker, input lock, ANR, or foreground loss in the known physical-device stress sequence.
- Detail navigation from top/latest and recent rows.
- Guest/no-auth Home access in shell tests.
- Light/dark, narrow, large-text, and reduced-motion widget paths.
- No fake Home loading/error/retry UI.

## Unverified scenarios

- Loaded Home state on physical device; this device had an honest empty local collection and data was not fabricated.
- Partial-value Home state on physical device; no natural partial-value local data was available.
- Recent-item detail action on physical device; no recent items existed in the local collection.
- Real device dark-mode screenshot.
- Real device large-text screenshot.
- Real device reduced-motion setting.
- Real device landscape screenshot.
