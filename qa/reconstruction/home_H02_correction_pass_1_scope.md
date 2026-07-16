# Home H02 Correction Pass 1 Scope

## Authority

- Master image: `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_02_Home\images\home_screen_flow_master.png`
- Master SHA-256: `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A`
- Matrix: `releases/v1.0/engineering_blueprints/Home/H02/07_Visual_Correction_Matrix.md`
- Flutter branch: `rebuild/product-language-v1`
- Starting HEAD: `b82e5cf55ed9dcc1c11a59185add2bbc93e4d38a`

## Pass 1 Boundaries

This pass applies only H02 visible first-viewport corrections that do not require Search, App Shell, Product Language, Design Bible, Design System, backend, provider, repository, or unsupported behavior changes.

No Flutter implementation is permitted for corrections that require a missing asset or a missing product contract.

## Selected Corrections

| ID | Severity | Component | Pass 1 Decision | Required Action | Verification |
| --- | --- | --- | --- | --- | --- |
| H02-007 | Critical | Hero emblem | Blocked | Replace only if an exact PackLox layered emblem asset exists. Asset search found no reusable exact emblem in Flutter, Design Platform, or legacy Flutter assets. Do not fabricate. | Scope/result record blocker. |
| H02-008 | High | Hero glow | Blocked | Restyle/resize only with the approved emblem asset. Asset unavailable, so do not fabricate glow around an unrelated icon. | Scope/result record blocker. |
| H02-009 | Critical | Hero title | Implement | Align to the two-line authority composition at Samsung-class width using a bounded text measure, without hard-coding a newline. | Widget geometry and text tests. |
| H02-015 | Critical | Sample Scan | Blocked for default runtime | Keep disabled/unavailable unless an existing callback is provided. Do not invent product behavior. | Existing callback test plus result blocker. |
| H02-017 | High | Hero padding | Implement | Reduce upper hero padding and increase lower stack rhythm to match the authority hierarchy. | Widget geometry test. |
| H02-019 | High | Hero height/proportion | Implement | Resize hero internal proportions so the card remains compact while the headline and CTA carry the authority hierarchy. | First-viewport density test. |
| H02-024 | High | Cards tile | Implement | Resize/restyle tile to authority compact tile geometry and category color. | Category tile test. |
| H02-025 | High | Coins tile | Implement | Resize/restyle tile to authority compact tile geometry and category color. | Category tile test. |
| H02-026 | High | Figures tile | Implement | Resize/restyle tile to authority compact tile geometry and category color. | Category tile test. |
| H02-027 | High | More tile | Implement | Resize/restyle tile to authority compact tile geometry and category color. | Category tile test. |
| H02-028 | Critical | Category icon colors | Implement | Restore per-category authority color separation instead of one blue icon color. | Category icon color assertions. |
| H02-035 | Critical | Bottom navigation | Excluded | Five-tab authority requires Search/App Shell contract work. Explicitly outside Pass 1. | Scope/result record exclusion. |
| H02-037 | High | Bottom navigation order | Excluded | Bottom nav order requires App Shell/Search changes. Explicitly outside Pass 1. | Scope/result record exclusion. |

## Typography Guard

H02 text must continue using the current frozen Product Language theme styles. No new font family is introduced because `pubspec.yaml` contains no active custom font family and `AppTheme` already maps text roles through existing `AppTextStyles`.

## Implementation Targets

- `lib/features/home/presentation/widgets/home_shared_components.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `test/home_shared_components_test.dart`
- `test/home_page_test.dart`

## Not In Scope

- App Shell or Search navigation.
- Any Design Bible, Design System, Engineering Blueprint, or Product Language modifications.
- New assets, cropped assets, generated assets, or fabricated PackLox emblem substitutes.
- Unsupported Sample Scan behavior.
- H03 or any non-H02 state implementation.
