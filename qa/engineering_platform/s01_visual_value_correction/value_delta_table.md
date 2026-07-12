# S01 value-delta table

Prepared before visual implementation. `current` describes the active Samsung-proven implementation; `new` is the intended contract-backed value.

| Region | Property | Current | Contract required/preferred | Intended new | Delta | Contract ID | Confidence / tolerance | Implementation |
|---|---|---:|---:|---:|---|---|---|---|
| Header | safe area→greeting | 16; 12 short | 24 preferred, 16–32 | 24; 16 short | +8 / +4 | SP-SAFE-GREETING | medium / provisional | `scan_hub_presentation.dart` |
| Header | greeting→name | 8 scaled | 8 preferred, 6–12 | 8 scaled | verified unchanged | SP-GREETING-NAME | high / approved | same |
| Header | name line height | 26 | 28 preferred, 26–56 | 28 | +2 | PLX-VI-M-NAME-H | high / approved | same |
| Header | name→emoji | 6 | 6 preferred, 4–8 | 6 | verified unchanged | SP-NAME-EMOJI | medium / provisional | same |
| Header | header→hero | 16; 12 short | 24 preferred, 16–32 | 24; 16 short | +8 / +4 | SP-HEADER-HERO | medium / provisional | same |
| Header | notification | 48 target, 22 icon, row-center | 48 target, 22 icon, full-group center | unchanged | verified compliant | PLX-VI-M-NOTIFY / ALIGN-NOTIFICATION | high / approved; medium / provisional | same |
| Hero | horizontal margin | 16; 12 at ≤360 | 24 preferred; 16 at 360 | 24; 16 at ≤360 | +8 / +4 | PROP-PAGE-MARGIN | medium / moderate | same |
| Hero | height | ratio-derived min 132–168, no normal max | 144 preferred, 132–168 | ratio-derived preferred, explicit 132/168 bounds; large-text expansion | activate min/max | PLX-VI-M-HERO-H | medium / provisional | same |
| Hero | aspect | width/2.38 | 2.38 preferred, 2.25–2.55 | width/2.38 | verified unchanged | PROP-HERO-ASPECT | medium / strict | same |
| Hero | padding | 16 | `spacing.lg` = 16 | 16 | verified unchanged | PLX-VI-M-HERO-H anatomy | medium / provisional | same |
| Hero | title width | 64% inner width | 56% preferred, 48–64% | 56% | −8 percentage points | PROP-HERO-TITLE-WIDTH | medium / moderate | same |
| Hero | title type | 24 / 32, w800 | display / 32, w800 | 24 / 32, w800 | verified unchanged | `hero_title` typography role | medium / provisional | same |
| Hero | title→subtitle | 8 | 8 preferred, 6–12 | 8 | verified unchanged | SP-HERO-TITLE-SUBTITLE | medium / provisional | same |
| Hero | icon | 42, row center | 44 target; 26–36% of hero | 44, trailing-center | +2 and explicit alignment key | PLX-VI-M-HERO-ICON / ALIGN-HERO | low / provisional | same |
| Hero | radius | 12 | radius.md = 12 | 12 | verified unchanged | SURFACE-HERO | provisional | same |
| Hero | border | default 1px blue | subtle blue boundary | 1px blue | verified unchanged | SURFACE-HERO | provisional | same |
| Option | hero→heading | 16 | 24 preferred, 20–32 | 24 | +8 | SP-HERO-SECTION | medium / provisional | same |
| Option | heading→first tile | 12 | 12 preferred, 8–16 | 12 | verified unchanged | SP-SECTION-FIRST | medium / provisional | same |
| Entry | height | min 72 | preferred 72, 64–96 | preferred/min 72, responsive growth | verified preferred | PLX-VI-M-TILE-1/2/3 | high / approved | same |
| Entry | padding | 12 H / 12 V | spacing.md = 12 | 12 / 12 | verified unchanged | tile internal padding | high / approved | same |
| Entry | icon container | 40×40 | 40–44 | 40×40 | verified minimum | PROP-TILE-ICON | high / strict | same |
| Entry | icon | 22 | 22 | 22 | verified unchanged | camera/gallery/sample icon contracts | low / provisional | `scan_hub_page.dart` / presentation |
| Entry | icon→text | 12 | 16 preferred, 12–20 | 16 | +4 | SP-ICON-TEXT | high / approved | presentation |
| Entry | title→subtitle | 4 | 4 preferred, 2–6 | 4 | verified unchanged | SP-ENTRY-TITLE-SUBTITLE | high / approved | presentation |
| Entry | peer spacing | 12 | 12 preferred, 8–16 | 12 | verified unchanged | SP-TILE-12 / SP-TILE-23 | high / approved | presentation |
| Entry | radius/border | 12 / 1px token | radius.md / subtle outline | 12 / 1px token | verified unchanged | SURFACE-ENTRY | high / approved | presentation |
| Navigation | height | 70 | 72 preferred, 64–88 | verify only; no change | within range | PLX-VI-M-NAV-H | medium / provisional | `glass_bottom_nav_bar.dart` |
| Navigation | width / active | ~0.93–0.94 / 0.25 | 0.86–0.94 / 0.25–0.36 | verify only; no change | within range | PROP-NAV-WIDTH / PROP-NAV-ACTIVE | medium | same |

The material delta is concentrated in outer rhythm, hero content-grid width, hero constraints/icon placement, and tile icon/text rhythm. Contract-identical values are retained to avoid inventing a second design.
