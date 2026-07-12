# Sprint 03 freeze record

## 1. Sprint identity

Sprint: App Shell Presentation Reconstruction

Branch: `rebuild/product-language-v1`

Freeze date: 2026-07-13

Starting frozen HEAD: `f849198c4c1eb52ba1c1b54c303a45d4d67e6cc6`

Freeze HEAD before this governance commit: `a39dddf5a4e54f886d09a2729681a39ae600fdcd`

## 2. Final implementation commit chain

Sprint 03 implementation commits:

- `70c495c` docs: specify app shell reconstruction sprint
- `8a4c1da` feat: reconstruct app shell presentation
- `d042e47` test: validate app shell navigation and lifecycle
- `a39dddf` chore: add app shell reconstruction runtime evidence

## 3. Approved scope

Sprint 03 reconstructed only the post-onboarding app shell presentation and shell-level navigation composition.

Approved ownership:

- application frame after onboarding completion
- bottom navigation presentation
- selected and unselected destination states
- shell-level surfaces and background treatment
- bottom safe-area and system-inset handling
- tab switching presentation
- shell accessibility semantics
- responsive bottom navigation behaviour
- retained-state and performance strategy at the shell boundary

Sprint 03 did not reconstruct Home, Scanner, Portfolio, or Settings feature contents.

## 4. Original shell architecture

Before Sprint 03, PackLox used `MaterialApp(home: AppShell)`.

`AppShell` owned both:

- onboarding-state resolution; and
- the post-onboarding tab scaffold.

Selected-tab state was owned by `appShellTabControllerProvider` / `AppShellTabController`. The shell already used active-destination construction through a switch-like selected-tab builder, not an all-tab retained `IndexedStack`.

The existing shell bottom navigation was implemented through `GlassBottomNavBar` and `NavBarItem`.

## 5. Final shell architecture

The final Sprint 03 shell architecture is approved.

The shell now uses declarative destination descriptors and a Product Language-aligned navigation surface while preserving the existing route model.

Final architecture facts:

- only the active destination is built;
- no unconditional `IndexedStack` exists;
- no all-tab retained subtree architecture was introduced;
- inactive feature trees are not all kept mounted;
- state continuity is owned through Riverpod controllers and a shared `PageStorageBucket`;
- scanner lifecycle is not retained merely because Scanner is a primary tab;
- tab switching does not migrate into route pushes;
- no router migration occurred;
- `MaterialApp(home: AppShell)` remains the entry structure;
- `AppShell` still owns onboarding completion handoff and post-onboarding shell presentation.

## 6. Destination inventory

Primary shell destinations are exactly:

| Index | Label | Icon | Selected icon | Widget |
|---:|---|---|---|---|
| 0 | Home | `Icons.home_outlined` | `Icons.home_rounded` | `HomeScreen(onScanPressed, onImportPhotoPressed, onPortfolioPressed)` |
| 1 | Portfolio | `Icons.inventory_2_outlined` | `Icons.inventory_2_rounded` | `PortfolioScreen(onScanPressed)` |
| 2 | Scan | `Icons.camera_alt_outlined` | `Icons.camera_alt_rounded` | `ScanHubPage(onViewPortfolio)` |
| 3 | Settings | `Icons.settings_outlined` | `Icons.settings_rounded` | `SettingsScreen()` |

No Search or Notifications primary destination was added or approved.

## 7. Lifecycle strategy

Lifecycle strategy is approved.

Sprint 03 uses active-destination-only rendering:

- the selected destination descriptor builds the current feature root;
- inactive destination widget trees are disposed rather than retained as mounted tab subtrees;
- provider/repository/controller state remains the continuity mechanism;
- a shell-level `PageStorageBucket` supports ordinary page-storage continuity without retaining every tab;
- tab switching remains provider state selection, not route pushing.

This strategy preserves the current shell performance shape and keeps resource-sensitive Scanner widgets inactive when the Scan destination is not selected.

## 8. Historical ANR risk

Historical risk recorded:

- PackLox previously had a release-only Android ANR;
- the observed failure involved input-dispatch timeout during repeated Home/Portfolio switching;
- retained all-tab composition was identified as the relevant shell-level risk.

Sprint 03 mitigation:

- active-destination-only rendering;
- no unconditional all-tab retention;
- inactive feature subtree disposal/recreation under the current strategy;
- continuity through controller/provider ownership where required;
- runtime tab-switch stress validation on Android;
- Android screenshots, hierarchy, and log evidence captured.

Sprint 03 does not claim that all future ANR risk is permanently eliminated. It does record that the known previous shell architecture risk was avoided.

## 9. Architecture approval

Architecture is approved.

Preserved:

- frozen Sprint 01 bootstrap and entry behaviour;
- frozen Sprint 02 onboarding behaviour;
- `onboarding_completed_v1`;
- guest and signed-out local access;
- `AppShell` handoff;
- selected-tab provider ownership;
- existing Navigator usage for feature routes;
- existing authentication separation.

Not introduced:

- auth guard;
- named-router migration;
- nested shell navigator;
- Search or Notifications shell destinations;
- backend dependency;
- feature-screen reconstruction.

## 10. Performance approval

Performance and lifecycle strategy are approved.

The shell does not eagerly mount Home, Portfolio, Scan, and Settings together. Decorative navigation animation is short and respects reduced-motion widget-test coverage. No artificial tab-switch delay was introduced.

Runtime stress switching completed without an observed input lock or ANR on the Samsung device.

## 11. Runtime approval

Runtime behaviour is approved.

Observed on Samsung SM E625F, Android 13:

- first-run onboarding still appeared before shell entry;
- `Explore Dashboard` handed off to Home;
- Home, Portfolio, Scan, and Settings were reachable from the bottom navigation;
- selected and unselected treatments updated correctly;
- rapid tab switching remained responsive;
- post-stress shell stayed on Portfolio;
- no observed input lock occurred;
- no observed ANR occurred.

## 12. Product Language approval

Product Language fit is approved.

Shell navigation classification: **B. Composition of approved Product Language foundation primitives**.

The navigation treatment uses:

- `PackLoxTokens.background`;
- `PackLoxTokens.surface`;
- `PackLoxTokens.border`;
- `PackLoxTokens.blue`;
- `PackLoxTokens.cyan`;
- `PackLoxTokens.textPrimary`;
- `PackLoxTokens.textSecondary`;
- `AppSpacing`;
- `AppRadius`;
- `PackLoxMotionTheme`;
- `MotionTapScale`;
- Flutter `SafeArea`;
- Flutter `Semantics`.

It remains implemented in the existing compatibility widget `GlassBottomNavBar`. It is not recorded as an existing approved Product Language component and is not automatically promoted into the Product Language by this freeze.

Future Design Studio review may decide whether the shell navigation should become an official reusable Product Language component.

## 13. Visual approval

Visual evidence is approved for Sprint 03 freeze.

Evidence directory:

- `qa/screenshots/reconstruction/sprint_03_app_shell/`

Captured screenshots include:

- `home_selected.png`;
- `portfolio_selected.png`;
- `scan_selected.png`;
- `settings_selected.png`;
- `post_stress_portfolio_selected.png`.

The captured shell shows the approved Product Language-aligned navigation surface, selected destination state, unselected destination state, and bottom safe-area ownership.

## 14. Accessibility and responsive approval

Accessibility and responsive behaviour are approved for freeze based on combined widget-test and runtime evidence.

Widget-test evidence:

- selected semantics move between destinations;
- primary navigation contains only Home, Portfolio, Scan, and Settings;
- reduced-motion tab switching does not depend on artificial timers;
- large text and narrow width do not overflow the shell navigation in focused tests;
- light and dark shell navigation render without overflow in focused tests.

Runtime hierarchy evidence:

- `shell_hierarchy.xml` contains `Primary navigation`;
- destination labels are exposed as Home, Portfolio, Scan, and Settings;
- selected state was exposed for Portfolio after stress switching.

Physical-device large text, dark mode, reduced motion, gesture navigation, and landscape were not separately captured and must not be claimed as physical-device evidence.

## 15. Scanner lifecycle approval

Scanner lifecycle behaviour is approved.

Preserved rules:

- Scan is a normal primary destination;
- Scan hub shows bottom navigation;
- bottom navigation hiding remains limited to the pre-existing active-capture-before-result scanner path;
- Scanner widget tree is not retained while another destination is selected;
- scanner state remains controller-owned;
- AppShell does not take ownership of camera resources;
- leaving Scan after a saved result preserves the existing `resetAfterSaved()` behaviour.

## 16. Back and navigation approval

Back and navigation behaviour is approved.

Sprint 03 preserved:

- existing root `MaterialApp(home: AppShell)` structure;
- existing Navigator behaviour for feature routes;
- no shell-specific back-to-Home policy from non-default tabs;
- no onboarding re-entry through shell back navigation after completion;
- no deep-link route added to the shell;
- password-recovery and auth deep-link coordination outside shell routing.

## 17. Tests and validation

Validation results:

- `flutter analyze` - passed;
- `flutter test test/shared_shell_s01_test.dart --reporter=compact` - passed, 2 tests;
- `flutter test test/app_shell_presentation_test.dart --reporter=compact` - passed, 11 tests;
- `flutter test test/bootstrap_entry_presentation_test.dart --reporter=compact` - passed, 12 tests;
- `flutter test test/onboarding_presentation_test.dart --reporter=compact` - passed, 10 tests;
- `flutter build apk --debug --flavor local` - passed;
- `flutter install -d RZ8R213M8ZL --debug --flavor local` - passed;
- `flutter test --reporter=compact` - completed with 530 passed, 19 failed.

The full suite must not be described as passing. The 19 failures remain baseline debt outside Sprint 03 shell changes.

## 18. Runtime evidence

Runtime evidence was captured on:

- device: Samsung SM E625F;
- Android: 13 / API 33;
- device id: `RZ8R213M8ZL`;
- package: `com.collectiq.ai.local`;
- flavor/build: local debug APK.

Evidence directory:

- `qa/screenshots/reconstruction/sprint_03_app_shell/`

Screenshot evidence:

- `initial.png`;
- `onboarding_step2_checkpoint.png`;
- `onboarding_step3_before_handoff.png`;
- `home_selected.png`;
- `portfolio_selected.png`;
- `scan_selected.png`;
- `settings_selected.png`;
- `post_stress_portfolio_selected.png`.

Runtime observation:

- shell navigation runtime pass;
- repeated tab-switch stress pass;
- Home to Portfolio switching;
- Home to Scanner switching;
- Scanner destination activation and deactivation by tab switching;
- absence of observed input lock;
- absence of observed ANR.

Android log evidence:

- `tab_stress_logcat.txt`;
- log scan found no app-attributable ANR, fatal exception, force-close, or input-dispatch timeout marker;
- unrelated device/service noise was present and is non-blocking.

Widget-test evidence:

- default Home selection;
- four-destination inventory;
- destination display;
- selected-state updates;
- repeated selected-tab no-op;
- rapid tab taps;
- inactive Scanner not retained off tab;
- selected semantics;
- light/dark rendering;
- narrow/large-text nav rendering;
- bottom inset ownership;
- reduced-motion tab switching.

Unverified physical-device scenarios:

- gesture navigation variant;
- three-button navigation variant beyond the connected device state shown in screenshots;
- device-level large text;
- device-level dark mode;
- device-level reduced motion;
- landscape.

## 19. Known limitations

- Full test suite still has 19 known failures outside Sprint 03.
- Runtime QA was performed on one Android 13 Samsung device.
- Physical-device dark mode, large text, reduced motion, and landscape screenshots were not captured.
- The shell navigation remains a foundation composition, not a frozen official Product Language component.
- Future feature reconstruction may need additional provider-owned state if PageStorage is insufficient for a destination-specific presentation requirement.

## 20. Explicitly excluded work

- Home presentation reconstruction;
- Scanner presentation reconstruction;
- Portfolio presentation reconstruction;
- Settings presentation reconstruction;
- authentication redesign;
- auth guard introduction;
- router migration;
- backend changes;
- analyzer changes;
- native deep-link changes;
- Search or Notifications destination creation;
- shell lifecycle redesign beyond the approved active-destination descriptor structure;
- artificial tab-switch delay;
- Product Language component promotion for shell navigation.

## 21. Non-blocking future considerations

Future consideration, not a Sprint 03 defect:

- decide whether shell navigation should become an official Product Language component after Design Studio review;
- decide whether AppShell entry resolution and post-onboarding shell responsibilities should later be separated;
- re-evaluate whether `PageStorageBucket` remains sufficient for each reconstructed destination;
- increasingly move destination-level presentation state into providers as Home, Scanner, Portfolio, and Settings are reconstructed.

Do not refactor these items during Sprint 03 freeze.

## 22. Rollback boundary

Rollback is limited to:

- Sprint 03 specification;
- shell destination descriptors;
- shell navigation presentation;
- AppShell integration for descriptor-based active destination rendering;
- focused app shell tests;
- shared shell test expectation update;
- Sprint 03 runtime comparison;
- Sprint 03 runtime evidence;
- this freeze governance record.

No data migration, auth change, backend change, router change, feature-screen reconstruction, or native configuration change is part of the Sprint 03 rollback boundary.

## 23. Freeze declaration

Sprint 03 is frozen as App Shell Presentation Reconstruction.

Approved:

- architecture;
- performance and lifecycle strategy;
- runtime behaviour;
- Sprint 01 and Sprint 02 regression safety;
- Product Language fit as a foundation composition;
- visual evidence;
- accessibility and responsive behaviour;
- scanner lifecycle preservation;
- navigation and back-behaviour preservation;
- full-suite status accepted with the existing 19-failure baseline debt.

Sprint 04 may be planned next as Home Presentation Reconstruction, but no Sprint 04 implementation is authorized by this freeze record.
