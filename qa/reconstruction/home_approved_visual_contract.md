# Home Approved Visual Contract

Scope: Home only.
Authority: Design Bible v1.0 Volume_02_Home.
Implementation status: contract recovery before Flutter remediation.

## 1. Authority identity

Primary authority is C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_02_Home/images/home_screen_flow_master.png. The master board is Version 1.0, imported 2026-07-11, original filename home screen flow.png, stored as home_screen_flow_master.png, dimensions 1402x1122, SHA256 ec3f05a833fa2b7ba25ed81531e09da011d1882bf2805d0e512ebba3aa866c4a.

Approved crops are S01 Welcome, S02 Empty Collection, S03 Small Collection, S04 Growing Collection, S05 Power Collector, S06 Loading State, S07 Offline State, S08 Syncing State, S09 Insights, and S10 No Valuation.

## 2. Approval/freeze evidence

Release evidence: releases/v1.0/MANIFEST.md records Release v1.0, import date 2026-07-11, 11 approved master images, and 96 extracted application screens.

Volume evidence: Volume_02_Home/README.md states the Home board defines the collection dashboard across lifecycle and connectivity states, contains 10 approved screen references, is an approved dark-theme product board for iOS and Android, and is contractual.

Inventory evidence: Volume_02_Home/visual_inventory.md records Status: Approved contractual reference and marks S01 through S10 Approved.

Golden evidence: Volume_02_Home/qa/golden_mapping.md records the master board as contractual source and the extracted screen files as convenience references.

## 3. Target viewport

The approved crops are board-extracted mobile frames with heights of 426 px and widths of 106 to 127 px. Runtime validation must record platform, logical viewport, pixel ratio, theme, locale, text scale, fixture, animation state, and Design Bible release. Pixel-perfect comparison is only valid when approved and runtime dimensions match.

## 4. Screen background

Home uses a dark root background matching PLX-PL-1.0 PackLoxTokens.background, #0B0F17, or a darker board-equivalent root. Background must remain visually behind all screen content and bottom navigation. No light root background is allowed for the approved dark Home release.

## 5. Safe areas

Content begins below the platform status area. Runtime must keep header content outside the display cutout and keep bottom navigation above the system navigation bar. On SM E625F evidence, usable app content begins below a 92 px status/cutout inset and app navigation sits above a 135 px Android navigation bar.

## 6. Header placement

Header is first content after the status bar. It is left-aligned with the screen content grid. Notification control is right-aligned in the same header row. Header must precede Hero, snapshot, categories, or other body sections.

## 7. Header content

Approved Home header copy is time greeting plus user name where profile data exists, shown as Good morning, Harry in the board. Runtime may substitute fallback user copy only when profile data is unavailable. Notification icon remains visible in the header and must not become the primary action.

## 8. Hero placement

S01 Welcome uses a blue onboarding/collection card directly under the header. S02 Empty Collection uses a dark empty collection card directly under the header. Populated states show collection overview modules directly under the header. Hero or leading card must not push all collection status below unrelated secondary actions.

## 9. Hero dimensions

On approved crops, the leading card occupies the main upper body but leaves lower first-viewport content visible. In runtime remediation, the leading Home card must be bounded so the first viewport can include the next approved section for that state. On a 1080x2400 SM E625F capture, a 756 px Hero followed by two 259 px action cards before the snapshot fails this first-viewport allocation.

## 10. Hero content

S01 content: Ready to build your collection?, Scan a Collectible, Learn How It Works, Why PackLox? explanations. S02 content: Your collection is waiting, Scan your first item to get started, Scan a Collectible, Try a Sample Scan. Populated states replace empty messaging with collection count, value, trends, categories, health, or insights according to S03 through S10.

## 11. Primary action

Primary Home action is Scan a Collectible. It uses the approved Button System where Flutter uses a component implementation. In S02, the primary action sits inside the empty collection card above Try a Sample Scan. The runtime label Scan a collectible is behaviorally acceptable, but case and placement must be reconciled against the board.

## 12. Section order

Approved order is header, leading state card or collection overview, state-specific supporting content, bottom navigation. For S02 this is header, empty card, Popular Categories, bottom navigation. Runtime order must not insert full-width Import photo and Open portfolio cards between the leading empty state and collection state content unless those cards are approved as a replacement for Popular Categories.

## 13. Collection Snapshot contract

Populated states must expose item count, total value estimate when available, value change when available, thumbnails, and View All where shown. Empty state must not fabricate value or count. Snapshot must be visible early enough that the user understands collection status without scrolling past unrelated actions.

## 14. Recent Collectibles contract

Recent scans or recent collectibles appear when saved items exist. Items use thumbnail, category/name, value availability, and recency where shown by S03 through S10. Empty state must not show a recent list.

## 15. Quick actions contract

Approved quick actions are compact: Scan, Search, Import, Share in S03; Scan a Collectible, Search Collection, View Portfolio, View Insights in board action principles. Runtime remediation must use compact quick actions or approved EntryTile variants that fit the board hierarchy. Two large stacked EntryTiles are not board-equivalent for S02.

## 16. Insight/valuation contract

S09 includes Collection Insights, range chips, total value estimate, charts, and top categories by value. S10 includes Valuation Unavailable copy and an explanatory button. Runtime valuation notes must distinguish unavailable valuation from zero value and must not imply a value where none exists.

## 17. Empty-state contract

S02 is the controlling empty-state reference. Required visible elements are header, notification icon, empty collection card with illustration, Your collection is waiting, explanatory scan copy, Scan a Collectible, Try a Sample Scan, Popular Categories, and bottom navigation. Runtime may omit populated metrics in true empty state.

## 18. Populated-state contract

S03 through S05 control populated states by collection size. S03 small collection shows item count, thumbnails, total value estimate, quick actions, and recent scans. S04 growing collection deepens categories and recent scans. S05 power collector includes collection health and top categories. Runtime populated state requires direct crop comparison before freeze.

## 19. Typography mapping

Header greeting maps to PLX Header secondary text: 14 px, 20/14 line height, medium weight where component is used. Header name maps to 30 px, 1.18 line height, 700 weight. Hero title maps to 30 px, 1.04 line height, 700 weight when PackLoxHero is used. Board typography must remain high contrast on dark surfaces.

## 20. Colour/token mapping

Root background maps to PackLoxTokens.background #0B0F17. Raised surfaces map to PackLoxTokens.surfaceRaised #1A2233 where PL components are used. Borders map to PackLoxTokens.border #334155. Primary action maps to PackLoxTokens.blue #2563EB. Cyan accent maps to #22D3EE. Success maps to #22C55E. Error maps to #EF4444.

## 21. Surface mapping

Approved dark cards are raised from the root with subtle borders. Hero/onboarding card uses blue emphasis only for S01 and comparable primary states. Empty collection card in S02 is a dark card with central illustration, not a full blue gradient Hero.

## 22. Radius mapping

PL Hero uses 20 px radius on compact width and 24 px otherwise. PL Header notification button uses 15 px radius. PL section surfaces in current Flutter use AppRadius.lg. Remediation must align radii to the approved component or approved crop role, not mix large Hero radius into every Home section.

## 23. Elevation mapping

Home surfaces use low shadow/depth. Runtime section surfaces may use AppElevation.level1 only where the board shows raised cards. Bottom navigation may keep its frozen App Shell depth unless Home authority recovery explicitly reopens App Shell.

## 24. Iconography mapping

Approved board uses notification bell, PackLox collection illustration, category icons, scan camera, search, portfolio, chart/insight, sync, offline, and bottom nav icons. Runtime Material icons may be retained only when they preserve the approved meaning, size hierarchy, and contrast.

## 25. Spacing measurements

Current runtime horizontal content padding is 45 px on a 1080 px capture. Runtime Hero bounds are [45,337][1035,1093]. Runtime action group bounds are [45,1127][1035,1667]. Runtime nav bounds are [34,2029][1046,2173]. Remediation must reduce first-viewport vertical allocation so the approved next section is visible without being occluded by app nav.

## 26. Grid/alignment rules

Home uses one left-aligned content grid. Header text, leading card, category rows, metric cards, and list sections align to that grid. Cards and controls must not extend behind bottom navigation. Compact category/action grids use equal-width cells where visible in the board.

## 27. Scroll behaviour

Home is vertically scrollable and must preserve App Shell tab state. Pull-to-refresh is shown as a board interaction principle but is not proven implemented in current Flutter. Runtime must avoid scroll positions where bottom navigation hides essential empty-state copy or actions.

## 28. First-viewport content

S02 first viewport must show empty card, primary and secondary empty actions, Popular Categories start, and bottom navigation. Current runtime first viewport shows Header, Hero, Import photo, Open portfolio, and only a partially visible Collection snapshot. This is not board-conformant.

## 29. Responsive adaptation rules

Because v1.0 lists responsive behavior as future work, adaptation is allowed only to preserve hierarchy at smaller or larger logical widths. Adaptation may alter wrapping, row count, and text truncation. Adaptation may not remove approved state sections, change primary action hierarchy, or replace compact board sections with unrelated large surfaces.

## 30. Accessibility requirements

Runtime must preserve 44 px minimum touch targets, semantic labels for header, notification, primary action, quick actions, collection status, and bottom nav, focus order matching visual order, contrast on dark surfaces, text scale support, and reduced-motion behavior.

## 31. Motion rules

Board notes allow cards fade in, numbers count up, pull to refresh, and tap feedback scale down 2%. Runtime must respect reduced motion. Motion must not change section order, delay availability of primary Scan action, or hide Home content needed for first-viewport recognition.

## 32. Components that are approved

Approved Product Language components available for Flutter composition: PLX-CMP-HEADER@1.0.1, PLX-CMP-HERO@1.0.1, PLX-CMP-ENTRY-TILE@1.0.0, and PLX-CMP-BUTTON@1.0.0. These approvals do not by themselves approve the whole Home screen composition.

## 33. Components that are compositions

Home Collection Snapshot, Recent Collectibles, compact quick actions, Popular Categories, valuation/insight note, collection health, top categories, charts, and state-specific cards are Home compositions unless later promoted to approved Product Language components.

## 34. Candidate components

Candidate components for future approval: Metric Card, Category Chip, Recent Scan Card, Collection Thumbnail Row, Skeleton Card, Offline Illustration, Retry Button, Circular Sync Indicator, Trend Chart, Donut Chart, Valuation Notice, and compact Home Quick Action.

## 35. Prohibited legacy elements

Do not restore bespoke elastic, parallax, or reveal-heavy Home motion. Do not introduce fake totals, fake values, fake recent scans, or unsupported portfolio data. Do not treat Sprint 04 PL composition as board-conformant without a board-to-runtime comparison.

## 36. Allowed runtime adaptations

Allowed adaptations: fallback user name when profile is unavailable; empty state when local portfolio is empty; hidden Recent Collectibles when no items exist; unavailable valuation when no reliable value exists; retained business callbacks for Scan, import, and portfolio; preserved App Shell behavior during a visual remediation.

## 37. Non-negotiable visual requirements

Home must be dark theme; header first; notification visible; primary Scan a Collectible action visible in the leading state area; empty state must use S02 hierarchy; populated states must map to S03 through S05; loading/offline/sync/no-valuation states must map to S06 through S10; first viewport must reveal the approved next section for the state.

## 38. Behavioural contracts that must remain unchanged

Home remains local-first and reads portfolio state. Scan action still selects the Scan tab and starts a new scan. Import action still opens gallery import through the Scan flow. Portfolio action still selects Portfolio. Home must not introduce backend ownership, repository ownership, independent loading/error/retry state, or authentication routing changes.

## 39. Evidence requirements

Every remediation commit must include approved reference path, fresh runtime first viewport, full scroll where scrollable, empty state, populated state where safely available, XML hierarchy, device model, OS/API, viewport, density, text scale, theme mode, status/nav bar state, comparison artifacts, and deviation closure notes.

## 40. Acceptance criteria

Acceptance requires direct comparison against the master board and the matching crop for each implemented state. Critical and High deviations in home_visual_deviation_matrix.md must be fixed or explicitly marked as accepted design changes by a new approved authority. Tests must cover behavior and state rendering. Visual freeze may be restored only after fresh runtime evidence and documented review.
