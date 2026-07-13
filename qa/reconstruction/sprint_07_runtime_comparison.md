# Sprint 07 Detail Runtime Comparison

Date: 2026-07-13
Device: Samsung SM-E625F, `RZ8R213M8ZL`
Build: local debug APK, `com.collectiq.ai.local`

## Device Gate

`adb devices -l` reported:

- `RZ8R213M8ZL device product:f62ins model:SM_E625F device:f62 transport_id:1`

Flutter device discovery was attempted with `flutter devices`, but the wrapper hung without output. The process was stopped after ADB had confirmed the required physical device.

## Build And Install

The Flutter wrapper also hung before starting Dart/Gradle for `flutter build apk --debug --flavor local`, so the local debug APK was built through the project Gradle wrapper:

- `.\\gradlew.bat assembleLocalDebug`
- `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`
- Result: `BUILD SUCCESSFUL in 13s`
- APK: `build\app\outputs\flutter-apk\app-local-debug.apk`

Install command:

- `adb -s RZ8R213M8ZL install -r build\app\outputs\flutter-apk\app-local-debug.apk`
- Result: `Success`

## Runtime Seed

The installed app was cleared and seeded through debug-only `run-as com.collectiq.ai.local`.

Seed evidence:

- `qa/screenshots/reconstruction/sprint_07_detail/runtime_seed_prefs.xml`

The seed includes:

- one populated trading-card Detail record with gallery images, stored AI reasoning/confidence explanation, explicit rarity, pricing, market summary, notes, and recommendation
- one minimal coin record with unavailable valuation data
- completed onboarding flag so App Shell opens directly

## Runtime Checks

Captured evidence:

- `01_launch_home.png/xml`: seeded Home launch with real collection totals
- `02_portfolio_seeded.png/xml`: seeded Portfolio list and Detail entry row
- `03_detail_top.png/xml`: Detail app bar, shared Header, hero, gallery strip, confidence, rarity, title, and value
- `04_detail_mid.png/xml`: stored `AI Review`, key attributes, notes entry
- `07_detail_market_expanded.png/xml`: expanded saved Market Evidence
- `09_detail_price_alerts.png/xml`: evidence-only `Value Evidence`, no fabricated price-history series, and Price Alerts section
- `10_edit_dialog.png/xml`: edit dialog opens with persisted item values
- `11_gallery_review.png/xml`: full-screen gallery review with photo index, primary state, edit/delete actions
- `12_tab_scroll_stress.png/xml`: tab switch and scroll stress returns to stable Portfolio state
- `13_runtime_logcat.txt`: Android runtime log capture

## Observed Result

Detail runtime preserved existing navigation, edit dialog access, gallery review, wishlist controls, recommendation, price alerts, and Portfolio return behaviour.

The reconstructed Detail presentation showed stored AI evidence only. The value evidence area displayed saved pricing and market metadata only and explicitly stated that no saved price-history series exists.

Crash scan found no CollectIQ `FATAL EXCEPTION`, `E/flutter`, app ANR, force-finish, or process-death signal. Logcat contains unrelated third-party/system noise from other packages.

## Test Baseline

Focused regression checks passed for analyzer, Detail navigation/actions, Detail empty states, gallery image switching, gallery review/delete/primary safeguards, notes/edit persistence, Home entry to Detail, frozen bootstrap/onboarding/App Shell/Home, scanner focused suite, cloud sync status widget, and Sprint 06 portfolio filter/sort/high-volume checks.

Full suite comparison remained unchanged from the Sprint 06 frozen baseline:

- `534 passed, 16 failed`

The remaining full-suite failures match known baseline debt, including the pre-existing `portfolio carousel edit updates image enhancement metadata` failure.
