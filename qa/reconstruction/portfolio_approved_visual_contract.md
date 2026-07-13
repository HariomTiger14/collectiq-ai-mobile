# Portfolio Approved Visual Contract

Scope: Portfolio only. This is an audit and contract-recovery artifact, not implementation.

## 1. Authority identity
Primary authority: C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_06_Portfolio/images/portfolio_flow_master.png. Version 1.0, imported 2026-07-11, dimensions 1536x1024, SHA256 40e22e960b9e73835a4463aeb2d72b6ed4f9bf32de98f1171b6c3f43376324b4.

## 2. Approval/freeze evidence
Design Bible v1.0 release manifest freezes approved master images and extracted screens. Volume_06_Portfolio visual_inventory.md marks S01-S10 Approved. golden_mapping.md states the master is contractual source.

## 3. Target viewport
Approved crops are mobile board frames, mostly 134x402 px with S10 at 202x402 px. Runtime evidence must record platform, logical viewport, pixel ratio, theme, locale, text scale, fixture, animation state, and Design Bible release.

## 4. Root background
Portfolio root uses a dark background equivalent to PackLoxTokens.background #0B0F17. Light root backgrounds are not part of the approved dark Portfolio release.

## 5. Safe areas
Content must start below the platform status/cutout area and bottom navigation must sit above system navigation. SM E625F evidence has a 92 px status/cutout inset and 135 px navigation bar inset.

## 6. Header placement
Header is the first visible Portfolio content after the status bar. It must precede search, summary cards, grid, filters, and item list content.

## 7. Header content
Approved S01 header is My Collection. Current Flutter uses PackLoxHeader with Your collection and Portfolio fallback. Remediation must either align to My Collection or record a Product Language-approved title substitution.

## 8. Collection summary
Approved S01 shows compact total items and value cards plus recent scans and top category. Runtime summary must not dominate the first viewport with a light card that displaces approved search and recent content.

## 9. Item count presentation
Approved S01 shows Total Items as the first metric. Current empty runtime shows 0 Items inside a summary card. Populated state must show real item count only.

## 10. Total value presentation
Approved S01 shows Total Value (Est.) with trend chart and change indicator. Current runtime shows $0 Total value in a light summary card. Values must not be fabricated.

## 11. Search placement
Approved S01 places search near the top of the Portfolio Home surface. Approved S02 is a dedicated Search state. Current Flutter hides search when item count is zero; this is an implementation decision requiring authority clarification.

## 12. Search dimensions
Search is a compact full-width field within the mobile frame, not a detached modal. Runtime remediation must measure and keep it inside the content grid.

## 13. Search visual state
Approved search uses dark field styling, recent searches, suggestions, and keyboard state in S02. Runtime search active state was not freshly capturable because no items were present.

## 14. Filter access
Approved S03 includes filter controls in-screen. Current runtime exposes a Filter tool button and modal sheet even when empty. Access can remain, but visual treatment must be board-aligned or formally approved.

## 15. Sort access
Approved board includes sort control and sort options. Current runtime has Sort: Recently Added button and modal sheet. Label semantics are useful but visual treatment differs.

## 16. Filter-sheet contract
The board does not approve a separate light modal filter sheet. If Flutter keeps a bottom sheet, it must be dark, tokenized, safe-area aware, and traceable to S03 filter/dropdown/range-slider authority or a new approved overlay authority.

## 17. Sort-sheet contract
The board does not approve a separate light modal sort sheet. If Flutter keeps a bottom sheet, it must match approved dark surface language and preserve sort options without changing behavior.

## 18. First-viewport hierarchy
Approved S01 first viewport contains header, search, summary/value cards, recent scans/top category, and bottom nav. Current empty runtime contains header, large summary, sort/filter buttons, Add item, empty card, and bottom nav.

## 19. Grid/list layout
Approved board shows grid, list, and compact modes as approved options. Current Flutter implements responsive grid only for populated items and does not expose view mode controls.

## 20. Column count
Approved S05 crop shows a two-column item grid in the mobile board. Current Flutter uses 1 column under 360 px, 2 columns between 360 and 720 px, and 3 columns at 720 px or wider.

## 21. Gutter rules
Item grids must keep consistent dark gutters and not collide with bottom navigation. Current Flutter uses AppSpacing.xl main-axis and AppSpacing.lg cross-axis spacing.

## 22. Item-card dimensions
Approved item card is compact enough to show multiple items in one mobile viewport. Current card aspect ratios are 0.47 for two columns and 0.58 for one/three columns, which must be verified against S05.

## 23. Item-card image ratio
Approved item cards use image-first cards with a near-square image. Current PortfolioGridTile uses AspectRatio 1 for thumbnails.

## 24. Item-card content order
Approved S05 order is image, title, value, status/condition indicators, and quick value context. Current order is image, title, badges, spacer, Est. value row, chevron, overflow menu.

## 25. Title treatment
Titles must be high contrast, two-line safe, and below image. Current Flutter maxes titles at 2 lines with titleSmall weight 900.

## 26. Category/metadata treatment
Approved board uses category and condition/status labels. Current Flutter uses category, confidence, trend, and wishlist badges. Extra badges require acceptance or alignment.

## 27. Valuation treatment
Approved valuation uses currency plus trend/confidence semantics. Current Flutter always formats estimatedValue as currency, including zero, in grid cards.

## 28. Unavailable valuation treatment
Unavailable valuation must not display as a confident $0 unless the item truly has zero value. Current grid value helper does not branch by valuationStatus.

## 29. Zero-value treatment
Zero valuation must be distinct from unavailable valuation. If a real zero-value item exists, the UI must label it as zero value without implying provider failure.

## 30. Favorite treatment
Approved item cards show heart/favorite treatment in component examples. Current grid shows wishlist badge text when a wishlist status exists, not a heart control.

## 31. Gallery/image-count treatment
Approved task requested gallery indicator review; current PortfolioGridTile does not expose a gallery count badge in the grid. Detail handles gallery, but Portfolio card authority remains incomplete.

## 32. Item-menu treatment
Approved S07 shows item options quick actions. Current Flutter uses PopupMenuButton with View details, Edit, Delete. Visual and action coverage differ from S07 options.

## 33. Empty-state contract
Approved master includes an Empty State component: Your collection is empty and Scan Your First Item. Current empty runtime says No collectibles saved yet and Scan Collectible after a large summary card.

## 34. No-results contract
Approved master includes No Results State: No items found and Clear Filters. Current Flutter no-results state matches that concept but was not freshly capturable because search controls require items.

## 35. Partial-data contract
Items with missing valuation, missing confidence, missing category, or missing image must preserve layout and use explicit unavailable labels.

## 36. Missing-image contract
Current image placeholder uses image_not_supported icon. Approved empty/item-card placeholder treatment must be checked against S05 and empty-state components before freeze.

## 37. Populated-state contract
S01, S04, S05, S06, and S07 require populated Portfolio evidence. Current recovery did not produce fresh populated evidence; remediation must capture it before freeze.

## 38. Typography mapping
Use approved Product Language text weights only where component contracts exist. Current header uses 30 px title from PackLoxHeader. Current sheet titles are very large and dark-on-light, not board-aligned.

## 39. Colour/token mapping
Root maps to PackLoxTokens.background #0B0F17. Dark surfaces should map to PackLoxTokens.surface #111827 or surfaceRaised #1A2233. Primary blue maps to #2563EB. Current light surfaces require remediation or explicit approval.

## 40. Surface mapping
Approved Portfolio surfaces are dark cards with subtle borders. Current summary and sheets render light surfaces, creating a major mismatch.

## 41. Radius mapping
Approved cards use rounded dark card corners. Current runtime uses large rounded summary card and AppRadius.xxl sheet top corners. Radii must be mapped to board roles.

## 42. Elevation mapping
Approved cards are low-depth dark surfaces. Current grid uses AppElevation.level2 and sheets use large shadows; verify before freeze.

## 43. Iconography mapping
Approved board includes search, filter, sort, grid/list/compact, selection, overflow/actions, export, share, backup, and nav icons. Current runtime lacks view-mode icons in the main Portfolio UI.

## 44. Spacing measurements
Fresh runtime: first entry capture is 1080x2400. Status inset is 92 px, nav inset 135 px. Current first viewport places summary from about y=338 to y=1177 and Add item around y=1361 to y=1516, with empty card partially under nav.

## 45. Alignment/grid rules
All Portfolio content must align to one content grid. Current horizontal content padding follows AppSpacing.lg on SM E625F but light summary width is narrower than most runtime surfaces.

## 46. Initial scroll position
Portfolio must enter at top of scroll. Sprint 06 previously fixed initial scroll behavior; this must remain unchanged.

## 47. Scroll-restoration policy
Portfolio currently uses ScrollController keepScrollOffset false. Re-entry should not resume stale scrolled positions unless explicitly approved.

## 48. Return-from-Detail scroll policy
Returning from Detail must keep a usable Portfolio context without jumping behind the bottom nav. Current behavior must be regression-tested if item cards move.

## 49. Tab re-entry scroll policy
Tab re-entry must keep Portfolio reachable and not preserve an invalid mid-card offset. Current Sprint 06 behavior remains a frozen behavior constraint.

## 50. Responsive rules
Grid can adapt from one to two to three columns, but approved mobile S05 needs direct comparison at the target logical width. Search/filter/sort controls must remain reachable at narrow widths.

## 51. Accessibility requirements
Controls require 44 px minimum targets, semantic labels for search, filters, sort, add item, item cards, item menus, values, missing values, and bottom nav, plus focus order matching visual order.

## 52. Motion rules
Motion may use subtle reveal/tap feedback if reduced motion is respected. Sheet elastic/parallax motion is not approved by Portfolio authority and needs explicit review.

## 53. Approved components
Approved reusable PL components available: PLX-CMP-HEADER@1.0.1, PLX-CMP-HERO@1.0.1, PLX-CMP-ENTRY-TILE@1.0.0, PLX-CMP-BUTTON@1.0.0. Portfolio screen composition itself is approved by Design Bible Volume_06, not by component approval alone.

## 54. Primitive compositions
Portfolio summary, search field, filter/sort controls, item grid card, empty/no-results states, and sheets are screen compositions unless later promoted to Product Language components.

## 55. Candidate components
Candidate components: Collection Search Bar, Portfolio Metric Card, Value Trend Chart, Recent Scan Row, Filter Dropdown, Range Slider, Sort Control, Item Grid Card, Selection Checkbox, Bulk Action Bar, Item Action Menu, Collection Card, Share Link Field, Share Channel, Visibility Selector, Export Option, Cloud Backup Card, Floating Action Button.

## 56. Prohibited legacy elements
Do not restore stale Portfolio custom scroll bugs or pre-freeze inset behavior. Do not introduce fake portfolio data, fake values, or fake gallery counts.

## 57. Allowed runtime adaptations
Allowed: true empty state, hidden search when formally accepted for empty portfolios, local-first data, unavailable state labels, App Shell four-tab retention until shell authority is reopened.

## 58. Non-negotiable visual requirements
Dark Portfolio root, board-backed top hierarchy, search/filter/sort access for populated state, real item counts/values, distinct unavailable valuation, board-aligned item cards, and no light modal sheets unless separately approved.

## 59. Behavioural contracts that must remain unchanged
Portfolio remains local-first and reads portfolioControllerProvider. Add item still starts Scan. Item tap opens Detail. Delete confirmation remains guarded. Sorting/filtering/searching must not mutate item data.

## 60. Evidence requirements
Remediation must provide fresh empty, populated, search active, no-results, category filter, sort, post-filter, post-sort, gallery, missing image, unavailable valuation, zero valuation if available, XML, device metadata, and side-by-side comparisons.

## 61. Acceptance criteria
All Critical and High deviations must be fixed, explicitly accepted as adaptations, or moved to a new approved authority. Tests must cover behavior and state rendering. Portfolio visual freeze may be restored only after fresh runtime comparison against the approved master and matching crops.
