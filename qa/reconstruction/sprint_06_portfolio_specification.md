# Sprint 06 Portfolio specification

Status: specification only. No production, test, runtime-evidence, or design implementation is authorized until this document is committed.

Branch: `rebuild/product-language-v1`

Starting frozen HEAD: `c92d7a5a2361b1851836035a3cd438824294bcf7`

Sprint title: Portfolio Presentation Reconstruction

Authoritative Product Language release: `PLX-PL-1.0`

Sprint 01, Sprint 02, Sprint 03, Sprint 04, and Sprint 05 remain frozen. This sprint owns only Portfolio presentation and Portfolio-specific presentation states.

## 1. Current Portfolio architecture

The Portfolio tab is selected through the frozen App Shell destination at index 1 and renders `PortfolioScreen(onScanPressed: _startNewScan)`. Home opens Portfolio by asking App Shell to select the Portfolio tab. Scanner result "View Portfolio" also selects the Portfolio tab after an item is saved.

`PortfolioScreen` is the canonical Portfolio entry screen. It is a `ConsumerStatefulWidget` that owns screen-local presentation state for search, sort, category filter, confidence filter, trend filter, and a `ScrollController`. It watches `portfolioControllerProvider`, requests `ensureLoaded()` after first frame, reads `orderedItems`, derives visible items in the widget layer, and pushes `CollectibleDetailPage` for existing Detail navigation.

`PortfolioController` owns loading, error, saved items, save/update/delete/clear/demo seed actions, and repository/cloud-sync coordination. `PortfolioState.orderedItems` delegates to shared newest-first sorting. `PortfolioState.totalValue` currently sums `estimatedValue` for every ordered item.

`SharedPreferencesPortfolioRepository` is the local persistence implementation. It stores JSON at `portfolio_items`, preserves item identity by id, saves a fresh `savedAt` timestamp when adding, preserves timestamp when updating/upserting synced items, and sorts newest first before persistence.

## 2. Runtime flow map

1. Frozen App Shell builds only the active Portfolio destination.
2. `PortfolioScreen.initState` schedules `portfolioControllerProvider.notifier.ensureLoaded()`.
3. `PortfolioController.loadItems()` reads `portfolio_items` through `PortfolioRepository.getItems()`.
4. Loaded items are sorted newest-first.
5. `PortfolioScreen` applies search/filter/sort presentation state to `orderedItems`.
6. Empty, loading, error, no-results, or grid content renders from controller plus presentation state.
7. Item tap or "View details" pushes `CollectibleDetailPage` with the item and delete callback.
8. Delete asks for confirmation, calls `PortfolioController.removeItem(id)`, reloads local state, and attempts cloud delete.
9. Add Item invokes the existing `onScanPressed` callback, which resets Scanner and selects the Scan tab.
10. Scanner saves through `ScannerController.saveScanResultToPortfolio()`, which calls `portfolioControllerProvider.notifier.saveItem(item)`.

## 3. Controller/provider ownership

`portfolioControllerProvider` is the Portfolio state owner. It owns:

- list of `CollectibleItem`s;
- loading state;
- user-safe error message;
- local save/update/delete/clear/demo actions;
- cloud sync coordination after local changes;
- repository dependency through `portfolioRepositoryProvider`.

Presentation may derive visible items, labels, layout, and local filter/sort UI state, but it must not rewrite repository, sync, save, update, delete, identity, or valuation business rules.

## 4. Repository and sync ownership

`PortfolioRepository` owns the persistence contract: add, upsert synced item, update, get, remove, image-sync metadata update, and clear.

`SharedPreferencesPortfolioRepository` owns local JSON persistence at `portfolio_items`.

`CloudPortfolioSyncCoordinator` is called by `PortfolioController` after save/update/delete and must remain the sync coordinator. Sprint 06 must not alter Supabase contracts, cloud storage paths, environment flags, or backend sync semantics.

## 5. Item identity contract

`CollectibleItem.id` is the stable item identity. Repository add/upsert/update/remove match by id. Presentation keys use ids (`portfolio-grid-item-$id`) and must preserve stable identity for taps, menus, delete, and Detail handoff.

## 6. Ordering contract

Canonical ordering is `collectiblesNewestFirst`, implemented by `compareCollectiblesNewestFirst`. It sorts by `collectibleDisplayTimestamp(item)`, currently `createdAt`, descending. Ties fall back to id descending.

`SharedPreferencesPortfolioRepository.addItem()` assigns a fresh saved timestamp through `_nextSavedAt()`. If the clock would place a new item at or before the newest existing item, the repository advances by one microsecond.

Default Portfolio presentation sort is "Recently Added", which uses this newest-first contract.

## 7. Search contract

Current search is screen-local and immediate. It:

- trims the query;
- lowercases the query;
- matches `item.title` and `item.category` only;
- does not debounce;
- does not persist across app restart;
- is retained only while the active `PortfolioScreen` state remains mounted/PageStorage preserves shell state.

Presentation labels must not imply search covers notes, brand, year, metadata, or Detail fields unless implementation is separately updated and tested.

## 8. Filter contract

Current filters are screen-local:

- category filter via visible chips and filter sheet;
- confidence filter through filter sheet;
- trend filter through filter sheet.

Category matching is keyword-based over category plus title:

- Cards: contains `card` or `tcg`;
- Coins: contains `coin`;
- Comics: contains `comic`;
- Memorabilia: contains `memorabilia`, `sports`, `autograph`, or `jersey`;
- Other: not any of the above.

Confidence filters use `item.confidence >= 0.80` or `< 0.80`.

Trend filters use normalized `item.marketSummary?.trendLabel`; rising/down/cooling keywords map to Rising or Cooling, otherwise Stable.

## 9. Sort contract

Current sort modes:

- Recently Added: `compareCollectiblesNewestFirst`;
- Value High -> Low: `estimatedValue` descending;
- Value Low -> High: `estimatedValue` ascending;
- Confidence: confidence descending;
- Trend: Rising before Stable before Cooling, using normalized trend rank;
- Category: category lowercase ascending.

Sort is presentation-local and does not change repository ordering or persistence.

## 10. Category contract

`CollectibleItem.category` is the stored category. Presentation may group or label category filters, but it must preserve stored category text on item cards and must not mutate category values to fit a visual taxonomy.

## 11. Favorite contract

Favorite state is not stored on `CollectibleItem`. Current Portfolio cards read `wishlistEntriesProvider` and map matching `WishlistStatus` entries by item id into optional labels: Owned, Wanted, Missing. Detail has separate favorite/detail actions outside Sprint 06 scope.

Sprint 06 may present existing wishlist/favorite-like state if available, but must not invent a Portfolio favorite field or alter wishlist semantics.

## 12. Item-action contract

Current grid item actions:

- card tap: open existing Detail screen;
- View details menu item: open existing Detail screen;
- Edit menu item: show "Edit collectible profile is coming soon.";
- Delete menu item: confirm, then call `PortfolioController.removeItem(id)`;
- Add Item action: call existing `onScanPressed` to enter Scanner.

No unsupported export/import/share/action workflow may be added.

## 13. Delete contract

Delete requires a confirmation dialog with Cancel/Delete. Confirmed delete calls `PortfolioController.removeItem(id)`. If delete originates from Detail and succeeds, Portfolio pops the Detail route.

Presentation must prevent card tap and menu/delete actions from conflicting.

## 14. Primary-image contract

Primary image ownership lives in `CollectibleItem.imagePath` plus `CollectibleImage.isPrimary` in `galleryImages`. Scanner save constructs `imagePath` from the selected primary/fallback path and persists gallery images.

Existing grid thumbnail helper currently chooses `imagePath` first, then primary gallery image, then first gallery image, then placeholder. Detail and `effectiveGalleryImages` expose gallery compatibility for legacy one-image records.

Sprint 06 should document and preserve actual fallback unless a narrowly scoped Portfolio presentation fix is required to avoid hiding real gallery data.

## 15. Gallery-image contract

`CollectibleItem.galleryImages` stores ordered `CollectibleImage` records with path, role, source, original path, enhancement preset, quality metadata, and `isPrimary`. `effectiveGalleryImages` returns cleaned gallery images, or falls back to one primary front image from `imagePath` for legacy items.

Presentation must not discard gallery images, hide multi-image state, or show fake image counts.

## 16. Thumbnail fallback contract

Current thumbnail fallback in `PortfolioGridTile`:

1. `item.imagePath` when non-empty;
2. primary `galleryImages` path;
3. first non-empty `galleryImages` path;
4. category icon placeholder.

Image rendering supports network URLs, asset paths, local file paths through `buildLocalPortfolioImage`, and placeholder for empty/sample/selected-image paths or decode failure.

## 17. Detail-navigation contract

Portfolio Detail navigation is existing and out of scope for reconstruction. Portfolio pushes `CollectibleDetailPage(item, onDelete)` through `MaterialPageRoute`. Existing Detail actions, gallery, edit, delete, favorite, and notes behaviours must be preserved.

## 18. Scanner handoff contract

Scanner save uses `portfolioControllerProvider.notifier.saveItem(item)` and local/cloud sync remains controller-owned. Portfolio Add Item calls App Shell `onScanPressed`, which resets Scanner state and selects Scan. Scanner "View Portfolio" selects Portfolio tab.

No scanner-to-portfolio handoff rewrite is authorized.

## 19. Empty-state contract

Empty Portfolio means `portfolioState.items.isEmpty`, not search/filter hiding results. Current empty state offers Scan Collectible via `onScanPressed`. It is not an error and must not fabricate portfolio metrics.

## 20. No-results contract

No-results means the repository has items but presentation search/filter state produces `visibleItems.isEmpty`. Current clear action resets search, category, confidence, trend, and sort to defaults.

## 21. Loading-state contract

Loading is `PortfolioState.isLoading`. Current UI shows a progress indicator only when loading and items are empty. Loading over an existing collection does not replace visible items. No artificial loading timer exists or is allowed.

## 22. Error-state contract

`PortfolioState.errorMessage` is user-safe copy set by controller catch blocks. Current UI shows `PortfolioErrorState(message)` and no retry action. Sprint 06 must not add retry unless backed by a safe controller action and tested.

## 23. Partial-data contract

Partial data includes unavailable valuation, zero valuation, missing image, missing optional metadata, local-only sync, failed sync, and incomplete gallery metadata. Presentation must show available item identity and metadata honestly without hiding the item.

Current `totalValue` sums `estimatedValue`, including zero. Existing domain `valuationStatus`, `valuationSource`, `pricing`, and `marketSummary` preserve richer semantics for future presentation; Sprint 06 must not redefine them.

## 24. Guest/local contract

Guest and signed-out users retain local portfolio access. SharedPreferences local persistence works without auth/cloud. Cloud failures are swallowed by sync coordinator calls and must not block local save/update/delete presentation.

No auth guard or sign-in requirement may be introduced.

## 25. Current visual hierarchy

Current hierarchy:

1. large custom `PortfolioHeroHeader` consuming about 198px plus status inset;
2. three action tiles: Sort, Filter, Add Item;
3. optional Find Items card with search and category chips;
4. Portfolio Snapshot card;
5. content state: loading/error/empty/no-results/grid;
6. item grid with premium tiles and menu.

Current risks: oversized hero, duplicated section cards, summary before items, filter controls partly hidden in sheets, technical confidence/trend badges on cards, and a visual style that leans decorative rather than dense collection management.

## 26. Current performance risks

Observed source risks:

- filtering/sorting occurs in `build`;
- visible-item derivation repeats on every rebuild;
- `MotionReveal` delay scales by item index;
- custom hero/parallax/ambient gradients add motion/decorative cost;
- card thumbnails may decode large local images;
- nested shrink-wrapped metric grid sits inside scroll content;
- broad widget watches combine portfolio, wishlist, and local presentation state.

These are presentation risks. Do not rewrite domain logic for micro-optimization.

## 27. Proposed information hierarchy

Target hierarchy:

1. approved Header as compact first signal;
2. concise collection summary with item count, valued total, and unvalued/partial-data cue;
3. search;
4. compact filter/sort access and active filter chips;
5. first visible row of real items;
6. empty/no-results/error states in the content region.

This hierarchy prioritizes collection management over decoration and keeps real items visible earlier.

## 28. Product Language composition

A. Existing approved Product Language components:

- `PackLoxHeader` v1.0.1;
- `PackLoxButton` v1.0.0 for clear commands;
- `PackLoxEntryTile` v1.0.0 only where the action semantics match;
- `PackLoxHero` v1.0.1 only if a compact Portfolio use is explicitly justified.

B. Composition of approved foundation primitives:

- Portfolio scaffold;
- collection summary;
- search field shell;
- filter/sort control row;
- item grid/list layout;
- valuation status;
- gallery/image indicators;
- empty/no-results/error states;
- responsive spacing, radius, borders, elevation, iconography, safe areas, and motion.

C. Candidate treatments requiring Design Studio review:

- portfolio item card;
- collection summary;
- filter/sort control group;
- gallery-count badge;
- valuation status treatment;
- empty/no-results composition.

No C candidate is promoted by Sprint 06.

## 29. First-viewport strategy

First viewport should normally contain Header, concise summary, search, compact filter/sort controls, and the first row of real items. Avoid oversized hero, duplicated totals, too many cards, deep sync diagnostics, large decorative surfaces, and controls that hide the grid.

## 30. Header strategy

Use approved Header v1.0.1 if implementation proceeds. Header should identify Portfolio and may include concise support copy. It must not become a marketing hero or obscure item access.

## 31. Collection-summary strategy

Summary should display real item count, current total per existing contract, and honest unvalued/partial valuation context where data supports it. It must not fabricate trends, gains, category counts beyond stored categories, sync health, or confidence.

## 32. Search strategy

Search remains immediate and local unless a controller contract is explicitly introduced later. Labels must match actual fields searched. Clear search must restore the documented default visible set.

## 33. Filter/sort strategy

Filter and sort controls should be compact and reachable. Labels must match current semantics. Disabled/unavailable options should not be shown as active. Rapid changes must not duplicate controller operations because these controls are presentation-local.

## 34. Grid/list strategy

Use lazy construction. Cards must not be excessively tall. Grid/list should adapt across narrow, typical, and large phones without clipping titles or values. Do not retain Portfolio tree outside frozen active shell destination behaviour.

## 35. Item-card strategy

Cards should show title, category, valuation state, thumbnail, gallery presence where useful, and menu affordance. Favorite/wishlist state must not rely on color alone. Card tap must open the correct item; menu tap must not also trigger card tap.

## 36. Image strategy

Use existing image paths and gallery records. Preserve fallback order. Use placeholders only when no renderable image exists or decode fails. Do not show only one image state if gallery data exists; indicate gallery/multi-image presence where useful.

## 37. Empty/no-results strategy

Empty: no saved items, honest local-first scanner CTA.

No-results: existing items hidden by search/filter, preserve query/filter context and provide valid clear action.

Partial-data: items remain visible; missing valuation/image/sync data is labelled honestly.

## 38. Responsive rules

Validate narrow Android phone, typical phone, large phone, portrait, shell content bounds, gesture navigation, three-button navigation where possible, large text, and reduced motion. Landscape should remain no worse than current support.

Search, filters, sort, card titles, values, and menus must not clip or overlap.

## 39. Accessibility rules

Cards should announce title, value state, image/gallery count where exposed, and wishlist/favorite state where exposed. Controls should announce selected filter/sort state. Touch targets must meet minimum size. No information may depend on color alone. Decorative elements must be excluded from semantics.

## 40. Motion and reduced-motion rules

Motion may clarify entry, selection, and filtering but must not be continuous or required for state. Reduced motion must disable/shorten nonessential reveal/parallax effects. No artificial loading or search delay may be added.

## 41. Performance budget

Prefer lazy slivers, small widget boundaries, cached derived values where simple, bounded animation, appropriately sized thumbnails, and const widgets. Avoid full-resolution image decoding for cards where controllable, nested scroll conflicts, excessive shadows/blur, and broad provider watches in each item card.

## 42. Allowed files

Allowed for specification commit:

- `qa/reconstruction/sprint_06_portfolio_specification.md`

Potentially allowed after spec commit:

- `lib/features/portfolio/presentation/portfolio_screen.dart`
- `lib/features/portfolio/presentation/widgets/portfolio_widgets.dart`
- `lib/features/portfolio/presentation/widgets/portfolio_local_image.dart`
- `lib/features/portfolio/presentation/widgets/portfolio_local_image_io.dart`
- `lib/features/portfolio/presentation/widgets/portfolio_local_image_stub.dart`
- focused Portfolio tests under `test/`
- runtime evidence under `qa/screenshots/reconstruction/sprint_06_portfolio/`
- `qa/reconstruction/sprint_06_runtime_comparison.md`

`CollectibleDetailPage` is prohibited unless a narrowly scoped Detail handoff bug blocks Portfolio and is separately justified.

## 43. Prohibited files

Prohibited unless separately approved:

- backend, analyzer, Supabase, cloud config, schema/migrations, native config, signing, environment files, secrets;
- Portfolio domain/repository/service/controller business-rule rewrites;
- `lib/shared/domain/entities/collectible_item.dart` except a proven serialization compatibility bug;
- `lib/shared/domain/collectible_sorting.dart` except a proven ordering contract bug;
- Scanner, Detail, Settings, Authentication, App Shell lifecycle/navigation, Home, Onboarding, Bootstrap, and router framework changes;
- original dirty worktree `C:\Users\hario\Desktop\projects\collectiq_ai`.

## 44. Test plan

Run:

- `flutter analyze`
- Sprint 01 bootstrap tests
- Sprint 02 onboarding tests
- Sprint 03 App Shell tests
- Sprint 04 Home tests
- focused Sprint 05 Scanner tests
- focused Portfolio tests
- full suite, compared with Sprint 05 remediated baseline: 534 passed, 16 failed

Focused Portfolio coverage should include App Shell rendering, Header use, item count, total value contract, unavailable vs zero value, empty state, no-results state, clear search/filter, default sort, all sort options, category/favorite filters where present, primary image, gallery fallback, legacy image fallback, placeholder only when needed, image count accuracy, Detail open, menu actions, delete once, scanner-added multi-image item, guest/local behaviour, no auth gate, themes, large text, narrow viewport, reduced motion, rapid controls, tab switch state, and no artificial loading timer.

Do not create fake contracts to satisfy tests.

## 45. Runtime evidence plan

Device: Samsung SM E625F, Android 13 / API 33, device id `RZ8R213M8ZL`.

Evidence directory:

- `qa/screenshots/reconstruction/sprint_06_portfolio/`

Runtime QA should cover Portfolio entry from App Shell and Home action, empty Portfolio, populated Portfolio, partial valuation, search, no-results, clear search, category filter, sort options, favorite filter if present, primary image, gallery fallback, item menu, Detail navigation, return from Detail, scanner-added item, multi-image indicator, tab switch away/back, scroll restoration, rapid filtering/sorting, Home <-> Portfolio switching, Scanner <-> Portfolio switching, no overflow, no blank frame, no route lock, no input lock, no ANR, and no frozen Sprint regression.

Create `qa/reconstruction/sprint_06_runtime_comparison.md` after runtime validation. Do not fabricate unavailable states.

## 46. Rollback boundary

Rollback is limited to Sprint 06 specification, Portfolio presentation files, focused Portfolio tests, Sprint 06 runtime comparison, and Sprint 06 runtime evidence.

Rollback must not require data migration, backend rollback, Supabase rollback, analyzer rollback, scanner rollback, Detail rollback, auth rollback, router rollback, App Shell rollback, Home rollback, or frozen Sprint 01-05 rollback.

## 47. Explicit non-goals

- no Portfolio business-logic rewrite;
- no valuation-definition change;
- no Scanner reconstruction;
- no Detail reconstruction;
- no Settings reconstruction;
- no App Shell redesign;
- no Home redesign;
- no auth redesign;
- no auth guard;
- no router migration;
- no backend/Supabase contract change;
- no fabricated data;
- no artificial loading delay;
- no speculative collection features;
- no Capture System promotion;
- no push;
- no merge;
- no Sprint 07 work.

## Portfolio file inventory

| Path | Responsibility | Classification | State owner | Runtime usage | Status | Tests | Safe to modify |
|---|---|---|---|---|---|---|---|
| `lib/features/portfolio/presentation/portfolio_screen.dart` | Canonical Portfolio screen, local search/filter/sort, grid, Detail push | presentation | screen-local + `portfolioControllerProvider` | active Portfolio tab | current | broad widget tests | yes |
| `lib/features/portfolio/presentation/widgets/portfolio_widgets.dart` | Portfolio summary, empty/no-results/error, grid tile, images, menus | presentation/shared Portfolio | caller/controller data | used by Portfolio/Home/tests | current with legacy list card pieces | broad widget tests | yes |
| `lib/core/ui/portfolio/portfolio_ui.dart` | Portfolio hero/action/section/glass components | shared presentation candidate | caller data | used by Portfolio screen and widget tests | current, partly decorative/legacy | broad widget tests | yes if Portfolio-only |
| `lib/features/portfolio/presentation/widgets/portfolio_local_image*.dart` | local image rendering abstraction | shared Portfolio presentation | path input | used by thumbnails/cards | current | widget tests | yes if presentation-safe |
| `lib/features/portfolio/presentation/controllers/portfolio_controller.dart` | Portfolio state/actions/cloud sync coordination | controller/business | `portfolioControllerProvider` | canonical | current | broad/controller behaviour tests | no except proven integration defect |
| `lib/features/portfolio/domain/repositories/portfolio_repository.dart` | persistence contract | domain | repository implementers | canonical | current | repository tests through widget flows | no |
| `lib/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart` | local persistence | data | SharedPreferences | canonical | current | broad widget flows | no |
| `lib/features/portfolio/domain/services/demo_collectible_seed_service.dart` | demo data seed/clear | domain/service | service | Settings demo mode | current | broad tests | no |
| `lib/shared/domain/entities/collectible_item.dart` | item, gallery, sync, valuation serialization | shared domain | immutable entity | canonical | current | serialization/scanner/detail tests | no |
| `lib/shared/domain/collectible_sorting.dart` | newest-first sorting | shared domain | pure functions | canonical | broad tests | no |
| `lib/features/portfolio/presentation/pages/collectible_detail_page.dart` | Detail screen/handoff target | presentation out of Sprint 06 scope | route-local + callbacks | pushed by Portfolio | current | detail tests | no |
| `lib/features/home/presentation/pages/home_page.dart` | Home Portfolio handoff | frozen Home presentation | callbacks | opens Portfolio tab | frozen current | Home tests | no |
| `lib/core/navigation/app_shell.dart` | Portfolio tab and Home/Scanner handoffs | frozen App Shell | `appShellTabControllerProvider` | canonical shell | frozen current | shell tests | no |

No obsolete Portfolio presentation file is proven unreachable yet. Do not delete legacy/card variants without separate reachability evidence.

## Data and valuation audit

| User-facing value | Source | Calculation owner | Null/zero/partial behaviour | Status | Rename safety |
|---|---|---|---|---|---|
| Item count | `PortfolioState.itemCount` from `items.length` | controller state getter | zero means empty; no null | real | safe label rename |
| Total collection value | `PortfolioState.totalValue` summing `estimatedValue` | controller state getter | currently sums zero/unavailable as stored zero; does not inspect `valuationStatus` | derived from stored items | label must reflect estimate |
| Individual value | `CollectibleItem.estimatedValue` | analyzer/save/domain data | zero displays as `$0`; unavailable semantics live in `valuationStatus` | stored/derived | presentation may label unavailable only if status supports it |
| Unvalued items | `valuationStatus`, `estimatedValue`, pricing/market metadata | presentation may count only from existing fields | unavailable must not become zero; zero-value distinct from unavailable | derived | safe if explicit |
| Category count | unique non-empty `item.category` | current screen helper | empty categories ignored | derived | safe |
| Category label | `item.category` | stored item | empty may show empty unless guarded | real | do not mutate |
| Favorite/wishlist | `wishlistEntriesProvider` by item id | wishlist provider | absent means no label | real when present | label must match status |
| Confidence | `item.confidence` | analyzer/domain | zero displays `0%`; may be stale analyzer metadata | stored/derived | avoid overemphasis |
| Image count | `item.effectiveGalleryImages.length` or `galleryImages.length` | entity/presentation | legacy one-image item exposes one effective image | derived real | safe if accurate |
| Primary image | `item.imagePath` and `CollectibleImage.isPrimary` | scanner/save/detail | falls back to gallery/placeholder | real | no |
| Recent/new status | `item.createdAt`/`savedAt` | repository/domain | epoch fallback for malformed legacy data | real/cached | safe |
| Sync status | `item.syncStatus`, `lastSyncedAt`, `syncError` | cloud sync/entity | localOnly default; current Portfolio does not surface it | real when shown | label honestly only |
