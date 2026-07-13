# Full test suite baseline debt

Date: 2026-07-13

Sprint 01 HEAD: `0f5c93c39abdc747770205ff0eb51715d602b34e`

## History

Sprint 01:

- 509 passed
- 19 failed

Sprint 02:

- 519 passed
- 19 failed

The Sprint 02 failure count did not increase from the recorded Sprint 01 baseline. The ten additional passing tests correspond to the new Sprint 02 onboarding coverage. The existing 19 failures remain outside Sprint 02 onboarding changes.

Sprint 03:

- 530 passed
- 19 failed

The Sprint 03 failure count remained unchanged from the recorded Sprint 01 and Sprint 02 baseline. The eleven additional passing tests correspond to the new Sprint 03 app shell coverage. The existing 19 failures remain outside Sprint 03 app shell changes.

Sprint 04 initial:

- 525 passed
- 25 failed

Sprint 04 remediated:

- 531 passed
- 19 failed

The Sprint 04 initial run exposed six new failures in broad Home-facing widget tests. Those tests still referenced stale Home copy, removed custom hero internals, or the removed Home-specific CTA key after the approved Home reconstruction. The expectations were reconciled to the approved Sprint 04 Home surface without weakening frozen Sprint 01, Sprint 02, or Sprint 03 contracts.

The remediated Sprint 04 full-suite result returned to the documented 19-failure baseline. The extra passing test reflects Sprint 04 Home coverage and expectation reconciliation. The full suite must not be described as passing.

Sprint 05 pre-remediation:

- 526 passed
- 24 failed

Sprint 05 remediated:

- 534 passed
- 16 failed

Sprint 05 is non-regressive against the Sprint 04 remediated baseline. The remediated Sprint 05 failure count improved by three compared with Sprint 04, from 19 failures to 16 failures. New Scanner coverage increased passing tests, obsolete Scanner structure failures were removed, eight stale broad widget expectations were reconciled against actual Sprint 05 scanner contracts, and one genuine duplicate lost-picker recovery defect was fixed.

The Sprint 05 full suite must not be described as entirely passing.

Sprint 03 focused validation:

- Sprint 01 bootstrap tests passed: 12
- Sprint 02 onboarding tests passed: 10
- Sprint 03 app shell tests passed: 11
- shared shell S01 tests passed: 2
- `flutter analyze`: passed
- Android local debug build: passed

Sprint 04 focused validation:

- Sprint 01 bootstrap tests passed: 12
- Sprint 02 onboarding tests passed: 10
- Sprint 03 app shell tests passed: 11
- Sprint 04 Home tests passed: 12
- `flutter analyze`: passed
- Android local debug build: passed
- Android install/launch on Samsung SM E625F: passed
- physical Home/App Shell stress sequence: passed

Sprint 05 focused validation:

- eight target tests individually passed
- eight target tests together passed
- focused Scanner suite: 51 passed
- frozen Sprint 01-04 suite: 45 passed
- `flutter analyze`: passed

The full suite must not be described as passing. Do not fix unrelated failures as part of Sprint freeze governance.

## Sprint 01 baseline context

This baseline was captured after Sprint 01 implementation and before freeze. The failures are outside Sprint 01 changed files and are not fixed in the freeze task.

Known failure groups reported:

- analyzer provider/contract expectation, including `expected gemini, actual null`
- scanner widget copy expectations, including missing expected scanner review/workspace text
- portfolio metadata/widget expectations, including missing expected enhancement metadata labels

Required later classification for each failure:

- obsolete expectation
- genuine regression
- environment/configuration dependency
- reconstruction mismatch
- analyzer contract mismatch

Do not treat this document as approval to skip focused tests for future sprints. Each reconstruction sprint must continue to run its own focused tests and then report the full-suite baseline honestly.
