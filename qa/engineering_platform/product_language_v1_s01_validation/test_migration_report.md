# S01 test migration report

## Root cause

The legacy `scan_hub_page_test.dart` could not load because it referenced eleven removed `ScannerS01VisualValues` geometry members. Geometry now belongs to shared Product Language components. Additional broad tests asserted the old hero copy, collectible visual key, and reached through the former `FilledButton` anatomy. The apparent loading stall was the runner remaining at test-file load while compilation failed. Camera route settling was also made deterministic by replacing `pumpAndSettle` with finite 300/600 ms pumps.

## Replacements

- Exact local hero/tile geometry assertions were replaced with `PackLoxHeader`, `PackLoxHero`, and three `PackLoxEntryTile` type assertions.
- Scanner variants and non-null callbacks are asserted directly.
- Old copy and local visual keys were replaced with the approved shared hero copy.
- Gallery setup now taps the public reusable tile key instead of casting a compatibility descendant to `FilledButton`.
- The source-structure test now proves shared component imports/usages and rejects local `ScanHubHero`/`ScanHubEntryTile` clones.

## Preserved behavior

Greeting periods, authenticated first name, Collector fallback, notification semantics, camera open/close, gallery callback, sample handoff, active-session behavior, responsive widths 360/390/412/430, large text, shared shell navigation, selected Scan semantics, accessibility labels, and absence of workspace controls remain covered.

## Results

- Focused Product Language/S01/shell: 23 passed.
- Migrated broad widget/structure set: 141 passed.
- Full Flutter suite: 520 passed, no hang.
- Flutter analyze: no issues.
