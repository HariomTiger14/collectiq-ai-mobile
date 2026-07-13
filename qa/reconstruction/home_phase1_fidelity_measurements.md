# Home Phase 1 Fidelity Measurements

Date: 2026-07-13

Branch: `rebuild/product-language-v1`

Scope: Home empty first viewport density correction only.

## Authority

Approved source:

- `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_02_Home\images\home_screen_flow_master.png`

Measured source image:

- Full authority image: `1402 x 1122`
- H02 empty Home crop: `qa/screenshots/approved_authority_remediation/home/authority/phase1_authority_h02_empty_collection_crop.png`
- H02 crop size: `141 x 507`

The crop is a small board excerpt from the authority composite. Ratios below are used as fidelity guidance, not as one-to-one physical pixel targets for the Samsung device.

## Runtime Evidence

Before correction:

- `qa/screenshots/approved_authority_remediation/home/fidelity_current/phase1_fidelity_current_first_viewport.png`

After correction:

- `qa/screenshots/approved_authority_remediation/home/fidelity_after/phase1_fidelity_after_first_viewport.png`
- `qa/screenshots/approved_authority_remediation/home/fidelity_after/phase1_fidelity_after_mid_scroll.png`
- `qa/screenshots/approved_authority_remediation/home/fidelity_after/phase1_fidelity_after_full_page.png`
- `qa/screenshots/approved_authority_remediation/home/fidelity_after/phase1_fidelity_after_tab_stress.png`
- `qa/screenshots/approved_authority_remediation/home/comparison/phase1_fidelity_approved_vs_after.png`

Physical target:

- Samsung SM E625F, device id `RZ8R213M8ZL`
- Screen capture: `1080 x 2400`
- Runtime content bounds after correction: `[0,92][1080,2029]`
- Bottom navigation bounds after correction: `[34,2029][1046,2173]`

## Measurement Table

| Area | Approved H02 direction | Before correction | After correction | Decision |
| --- | --- | --- | --- | --- |
| First viewport density | Header, compact empty card, category choices, and bottom navigation are all visible in the first phone state. | Large hero/status/category spacing pushed secondary hierarchy down; quick actions were not properly visible. | Header, empty card, status, Popular Categories, and one-row quick actions are visible above bottom navigation. | Match for density goal. |
| Empty hero height | Compact dark authority card, not a dominant marketing hero. | Hero height about `689 px` of `1937 px` app content, roughly `35.6%`. | Hero bounds `[45,292][1035,829]`, height `537 px`, roughly `27.7%` of app content. | Acceptable responsive adaptation. |
| Primary scan button | Centered compact action, visually narrower than the card. | Full-width button dominated the hero. | Button uses compact size and `0.76` width factor; observed width is about 70-76% of hero width depending on physical padding. | Match. |
| Collection status | H02 exact crop does not show a separate status card; Phase 1 product contract retained status below the hero. | Status copy and duplicate scan action consumed excessive vertical space. | Status title/body are compact; duplicate `Scan first collectible` action removed. | Acceptable product-contract adaptation. |
| Popular Categories | Four compact category choices visible together. | Category section was lower and oversized. | Four chips are on one row with bounds `[82,1285][262,1436]`, `[273,1285][453,1436]`, `[464,1285][644,1436]`, `[655,1285][835,1436]`. | Match. |
| Quick actions | H02 exact crop has `Try a Sample Scan` and bottom navigation; Phase 1 retained Home quick actions. | Quick actions fell out of the first viewport. | Quick actions are a compact one-row secondary group, bounds `[45,1495][1035,1675]`. | Acceptable product-contract adaptation. |
| Bottom spacing | Authority crop keeps navigation close to the content stack. | Excessive spacing hid secondary hierarchy. | Remaining free space exists between quick actions and nav on the taller Samsung viewport, but no key first-viewport content is hidden. | Mild residual responsive mismatch, not a blocker. |

## Corrected Constants

Production file:

- `lib/features/home/presentation/pages/home_page.dart`

Changes that produced the density correction:

- Home frame top gaps reduced from `AppSpacing.sm/md` to `AppSpacing.xs/sm`.
- Empty hero padding reduced from large to medium/small values.
- Empty hero icon reduced from `86 x 86` to `60 x 60`.
- Empty hero title changed from `headlineSmall` to `titleLarge`; body changed from `bodyMedium` to `bodySmall`.
- Primary scan button changed from full-width to compact with `FractionallySizedBox(widthFactor: 0.76)`.
- Empty status duplicate scan action removed.
- Popular category chips reduced from `82 x 72` minimum to `64 x 54` minimum.
- Quick actions changed to one row on Samsung width by moving the compact breakpoint from `< 420` to `< 300`.
- Quick action minimum height reduced from `96` to `64`.
- Section surfaces reduced from large to medium padding.

## Result

The corrected Home screen now satisfies the Phase 1 fidelity objective for authority proportions and first-viewport density while preserving the existing Home product contract and App Shell ownership boundaries.
