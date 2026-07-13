# Sprint 04 test regression analysis

Date: 2026-07-13

Branch: `rebuild/product-language-v1`

Starting HEAD: `a24ca8faca4cd7dd80974980a6716ab45978f39f`

## Captured full-suite regression run

Command:

`C:\Users\hario\Desktop\flutter\bin\flutter.bat test --reporter=expanded *> qa\reconstruction\sprint_04_full_test_output.txt`

Result:

- 525 passed
- 25 failed
- output captured at `qa/reconstruction/sprint_04_full_test_output.txt`

The Sprint 03 full-suite baseline was 530 passed and 19 failed. The extra Sprint 04 failures were isolated to broad widget tests whose Home expectations still referenced removed Home presentation internals or the old Home CTA shape.

## All 25 failures from captured output

| # | Test | Classification |
|---|---|---|
| 1 | `test/analyzer_service_test.dart`: MockAnalyzerProvider consumes the backend analyzer contract when configured | Existing baseline debt: analyzer contract mismatch |
| 2 | `test/scanner_volume_03_structure_test.dart`: Volume 03 scanner structure camera and review use shared scanner controls | Existing baseline debt: scanner reconstruction expectation |
| 3 | `test/scanner_volume_03_structure_test.dart`: Volume 03 scanner structure workspace uses approved copy, shared treatments, and no raw confidence | Existing baseline debt: scanner reconstruction expectation |
| 4 | `test/scanner_volume_03_structure_test.dart`: Volume 03 scanner structure analysing state uses approved progress copy | Existing baseline debt: scanner reconstruction expectation |
| 5 | `test/widget_test.dart`: shows home dashboard content | Sprint 04 Home test expectation drift |
| 6 | `test/widget_test.dart`: home scan button selects Scan tab | Sprint 04 Home test expectation drift |
| 7 | `test/widget_test.dart`: shell recreation returns to Home and Scan still works | Sprint 04 Home test expectation drift |
| 8 | `test/domain_unit_test.dart`: DioAiBackendApiService FastAPI detail error preserves analyzer error code | Existing baseline debt: analyzer/backend contract mismatch |
| 9 | `test/domain_unit_test.dart`: Supabase foundation SIT scripts pass required dart defines without hardcoded secrets | Existing baseline debt: environment/script expectation |
| 10 | `test/widget_test.dart`: scan capture flashes and shows next capture suggestion | Existing baseline debt: scanner workspace expectation |
| 11 | `test/widget_test.dart`: workspace capture next opens camera for the back photo | Existing baseline debt: scanner workspace expectation |
| 12 | `test/widget_test.dart`: capture review acceptance returns to updated workspace | Existing baseline debt: scanner workspace expectation |
| 13 | `test/widget_test.dart`: full workspace scan review analyze loop uses updated photo list | Existing baseline debt: scanner workspace expectation |
| 14 | `test/widget_test.dart`: camera denied UI shows friendly message | Existing baseline debt: scanner camera expectation |
| 15 | `test/widget_test.dart`: camera completion remains on Scan tab | Sprint 04 Home test expectation drift |
| 16 | `test/widget_test.dart`: gallery completion from Home CTA remains on Scan tab | Sprint 04 Home test expectation drift |
| 17 | `test/widget_test.dart`: gallery import confirms enhancement before adding photo | Existing baseline debt: scanner/gallery expectation |
| 18 | `test/widget_test.dart`: gallery import follows review workspace analyze result portfolio flow | Existing baseline debt: scanner/gallery expectation |
| 19 | `test/widget_test.dart`: enhancement preview shows only Original and Enhanced | Existing baseline debt: enhancement expectation |
| 20 | `test/widget_test.dart`: enhancement preview can switch Enhanced back to Original | Existing baseline debt: enhancement expectation |
| 21 | `test/widget_test.dart`: saving enhanced scan preserves portfolio gallery metadata | Existing baseline debt: enhancement metadata expectation |
| 22 | `test/widget_test.dart`: scan preview remains mounted during analyze | Existing baseline debt: scanner preview expectation |
| 23 | `test/widget_test.dart`: premium result shows Enhanced badge when photo is enhanced | Existing baseline debt: enhancement metadata expectation |
| 24 | `test/widget_test.dart`: home scan CTA starts clean after unsaved scan | Sprint 04 Home test expectation drift |
| 25 | `test/widget_test.dart`: portfolio carousel edit updates image enhancement metadata | Existing baseline debt: portfolio enhancement metadata expectation |

## Newly failing versus Sprint 03

These six broad widget tests were newly failing after Sprint 04:

- `shows home dashboard content`
- `home scan button selects Scan tab`
- `shell recreation returns to Home and Scan still works`
- `camera completion remains on Scan tab`
- `gallery completion from Home CTA remains on Scan tab`
- `home scan CTA starts clean after unsaved scan`

Root cause: the broad `test/widget_test.dart` assertions still looked for the removed custom Home hero/CTA keys or old visible copy. Sprint 04 intentionally replaced those with approved Product Language primitives: `PackLoxHeader`, `PackLoxHero`, `PackLoxButton` through the Hero action slot, and `PackLoxEntryTile`.

Fix: update only the broad Home-facing assertions to use the new approved Home surface and visible action text. No production code was changed.

## Frozen expectation review

- `test/bootstrap_entry_presentation_test.dart`: no changes required; focused bootstrap presentation suite passes.
- `test/onboarding_presentation_test.dart`: no changes required; focused onboarding presentation suite passes.
- `test/app_shell_presentation_test.dart`: no changes required; focused shell presentation suite passes.
- `test/home_page_test.dart`: no changes required in remediation; dedicated Sprint 04 focused Home suite passes.
- `test/widget_test.dart`: updated broad Home expectations to align with the already-reconstructed Sprint 04 Home composition while preserving scan and shell handoff intent.

## Validation after remediation

- `flutter analyze`: passed.
- `flutter test test\bootstrap_entry_presentation_test.dart --reporter=compact`: passed, 12 tests.
- `flutter test test\onboarding_presentation_test.dart --reporter=compact`: passed, 10 tests.
- `flutter test test\app_shell_presentation_test.dart --reporter=compact`: passed, 11 tests.
- `flutter test test\home_page_test.dart --reporter=compact`: passed, 12 tests.
- Targeted six newly failing broad widget tests: all passed individually.
- Full suite after remediation: 531 passed, 19 failed.

The full suite must still not be described as passing. The remaining 19 failures are the known baseline debt groups outside the Sprint 04 Home remediation.
