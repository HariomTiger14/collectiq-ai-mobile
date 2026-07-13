# Home Approved Authority Remediation Plan

Scope: proposed implementation plan only. No implementation is started by this document.

## Likely files to change

- lib/features/home/presentation/pages/home_page.dart
- lib/features/home/presentation/widgets/home_dashboard_widgets.dart only if legacy widgets are reused or removed from references
- lib/core/ui/product_language/packlox_hero.dart only if an approved Hero variant needs configuration support
- lib/core/ui/product_language/packlox_entry_tile.dart only if compact Home action use requires an approved variant
- test/home_page_test.dart
- test/widget_test.dart only for broad expectations affected by approved Home order

## Shared components involved

- PackLoxHeader PLX-CMP-HEADER@1.0.1
- PackLoxHero PLX-CMP-HERO@1.0.1 for S01-like welcome only
- PackLoxButton PLX-CMP-BUTTON@1.0.0
- PackLoxEntryTile PLX-CMP-ENTRY-TILE@1.0.0 only where the board hierarchy allows it

## Screen-specific composition changes

- Replace S02 empty blue Hero with an approved empty collection card composition.
- Add or formally exclude Try a Sample Scan.
- Add Popular Categories or formally exclude it with product-owner approval.
- Move Collection Snapshot or approved status content above unrelated large action cards.
- Replace stacked large quick-action EntryTiles with compact quick actions for populated states.
- Add explicit mappings for S03, S04, S05, S09, and S10 before populated freeze.

## Token corrections

- Preserve PackLoxTokens.background #0B0F17.
- Use dark raised surfaces for S02 empty card instead of blue Hero gradient.
- Keep PackLoxTokens.blue #2563EB for primary Scan action.
- Use PackLoxTokens.success #22C55E and amber/error tokens only for board-supported status states.

## Layout corrections

- Keep header first after SafeArea.
- Keep notification in header right slot.
- Bound leading card height so first viewport reveals the approved next state section.
- Ensure bottom navigation does not cover required empty-state copy or action.
- Keep content aligned to one left/right grid.

## Legacy elements to remove

- Do not restore pre-Sprint 04 bespoke Home motion or fake data panels.
- Remove any Home code paths that duplicate approved component anatomy without need.
- Remove references that call the current PL composition Design Bible-conformant before remediation.

## First-viewport corrections

For S02 on SM E625F-class portrait runtime, first viewport must show header, empty card, primary and secondary empty actions, start of Popular Categories, and App Shell nav. If App Shell nav remains four-item due Sprint 03 freeze, record that as an App Shell exception, not a Home conformance pass.

## Responsive corrections

- Test narrow width 360 logical px and standard Android portrait width.
- Text may wrap but must not hide primary Scan action.
- Category/action rows may wrap but must remain before unrelated secondary surfaces in S02.

## Test updates required

- Empty Home order test against S02 contract.
- Scan action handoff unchanged.
- Import and portfolio handoffs unchanged if retained.
- Populated fixture tests for S03/S04/S05 data surfaces.
- No-valuation fixture test for S10.
- Accessibility/focus order test for header, primary action, categories/actions, snapshot, nav.

## Runtime evidence required

- Fresh first viewport screenshot and XML.
- Fresh full scroll screenshot and XML where content exceeds viewport.
- Fresh empty state.
- Fresh populated state from safe fixture or real saved item.
- Fresh no-valuation state if implemented.
- Device metadata: model, OS/API, viewport, density, text scale, theme, status/nav insets.
- Side-by-side comparison against approved crop.

## Commit plan

1. fix: align home structure with approved authority
2. fix: align home visual tokens and spacing
3. test: validate approved home visual contract
4. chore: add approved home authority evidence
5. docs: amend home visual freeze

## Rollback plan

Revert Home presentation commits only. Keep portfolio data, scanner state, backend, router, auth, and Product Language definitions unchanged. If a shared component change is made, isolate it behind a variant or revert the shared component commit before screen-specific rollback.

## Risk to frozen behaviour

- Scan tab selection must not regress.
- Gallery import handoff must not regress.
- Portfolio tab handoff must not regress.
- Scroll persistence and App Shell tab switching must not regress.
- No Home-owned backend or repository must be introduced.

## Acceptance checklist

- Design Bible v1.0 Home authority path cited in freeze docs.
- HVD-001 through HVD-010 closed, accepted, or deferred with explicit authority.
- Flutter tests pass for Home-focused cases.
- Existing frozen App Shell behavior remains intact.
- Fresh Samsung runtime evidence captured.
- Product owner decides whether visual freeze is restored or superseded by a new Home authority.
