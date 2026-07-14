# Home Owner V1 Runtime Comparison

Date: 2026-07-14

Branch: `rebuild/product-language-v1`

Primary authority:

- `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\owner_amendments\home_empty_state_v1.png`

Measurement contract:

- `qa/reconstruction/home_owner_v1_measurements.md`

Runtime evidence:

- `qa/screenshots/approved_authority_remediation/home/owner_v1/owner_v1_runtime.png`
- `qa/screenshots/approved_authority_remediation/home/owner_v1/owner_v1_runtime.xml`
- `qa/screenshots/approved_authority_remediation/home/owner_v1/owner_v1_logcat.txt`
- `qa/screenshots/approved_authority_remediation/home/owner_v1/owner_v1_vs_runtime.png`

Runtime package note:

- The clean debug APK installs as `com.collectiq.ai`.
- Earlier stale captures from `com.collectiq.ai.local` were discarded and replaced with the final clean-package capture.

## Visual Acceptance Matrix

| Area | Classification | Notes |
| --- | --- | --- |
| Overall composition | MATCH | Header, hero, Collection Status, Popular Categories, Quick Actions, bottom navigation, and system nav appear in the same first-viewport order. |
| First viewport density | MATCH | All owner-approved first-viewport sections are visible without scrolling on Samsung runtime. |
| Header and notification affordance | ACCEPTABLE RESPONSIVE ADAPTATION | Header content, greeting, wave, and notification button match the authority. Runtime status bar has device-specific icons/time and the disabled notification icon is slightly dimmer. |
| Hero | MATCH | Hero is horizontal with large icon/orb left, copy right, and primary CTA below the body copy. |
| Hero dimensions and padding | ACCEPTABLE RESPONSIVE ADAPTATION | Runtime card is proportionally close; copy block starts slightly farther right because of Samsung logical scaling and text metrics. |
| Hero icon sizing | MATCH | Runtime icon/orb scale matches the authority relationship to card height. Decorative sparkles/noise are not present because they are not part of the current Flutter asset system. |
| Hero title/body spacing | MATCH | Title, body, and CTA follow the measured vertical order and spacing. |
| CTA dimensions | ACCEPTABLE RESPONSIVE ADAPTATION | CTA height and corner treatment match; runtime width is slightly narrower than the owner PNG but remains in the same visual role and no longer spans the full card. |
| Collection Status | MATCH | Runtime uses the owner-approved four metric columns with `0`, `-`, `-`, `0`, dividers, and footer copy. |
| Collection Status dimensions | ACCEPTABLE RESPONSIVE ADAPTATION | Runtime status surface is slightly shorter than the authority because Flutter text metrics are tighter, but the card remains visually equivalent and readable. |
| Popular Categories | MATCH | Runtime uses a titled section surface with four category tiles in one row. |
| Category tile spacing | MATCH | Four tiles fit cleanly with even spacing and no wrapping. |
| Category icon sizes | MATCH | Icons are larger tile icons rather than the previous small chips. |
| Quick Actions | MATCH | Runtime uses the titled surface, body copy, and three horizontal icon-label-chevron actions. |
| Quick Actions dimensions | ACCEPTABLE RESPONSIVE ADAPTATION | Runtime action buttons are slightly taller/wider due to Samsung scaling, but all three fit in one row and the surface clears the bottom navigation. |
| Vertical spacing rhythm | MATCH | Inter-section rhythm is compact and consistent; quick actions no longer collide with the bottom navigation. |
| Surfaces and borders | ACCEPTABLE RESPONSIVE ADAPTATION | Dark raised surfaces, rounded borders, and blue accents match; runtime lacks the authority PNG's smoky bitmap texture, which is acceptable because no new background asset was introduced. |
| Button sizing | ACCEPTABLE RESPONSIVE ADAPTATION | Primary and secondary buttons match role and hierarchy with small differences from Flutter text/icon metrics. |

## Material Mismatch Review

No material mismatch remains in the validated Samsung runtime capture.

Known acceptable adaptations:

- Device status bar content differs from the owner image because it is controlled by the Samsung device.
- The runtime build uses existing Flutter surfaces rather than adding a new smoky bitmap background texture.
- The disabled notification affordance preserves the existing no-notifications business contract while matching the visual placement.

## Validation

Focused validation:

- `flutter analyze`
- `flutter test test/home_page_test.dart --reporter=compact`
- `flutter test test/shared_visual_foundations_test.dart --reporter=compact`
- `flutter test test\widget_test.dart --reporter=compact --name "shows home dashboard content|home empty snapshot keeps scan encouragement focused|responsive smoke renders key screens"`
- `flutter test test\bootstrap_entry_presentation_test.dart test\onboarding_presentation_test.dart test\app_shell_presentation_test.dart test\shared_shell_s01_test.dart test\product_language_components_test.dart test\scan_hub_page_test.dart --reporter=compact`
- `flutter test test\scanner_widgets_test.dart test\camera_capture_page_test.dart --reporter=compact`

Full suite:

- `flutter test --reporter=compact` completed with `554 passed, 16 failed`.
- The full suite is not green and must not be described as passing.
- The failure count remains at the accepted baseline threshold of 16 and does not exceed it.
- Output is recorded in `qa/reconstruction/home_owner_v1_full_test_output.txt`.

Final capture flow:

- `adb devices -l` confirmed `RZ8R213M8ZL` as `device`.
- Clean package capture used `com.collectiq.ai/com.collectiq.ai.MainActivity`.
- Onboarding was completed on-device before capturing Home.
- Fresh screenshot and hierarchy were captured from the Samsung runtime.

## Final Decision

Every reviewed area is classified as `MATCH` or `ACCEPTABLE RESPONSIVE ADAPTATION`.

No material mismatch remains for the owner-approved Home empty-state first viewport.
