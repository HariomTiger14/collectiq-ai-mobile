# PackLox Phase H1 - Home H02 Master-Authority Correction Matrix

Date: 2026-07-16

## Authority

- Master Home board: `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_02_Home\images\home_screen_flow_master.png`
- Master SHA-256: `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A`
- Master dimensions: `1402x1122`
- H02 crop: `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_lock\Home\Home_Design_System_v1\01_Authority\state_crops\H02_Empty_Collection.png`
- Home Design System commit: `5571512a99a925788a7fce0b3c4f4fd53fce7485`

## Inputs Compared

- Approved H02 crop: compact app bar, centered empty hero, primary Scan CTA, tertiary Sample Scan action, Popular Categories, bottom navigation.
- Current H02 Samsung evidence: `qa/screenshots/design_lock/home/H02/runtime/home_H02_first_viewport.png`.
- Current Flutter composition at H0 final: `HomeStateContainer`, `_EmptyCollectionCard`, `_CollectionSnapshotSection`, `_PopularCategoriesSection`, `_CompactQuickActions`.
- Phase H0 shared components: `HomeAppBar`, `HomeStateContainer`, `HomeSection`, `HomeSectionSurface`, `HomeCategoryGrid`, `HomeCategoryTile`, `HomeQuickActionGrid`, `HomeRecentItemCard`.

Confidence:

- A - directly observable
- B - normalized from authority proportions
- C - engineering choice due source limitation
- D - unresolved

| Area | Authority | Current | Measured/Observed Deviation | Required Correction | Confidence |
| --- | --- | --- | --- | --- | --- |
| Top inset | Safe-area/status inset, then compact header. | Safe-area ownership preserved by `Scaffold` body; previous Samsung runtime starts below system bar. | Safe-area behavior is acceptable; content below it is too tall. | Preserve safe-area ownership. Do not add custom status padding. | A |
| Header height | Compact header: small greeting line and name with compact notification affordance. | H0 uses `HomeAppBar` wrapping `PackLoxHeader`; runtime typography is larger than crop because it renders `Collector` with emoji-style greeting. | Header consumes materially more vertical space than crop. | Use shared Home app bar, feed real/time-aware greeting and fallback name, avoid fake badge; keep no large extra eyebrow block beyond `PackLoxHeader` contract. | B |
| Greeting typography | Crop shows compact "Good morning," and first name/fallback. | Runtime shows "Your collection" eyebrow and large `Collector` heading. | Copy and hierarchy are not H02 crop-aligned. | Use time-aware greeting, real first name or `Collector` fallback, no fake notification count. | A |
| Notification affordance | Small outline bell affordance, no badge. | Runtime shows large rounded-square bell, no fake badge. | Affordance is visually larger than crop but matches existing shared header contract. | Preserve existing notification callback/disabled state; do not fabricate unread count. | B |
| Empty-state hero/card | One raised navy card, centered composition, no horizontal split. | Runtime hero is wide horizontal icon/text/CTA layout. | Current hero is much taller/wider and split-layout, unlike centered H02 card. | Replace empty H02 hero with centered `HomeEmptyCollectionHero` using H0 tokens/components. | A |
| Central icon size | Centered PackLox collection mark around hero-token scale. | Runtime icon is left-aligned in a circular container. | Icon placement and role differ. | Center PackLox collection mark; use restrained hero icon size. | A |
| Title/body hierarchy | Centered title "Your collection is waiting"; short body "Scan your first item to get started." | Runtime title/body match intent but are left-of-center in horizontal layout. | Copy is acceptable; layout and hierarchy are not. | Keep product-safe authority copy and center it inside hero. | A |
| Primary CTA | One full-width primary "Scan a Collectible" inside hero. | Runtime CTA is inside hero but wide within horizontal layout. | CTA is correct action but oversized and not centered in compact vertical card. | Keep one primary CTA, full-width within compact card, wired to existing scan callback. | A |
| Sample-scan action | Tertiary "Try a Sample Scan" action beneath CTA. | Runtime has no sample-scan action in H02. | Missing authority action. | Render tertiary action only if a real callback exists; otherwise render disabled honest label and document callback gap. | A |
| Popular Categories heading | Section immediately follows hero; heading and small helper copy. | Runtime categories appear after Collection Status card. | Extra status section pushes categories down. | Move Popular Categories immediately after hero. | A |
| Category tile count | Four tiles: Cards, Coins, Figures, More. | Runtime has four tiles with those labels. | Count matches; current section is too low in page. | Preserve four tiles, no counts. | A |
| Category icon family | Rounded outline icons, Cards/card stack, Coins/collectible medallion, Figures/figurine, More/grid/ellipsis. | Runtime uses semantic icons from H0: card stack, circle coin, robot-like figure, grid. | Semantics are mostly aligned; figure icon remains an engineering approximation. | Keep collectible semantics; avoid money/vehicle icons. | B |
| Category tile size | Compact tiles in one row at 360-430dp. | Runtime tiles are larger and inside a large section card on Samsung. | Tile density is looser than H02 crop. | Use compact section/tile sizing; allow two columns below 360dp and large text. | B |
| Page density | First viewport shows header, complete hero, categories, and nav. | Runtime shows header, hero, Collection Status, categories, Quick Actions, nav; much taller content. | Extra sections and large hero break H02 authority hierarchy. | Remove H02-only Collection Status and Quick Actions; compact hero/section spacing. | A |
| Section gaps | 10-16dp rhythm. | Runtime uses large card-to-card gaps and extra sections. | Vertical rhythm is too heavy for H02. | Use H0 `HomeSection` with compact H02 spacing. | B |
| Card radius | Restrained raised card radius. | Runtime cards use large rounded corners consistent with older lock. | Radius appears larger than compact H02 crop. | Add/use H02 compact hero/section surfaces with restrained radius. | B |
| Card border | Subtle navy border on raised dark surface. | Runtime border is visible and heavy around large cards. | Border treatment is acceptable but over-prominent due scale. | Use H0 token border, restrained opacity/width through shared surfaces. | B |
| Bottom navigation | Approved board shows five destinations including Search. | Current App Shell has four destinations: Home, Portfolio, Scan, Settings. | Product-contract mismatch remains. | Do not modify App Shell in H1; record as ACCEPTABLE TEMPORARY PRODUCT-CONTRACT DEVIATION. | A |
| First viewport coverage | H02 crop shows header, hero, categories, and nav without status/quick sections. | Samsung runtime shows all old sections, but not authority hierarchy. | Coverage contains too much unsupported content. | H02 first viewport must show only approved hierarchy plus current four-tab nav. | A |
| Bottom clearance | Content clears fixed bottom nav and system navigation. | Runtime has clearance and nav visibility. | Clearance is acceptable. | Preserve `HomeStateContainer` bottom clearance; no clipping. | A |

## Summary

H1 must correct H02 by recomposing the empty state from shared Home components into the master-approved hierarchy. The main production changes are removing H02-only `Collection status` and `Quick actions` from the empty branch, replacing the old horizontal empty hero with a centered compact H02 hero, adding the sample-scan tertiary affordance only honestly, and keeping Popular Categories immediately after the hero.

The current four-tab App Shell is an ACCEPTABLE TEMPORARY PRODUCT-CONTRACT DEVIATION for H1 only. Full Home-flow fidelity remains blocked until Search navigation is resolved.
