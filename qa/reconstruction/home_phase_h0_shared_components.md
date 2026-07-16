# PackLox Home Phase H0 Shared Component System

## Authority

- Reconstruction branch: `rebuild/product-language-v1`
- Starting reconstruction HEAD: `e5648e0ac668c6c5bb8dc29e44d1c5acd549c1d3`
- Design Platform HEAD read-only: `5571512a99a925788a7fce0b3c4f4fd53fce7485`
- Master visual authority: `releases/v1.0/design_bible/Volume_02_Home/images/home_screen_flow_master.png`
- Master authority dimensions: `1402x1122`
- Master authority SHA-256: `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A`
- Design package read: `releases/v1.0/design_lock/Home/Home_Design_System_v1`

## Scope

Phase H0 created a shared Home presentation component system only. It did not implement or visually freeze any Home state, did not correct the approved H02 empty-state composition, and did not change App Shell, Search, Product Language, providers, controllers, repositories, routing, backend behavior, or data contracts.

No Samsung physical-runtime gate belongs to this H0 component-only phase.

## Files Changed

- `lib/features/home/presentation/widgets/home_shared_components.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `test/home_shared_components_test.dart`
- `qa/reconstruction/home_phase_h0_component_mapping.md`
- `qa/reconstruction/home_phase_h0_shared_components.md`

## Component Inventory

New shared Home components:

- `HomeTokens`
- `HomeAppBar`
- `HomeStateContainer`
- `HomeSection`
- `HomeSurface`
- `HomeSectionHeader`
- `HomeSectionSurface`
- `HomeCollectionStrip`
- `HomeCollectionStripItem`
- `HomeValueMetricCard`
- `HomeCategoryTile`
- `HomeCategoryGrid`
- `HomeQuickAction`
- `HomeQuickActionTile`
- `HomeQuickActionGrid`
- `HomeRecentItemCard`

Refined or extracted from existing Home behavior:

- Home app bar wrapper around the existing `PackLoxHeader`
- Section layout and surface framing
- Quick action grid presentation
- Popular category tile/grid presentation
- Recent collectible row/card presentation

Created as Home-local shared primitives:

- Collection strip tiles and overflow tile
- Value metric card with unavailable-value support and optional real-history trend rendering
- Home state container with shared max-width, gutters, and bottom clearance

## Measurement Confidence

- High confidence: approved color tokens, dark background, surface colors, type hierarchy intent, card spacing, content width, bottom clearance, Home category semantics, unavailable-value handling.
- Medium confidence: exact corner radii and micro spacing where the design lock specifies system intent rather than pixel-perfect implementation.
- Deferred: state-specific final composition and exact H02 empty visual correction. Those remain phase-owned by later Home state work.

## Blocked Or Deferred Components

The mapping document records blocked components whose approved visual shape depends on missing or out-of-scope data/state contracts:

- Welcome hero
- Category breakdown bars
- Collection health
- Skeleton/loading
- Offline
- Syncing
- Insights
- No-valuation
- Bottom navigation/Search dependency

These were not fabricated in H0.

## Runtime Behavior Boundaries

- Current populated Home behavior is preserved.
- Existing empty Home behavior remains intact; H0 only provides shared components.
- No fake counts, valuations, trends, sync states, health states, or category analytics were introduced.
- `HomeValueMetricCard` treats unavailable values separately from zero.
- Category semantics stay collectible-specific: cards are trading cards, coins are collectibles rather than currency, figures are figurines rather than vehicles.
- Quick actions keep existing callbacks and disabled behavior.
- Search and App Shell remain unchanged.

## Responsive Behavior

- Shared Home content uses a max content width of `600`.
- Gutters adapt for narrow phone widths.
- Category grids wrap to two columns on narrow or large-text layouts.
- Shared surfaces and item cards keep stable constraints for 320dp and large text.
- Bottom clearance is supplied by `HomeStateContainer`.

## Validation

- `flutter analyze` - passed, no issues.
- `flutter test test\home_shared_components_test.dart --reporter=compact` - passed, `20` tests.
- `flutter test test\home_page_test.dart test\shared_visual_foundations_test.dart test\app_shell_presentation_test.dart --reporter=compact` - passed, `42` tests.
- `flutter test test\portfolio_screen_test.dart test\detail_screen_test.dart --reporter=compact` - passed, `12` tests.
- `flutter test test\scanner_volume_03_structure_test.dart test\scanner_widgets_test.dart test\scan_hub_page_test.dart test\camera_capture_page_test.dart test\scan_image_processing_service_test.dart --reporter=compact` - passed, `45` tests.
- `flutter test test\auth_presentation_test.dart test\web_auth_pages_test.dart test\settings_phase6b_test.dart --reporter=compact` - passed, `28` tests.
- `flutter test --reporter=compact` - completed at `609 passed / 9 failed`. This matches the accepted `589 passed / 9 failed` baseline plus the new 20 Home H0 shared component tests.

## Rollback Boundary

Rollback the four H0 commits to remove the shared Home component system. This should restore the previous Home page implementation while leaving Design Platform, App Shell, Search, Product Language, providers, controllers, repositories, backend code, and routing untouched.
