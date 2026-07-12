# Full test suite baseline debt

Date: 2026-07-13

Sprint 01 HEAD: `0f5c93c39abdc747770205ff0eb51715d602b34e`

Baseline result:

- 509 passed
- 19 failed

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
