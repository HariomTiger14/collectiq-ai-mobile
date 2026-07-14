# Home Visual Weight Correction Measurements

Date: 2026-07-14
Branch: `rebuild/product-language-v1`
Starting HEAD: `62d31cd2253df589df1f07184751661cbc020501`

Scope: Home empty-state visual-weight correction only. Measurements are logical Flutter pixels unless noted.

## Source Measurements

| Element | Before correction | After correction | Change |
| --- | ---: | ---: | ---: |
| Hero icon-circle diameter | 96 | 78 | -18.8% |
| Archive icon size | 44 | 36 | -18.2% |
| Hero outer vertical padding | 36 total | 28 total | -22.2% |
| Hero icon-to-copy horizontal gap | 16 | 12 | -25.0% |
| Title-to-subtitle spacing | 8 | 4 | -50.0% |
| Subtitle-to-CTA spacing | 16 | 10 | -37.5% |
| Collection Status divider height | 72 | 52 | -27.8% |
| Collection Status metric icon size | 24 | 18 | -25.0% |
| Collection Status value typography | `titleLarge` | `titleMedium` | reduced |
| Collection Status footer spacing | 16 | 8 | -50.0% |
| Popular Categories tile min height | 70 | 60 | -14.3% |
| Popular Categories row gap | 8 | 4 | -50.0% |
| Popular Categories icon size | 32 | 30 | -6.3% |
| Popular Categories icon-to-label spacing | 8 | 4 | -50.0% |
| Quick-action height | 58 minimum | 58 minimum | unchanged |

## Ratio Comparison

| Area | Approved ratio | Current ratio after correction | Required correction | Allowed tolerance |
| --- | --- | --- | --- | --- |
| Hero total height / 1000 px test viewport | 0.11-0.17 | guarded by `0.11-0.17` widget test | reduce by about 8-12% from owner-v1 runtime | 0.11-0.17 |
| Hero height / hero width | 0.29-0.43 | guarded by `0.29-0.43` widget test | reduce from prior `0.34-0.48` allowance | 0.29-0.43 |
| Icon circle / hero height | less than 0.70 | guarded below `0.70` | make heading/copy primary | less than 0.70 |
| Icon circle / 390 px width | 0.19-0.21 | 0.20 | reduce visual dominance | +/- 0.02 |
| Archive icon / icon circle | 0.44-0.48 | 0.46 | preserve clarity while reducing mass | 0.42-0.50 |
| Collection Status height / 1000 px test viewport | 0.11-0.18 | guarded by `0.11-0.18` widget test | compact dashboard summary | 0.11-0.18 |
| Popular Categories height / 1000 px test viewport | 0.10-0.17 | guarded by `0.10-0.17` widget test | reduce section height by about 6-10% or more without losing touch target | 0.10-0.17 |
| Category tile height | 60-78 px | guarded by `60-78` widget test | reduce from old 70-92 px range | 60-78 px |
| Category icon size | 28-32 px | 30 px | consistent semantic icon family | 28-32 px |
| Quick-action height | 58-74 px | unchanged guarded range | preserve quick actions | 58-74 px |

## Authority Comparison

Approved H02 and owner-approved `home_empty_state_v1.png` both prioritize the empty-state heading/copy over the icon. The correction keeps the same Home hierarchy and dark surface treatment while reducing the icon-circle, tightening vertical spacers, and increasing first-viewport density so more of Collection Status is visible.

## Required Corrections Recorded

- Hero icon dominance: corrected by reducing the circle from 96 to 78 and archive icon from 44 to 36.
- Hero height: corrected through smaller vertical padding and text/CTA spacing.
- Collection Status role: corrected by making the empty state a compact dashboard summary with no repeated hero CTA/headline.
- Category semantics: corrected by replacing the generic currency icon and toy/car-adjacent icon with collectible coin and figurine-style icons.
- Category spacing: corrected by reducing tile min height, row gap, internal vertical padding, and icon-to-label spacing.

Samsung physical screenshots and hierarchy are stored under `qa/screenshots/approved_authority_remediation/home/visual_weight_correction/`.
