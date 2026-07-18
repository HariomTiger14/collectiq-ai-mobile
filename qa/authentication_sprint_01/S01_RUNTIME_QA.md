# Authentication Flutter Sprint 01 - S01 Runtime QA

Date: 2026-07-18

Scope: Authentication S01 Welcome / Launch only.

## Authority

- `C:\Users\hario\Desktop\projects\packlox-design-platform\incoming_authority\reset_2026_07_18\S01_visual_direction_package_v0.7\`
- `C:\Users\hario\Desktop\projects\packlox-design-platform\incoming_authority\reset_2026_07_18\authentication_mvp_handoff\`
- Brand v2 board: `C:\Users\hario\Desktop\projects\packlox-design-platform\incoming_authority\reset_2026_07_18\ChatGPT Image Jul 18, 2026, 12_06_58 AM.png`

## Reclassification

Previous runtime QA result: **FAIL / NEEDS FIDELITY FIX**.

Reason: the prior S01 runtime hero was a Flutter vector approximation. It did not match frozen S01 v0.7 closely enough because v0.7 uses realistic premium acrylic collectible slab artwork with supporting die-cast car and coin.

## Final Fidelity Fixes

Hero source:

- `C:\Users\hario\Desktop\projects\packlox-design-platform\incoming_authority\reset_2026_07_18\PLX-V01-S01-HERO-PREMIUM-COLLECTIBLES.png`
- Source dimensions: `864 x 1821`
- Flutter asset: `assets/packlox/s01_hero_premium_collectibles_v0_7.png`
- Output dimensions: `1000 x 780`
- Source crop: `x=0, y=440, w=864, h=1030`
- SHA256: `1800C33328999125A4CE7BF480F542B680C0C1CE8C52EBBCEC2829150E2B857E`

Brand emblem source:

- Brand source: `ChatGPT Image Jul 18, 2026, 12_06_58 AM.png`
- Source dimensions: `1536 x 1024`
- Flutter asset: `assets/packlox/brand/packlox_brand_v2_emblem_authority_v0_7.png`
- Output dimensions: `256 x 256`
- Source crop: `x=334, y=96, w=160, h=160`
- SHA256: `15647A271930F627035A5AB6BE5EEFFC1FE43F0A34C7178046FE3D51A8D43C0D`
- Caveat: no final production Brand v2 outline SVG was present in the Sprint 01 authority package. The older repo SVG `assets/packlox/brand/packlox_emblem_layered_v1.svg` is marked as proposal material and does not match the approved Brand v2 angular mark, so the runtime uses this Brand v2 authority-derived PNG.

Runtime scale:

- Emblem slot: `88 x 88` logical px.
- Emblem internal padding: `4` logical px.
- Final visible emblem target: approximately `80 x 80` logical px, within the requested `72-88` logical px range.

Legal text:

- Body legal text: `12.5sp`.
- Terms and Privacy link text: `12.5sp`.
- Link minimum size in Flutter: `48 x 48` logical px.
- F62 runtime measured bounds at density override `420`: Terms and Privacy links are `126` physical px tall, equal to `48` logical dp.
- Legal bottom inset: `24` logical px, keeping the legal line above the Android navigation bar without competing with `Explore as Guest`.

Implementation note: hero and emblem are bitmap assets. Wordmark, tagline, buttons, legal copy, route actions, semantics, safe areas, and touch targets remain live Flutter widgets.

## Validation Commands

| Check | Result |
| --- | --- |
| `flutter analyze` | PASS - no issues found. |
| `flutter test test/auth_presentation_test.dart` | PASS - 22 tests. |
| `flutter test test/settings_phase6b_test.dart` | PASS - 6 tests. |
| `git diff --check` | PASS - whitespace check clean; line-ending warnings only. |
| `android\gradlew.bat -p android assembleProdDebug` | PASS - build successful. |
| `adb install --user 0 -r -d build\app\outputs\flutter-apk\app-prod-debug.apk` | PASS - fresh install succeeded. |

## Device Runtime

- Model: Samsung `SM-E625F`
- Device id: `RZ8R213M8ZL`
- Physical size: `1080x2400`
- Density override: `420`
- Package: `com.collectiq.ai`
- Fresh package update time after final polish: `2026-07-18 13:31:54`

## Screenshot Evidence

Final logo/legal polish screenshot:

- `qa/authentication_sprint_01/screenshots/S01_WELCOME_RUNTIME_F62_logo_legal_fix.png`

Previous screenshots retained for comparison:

- `qa/authentication_sprint_01/screenshots/S01_WELCOME_RUNTIME_F62_final.png`
- `qa/authentication_sprint_01/screenshots/S01_WELCOME_RUNTIME_F62_fidelity_fix.png`
- `qa/authentication_sprint_01/screenshots/S01_WELCOME_RUNTIME_F62_v3.png`

## Green Left-Edge Sliver

Conclusion: **system overlay / capture artifact, not Flutter S01 UI**.

Evidence:

- The Flutter accessibility tree for S01 lists the brand, tagline, hero, CTA buttons, and legal content, with visible content nodes beginning at `x=63`.
- No S01 semantic/button/image node is present at the left-edge sliver location.
- Device system settings include Samsung edge-panel entries, including `cocktail_bar_enabled_cocktails=com.samsung.android.app.taskedge.edgepanel.TaskEdgePanelProvider` and `edge_handler_position_percent=16.112532`.

No Flutter UI removal was required. The native Android splash still uses old CollectIQ-era branding and remains outside this S01 Flutter route sprint.

## Visual QA Against Frozen v0.7

| Requirement | Result | Notes |
| --- | --- | --- |
| Brand v2 emblem | PASS WITH NOTE | Runtime uses the Brand v2 authority-derived emblem PNG at an approximately 80dp visible size. Production outline SVG remains missing from this Sprint 01 authority set. |
| PackLox wordmark | PASS | Wordmark remains live Flutter text. |
| Tagline | PASS | Exact copy: `Identify. Value. Protect.` |
| Premium dark background | PASS | Dark premium atmosphere preserved. |
| Realistic premium collectible hero | PASS | Runtime uses the authority-derived bitmap hero with acrylic slab, supporting car, and coin. |
| No old lock/scanner/design-bible assets | PASS | No old scanner crops, legacy lock artwork, or old Design Bible images were used. |
| CTA hierarchy | PASS | `Create Account`, `Sign In`, `Explore as Guest` visible in correct order. |
| Hero and CTA spacing | PASS | CTA does not overlap the hero; a clear gap is visible. |
| Legal copy visible | PASS | Legal body and link text are readable and not clipped. |
| Legal link tap targets | PASS | Terms and Privacy links measure 48dp high on the F62 runtime tree. |
| Safe areas respected | PASS | Status and bottom gesture areas clear on F62 viewport. |
| Touch target size | PASS | Primary/secondary actions are large; tertiary and legal link actions are comfortably tappable. |

## QA Conclusion

**PASS / LOGO AND LEGAL POLISH APPLIED** for Authentication Flutter Sprint 01 S01.

S01 now uses the approved realistic collectible hero direction, the closest available Brand v2 authority-derived standalone emblem, a clearer top emblem scale, and readable legal copy with verified 48dp legal link tap targets. Remaining caveat: final production Brand v2 vector/outline assets should replace the raster emblem when supplied.
