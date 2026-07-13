# Sprint 06 Test Regression Analysis

Date: 2026-07-13

Branch: `rebuild/product-language-v1`

Starting HEAD: `9312b0b72ad6570ea2382a71732e1de0d0ef43d6`

## Baseline

Sprint 06 freeze validation first ran the focused frozen suites successfully, then ran the full suite against the Sprint 05 remediated ceiling.

Sprint 05 remediated full-suite baseline:

- 534 passed
- 16 failed

Initial Sprint 06 full-suite result:

- 532 passed
- 18 failed

Because the initial failure count exceeded the approved Sprint 05 ceiling by two, freeze governance was paused and the new failures were investigated before any freeze record was created.

## Focused validation before remediation

- Sprint 01 bootstrap suite: 12 passed.
- Sprint 02 onboarding suite: 10 passed.
- Sprint 03 App Shell suite: 11 passed.
- Sprint 04 Home suite: 12 passed.
- Sprint 05 focused Scanner suite: 51 passed.
- Sprint 06 focused Portfolio checks: 7 passed.

## Newly failing tests

| Test file | Test name | Previous baseline status | Current failure | Sprint 06 relevant code changed? | Classification | Root cause | Correction |
|---|---|---|---|---|---|---|---|
| `test/widget_test.dart` | `bottom navigation switches all major tabs without crashing` | Passing in Sprint 05 remediated full suite | Expected `Total collection value`; actual reconstructed Portfolio rendered no such text | Yes, Portfolio presentation was reconstructed | Stale Portfolio presentation expectation | Broad App Shell navigation test asserted removed legacy Portfolio summary copy instead of the approved Sprint 06 compact summary surface | Replaced the stale text assertion with `Collection summary` and `portfolio-compact-snapshot`, preserving the tab-switch smoke contract |
| `test/widget_test.dart` | `saves scanner result to portfolio` | Passing in Sprint 05 remediated full suite | Expected `Total collection value`; actual reconstructed Portfolio rendered no such text | Yes, Portfolio presentation was reconstructed | Stale Portfolio presentation expectation | Scanner-to-Portfolio save test asserted removed legacy Portfolio summary copy after navigating to the saved item | Removed the stale summary-copy assertion from the saved-item viewport and kept the real save evidence: saved Charizard text and `$1,850` value on the reconstructed Portfolio grid |

## Existing baseline failures

The remaining 16 failures after remediation match the known Sprint 05 baseline debt groups:

- analyzer provider/backend contract mismatch;
- backend detail error expectation;
- Supabase SIT script expectation;
- scanner workspace/camera/gallery/enhancement expectation debt;
- enhancement metadata/detail expectation debt.

No remaining failure was introduced by Sprint 06 Portfolio presentation changes.

## Remediation

Only `test/widget_test.dart` was changed. Production code was not changed.

The updates reconcile broad legacy assertions to the approved Sprint 06 Portfolio presentation while preserving the behavioural intent of each test:

- App Shell can switch from Home to Portfolio, Scan, and Settings without a Flutter error.
- Scanner save still persists the sample Charizard result and exposes it from Portfolio with the expected value.

## Validation after remediation

Focused remediation:

- `bottom navigation switches all major tabs without crashing`: passed.
- `saves scanner result to portfolio`: passed.

Full suite after remediation:

- 534 passed
- 16 failed

The full-suite failure count returned to the Sprint 05 remediated ceiling. The full suite must not be described as entirely passing.
