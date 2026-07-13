# Portfolio Approved Authority Remediation Plan

Scope: proposed plan only. No implementation is started here.

## Exact files likely to change

- lib/features/portfolio/presentation/portfolio_screen.dart
- lib/features/portfolio/presentation/widgets/portfolio_widgets.dart
- test/portfolio_screen_test.dart or equivalent focused Portfolio tests
- test/widget_test.dart only for broad Portfolio expectations affected by approved authority

## Shared components involved

- PackLoxHeader PLX-CMP-HEADER@1.0.1
- PackLoxButton PLX-CMP-BUTTON@1.0.0
- Product Language tokens
- Candidate sheet, metric-card, search, item-card components if promoted later

## Screen composition changes

- Align top hierarchy to approved S01/S02/S03 states.
- Replace light summary and sheet surfaces with dark board-backed surfaces.
- Decide search visibility for empty Portfolio.
- Capture and align populated grid before freeze.

## Token corrections

- Preserve dark root #0B0F17.
- Use dark raised surfaces for summary/cards/sheets.
- Reserve bright blue for primary actions and selected controls.
- Remove unapproved light summary/sheet surfaces unless explicitly approved.

## Header corrections

- Align Portfolio header copy to My Collection or formally approve PackLoxHeader fallback copy.
- Preserve notification slot behavior unless Notifications scope is reopened.

## Summary corrections

- Rebuild summary as compact metric/value cards matching S01/S04.
- Add value trend/change only when real data exists.
- Distinguish zero from unavailable valuation.

## Search/filter/sort corrections

- Align search field with S01/S02.
- Align filter/sort with S03.
- Replace bright modal sheets with dark board-aligned controls or create a separate approved overlay authority.

## Item-card corrections

- Compare populated cards to S05.
- Align title, image, value, badge, menu, favorite/wishlist, and gallery indicators.
- Ensure unavailable valuation does not display as confident $0.

## Image/gallery corrections

- Validate square crop against S05.
- Add gallery/image-count treatment only if approved or formally required.
- Preserve missing-image placeholder without faking an image.

## Empty/no-results corrections

- Align empty state copy and placement to the board empty component.
- Capture no-results using a safe populated fixture.

## Scroll/inset corrections

- Preserve Sprint 06 initial top scroll behavior.
- Ensure empty and populated lower content clears bottom nav.

## Responsive corrections

- Validate 360 logical px, standard Android portrait, and wider layouts.
- Keep grid columns and controls stable without text overflow.

## Accessibility corrections

- Maintain 44 px targets, semantic labels, focus order, text scale, and reduced motion.
- Add explicit semantics for valuation unavailable and item menus.

## Test updates

- Portfolio empty order and surface tests.
- Populated grid fixture tests.
- Search/no-results fixture tests.
- Filter/sort state tests.
- Valuation status display tests.
- Scroll and Detail return tests.

## Runtime evidence required

Fresh empty, populated, search active, no-results, filter, sort, post-filter, post-sort, gallery/multi-image, missing-image, unavailable valuation, zero valuation if safely available, XML, metadata, and side-by-side comparisons.

## Commit plan

1. fix: align portfolio structure with approved authority
2. fix: align portfolio cards and controls with approved authority
3. fix: align portfolio scroll and state presentation
4. test: validate approved portfolio visual contract
5. chore: add approved portfolio authority evidence
6. docs: amend portfolio visual freeze

## Rollback plan

Revert Portfolio presentation commits only. Do not touch backend, routing, auth, Home, Detail, Scanner, or Product Language definitions. Isolate any shared component change in its own commit for clean rollback.

## Frozen-behaviour risks

Search/filter/sort behavior, Add item Scan handoff, item tap Detail handoff, delete confirmation, and initial scroll behavior must not regress.

## Acceptance checklist

- Design Bible Portfolio authority cited.
- PVD-001 through PVD-012 resolved, accepted, or explicitly deferred.
- Fresh populated runtime evidence captured.
- Focused Portfolio tests updated.
- No unrelated sprint or screen changes included.
