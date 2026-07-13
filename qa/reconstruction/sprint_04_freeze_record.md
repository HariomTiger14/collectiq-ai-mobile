# Sprint 04 freeze record

## 1. Sprint identity

Sprint: Home Presentation Reconstruction

Branch: `rebuild/product-language-v1`

Freeze date: 2026-07-13

Frozen starting HEAD: `f3b754f14b40e2b42f8e0e4f09424c50b20e0c1c`

Final Sprint 04 HEAD before this governance commit: `625b9cab1e22fb45e8b8593149edcfefa8c5c505`

## 2. Complete Sprint commit chain

Sprint 04 commits:

- `f3b754f` docs: specify home reconstruction sprint
- `4fd62ee` feat: reconstruct home presentation
- `658caba` feat: reconstruct home presentation
- `a71df68` test: validate home presentation and states
- `a24ca8f` chore: add home reconstruction runtime evidence
- `295dcde` fix: reconcile home widget expectations
- `330d6db` test: document sprint 04 regression baseline
- `2ff30a1` chore: record sprint 04 device diagnostics
- `625b9ca` chore: complete home runtime validation

## 3. Final Sprint 04 HEAD

Final Sprint 04 implementation/runtime HEAD: `625b9cab1e22fb45e8b8593149edcfefa8c5c505`.

This freeze-governance commit records the approval decision and does not alter production or test source.

## 4. Approved scope

Sprint 04 reconstructed only Home presentation.

Approved ownership:

- Home visual hierarchy;
- approved Header and Hero composition;
- primary Scan action presentation;
- quick-action presentation;
- collection snapshot presentation;
- recent-item presentation;
- empty-state presentation;
- valuation note presentation;
- Home responsive, accessibility, motion, and reduced-motion behaviour;
- Home/App Shell runtime stress validation.

Sprint 04 did not reconstruct Scanner, Portfolio, Detail, Settings, Authentication, backend services, routing, or App Shell lifecycle.

## 5. Original Home architecture

Before Sprint 04, Home was a presentation-heavy custom surface with bespoke greeting/hero treatment, local action cards, elastic/parallax/reveal-heavy motion, duplicated first-viewport action hierarchy, and presentation-specific metric panels.

The underlying architecture was already local-first and controller-driven. Home read portfolio state and invoked existing scan/import/portfolio callbacks; it did not own a backend, repository, or independent asynchronous data contract.

## 6. Final Home architecture

Final Home architecture is approved.

Home remains synchronous and local-first:

- Home watches `portfolioControllerProvider`.
- Home reads `orderedItems`.
- Analytics remain owned by `CollectorDashboardAnalyticsService.build(items)`.
- Presentation performs only presentation-safe shaping and formatting.
- No repository or service ownership moved into Home presentation.
- No independent Home loading, error, or retry contract exists.
- No such contract was invented.
- No artificial loading delay was added.

## 7. Original and final information hierarchy

Original hierarchy:

1. custom greeting surface;
2. bespoke animated hero;
3. standalone scan card/action;
4. custom secondary action cards;
5. duplicated metric/summary panels;
6. animated recent/reveal rows.

Final hierarchy:

1. approved Header;
2. approved Hero;
3. approved primary Scan action through the Hero action slot and Button System;
4. approved Entry Tiles;
5. collection snapshot;
6. recent real items;
7. grounded valuation note.

Elastic/parallax/reveal-heavy Home motion and bespoke action-card variants were removed.

## 8. Product Language component mapping

Existing approved Product Language components:

- `PackLoxHeader` v1.0.1
- `PackLoxHero` v1.0.1
- `PackLoxEntryTile` v1.0.0
- `PackLoxButton` v1.0.0 through the Hero action slot

Compositions of approved primitives:

- collection snapshot;
- recent-item rows;
- valuation note.

New Product Language candidates: none.

No Home-specific Header, Hero, Entry Tile, or Button variant was introduced.

## 9. Data and metric inventory

Home displays only data derived from real saved items:

- item count uses `items.length`;
- collection value uses only displayable valued items;
- unavailable values are not coerced to zero;
- genuine zero-valued estimates may display zero;
- empty collection remains distinct from a zero-value collection;
- partial-value collections retain real items and valid valued totals;
- recent items use real ordered items;
- top/latest falls back from highest displayable-value item to latest real item;
- valuation-needed count uses saved items without displayable valuation.

No trends, gains, system health, backend status, raw confidence, or other unsupported metrics were fabricated.

Physical-device evidence showed the genuine empty Home state because the local device had no collection data. Physical loaded-data evidence was not captured.

## 10. Data-integrity approval

Data integrity is approved.

Loaded, unavailable-value, zero-value, partial-value, and empty states are covered by focused Home widget tests. Physical runtime evidence covers the honest empty local device state.

## 11. Architecture approval

Architecture is approved.

Preserved:

- frozen Sprint 01 bootstrap and entry behaviour;
- frozen Sprint 02 onboarding behaviour;
- frozen Sprint 03 App Shell navigation and lifecycle;
- selected-tab ownership;
- Home controller/provider ownership;
- portfolio data source ownership;
- guest and signed-out local access;
- scanner entry callback;
- portfolio callback;
- backend contracts.

Not introduced:

- auth guard;
- router migration;
- backend dependency;
- Home repository/service ownership;
- independent Home loading/error/retry state.

## 12. Regression-safety approval

Regression safety is approved.

Full-suite history:

- Sprint 04 initial: 525 passed, 25 failed.
- Sprint 04 remediated: 531 passed, 19 failed.

The six newly failing tests were stale broad Home copy/hero expectations in `test/widget_test.dart`. They were reconciled to the approved Sprint 04 Home surface without weakening frozen Sprint 01-03 contracts. The final full-suite failure count returned to the documented 19-failure baseline. The full suite must not be described as passing.

## 13. Performance approval

Performance is approved for the validated Home/App Shell runtime sequence.

Home no longer uses the removed elastic/parallax/reveal-heavy presentation stack. The final Home surface is bounded, local-first, and scrollable. Physical-device stress covered repeated Home/Portfolio switching, repeated Home/Scan switching, Home scroll followed by tab switching, and rapid tab switching.

This record does not claim that all possible future ANR risk is permanently eliminated. It records that the known Home/App Shell stress sequence passed during this run.

## 14. Visual approval

Visual fidelity is approved from Samsung physical-device evidence.

Evidence directory:

- `qa/screenshots/reconstruction/sprint_04_home/`

Captured:

- `empty_home_first_viewport.png`
- `empty_home_lower_content.png`
- `scan_action_handoff.png`
- `portfolio_action_handoff.png`
- `home_after_tab_scroll_stress.png`

The captured Home evidence shows the approved Header, approved Hero, approved Hero Button action, approved Entry Tiles, empty collection snapshot, and shell navigation.

## 15. Runtime approval

Runtime behaviour is approved.

Observed on Samsung SM E625F, Android 13 / API 33, device id `RZ8R213M8ZL`:

- ADB authorised;
- Flutter device discovery passed;
- local debug build passed;
- install passed;
- launch passed;
- foreground activity confirmed as `com.collectiq.ai.local/com.collectiq.ai.MainActivity`;
- Home opened through frozen App Shell;
- empty Home state observed honestly;
- Header, Hero, Hero Button, Entry Tiles, snapshot, Scan handoff, and Portfolio handoff observed;
- repeated Home -> Portfolio switching passed;
- repeated Home -> Scan switching passed;
- Home scroll stress passed;
- rapid tab switching passed;
- no observed overflow;
- no final blank frame;
- no route lock;
- no input lock;
- no ANR;
- no foreground loss.

## 16. Accessibility and responsive approval

Accessibility and responsive behaviour are approved for freeze based on combined widget-test and runtime evidence.

Widget-test evidence covers light/dark, narrow width, large text scale, reduced motion, empty, loaded, unavailable, zero-value, and partial-value Home states.

Physical-device evidence covers the default connected Samsung theme, orientation, navigation mode, and text scale.

Dark mode, device-level large text, reduced motion, landscape, and alternate navigation-mode screenshots were not captured physically and are not claimed as physical-device evidence.

## 17. Quick-action and navigation approval

Quick-action and navigation behaviour is approved.

Physical-device evidence confirms:

- Hero Scan action hands off to Scanner;
- Entry Tile Portfolio action hands off to Portfolio;
- bottom navigation returns to Home;
- Home remains reachable and responsive after repeated tab switching.

Recent-item detail navigation is covered by focused widget tests. It was not physically captured because the local device had an empty collection.

## 18. Empty and partial-data behaviour

Empty state is approved and physically captured. It remains honest, distinct from zero-value data, and does not fabricate totals.

Partial-value behaviour is approved by source tracing and focused widget tests. It was not physically captured because no natural partial-value local data was available.

Loaded collection behaviour is approved by source tracing and focused widget tests. It was not physically captured because the device had an empty local collection.

## 19. Non-applicable loading/error/retry states

Home has no independent asynchronous loading, error, or retry contract. No fake Home loading spinner, retry copy, or Home-specific error state was introduced.

Existing portfolio controller state remains owned by the portfolio feature.

## 20. Tests and validation

Focused validation:

- `flutter analyze`: passed.
- `flutter test test/bootstrap_entry_presentation_test.dart --reporter=compact`: passed.
- `flutter test test/onboarding_presentation_test.dart --reporter=compact`: passed.
- `flutter test test/app_shell_presentation_test.dart --reporter=compact`: passed.
- `flutter test test/home_page_test.dart --reporter=compact`: passed.

Full-suite validation:

- Sprint 04 initial: 525 passed, 25 failed.
- Sprint 04 remediated: 531 passed, 19 failed.

The remaining 19 failures are documented baseline debt and remain outside Sprint 04 Home changes.

## 21. Android build install and launch evidence

Device: Samsung SM E625F

Android: 13 / API 33

Device ID: `RZ8R213M8ZL`

Package: `com.collectiq.ai.local`

APK: `build\app\outputs\flutter-apk\app-local-debug.apk`

Commands/results:

- `flutter devices --device-timeout 30`: passed.
- `flutter build apk --debug --flavor local -v`: passed.
- `flutter install -d RZ8R213M8ZL --debug --flavor local`: passed.
- `adb shell monkey -p com.collectiq.ai.local -c android.intent.category.LAUNCHER 1`: passed.
- foreground check: `com.collectiq.ai.local/com.collectiq.ai.MainActivity`.

## 22. Physical-device evidence

Evidence directory:

- `qa/screenshots/reconstruction/sprint_04_home/`

Evidence files:

- `empty_home_first_viewport.png`
- `empty_home_first_viewport.xml`
- `empty_home_lower_content.png`
- `scan_action_handoff.png`
- `scan_action_handoff.xml`
- `portfolio_action_handoff.png`
- `portfolio_action_handoff.xml`
- `home_after_tab_scroll_stress.png`
- `home_after_tab_scroll_stress.xml`
- `tab_scroll_stress_logcat.txt`

## 23. Android log findings

Log path:

- `qa/screenshots/reconstruction/sprint_04_home/tab_scroll_stress_logcat.txt`

The log showed no observed:

- app ANR;
- input-dispatch timeout;
- Flutter framework exception;
- `E/flutter`;
- uncaught app exception.

Unrelated system/Bluetooth/Google Auth noise was present and is non-blocking. App-specific lines were normal input/window traces plus expected Scanner lost-picker recovery logs when visiting Scan.

## 24. Known limitations

Known limitations:

- loaded collection state was not physically captured because the device had an empty local collection;
- partial-value state was not physically captured because no natural partial-value local data was available;
- recent-item detail action was not physically captured because no recent items existed;
- loading/error/retry states are not applicable because Home has no independent asynchronous state contract;
- device-level dark mode, large text, reduced motion, landscape, and alternate navigation-mode evidence were not captured;
- loaded and partial-data correctness are supported by source tracing and focused widget tests, not physical screenshots.

## 25. Evidence limitations

Evidence limitations are intentionally preserved:

- physical screenshots cover the honest empty state only;
- widget tests and source tracing support loaded and partial-data correctness;
- unsupported or non-applicable states were not staged or fabricated;
- approval is limited to the validated Home/App Shell runtime sequence.

## 26. Explicitly excluded work

Explicitly excluded:

- Scanner presentation reconstruction;
- Portfolio reconstruction;
- Detail reconstruction;
- Settings reconstruction;
- Authentication redesign;
- App Shell redesign;
- Home redesign beyond Sprint 04 approved scope;
- backend changes;
- router migration;
- new Product Language component creation;
- fabricated data states.

## 27. Rollback boundary

Rollback is limited to:

- Sprint 04 specification;
- Home presentation composition;
- focused Home tests;
- broad Home expectation reconciliation in `test/widget_test.dart`;
- Sprint 04 runtime comparison;
- Sprint 04 diagnostics and regression documentation;
- Sprint 04 runtime evidence;
- this freeze record.

Rollback does not require data migration, backend rollback, router rollback, authentication rollback, or frozen Sprint 01-03 rollback.

## 28. Freeze declaration

Sprint 04, Home Presentation Reconstruction, is frozen at `625b9cab1e22fb45e8b8593149edcfefa8c5c505` pending this governance commit.

Approved statuses:

- Architecture: approved.
- Data integrity: approved.
- Regression safety: approved.
- Performance: approved for the validated Home/App Shell runtime sequence.
- Visual fidelity: approved from Samsung physical-device evidence.
- Runtime behaviour: approved.
- Overall: frozen.

## 29. Phase 1 approved authority amendment

Date: 2026-07-13

The visual approval in this Sprint 04 freeze record is amended for Home first-viewport authority alignment by Phase 1 of the Core Screen Visual Remediation Program.

Superseding amendment:

- `qa/reconstruction/home_visual_freeze_amendment.md`

Runtime comparison:

- `qa/reconstruction/home_approved_authority_runtime_comparison.md`

Evidence:

- `qa/screenshots/approved_authority_remediation/home/comparison/phase1_home_authority_before_after_first_viewport.png`
- `qa/screenshots/approved_authority_remediation/home/after/phase1_home_after_empty_first_viewport.png`
- `qa/screenshots/approved_authority_remediation/home/after/phase1_home_after_empty_mid_scroll.png`
- `qa/screenshots/approved_authority_remediation/home/after/phase1_home_after_empty_end_scroll.png`
- `qa/screenshots/approved_authority_remediation/home/after/phase1_home_after_tab_stress.png`

Phase 1 supersedes the earlier approved large blue Hero/Entry Tile first-viewport treatment with the approved dark empty collection card, collection status, Popular Categories, and compact lower-order quick actions.

The amendment does not reopen or alter Scanner, Portfolio, Detail, Settings, Authentication, backend, routing, App Shell lifecycle, or Product Language definitions.

Phase 1 validation summary:

- `adb devices -l`: `RZ8R213M8ZL` reported as `device`.
- `flutter analyze`: passed.
- `flutter build apk --debug`: passed.
- `adb install -r build\app\outputs\flutter-apk\app-prod-debug.apk`: passed.
- Focused Home/shared/app-shell regression validation: passed.
- Full suite: `546 passed, 24 failed`; full suite is not green and remaining failures are outside this Home visual authority amendment.

## 18. Phase 1 Home Fidelity Amendment

Date: 2026-07-13

The visual portion of this Sprint 04 freeze is amended by the later Phase 1 Approved Visual Authority correction. The Sprint 04 architecture and data-integrity decisions remain unchanged, but the original Hero/entry-tile visual approval is superseded for the empty Home first viewport.

Current authority evidence:

- `qa/reconstruction/home_phase1_fidelity_measurements.md`
- `qa/reconstruction/home_phase1_fidelity_acceptance.md`
- `qa/screenshots/approved_authority_remediation/home/comparison/phase1_fidelity_approved_vs_after.png`

Updated validation result:

- `flutter test --reporter=compact` completed with `554 passed, 16 failed` in `qa/reconstruction/phase1_fidelity_full_test_output.txt`.
- Home-focused tests and affected broad Home regressions passed.
- Remaining full-suite failures are outside Home authority fidelity scope.
