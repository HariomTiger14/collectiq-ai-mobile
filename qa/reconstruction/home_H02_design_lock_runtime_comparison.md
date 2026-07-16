# PackLox Home H02 Design Lock Runtime Comparison

Date: 2026-07-16
Flutter repo: `C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction`
Branch: `rebuild/product-language-v1`
Runtime HEAD: `930d9a51d52036f706fc2908d19e3a43fe84e00a`

## Authority

Design Platform commit: `1c8199a6b07b84c7e2667ec4fc8b01b5bf0686d5`
Authority PNG: `qa/screenshots/design_lock/home/H02/authority/Home_H02_Final.png`
Authority PNG dimensions: `853x1844`
Authority PNG SHA256: `117F5E10BAA05EB1AAB71006BBDACC3AE989F1BD88A3225556D0BE52FD0628E3`

## Runtime Evidence

Device: Samsung SM-E625F, `RZ8R213M8ZL`, Android 13 / API 33
Package: `com.collectiq.ai.local`
Activity: `com.collectiq.ai.local/com.collectiq.ai.MainActivity`
Build: Gradle fallback, `android\gradlew.bat assembleLocalDebug`
JDK: `C:\Program Files\Android\Android Studio\jbr`, OpenJDK 21.0.10
APK: `build\app\outputs\flutter-apk\app-local-debug.apk`, 191,822,483 bytes

Samsung screenshots:

- `qa/screenshots/design_lock/home/H02/runtime/home_H02_first_viewport.png`
- `qa/screenshots/design_lock/home/H02/runtime/home_H02_full_scroll.png`
- `qa/screenshots/design_lock/home/H02/runtime/home_H02_after_tab_return.png`
- `qa/screenshots/design_lock/home/H02/runtime/home_H02_header_closeup.png`
- `qa/screenshots/design_lock/home/H02/runtime/home_H02_hero_closeup.png`
- `qa/screenshots/design_lock/home/H02/runtime/home_H02_collection_status_closeup.png`
- `qa/screenshots/design_lock/home/H02/runtime/home_H02_categories_closeup.png`
- `qa/screenshots/design_lock/home/H02/runtime/home_H02_quick_actions_closeup.png`

Direct comparison:

- `qa/screenshots/design_lock/home/H02/comparison/Home_H02_Final_vs_Samsung_Runtime.png`

## H02 Reproduction

No data clear was required. The app launched into first-run onboarding because no `shared_prefs` files existed. Onboarding was completed through the normal visible UI, then Home was opened through the existing App Shell. With no local portfolio seed, `portfolio.orderedItems.isEmpty` produced the actual H02 empty state.

## Area Classification

| Area | Classification | Notes |
| --- | --- | --- |
| Header placement | MATCH | Header appears at the top with Samsung status bar inset and shared App Shell spacing. |
| Greeting hierarchy | MATCH | `Your collection` and `Collector` hierarchy matches the implemented H02 contract. |
| Notification affordance | MATCH | Disabled notification affordance is present; no fake count is shown. |
| Hero height | ACCEPTABLE RESPONSIVE ADAPTATION | Runtime uses the locked Flutter H02 responsive card proportions on 1080x2400 Samsung. |
| Hero icon scale | ACCEPTABLE RESPONSIVE ADAPTATION | Runtime icon is intentionally secondary and smaller per visual-weight correction. |
| Hero text hierarchy | MATCH | Title, helper copy, and CTA hierarchy are clear and stable. |
| CTA size/style | MATCH | Blue primary CTA renders at expected runtime prominence and preserves scan callback. |
| Collection Status structure | ACCEPTABLE RESPONSIVE ADAPTATION | Runtime uses the implemented honest three-metric structure; the authority PNG shows a fourth Scans slot that is not supported by the H02 no-fabrication contract. |
| Zero/unavailable semantics | MATCH | Hierarchy exposes `Items 0`, `Est. value unavailable`, and `Avg. condition unavailable`; no fabricated values. |
| Category icon semantics | ACCEPTABLE RESPONSIVE ADAPTATION | Runtime uses collectible-semantic icons for Cards, Coins, Figures, More. This intentionally differs from the PNG where Coins/Figures used less accurate symbols. |
| Category tile density | MATCH | Four compact category tiles are visible in first viewport. |
| Quick Actions | MATCH | Scan, Import, Portfolio appear with existing callbacks. |
| Spacing rhythm | MATCH | First viewport density matches the H02 runtime contract and keeps all sections visible. |
| Dark surfaces | MATCH | Dark canvas, raised surfaces, borders, and bottom nav are consistent. |
| First viewport density | MATCH | Header, hero, status, categories, quick actions, and bottom nav are visible on Samsung. |
| Bottom-nav clearance | MATCH | Bottom navigation clears Samsung three-button navigation. |

## Logcat / Stress

Validated:

- Home first entry
- Home scroll
- Home -> Scanner -> Home
- Home -> Portfolio -> Home
- repeated Home tab return
- app background/foreground

Logcat files:

- `qa/screenshots/design_lock/home/H02/logs/home_H02_focused_logcat.txt`
- `qa/screenshots/design_lock/home/H02/logs/home_H02_critical_log_scan.txt`

Result: no app-attributable fatal exception, AndroidRuntime crash, `E/flutter`, ANR, input dispatch timeout, overflow, route assertion, input lock, or process death was observed.

## Result

No production or test code changes were required during the physical runtime gate. The Samsung runtime is ready for Product Owner visual approval. This record does not claim final Product Owner approval.
