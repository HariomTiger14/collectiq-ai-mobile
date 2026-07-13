# Cross-Screen Visual Consistency Audit

## Consistent Runtime Patterns

- Bottom navigation selected state is stable across Home, Portfolio, Scan, and Settings shell evidence.
- Portfolio and Home both use collection-oriented summary language and value metrics.
- Scanner and Detail preserve confidence/value language across analysis and saved-item views.
- Detail image preview provides an explicit close affordance and primary/edit actions.

## Incomplete Consistency Contracts

- Empty states appear in Home and Portfolio but are not yet tied to one approved shared primitive.
- Portfolio filter/sort sheets are screen-local evidence; no shared bottom-sheet visual contract was found.
- No-results search state is captured but lacks an approved shared-state reference.
- Detail gallery/lightbox is runtime-captured but lacks a matching approved reference.
- Permission sheet is platform-owned; the app needs documented pre-permission or accepted platform-state treatment if visual audit includes it.

## Recommendation

Create a shared-state visual contract before further screen-specific freeze work. That contract should include empty, no-results, sheet, dialog/pre-permission, image preview, and destructive/secondary action states.
