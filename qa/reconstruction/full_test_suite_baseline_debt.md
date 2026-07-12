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

Sprint 03 focused validation:

- Sprint 01 bootstrap tests passed: 12
- Sprint 02 onboarding tests passed: 10
- Sprint 03 app shell tests passed: 11
- shared shell S01 tests passed: 2
- `flutter analyze`: passed
- Android local debug build: passed

The full suite must not be described as passing. Do not fix unrelated failures as part of Sprint 03 freeze governance.

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
