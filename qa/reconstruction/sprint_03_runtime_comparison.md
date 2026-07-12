# PackLox Frontend Reconstruction Sprint 03 Runtime Comparison

Date: 2026-07-13  
Branch: `rebuild/product-language-v1`  
Starting frozen HEAD: `f849198c4c1eb52ba1c1b54c303a45d4d67e6cc6`  
Device: Samsung SM E625F, Android 13 (API 33), device id `RZ8R213M8ZL`  
Build exercised: `flutter build apk --debug --flavor local` -> `build\app\outputs\flutter-apk\app-local-debug.apk`  
Installed package: `com.collectiq.ai.local`

## Scope

Sprint 03 covered the post-onboarding app shell presentation only:

- shell-level destination inventory;
- bottom navigation presentation;
- selected and unselected destination states;
- safe-area/inset ownership;
- active destination lifecycle;
- accessibility labels and selected state;
- reduced-motion and tab-switching behavior.

Home, Scanner, Portfolio, Settings feature content, backend behavior, auth behavior, routing model, and onboarding persistence were intentionally not reconstructed in this sprint.

## Runtime evidence

Evidence captured under `qa/screenshots/reconstruction/sprint_03_app_shell/`:

- `initial.png` — device began on first-launch onboarding before Sprint 03 shell QA.
- `onboarding_step2_checkpoint.png` — intermediate onboarding checkpoint while advancing through the real flow.
- `onboarding_step3_before_handoff.png` — final onboarding step before choosing the dashboard handoff.
- `home_selected.png` — Home destination selected after Explore Dashboard handoff.
- `portfolio_selected.png` — Portfolio destination selected.
- `scan_selected.png` — Scan destination selected on the existing Scan hub.
- `settings_selected.png` — Settings destination selected.
- `post_stress_portfolio_selected.png` — shell remained responsive after rapid tab switching.
- `shell_hierarchy.xml` — Android UI hierarchy dump after stress switching.
- `tab_stress_logcat.txt` — logcat excerpt after rapid tab switching.

## Intended vs observed shell composition

Intended:

- app starts at `MaterialApp.home -> AppShell`;
- incomplete onboarding continues to show the frozen Sprint 02 onboarding flow;
- completed onboarding shows the app shell with the preserved four destinations:
  - Home, index `0`;
  - Portfolio, index `1`;
  - Scan, index `2`;
  - Settings, index `3`;
- no Search, Notifications, auth gate, named-router migration, backend dependency, or new destination is introduced.

Observed on device:

- first launch correctly displayed the frozen onboarding sequence;
- choosing `Explore Dashboard` completed onboarding and opened Home;
- all four shell destinations were reachable from the bottom navigation;
- only the selected destination showed the filled blue/cyan selected treatment;
- unselected destinations stayed muted and tappable;
- `shell_hierarchy.xml` exposed `Primary navigation` with `Home`, `Portfolio`, `Scan`, and `Settings`; after stress switching, `Portfolio` had `selected="true"`.

## Lifecycle and ANR risk

The Sprint 03 implementation deliberately avoided the historical release-only ANR failure mode from unconditional `IndexedStack` retention.

Current shell lifecycle:

- `AppShell` builds one active destination at a time from destination descriptors;
- inactive feature trees are not retained as mounted tab subtrees;
- no all-tab `IndexedStack`, unconditional `Offstage` tab set, or always-mounted tab tree was introduced;
- shell-level continuity is limited to Riverpod controllers and a shared `PageStorageBucket`.

Runtime result:

- rapid Home -> Portfolio -> Scan -> Settings -> Scan -> Portfolio switching completed without visible stall;
- post-stress screenshot remained interactive on Portfolio;
- logcat scan found no ANR, fatal exception, force-close, or input-dispatch timeout marker attributable to the app.

Non-blocking log notes:

- `tab_stress_logcat.txt` includes unrelated device/service noise such as Google Play auth warnings, Bluetooth scan lines, Crashlytics initialization, and one WorkManager cancellation entry.
- No Sprint 03 shell crash or app-not-responding marker was observed.

## Safe area and insets

Observed:

- the bottom navigation surface owned the bottom inset area above Android system navigation;
- content was not visually hidden behind the shell nav in the captured Home, Portfolio, Scan, or Settings states;
- the Scan hub retained the bottom navigation; nav hiding remains limited to the pre-existing active-capture scanner path.

## Accessibility

Widget tests verified:

- semantic selected state moves between destinations;
- primary destination inventory contains only Home, Portfolio, Scan, Settings;
- reduced-motion tab switching does not depend on artificial timers.

Runtime hierarchy confirmed:

- `Primary navigation` container is present;
- each destination label appears in the Android hierarchy;
- selected state is exposed for the active destination after stress switching.

## Validation summary

Focused validation:

- `flutter analyze` — passed.
- `flutter test test/shared_shell_s01_test.dart --reporter=compact` — passed, 2 tests.
- `flutter test test/app_shell_presentation_test.dart --reporter=compact` — passed, 11 tests.
- `flutter test test/bootstrap_entry_presentation_test.dart --reporter=compact` — passed, 12 tests.
- `flutter test test/onboarding_presentation_test.dart --reporter=compact` — passed, 10 tests.

Full suite:

- `flutter test --reporter=compact` — completed with `+530 -19`.
- This preserves the prior known full-suite failure count after adding 11 Sprint 03 tests; the Sprint 03 focused shell/regression set is green.

Android runtime:

- `flutter build apk --debug --flavor local` — passed.
- `flutter install -d RZ8R213M8ZL --debug --flavor local` — passed.
- Samsung runtime tab navigation and stress-switch evidence captured.

## Limitations and freeze notes

- Runtime QA was performed on one Android 13 Samsung device only.
- Visual approval remains `runtime_ready`; this document is not a visual-approval freeze by itself.
- Full-suite failures remain pre-existing/out-of-scope for Sprint 03 and should stay tracked separately from shell reconstruction.
- Sprint 03 did not change the onboarding persistence key, auth guard behavior, backend integrations, router model, feature destination contents, or the original dirty worktree.
