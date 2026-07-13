# Home Phase 1 Fidelity Acceptance

Date: 2026-07-13

Branch: `rebuild/product-language-v1`

Scope: Home empty first viewport only. Portfolio Phase 2 was not started.

## Decision

Accepted for Phase 1 Home visual fidelity with documented responsive and product-contract adaptations.

This acceptance does not approve Portfolio, Detail, Scanner, Search, backend, auth, router, or Product Language definition changes.

## Match Areas

- Empty Home uses the approved dark authority direction instead of the rejected blue Hero treatment.
- Primary copy remains `Your collection is waiting` and `Scan your first item to get started.`
- Primary CTA remains `Scan a Collectible` and still hands off through the existing scanner callback.
- First viewport density now exposes the header, empty authority card, compact collection status, Popular Categories, and compact secondary quick actions.
- Popular Categories displays all four chips in one row on the validated Samsung device.
- The App Shell remains four-tab: Home, Portfolio, Scan, Settings.
- No Search tab, unsupported Home loading state, offline state, backend state, or invented Home-owned data contract was added.

## Responsive Adaptations

- The Samsung physical viewport is much larger than the H02 crop excerpt, so physical pixel sizes do not match the authority crop one-to-one.
- The empty authority card remains wider than the H02 board crop because the runtime app fills the real device viewport with current app padding.
- A free area remains below quick actions before the bottom navigation on the taller Samsung viewport. It is classified as a mild residual responsive mismatch because it no longer hides the required hierarchy.

## Product-Contract Adaptations

- Exact H02 shows `Try a Sample Scan`; Phase 1 Home still omits it because the safe sample flow is owned by Scan Hub/Scanner, not by a Home-owned callback.
- Phase 1 keeps `Collection status` and compact quick actions because they were already part of the Home product contract and existing callback ownership.
- The duplicate empty-status scan action was removed to restore authority density and avoid competing with the primary hero CTA.

## Validation

Passed focused validation:

- `flutter analyze`
- `flutter test test/home_page_test.dart --reporter=compact` - 16 passed
- `flutter test test/shared_visual_foundations_test.dart --reporter=compact` - 12 passed
- Focused broad Home/widget regressions for dashboard, shell recreation, gallery completion, and clean scan CTA - 4 passed
- Physical Android debug build, install, launch, Home screenshot capture, scroll capture, tab stress capture, XML hierarchy capture, and logcat capture completed on `RZ8R213M8ZL`

Full suite:

- `flutter test --reporter=compact` completed with `554 passed, 16 failed`.
- Output: `qa/reconstruction/phase1_fidelity_full_test_output.txt`
- Remaining failures are outside this Home fidelity scope: analyzer provider contract, backend error wording/SIT script expectations, scanner/capture/enhancement flows, and portfolio carousel metadata.
- The full suite is not green and must not be represented as passing.

## Evidence

- Measurements: `qa/reconstruction/home_phase1_fidelity_measurements.md`
- Approved crop: `qa/screenshots/approved_authority_remediation/home/authority/phase1_authority_h02_empty_collection_crop.png`
- Before runtime: `qa/screenshots/approved_authority_remediation/home/fidelity_current/phase1_fidelity_current_first_viewport.png`
- After runtime: `qa/screenshots/approved_authority_remediation/home/fidelity_after/phase1_fidelity_after_first_viewport.png`
- Side-by-side: `qa/screenshots/approved_authority_remediation/home/comparison/phase1_fidelity_approved_vs_after.png`
- Logcat: `qa/screenshots/approved_authority_remediation/home/fidelity_after/phase1_fidelity_after_logcat.txt`

## Final Boundary

Home Phase 1 fidelity is accepted for the corrected empty first viewport. The remaining full-suite failures and any Portfolio visual remediation belong to later, separate work.
