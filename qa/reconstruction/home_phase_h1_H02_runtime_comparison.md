# PackLox Home Phase H1 - H02 Runtime Comparison

Status: PROVISIONALLY ACCEPTED - SEARCH NAV DEPENDENCY OPEN

## Authority

- Master board: `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_02_Home\images\home_screen_flow_master.png`
- Master board SHA-256: `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A`
- H02 crop: `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_lock\Home\Home_Design_System_v1\01_Authority\state_crops\H02_Empty_Collection.png`
- Runtime device: Samsung `SM-E625F`, serial `RZ8R213M8ZL`, `1080x2400`, density `450`, override density `420`
- Runtime APK: `build\app\outputs\flutter-apk\app-local-debug.apk`, `versionName=1.0.0`, `versionCode=1`

## Evidence

- Authority copy: `qa/screenshots/design_lock/home/H02_master_authority/authority/H02_Empty_Collection.png`
- Runtime first viewport: `qa/screenshots/design_lock/home/H02_master_authority/runtime/home_H02_first_viewport.png`
- Runtime full scroll: `qa/screenshots/design_lock/home/H02_master_authority/runtime/home_H02_full_scroll.png`
- Header close-up: `qa/screenshots/design_lock/home/H02_master_authority/runtime/home_H02_header_closeup.png`
- Hero close-up: `qa/screenshots/design_lock/home/H02_master_authority/runtime/home_H02_hero_closeup.png`
- Categories close-up: `qa/screenshots/design_lock/home/H02_master_authority/runtime/home_H02_categories_closeup.png`
- Tab leave/return: `qa/screenshots/design_lock/home/H02_master_authority/runtime/home_H02_tab_left_portfolio.png`, `qa/screenshots/design_lock/home/H02_master_authority/runtime/home_H02_tab_return.png`
- Hierarchy: `qa/screenshots/design_lock/home/H02_master_authority/hierarchy/`
- Comparison: `qa/screenshots/design_lock/home/H02_master_authority/comparison/Home_H02_Master_Authority_vs_Samsung_Runtime.png`

## Comparison Matrix

| Area | Runtime result | Classification |
| --- | --- | --- |
| Empty H02 structure | Header, empty hero, primary Scan CTA, Sample Scan line, Popular Categories, and bottom nav are present in the approved order. | MATCH |
| Removed H02-only elements | Collection Status, Quick Actions, dashboard hero, search card, alert surfaces, and fabricated scan/value/condition metrics are absent. | MATCH |
| Header | Uses shared PackLox header with time-aware greeting and Collector fallback. Runtime name differs from authority sample name because no user name is available. | ACCEPTABLE RESPONSIVE ADAPTATION |
| Empty hero | Centered card, collection icon, title/body, and primary Scan CTA align to the authority intent. Runtime uses the H0 shared surface and Samsung width. | MATCH |
| Sample Scan | Authority shows `Try a Sample Scan`; runtime shows disabled `Sample Scan unavailable` because H1 did not change App Shell or scanner contracts to expose a sample callback. | TEMPORARY PRODUCT-CONTRACT DEVIATION |
| Popular Categories | Cards, Coins, Figures, More render as four compact collectible category tiles below the hero. | MATCH |
| Bottom navigation | Existing app shell remains four tabs: Home, Portfolio, Scan, Settings. Authority board includes Search as a future dependency. | TEMPORARY PRODUCT-CONTRACT DEVIATION |
| Density and first viewport | Hero, categories, and bottom nav fit in the Samsung first viewport without overlap; device Edge Panel handle appears as an external system overlay on the far left. | ACCEPTABLE RESPONSIVE ADAPTATION |
| Tab leave/return | Portfolio tab can be selected and Home returns to the same H02 composition. | MATCH |

## Validation

- `flutter analyze`: passed, no issues found.
- `flutter test test\home_page_test.dart --reporter=compact`: `20 passed`.
- `flutter test test\home_shared_components_test.dart --reporter=compact`: `20 passed`.
- Shared/app-shell/guard focused suites: passed in focused validation.
- Full suite: `610 passed / 9 failed`, matching the accepted non-Home baseline band with no H02 failure.
- Gradle build: `.\gradlew.bat assembleLocalDebug`: `BUILD SUCCESSFUL`.
- Samsung install: `adb -s RZ8R213M8ZL install -r build\app\outputs\flutter-apk\app-local-debug.apk`: `Success`.

## Result

Home H02 is provisionally accepted against the master authority. The remaining open items are product-contract dependencies, not H1 visual correction defects: Search navigation is not part of the frozen App Shell, and Sample Scan has no supported Home callback without expanding shell/scanner contracts.
