# Detail Approved Authority Remediation Plan

Date: 2026-07-13
Scope: Future implementation only. No implementation was performed in this recovery task.

## Objective

Align Flutter Detail with Design Bible v1.0 `Volume_07_Collectible_Detail` while preserving existing Detail behavior: Portfolio entry/return, image gallery review, edit, notes persistence, favorite/share/delete actions, valuation semantics, and runtime stability.

## Likely Files

- `lib/features/portfolio/presentation/pages/collectible_detail_page.dart`
- `lib/features/portfolio/presentation/widgets/portfolio_local_image.dart`
- `lib/core/ui/item_details/item_details_ui.dart`
- `lib/core/design_system/design_system.dart`
- `lib/core/theme/app_theme.dart`
- Detail, portfolio, and home widget tests that navigate into Detail

## Shared Components

Avoid changing shared Product Language components globally unless a token or primitive is missing. Prefer local Detail composition changes. If shared image loaders or dialogs are touched, run Portfolio and Scanner regression checks.

## Structure Changes

Replace the single long-scroll layout with the approved Detail state model. Implement persistent bottom detail tabs or equivalent approved tab controls for Item Overview, Image Gallery, Details & Info, Market & Value, AI Insights, Condition, Similar Items, Price History, Notes & Tags, and Actions Menu.

## Gallery Changes

Retain `effectiveGalleryImages`, selected image switching, use-as-primary, delete safeguards, edit enhancement integration, and full-screen review. Restyle hero, thumbnails, image count, and review chrome to match S01/S02.

## Valuation Changes

Move value from the oversized hero treatment into the approved Market & Value hierarchy. Add explicit unavailable valuation rendering so `valuationStatus: unavailable` does not read as a true `$0` valuation. Define a true zero-value fixture separately.

## Metadata Changes

Map year, set, rarity, material, player/character, condition, category, confidence, and brand into approved Details & Info and Condition components. Replace chip-heavy layout where the approved board uses attribute rows or condition bars.

## AI Evidence Changes

Replace the current linear `AI Review` card with the approved AI Insights composition, including confidence-ring treatment where visible. Preserve stored AI reasoning, confidence explanation, and detection quality.

## Notes And Actions Changes

Align notes field, tag chips, save affordance, and actions menu with S09/S10. Keep delete confirmation as an allowed adaptation unless a new approved confirmation crop is provided. Visually separate destructive delete.

## Surface, Token, Spacing, Layout Fixes

Use approved dark Detail root and compact surfaces. Reduce oversized rounded cards and long vertical gaps. Derive radii, spacing, elevation, and typography from the approved crops, then map to Product Language tokens.

## Responsive And Accessibility Fixes

Maintain Android safe area support, text scale support, semantic labels, focus order, and button roles. Validate at 1080x2400 on `RZ8R213M8ZL`; add smaller-width widget checks for overflow.

## Tests

- Focused Detail widget tests for tab order, first viewport, gallery switching, gallery review, use-primary, delete safeguards, notes persistence, favorite/share feedback, unavailable valuation, zero valuation, and missing image
- Portfolio navigation tests for entry and return
- Visual/screenshot evidence on Android physical device
- Regression checks for Home, Portfolio, Scanner, and App Shell navigation

## Runtime Evidence

Capture approved-vs-runtime evidence for S01 through S10, XML hierarchy for each main state, full-screen gallery, delete confirmation, unavailable valuation, missing image, and logcat crash scan.

## Commit Plan

Recommended future commits:

1. `fix: align detail structure with approved authority`
2. `fix: align detail gallery and valuation presentation`
3. `fix: align detail metadata and actions`
4. `test: validate approved detail visual contract`
5. `chore: add approved detail authority evidence`
6. `docs: amend detail visual freeze`

## Rollback Plan

Keep this recovery commit as the baseline evidence. If remediation destabilizes behavior, revert implementation commits only and preserve the authority docs/evidence. Do not revert unrelated Home, Portfolio, Scanner, backend, router, auth, or cloud-sync work.

## Frozen Behaviour Risks

Highest-risk areas are gallery edit/delete, valuation status semantics, notes persistence, delete confirmation, and Portfolio return. Rebuild visuals around those behaviors rather than replacing the underlying data/action contracts unnecessarily.

## Acceptance Checklist

- S01 Item Overview matches approved first viewport after scaling
- S02 Image Gallery matches hero, thumbnails, and review treatment
- S03 Details & Info maps all runtime metadata
- S04 Market & Value distinguishes unavailable and true zero values
- S05 AI Insights preserves stored evidence in approved composition
- S06 Condition is represented with approved condition treatment
- S07 Similar Items uses approved card treatment or explicit empty adaptation
- S08 Price History uses approved chart/table treatment or explicit missing-history adaptation
- S09 Notes & Tags includes approved notes and tag composition
- S10 Actions Menu matches approved action hierarchy
- Runtime logcat has no app crash
- Focused tests pass
- No Home, Portfolio, Scanner, backend, router, auth, or Product Language regressions
