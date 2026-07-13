# Sprint 06 Portfolio Runtime Comparison

Date: 2026-07-13
Branch: `rebuild/product-language-v1`
Device: `RZ8R213M8ZL` / `SM_E625F`
Package: `com.collectiq.ai.local`

## Device Gate

- `adb devices -l` reported `RZ8R213M8ZL` as `device`.
- `flutter devices --device-timeout 30` reported `SM E625F (mobile)`, Android 13 API 33.

## Build And Install

- First Gradle attempt from the repository root failed because the Gradle root is `android\`.
- Android local debug build then passed from `android\`:
  - `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`
  - `.\gradlew.bat :app:assembleLocalDebug`
- APK installed successfully with:
  - `adb -s RZ8R213M8ZL install -r build\app\outputs\flutter-apk\app-local-debug.apk`

## Runtime Data Setup

The installed local debug flavour did not expose the Settings demo-data seed control. For populated Portfolio runtime validation, a debug-only SharedPreferences seed was written through `run-as com.collectiq.ai.local`.

Seed file:

- `qa/screenshots/reconstruction/sprint_06_portfolio/runtime_seed_prefs.xml`

The seed preserved onboarding completion and added four Portfolio items:

- one trading card with market-estimated value;
- one coin with AI-estimated value;
- one comic with market trend data;
- one gallery-backed toy car with unavailable valuation and zero stored value.

Home runtime hierarchy after relaunch reported 4 collectibles worth `$2,750`, confirming the data loaded through the app repository path.

## Runtime Evidence

Captured under `qa/screenshots/reconstruction/sprint_06_portfolio/`:

- `01_launch_state.png` / `.xml`: Home after launch before populated seed.
- `02_empty_portfolio.png` / `.xml`: empty Portfolio state with Header, `$0` summary, Sort/Filter/Add actions, and empty copy.
- `11_after_seed_launch.xml`: Home after seeded relaunch, showing 4 collectibles and `$2,750`.
- `12_populated_portfolio.png` / `.xml`: populated Portfolio summary, category chips, action bar, and first grid item.
- `15_search_no_results_visible.png` / `.xml`: search no-results state with Clear filters.
- `16_filter_sheet.png` / `.xml`: filter sheet with category, confidence, trend, Apply, and Clear controls.
- `17_cards_filter_result.png` / `.xml`: Cards category filter result.
- `18_sort_sheet.png` / `.xml`: sort sheet with value, confidence, trend, category, and recently-added options.
- `22_detail_navigation.png` / `.xml`: Portfolio item opens existing Collectible Detail route.
- `23_tab_scroll_stress.png` / `.xml`: post Home/Portfolio/Scan/Portfolio switching and Portfolio scroll stress.
- `24_runtime_logcat.txt`: Android log capture after runtime validation.

## Observed Runtime Behaviour

- Empty Portfolio did not fabricate collection data.
- Populated Portfolio rendered the approved Header, real total value, real item count, valued count, category count, and partial valuation notice.
- Search no-results state appeared and exposed Clear filters.
- Filter and sort sheets opened without route lock or blank frame.
- Cards filter reduced the visible grid to the matching seeded trading card.
- Portfolio item tap opened the existing `CollectibleDetailPage`; Detail showed `Collectible Details`, `Runtime Charizard Holo`, `94%`, and `$1,850`.
- Home to Portfolio, Scan to Portfolio, scrolling, and repeated tab switching returned to a coherent Portfolio state.

## Focused Log Scan

Strict scan of `24_runtime_logcat.txt` found no matches for:

- `FATAL EXCEPTION`
- `ANR in com.collectiq.ai.local`
- `Input dispatching timed out`
- `Process: com.collectiq.ai.local`
- `E AndroidRuntime`

The log contains expected device/system noise, launch lines, Bluetooth scan lines, and Samsung framework messages.

## Validation Commands

- `flutter analyze` passed.
- Focused Portfolio tests passed:
  - `test\widget_test.dart --plain-name "loads saved portfolio items from local storage"`
  - `test\widget_test.dart --plain-name "filters portfolio items by search query"`
  - `test\widget_test.dart --plain-name "category filter limits portfolio items"`
  - `test\widget_test.dart --plain-name "portfolio filter sheet filters by confidence and trend"`
  - `test\widget_test.dart --plain-name "portfolio filter and sort sheets use premium components at 320px"`
  - `test\widget_test.dart --plain-name "sorts portfolio items by value and confidence"`
  - `test\widget_test.dart --plain-name "portfolio renders 500 seeded demo items without crashing"`
- `git diff --check` passed before runtime evidence documentation.
- Android local debug build, install, launch, Portfolio entry, populated/empty validation, search, filter, sort, detail navigation, tab switching, scroll stress, screenshots, hierarchy capture, and log capture completed on `RZ8R213M8ZL`.

