# Home Approved Authority Runtime Comparison - Phase 1

Date: 2026-07-13

Branch: `rebuild/product-language-v1`

Starting HEAD: `42a873fe6e3a35981e139a9f9d3b81e80f348cac`

Device gate: `RZ8R213M8ZL` reported as `device` by `adb devices -l`.

Approved authority:

- `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_02_Home\images\home_screen_flow_master.png`
- SHA-256: `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A`

## Before evidence

Directory:

- `qa/screenshots/approved_authority_remediation/home/before/`

Key files:

- `phase1_home_before_empty_first_viewport.png`
- `phase1_home_before_empty_first_viewport.xml`
- `phase1_home_before_empty_mid_scroll.png`
- `phase1_home_before_empty_mid_scroll.xml`
- `phase1_home_before_empty_end_scroll.png`
- `phase1_home_before_populated_first_viewport.png`
- `phase1_home_before_populated_first_viewport.xml`
- `phase1_home_before_populated_scrolled.png`
- `phase1_home_before_populated_scrolled.xml`
- `phase1_before_logcat.txt`
- `phase1_before_runtime_metadata.txt`

Before state findings:

- Empty Home still used the rejected large blue `PackLoxHero` treatment.
- Empty Home put Import/Open Portfolio action tiles above the collection status/snapshot.
- Popular Categories was not present in the first viewport.
- Populated before evidence was captured before the device was cleared for honest empty-state validation.

## After evidence

Directories:

- `qa/screenshots/approved_authority_remediation/home/after/`
- `qa/screenshots/approved_authority_remediation/home/hierarchy/`
- `qa/screenshots/approved_authority_remediation/home/logs/`
- `qa/screenshots/approved_authority_remediation/home/comparison/`

Key files:

- `phase1_home_after_empty_first_viewport.png`
- `phase1_home_after_empty_mid_scroll.png`
- `phase1_home_after_empty_end_scroll.png`
- `phase1_home_after_tab_stress.png`
- `phase1_home_after_empty_first_viewport.xml`
- `phase1_home_after_empty_mid_scroll.xml`
- `phase1_home_after_empty_end_scroll.xml`
- `phase1_home_after_tab_stress.xml`
- `phase1_home_after_logcat.txt`
- `phase1_home_authority_before_after_first_viewport.png`

After state findings:

- Empty Home now starts with the approved dark empty collection card copy: `Your collection is waiting` and `Scan your first item to get started.`
- Legacy `Your collection starts here`, `Start your collection`, and the large blue Hero treatment are absent from the captured hierarchy.
- `Collection status` follows the empty collection card.
- `Popular Categories` appears in the first viewport below the status card.
- Quick actions remain compact and lower in the scroll order.
- The App Shell remains four-tab: Home, Portfolio, Scan, Settings. No Search tab was added.
- Tab-switch stress covered Home -> Portfolio -> Home -> Scan -> Home and returned to Home without visible blank frame, route lock, or input lock.

## Visual comparison

Side-by-side evidence:

- `qa/screenshots/approved_authority_remediation/home/comparison/phase1_home_authority_before_after_first_viewport.png`

Comparison summary:

- Authority direction: compact dark first state, not oversized blue Hero.
- Before: legacy Hero and entry tiles dominated the first viewport.
- After: dark empty state, honest collection status, and Popular Categories are visible in the first viewport.

## Runtime log review

Log path:

- `qa/screenshots/approved_authority_remediation/home/logs/phase1_home_after_logcat.txt`

Findings:

- No observed `E/flutter` entry.
- No observed Flutter framework exception.
- No observed app ANR or input dispatch timeout for `com.collectiq.ai`.
- Log contains unrelated Samsung, Google, Bluetooth, and background app noise during the capture window.

## Validation

Passed focused validation:

- `flutter analyze`
- `flutter test test/home_page_test.dart --reporter=compact` - 16 passed
- `flutter test test/shared_visual_foundations_test.dart --reporter=compact` - 12 passed
- `flutter test test/bootstrap_entry_presentation_test.dart test/onboarding_presentation_test.dart test/app_shell_presentation_test.dart test/shared_shell_s01_test.dart test/product_language_components_test.dart test/scan_hub_page_test.dart --reporter=compact` - 58 passed
- `flutter test test/scanner_widgets_test.dart test/camera_capture_page_test.dart --reporter=compact` - passed in the pre-final validation run
- `flutter test test/widget_test.dart --reporter=compact --plain-name "responsive smoke renders key screens"` - 2 passed after stale Home assertions were reconciled

Full suite:

- `flutter test --reporter=compact` completed with `546 passed, 24 failed`.
- Output saved to `qa/reconstruction/phase1_full_test_output.txt`.
- Remaining failures are outside the Home authority implementation scope and are not described as passing.

## Populated-state boundary

A natural populated Home state was captured before the device was cleared for honest empty-state validation. After the final rebuild, the installed app-owned device data exposed only Flutter prefs/assets and no local portfolio database or seed file. No populated runtime state was fabricated.

Populated and partial-data Home behavior remain covered by focused Home widget fixtures and source-level preservation of real portfolio analytics semantics.

## Product-contract clarifications

- `Try a Sample Scan` is present in the approved image but was not added to Home because the existing safe sample action is owned by Scan Hub/Scanner controller behavior, and adding a Home-owned callback would reopen App Shell/navigation ownership.
- Unsupported Home-owned loading, offline, sync, AI status, and no-valuation insight states were not invented because the current Home screen has no independent asynchronous contract.
- Notifications remain disabled as before.

## Phase 1 Fidelity Correction Addendum

Date: 2026-07-13

Additional evidence was captured after the density correction requested for Phase 1 Home visual fidelity:

- Authority crop: `qa/screenshots/approved_authority_remediation/home/authority/phase1_authority_h02_empty_collection_crop.png`
- Before correction: `qa/screenshots/approved_authority_remediation/home/fidelity_current/phase1_fidelity_current_first_viewport.png`
- After correction: `qa/screenshots/approved_authority_remediation/home/fidelity_after/phase1_fidelity_after_first_viewport.png`
- Side-by-side: `qa/screenshots/approved_authority_remediation/home/comparison/phase1_fidelity_approved_vs_after.png`
- Measurements: `qa/reconstruction/home_phase1_fidelity_measurements.md`
- Acceptance: `qa/reconstruction/home_phase1_fidelity_acceptance.md`

Updated outcome:

- Hero/card proportions were reduced from the oversized first pass.
- The primary scan button was narrowed and compacted.
- Empty collection status no longer duplicates the scan action.
- Popular Categories and compact quick actions are now visible in the first viewport on the validated Samsung device.
- Full suite returned to `554 passed, 16 failed`; remaining failures are outside Home fidelity scope.
