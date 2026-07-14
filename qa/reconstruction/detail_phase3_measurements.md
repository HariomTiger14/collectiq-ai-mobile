# Detail Phase 3 Measurements

Date: 2026-07-14
Scope: Detail screen only.

Approved authority: `releases/v1.0/design_bible/Volume_07_Collectible_Detail/images/collectible_detail_flow_master.png`
Authority SHA-256: `9fb59e44d860b17b9c3e5671062857087543ef2614b7987625dac6e2c0d924b7`

Implementation measurements:
- Removed the duplicate Material `AppBar` plus embedded shared header from Detail runtime.
- Added a compact Detail authority header, overview hero/value block, and horizontal section tabs.
- Split Detail presentation into Overview, Gallery, Details, Market, Insights, Notes, and Actions.
- Preserved existing image ownership, gallery ordering, full-screen review, edit/share/favorite/delete, notes, wishlist, price alerts, sync status, and portfolio return behavior.
- Valuation now distinguishes unavailable states from an intentionally saved zero value.

Validation:
- `flutter analyze`: pass.
- `flutter test test/detail_screen_test.dart --reporter=compact`: pass.
- `flutter test test/cloud_sync_status_widget_test.dart --reporter=compact`: pass.
- Visual/frozen groups for shared foundations, Home, Portfolio, Detail, App Shell, Scanner: pass.
- Full suite observed after broad Detail test migration: `565 passed / 17 failed`; remaining failures are outside Phase 3 Detail visual scope and align with the existing broad-suite non-Detail baseline area.
