# Portfolio Phase 2 Measurements

Date: 2026-07-14

Branch: `rebuild/product-language-v1`

Primary authority:

- `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_06_Portfolio\images\portfolio_flow_master.png`
- Dimensions: `1536 x 1024`
- SHA-256: `40E22E960B9E73835A4463AEB2D72B6ED4F9BF32DE98F1171B6C3F43376324B4`

Extracted approved crops:

- S01-S09: `134 x 402`
- S10: `202 x 402`

Measurements use the extracted crops as the mobile-frame basis. Percentages are expressed against the `134 x 402` crop unless noted.

## S01 Portfolio Home

| Element | Approx bounds | Ratio | Implementation target |
| --- | --- | --- | --- |
| Frame | `134 x 402` | `100% x 100%` | Use as phone viewport ratio reference. |
| Status bar | `y=0 h=23` | `5.7%` height | Device-owned; preserve SafeArea. |
| Header | `x=10 y=34 w=92 h=15` | `68.7% w` | Title `My Collection`; no oversized hero treatment. |
| Search field | `x=9 y=65 w=116 h=24` | `86.6% w x 6.0% h` | Search remains near top, including empty Portfolio. |
| Total Items card | `x=9 y=96 w=116 h=48` | `86.6% w x 11.9% h` | Dark compact summary card, count first. |
| Total Value card | `x=9 y=153 w=116 h=60` | `86.6% w x 14.9% h` | Dark compact value card; no fabricated gain/loss. |
| Top category/recent block | `x=9 y=222 w=116 h=78` | `86.6% w x 19.4% h` | Show only real data; omit unsupported fake summaries. |
| Bottom nav | `x=10 y=355 w=114 h=30` | `85.1% w x 7.5% h` | Current four-tab shell is preserved as an adaptation. |

Spacing:

- Top inset to header title: about `34 px`, `8.5%` of crop height.
- Header-to-search gap: about `15 px`.
- Search-to-summary gap: about `7 px`.
- Summary-card vertical gap: about `9 px`.
- Bottom content must clear the nav by at least one card gap.

## S02 Search

| Element | Approx bounds | Ratio | Implementation target |
| --- | --- | --- | --- |
| Header row | `x=9 y=33 w=82 h=15` | `61.2% w` | Current inline search field is acceptable if behaviour remains unchanged. |
| Search field | `x=10 y=62 w=114 h=24` | `85.1% w x 6.0% h` | Dark field, search icon left, clear affordance when active. |
| Recent/suggestion rows | `x=12 y=111 w=101 h=115` | `75.4% w x 28.6% h` | Runtime may show filtered results instead of suggestions; document adaptation. |
| Keyboard | `y=268 h=106` | `26.4%` height | Device keyboard is platform-owned and not implemented by app. |

## S03 Filter & Sort

| Element | Approx bounds | Ratio | Implementation target |
| --- | --- | --- | --- |
| Header row | `x=10 y=33 w=84 h=15` | `62.7% w` | Keep Filter/Sort access; no Search tab. |
| Category control | `x=10 y=68 w=114 h=24` | `85.1% w x 6.0% h` | Dark control, selected value visible. |
| Subcategory control | `x=10 y=103 w=114 h=24` | `85.1% w x 6.0% h` | Preserve current category filter semantics only. |
| Condition control | `x=10 y=138 w=114 h=24` | `85.1% w x 6.0% h` | Current confidence/trend filters are behaviour-preserving adaptations. |
| Price range slider | `x=10 y=184 w=114 h=21` | `85.1% w x 5.2% h` | Use compact dark slider/sheet styling. |
| Sort control | `x=10 y=226 w=114 h=24` | `85.1% w x 6.0% h` | Selected sort visible. |
| Primary apply CTA | `x=10 y=275 w=114 h=25` | `85.1% w x 6.2% h` | Compact primary action, not oversized. |

The approved board shows an in-screen Filter & Sort composition, while Flutter currently has separate modal sheets. Combining them would change behaviour, so Phase 2 preserves separate sheets and aligns them to the dark board surface.

## S04 Collection Stats

| Element | Approx bounds | Ratio | Implementation target |
| --- | --- | --- | --- |
| Header | `x=37 y=35 w=61 h=14` | `45.5% w` | Stats title does not replace main Portfolio title. |
| Range segmented control | `x=31 y=64 w=74 h=14` | `55.2% w x 3.5% h` | Unsupported range controls deferred. |
| Total Value panel | `x=9 y=90 w=116 h=76` | `86.6% w x 18.9% h` | No fake chart/trend; show value only from real items. |
| Four metric tiles | `x=10 y=180 w=114 h=86` | `85.1% w x 21.4% h` | Compact real metrics only. |
| Highest Value row | `x=10 y=300 w=114 h=43` | `85.1% w x 10.7% h` | Runtime may omit if no real item exists. |

## S05 Item Grid

| Element | Approx bounds | Ratio | Implementation target |
| --- | --- | --- | --- |
| Header | `x=9 y=33 w=88 h=16` | `65.7% w` | Current title/count row can adapt to `All Items`. |
| Sort row | `x=10 y=60 w=114 h=24` | `85.1% w x 6.0% h` | Compact sort/filter access above grid. |
| Grid area | `x=10 y=92 w=114 h=244` | `85.1% w x 60.7% h` | Two columns on normal phone width. |
| Column count | 2 | n/a | Keep 2 columns at Samsung logical width. |
| Card width | `~54 px` | `40.3%` crop width | Runtime card width ratio should remain about `0.43-0.47` of content width. |
| Card height | `~96 px` | `23.9%` crop height | Runtime card height about `1.65-1.90x` card width. |
| Horizontal gutter | `~6 px` | `4.5%` crop width | Use compact gutters; avoid wide empty grid gaps. |
| Vertical gap | `~8 px` | `2.0%` crop height | Use compact vertical card gaps. |
| Image | near square, `~43 x 43` | `~80%` card width | Preserve square thumbnail and cover fit. |
| Title/value/category | lower half | n/a | Title first, value prominent, metadata muted. |
| Gallery badge | `~10-12 px` | n/a | Add only when real gallery count is greater than one. |
| Favorite/menu | top-right controls | n/a | Preserve existing item menu; wishlist badge is adaptation. |

## S06 Bulk Select

Approved frame shows selected item checkmarks, selected count header, and bulk actions. Current Portfolio does not implement bulk select. Phase 2 must not fake this state; record as `DEFERRED PRODUCT CONTRACT`.

## S07 Item Options

Approved frame shows item options for one selected item. Current Portfolio has an overflow menu with View details, Edit, and Delete. Preserve behaviour and align menu surface to dark board language; unsupported duplicate/move/share/export actions remain deferred.

## S08 Collections

Approved frame shows collection grouping. Current Portfolio has category filters, not user-created collections. Do not add collection management; defer as product contract.

## S09 Share Collection

Approved frame shows share link, channels, visibility, and comments. Current Portfolio has no share collection contract. Do not add share UI; defer.

## S10 Export / Backup

Approved wider crop `202 x 402` shows export format, include options, export, and backup controls. Current Settings has export/backup related entries, not Portfolio-owned export. Do not add Portfolio export/backup features in Phase 2; defer.

## Runtime Density Targets

For Samsung SM E625F runtime captures:

- Header, search, summary, sort/filter controls, at least the empty/no-results card top or the first grid row should be visible in the first viewport.
- Summary surfaces should not exceed `30%` of the viewport height in empty state.
- Search field height should be `44-56 logical px`.
- Sort/filter controls should be `40-52 logical px` tall.
- Two-column grid cards should have a width ratio of `0.43-0.48` of content width and a height ratio of `1.55-1.95` of card width.
- Bottom padding must clear the App Shell navigation and system navigation.
