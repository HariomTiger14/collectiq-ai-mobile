# Home Owner V1 Measurements

Date: 2026-07-14

Branch: `rebuild/product-language-v1`

Primary authority:

- `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\owner_amendments\home_empty_state_v1.png`

Authority hierarchy:

1. `home_empty_state_v1.png` Owner Approved
2. Home Design Bible Volume 02
3. Product Language
4. Flutter implementation

This document was created before Flutter implementation changes for the owner-approved amendment.

## Source Canvas

- Image size: `853 x 1844`
- First viewport includes Android status bar, Home content, bottom tab navigation, and Android system navigation.
- Main content horizontal inset: about `34 px`, or `4.0%` of canvas width.
- Card width: about `786 px`, or `92.1%` of canvas width.
- Primary visual rhythm: large rounded dark surfaces with subtle blue border and smoky/noisy dark background.

## Overall First Viewport Proportions

| Element | Bounds | Percent of canvas | Notes |
| --- | --- | --- | --- |
| Android status bar | `x=0 y=0 w=853 h=78` | `100% x 4.2%` | Not app-owned, but visible in screenshot. |
| Header block | `x=36 y=101 w=784 h=107` | `91.9% x 5.8%` | Left title/subtitle plus right notification button. |
| Hero card | `x=34 y=242 w=786 h=292` | `92.1% x 15.8%` | Horizontal layout. |
| Collection Status card | `x=34 y=560 w=786 h=350` | `92.1% x 19.0%` | Metric row with four columns. |
| Popular Categories card | `x=34 y=937 w=786 h=314` | `92.1% x 17.0%` | Four tiles in one row. |
| Quick Actions card | `x=34 y=1278 w=786 h=293` | `92.1% x 15.9%` | Three action buttons in one row. |
| Bottom nav | `x=27 y=1597 w=800 h=157` | `93.8% x 8.5%` | Existing App Shell navigation must be preserved. |
| Android system nav | `x=0 y=1754 w=853 h=90` | `100% x 4.9%` | Not app-owned. |

## Header

- Header bounds: `x=36 y=101 w=784 h=107`.
- Eyebrow `Your collection`: starts near `x=36 y=102`; text height about `28 px`.
- Title `Collector ??`: starts near `x=36 y=158`; text height about `50 px`.
- Notification button: `x=727 y=111 w=93 h=96`.
- Header to hero gap: `242 - 208 = 34 px`.

Implementation target:

- Preserve Home greeting semantics.
- Add a visual notification affordance if no business callback exists; it must not invent notification behavior.
- Header content should align to the same card inset rhythm as the rest of the screen.

## Hero

Hero card:

- Bounds: `x=34 y=242 w=786 h=292`.
- Corner radius visually about `32 px`.
- Outer border about `2 px`, low-contrast blue-gray.
- Internal horizontal padding: about `38 px` left and right.
- Internal vertical padding: about `43 px` top and `34 px` bottom.

Hero icon group:

- Icon orb bounds: `x=72 y=285 w=206 h=206`.
- Orb diameter: `206 px`, about `26.2%` of hero card width.
- Icon bounds: `x=131 y=348 w=90 h=86`.
- Icon visual size: about `90 px` wide.
- Icon to copy gap: `313 - (72 + 206) = 35 px`.

Hero copy and CTA:

- Copy block bounds: `x=313 y=313 w=467 h=187`.
- Title bounds: `x=313 y=313 w=442 h=41`.
- Body bounds: `x=313 y=370 w=366 h=25`.
- Title-to-body gap: about `16 px`.
- Body-to-CTA gap: about `24 px`.
- CTA bounds: `x=313 y=419 w=467 h=81`.
- CTA width is `59.4%` of hero card width.
- CTA height is `27.7%` of hero card height.
- CTA corner radius visually about `16 px`.

Implementation target:

- Hero must be horizontal on phone width: large icon/orb left, copy and CTA right.
- CTA must not be full card width.
- Hero density should keep the whole card near `16%` of the full owner viewport.

## Collection Status

Card:

- Bounds: `x=34 y=560 w=786 h=350`.
- Gap from hero: `26 px`.
- Corner radius visually about `32 px`.
- Internal horizontal padding: about `29 px`.
- Internal top padding: about `40 px`.

Title:

- Bounds: `x=63 y=600 w=255 h=31`.
- Title to metric row gap: about `32 px`.

Metric row:

- Row bounds: `x=76 y=663 w=677 h=141`.
- Four equal columns, each about `169 px` wide.
- Column divider gaps appear at about `x=199`, `x=402`, and `x=615`.
- Metric icons are about `38-42 px`.
- Icon-to-value gap: about `27 px`.
- Value text height: about `38 px`.
- Value-to-label gap: about `15 px`.
- Labels use muted text.

Footer:

- Bounds: `x=63 y=856 w=615 h=24`.
- Footer top gap from metric row: about `52 px` from row bottom estimate, with optical row content ending above the full row bounds.
- Text: `Value, condition, and saved history will appear here.`

Implementation target:

- Empty status must be metric-style, not a text-only empty card.
- Values must preserve semantics: `0 Items`, `- Est. value`, `- Avg. condition`, `0 Scans`.
- Do not fabricate real collection value or condition.

## Popular Categories

Card:

- Bounds: `x=34 y=937 w=786 h=314`.
- Gap from status card: `27 px`.
- Internal horizontal padding: about `29 px`.
- Internal top padding: about `41 px`.

Heading and body:

- Title bounds: `x=63 y=978 w=272 h=31`.
- Body bounds: `x=63 y=1035 w=257 h=24`.
- Title-to-body gap: about `26 px`.
- Body-to-tiles gap: about `22 px`.

Tiles:

- Cards tile: `x=65 y=1081 w=169 h=142`.
- Coins tile: `x=250 y=1081 w=169 h=142`.
- Figures tile: `x=436 y=1081 w=169 h=142`.
- More tile: `x=622 y=1081 w=169 h=142`.
- Horizontal tile gap: about `16-17 px`.
- Tile height: `142 px`, about `45.2%` of category card height.
- Category icons: about `42-50 px` visual size.
- Icon-to-label gap: about `24 px`.

Implementation target:

- Popular Categories must be a card/surface, not loose chips.
- Four category tiles must fit in one row at the validated Samsung width.
- Icon scale must be visibly larger than the prior chip implementation.

## Quick Actions

Card:

- Bounds: `x=34 y=1278 w=786 h=293`.
- Gap from Popular Categories card: `27 px`.
- Internal horizontal padding: about `27 px`.
- Internal top padding: about `42 px`.

Heading and body:

- Title bounds: `x=63 y=1320 w=199 h=31`.
- Body bounds: `x=63 y=1378 w=335 h=24`.
- Title-to-body gap: about `27 px`.
- Body-to-action-row gap: about `22 px`.

Action buttons:

- Scan: `x=61 y=1424 w=230 h=120`.
- Import: `x=311 y=1424 w=230 h=120`.
- Portfolio: `x=561 y=1424 w=230 h=120`.
- Horizontal action gap: about `20 px`.
- Button height: `120 px`, about `41.0%` of Quick Actions card height.
- Icon visual size: about `43 px`.
- Chevron visual size: about `32 px`.
- Icon-to-label gap: about `19 px`.

Implementation target:

- Quick Actions must be inside a titled section surface.
- Three actions must fit in one row at Samsung width.
- Buttons are horizontal icon-label-chevron controls, not square stacked tiles.

## Vertical Spacing Rhythm

- Status bar bottom to header top: `23 px`.
- Header bottom to hero top: `34 px`.
- Hero to Collection Status: `26 px`.
- Collection Status to Popular Categories: `27 px`.
- Popular Categories to Quick Actions: `27 px`.
- Quick Actions to bottom nav: `26 px`.
- Bottom nav to system nav: flush/overlap visual region begins at `1754 px`.

Implementation target:

- Use a consistent `~26-27 px` inter-card rhythm after the hero begins.
- Avoid excessive empty space before the bottom navigation.
- First viewport density should show all four major Home sections and the bottom nav together on the validated Samsung runtime.

## Acceptance Basis

Runtime comparison after implementation must classify these sections as `MATCH`, `ACCEPTABLE RESPONSIVE ADAPTATION`, or `MISMATCH`:

- Overall composition
- First viewport density
- Header and notification affordance
- Hero card
- Collection Status
- Popular Categories
- Quick Actions
- Vertical spacing
- Surfaces and borders
- Icon sizing
- Button sizing
