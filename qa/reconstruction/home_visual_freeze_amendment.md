# Home Visual Freeze Amendment - Phase 1

Date: 2026-07-13

Branch: `rebuild/product-language-v1`

Scope: Home only.

## Amendment reason

The earlier Sprint 04 freeze record approved a Home surface built around a large blue Hero and elevated action tiles. The later Approved Visual Authority Audit established that this did not match the approved Home authority image for the empty first state.

This amendment supersedes the visual portion of the Sprint 04 Home freeze for the Home first viewport and empty-state hierarchy. It does not reopen Home data architecture, portfolio ownership, scanner ownership, App Shell lifecycle, routing, backend, authentication, or Product Language definitions.

## Approved authority

- Authority image: `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_02_Home\images\home_screen_flow_master.png`
- SHA-256: `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A`

## Implemented corrections

- Replaced the rejected empty Home blue Hero with a compact approved dark empty collection card.
- Aligned empty-state copy to `Your collection is waiting` and `Scan your first item to get started.`
- Kept the primary scan action wired to the existing scanner handoff.
- Moved the empty collection status/snapshot above secondary quick actions.
- Added Popular Categories into the first viewport after the empty status card.
- Reduced quick actions to compact lower-order actions instead of large first-viewport entry tiles.
- Forced Home to the approved dark visual contract so device light theme no longer produces dark surfaces with dark text.
- Preserved real portfolio analytics semantics and did not coerce unavailable values to zero.
- Preserved the four-tab App Shell and did not add Search.

## Validation status

Approved for Phase 1 Home authority alignment with documented limitations.

Passed:

- `adb devices -l` confirmed `RZ8R213M8ZL` as `device`.
- `flutter analyze` passed.
- `flutter build apk --debug` passed for `app-prod-debug.apk`.
- `adb install -r build\app\outputs\flutter-apk\app-prod-debug.apk` passed.
- Physical launch, Home top capture, scroll capture, tab-switch stress, hierarchy capture, and log capture completed.
- `flutter test test/home_page_test.dart --reporter=compact` passed with 16 tests.
- `flutter test test/shared_visual_foundations_test.dart --reporter=compact` passed with 12 tests.
- Focused bootstrap/onboarding/app-shell/scan-hub regression group passed with 58 tests.
- Responsive broad smoke tests for key screens passed after stale Home copy expectations were reconciled.

Full suite:

- `flutter test --reporter=compact` completed with `546 passed, 24 failed`.
- The full suite is not green and must not be represented as passing.
- Remaining failures are documented broad-suite debt outside the Home authority implementation scope.

## Evidence

Runtime comparison:

- `qa/reconstruction/home_approved_authority_runtime_comparison.md`

Physical evidence:

- `qa/screenshots/approved_authority_remediation/home/before/`
- `qa/screenshots/approved_authority_remediation/home/after/`
- `qa/screenshots/approved_authority_remediation/home/hierarchy/`
- `qa/screenshots/approved_authority_remediation/home/logs/`
- `qa/screenshots/approved_authority_remediation/home/comparison/phase1_home_authority_before_after_first_viewport.png`

Full-suite output:

- `qa/reconstruction/phase1_full_test_output.txt`

## Remaining limitations

- After-state physical evidence covers the honest empty local device state only.
- Populated and partial-value Home states are covered by focused widget tests and source tracing; they were not fabricated on the physical device.
- `Try a Sample Scan` remains a product-contract clarification because the existing sample behavior is owned by Scan Hub/Scanner flow, not a safe Home-owned callback.
- Home-owned loading, offline, retry, sync, AI status, and advanced insight variants were not invented because Home has no independent asynchronous state contract.
- Notifications remain disabled as before.

## Freeze decision

Home visual fidelity is amended from the earlier Sprint 04 freeze to this Phase 1 approved authority alignment for the validated empty first viewport, scroll sequence, and App Shell handoffs.

Overall Home status after this amendment: approved for the validated Phase 1 scope with the limitations above.
