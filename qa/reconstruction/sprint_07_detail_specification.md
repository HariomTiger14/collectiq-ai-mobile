# Sprint 07 Detail specification

Status: specification only. No production, test, runtime-evidence, or design implementation is authorized until this document is committed.

Branch: `rebuild/product-language-v1`

Starting frozen HEAD: `4840c852bb3da725e8db5dde895be79ab2b87cdd`

Sprint title: Detail Presentation Reconstruction

Authoritative Product Language release: `PLX-PL-1.0`

Sprint 01 through Sprint 06 remain frozen. This sprint owns only collectible Detail presentation and Detail-specific presentation states.

## 1. Current Detail architecture

The canonical Detail screen is `CollectibleDetailPage` in `lib/features/portfolio/presentation/pages/collectible_detail_page.dart`. Portfolio opens it from `PortfolioScreen._openItem()` through the existing `MaterialPageRoute`, passing the selected `CollectibleItem` and an `onDelete` callback. Home recent items also open the same page. The page is a `ConsumerStatefulWidget` that receives an initial item, watches `portfolioControllerProvider` for a fresher copy by id, owns route-local scroll state, and owns route-local selected-gallery-path state.

The current Detail page is presentation-heavy and mixes UI with several presentation-state and action coordinators: image selection, full-screen gallery review, primary-image update, gallery-image deletion, gallery-image enhancement edit, notes update, edit dialog, local favorite toggle, wishlist status, price alerts, share placeholder, delete confirmation, metadata sections, market evidence, AI analysis, recommendation, and a generated price-history panel.

## 2. Runtime flow map

1. Portfolio or Home passes a `CollectibleItem` into `CollectibleDetailPage`.
2. Detail watches `portfolioControllerProvider.items` and replaces the route item with the matching current item when available.
3. Detail derives `currentItem.effectiveGalleryImages`.
4. `_selectedImageFor()` chooses the active image from selected path, primary image, `item.imagePath`, or first gallery image.
5. The hero image, thumbnail strip, title, category, confidence, value, AI summary, attributes, notes, actions, wishlist, metadata, price alerts, and recommendation render from `currentItem`.
6. Primary-image, gallery delete, gallery edit, notes save, and edit dialog updates call `portfolioControllerProvider.notifier.updateItem()`.
7. Delete confirmation calls the `onDelete` callback supplied by the opening surface. Successful delete pops the Detail route.
8. Full-screen review is a `Dialog.fullscreen` with `PageView`, zoom, close, Use as Primary, Edit Photo, and Delete photo actions.

## 3. Item identity contract

`CollectibleItem.id` is the stable identity. Detail must never key behaviour by title, category, image path, list index, or route position. The watched Portfolio state is filtered by `portfolioItem.id == widget.item.id`; if not found, the initial route item remains the fallback display item.

Presentation keys may use item id or image path for testability, but update/delete actions must continue to target the item id.

## 4. Controller/provider ownership

`portfolioControllerProvider` remains the Portfolio state owner. Detail may read the provider and call public update methods, but it must not create a separate state machine for Portfolio persistence.

Existing provider ownership:

- `portfolioControllerProvider`: item list, loading, errors, save/update/delete/clear/demo, cloud-sync coordination.
- `wishlistStatusForItemProvider`, `wishlistEntriesProvider`, `wishlistRepositoryProvider`: wishlist status read/update.
- `itemPriceAlertsProvider`, `priceAlertRepositoryProvider`, `priceAlertSummaryProvider`: local price-alert read/update.
- `imageEnhancementServiceProvider`, `imageQualityAssessmentServiceProvider`: existing image-enhancement review for supported gallery edit.

## 5. Repository/update ownership

`SharedPreferencesPortfolioRepository` persists JSON at `portfolio_items`. `PortfolioController.updateItem()` owns local update, immediate state refresh, persisted reload, and best-effort cloud sync through `CloudPortfolioSyncCoordinator.syncUpdatedItem()`.

Detail must not call `SharedPreferencesPortfolioRepository` directly. New presentation widgets must receive callbacks or item data rather than repository dependencies.

## 6. Primary-image contract

Primary image ownership lives in `CollectibleItem.imagePath` and `CollectibleImage.isPrimary`. `_setPrimaryImage()` normalizes `effectiveGalleryImages` so exactly the selected path is primary, updates `imagePath`, and persists through `PortfolioController.updateItem()`.

The selected display image is not always the primary image. It is route-local preview state and must not mutate the item until Use as Primary is invoked.

## 7. Gallery-image contract

`CollectibleItem.galleryImages` stores ordered `CollectibleImage` records with path, role, source, original path, enhancement preset, quality metadata, and `isPrimary`. `effectiveGalleryImages` filters empty gallery paths and falls back to a one-image gallery from `imagePath` for legacy records.

Detail must preserve every gallery image during item updates unless the user explicitly deletes one. Editing or primary selection must retain role, source, original path, enhancement metadata, quality metadata, and ordering wherever possible.

## 8. Thumbnail-order contract

Thumbnail order is `currentItem.effectiveGalleryImages` order. Selection changes only `_selectedGalleryPath`. Primary status is indicated separately and must not reorder the strip unless the underlying saved gallery order changes elsewhere.

## 9. Full-screen review contract

Full-screen review is `_PortfolioGalleryReview`. It opens from tapping the hero image, initializes a `PageController` at the selected image, allows horizontal paging, allows zoom through `InteractiveViewer`, displays photo index and role, and exposes close, Use as Primary, Edit Photo, and Delete photo. Delete is disabled when only one image remains.

Returning from full-screen review must preserve the selected image on the Detail page.

## 10. Image fallback contract

Detail image rendering currently handles:

- empty path: placeholder;
- `sample://` path: placeholder;
- `http://` or `https://`: `Image.network`;
- `assets/`: `Image.asset`;
- all other paths: `buildLocalPortfolioImage`.

Hero image path currently resolves from selected gallery image, then `item.cloudImageUrl`, then `item.imagePath`. Thumbnail rendering uses the gallery image path. Placeholders are valid only when no renderable image exists or image decode fails.

## 11. Valuation contract

Stored valuation fields include `estimatedValue`, `valuationStatus`, `valuationSource`, `aiEstimatedValue`, `pricing`, and `marketSummary`. Detail currently displays `estimatedValue` in the hero value card and can display pricing/market fields in expanded sections.

Sprint 07 must distinguish unavailable value from genuine zero value using existing valuation fields. It must not present estimated value as confirmed value. It must not invent market trend, gain/loss, price history, or current value if stored data does not support it.

## 12. Currency contract

`PricingInfo.currency` and market comps provide currency where market data exists. Existing helper `_formatMoney(value, currency)` returns `$x` for empty/AUD and `CURRENCY x` otherwise. `_formatPortfolioValue()` uses the app locale symbol and does not inspect `PricingInfo.currency`.

Sprint 07 presentation may rename labels for clarity, but it must not silently change stored currency semantics or convert values.

## 13. Null/zero/unavailable contract

Unavailable value is not zero. Genuine stored zero remains zero only when a real zero-value contract exists. Current helpers return `Value unavailable` for `value <= 0`, which is safer than fabricating value but collapses genuine zero and unavailable.

Missing optional metadata must be omitted or labelled as missing; it must not be filled with derived rarity, fake summary text, fake trend, or fake diagnostics.

## 14. Metadata contract

Stored metadata fields include category, condition, recommendation, primary match, confidence explanation, detection quality, AI reasoning, alternative matches, year, brand, set name, series, card number, player/character, rarity, estimated grade, language, edition, country, mint, material, notes, sync status, last synced time, and sync error.

Current `Primary Metadata` omits empty values. That omission is correct for optional fields. Sprint 07 should group metadata for scanning, not create long unstructured walls.

## 15. AI summary contract

Existing stored AI fields are `primaryMatch`, `confidenceExplanation`, `detectionQuality`, `aiReasoning`, and `alternativeMatches`. Current `_aiSummaryFor()` fabricates narrative text from available fields even when no stored AI summary exists. Sprint 07 must replace that with stored AI content or an honest absent-summary state.

AI summary must remain real stored content. Do not generate new AI copy locally.

## 16. Notes contract

`CollectibleItem.notes` stores local notes. `_NotesCard` owns a `TextEditingController`, initializes from `item.notes`, updates when item id or notes change, and saves through `PortfolioController.updateItem(widget.item.copyWith(notes: trimmedText))`.

Sprint 07 may reconstruct notes presentation, but must preserve the existing storage semantics and avoid direct repository calls.

## 17. Favorite contract

Current Favorite action is route-local only: `_isFavorited` toggles in widget state and shows a snackbar. It is not persisted to `CollectibleItem`. Persistent collection state is represented separately by wishlist status (`Owned`, `Wanted`, `Missing`) through the wishlist repository.

Sprint 07 must not imply Favorite persists unless it wires to an existing persisted contract and tests it. Prefer honest wishlist/status language if persistence is required.

## 18. Share contract

Current share action is a placeholder: `_shareItem()` shows `Sharing coming soon`. It does not invoke platform share, export, deep links, or clipboard. Sprint 07 must not claim real sharing unless an existing service contract is used and tested.

## 19. Delete contract

Item delete is optional and depends on the `onDelete` callback passed to Detail. `_confirmDetailDelete()` shows `Delete collectible?`, requires confirmation, calls `onDelete(item.id)`, and pops the route only when the callback returns `true`.

Gallery image delete is separate. `_deleteGalleryImage()` prevents deleting the final effective image, removes only the selected image, selects the next primary, persists via `PortfolioController.updateItem()`, and shows a snackbar.

## 20. Return-navigation contract

Detail uses normal Navigator route behaviour. The AppBar BackButton and successful item delete both return through Navigator. Sprint 07 must preserve predictable return to Portfolio/Home caller and must not add router migration or shell-level navigation changes.

## 21. Scanner/Portfolio handoff contract

Scanner creates saved `CollectibleItem` records with primary image, gallery images, enhancement metadata, quality metadata, and analyzer fields. Portfolio opens those records unchanged. Detail must not collapse scanner-provided gallery data, alter item identity, or rewrite scanner handoff data.

## 22. Loading-state contract

Detail itself has no independent route-level loading contract. It observes provider-backed sections that may load independently:

- Portfolio controller can be loading while item data exists.
- Wishlist status uses `AsyncValue`.
- Price alerts use `AsyncValue`.

Sprint 07 must not add fake route loading or artificial delay.

## 23. Error-state contract

Existing user-safe errors are limited. Portfolio update/delete failures set `PortfolioState.errorMessage`, but Detail currently only shows snackbars for successful actions and local guards. Wishlist and price-alert sections provide fallback/error messages. Sprint 07 may surface existing safe errors if useful, but must not expose raw technical exceptions.

## 24. Partial-data contract

Partial data includes missing image, one legacy image, missing valuation, zero valuation, missing pricing, missing market summary, missing optional metadata, absent AI review, empty notes, local-only sync, pending/failed sync, and incomplete gallery metadata. Partial data should remain visible and honest, not treated as a fatal route error.

## 25. Missing-image contract

Missing image or unsupported sample path currently renders a category/role placeholder. Metadata and actions remain visible. Sprint 07 must preserve that behaviour and must not hide the item because its image cannot render.

## 26. Guest/local contract

Guest and signed-out users retain local Detail access. SharedPreferences persistence works without auth/cloud. Cloud sync failures must not block local notes, metadata, primary image, gallery image, wishlist, alert, or delete presentation unless the existing controller reports failure.

## 27. Current visual hierarchy

Current hierarchy:

1. Material AppBar with `Collectible Details`, Back, and Edit.
2. Large framed image hero containing image, thumbnail filmstrip, category/confidence/rarity chips, title, confidence meter, and value card.
3. Low-confidence banner when confidence is below 70%.
4. AI Summary, currently generated from fields.
5. Key Attributes, notes, actions, wishlist status, detail sections, price alerts, similar collectibles, and price history.

Risks: image and title compete with decorative cards; confidence and derived rarity are overemphasized; fake AI summary and fake price history violate product honesty; actions are split; sections are numerous and card-heavy.

## 28. Current performance risks

Risks observed in source:

- single 3500-line Detail file with many nested widgets;
- large hero and thumbnail images can decode full local images;
- hero, thumbnail, value, badge, and metadata animations run even for simple state changes;
- full-screen review keeps a `PageView` plus zoomable full-size images;
- broad `portfolioControllerProvider` watch rebuilds the whole Detail route;
- `TextEditingController` state for notes updates during rebuilds;
- market/price-history formatting occurs in build;
- price-history section fabricates multiple bars from current value;
- numerous shadow/gradient cards.

## 29. Proposed information hierarchy

Target hierarchy:

1. approved Header or compact top record identity;
2. image hero/gallery with primary state and image count;
3. title/category and concise valuation state;
4. primary actions that genuinely work;
5. thumbnail strip and gallery controls;
6. stored AI review or honest absent state;
7. metadata groups;
8. notes and wishlist/status;
9. share/delete/secondary actions;
10. optional price alerts and sync status where genuinely supported.

Every section must earn its position by helping identify, inspect, value, or safely manage the saved item.

## 30. Product Language composition

A. Existing approved Product Language components:

- `PackLoxHeader` v1.0.1 for the top record context if it fits the route.
- `PackLoxButton` v1.0.0 for clear primary actions.

B. Composition of approved foundation primitives:

- Detail scaffold;
- image hero/gallery;
- thumbnail strip;
- valuation state;
- metadata groups;
- AI review state;
- notes editor;
- action groups;
- missing/partial-data states;
- dialogs and sheets using Material plus approved tokens.

C. Candidate treatments requiring Design Studio review:

- image hero/gallery;
- thumbnail strip;
- valuation status card;
- metadata group;
- AI summary/review card;
- notes editor;
- destructive action panel;
- full-screen gallery review.

No C candidate is promoted by Sprint 07.

## 31. First-viewport strategy

The first viewport should normally contain the item image, title, category, primary image state, image count, valuation availability, and genuinely supported primary actions. Avoid an oversized decorative hero that pushes item identity or valuation below the fold.

## 32. Header strategy

Use the approved Header only if it clarifies the Detail context without becoming a marketing hero. The route must preserve normal back navigation. The header should not replace item identity; the item title remains the primary record signal.

## 33. Image hero/gallery strategy

The image hero should prioritize inspecting the collectible. It should show the selected image, primary badge where true, enhancement badge where supported, and a clear affordance for full-screen review. It must not retain duplicate full-resolution layers unnecessarily.

## 34. Thumbnail strategy

Thumbnails should remain usable on narrow phones, announce position/primary state, and update the active image without mutating item data. Selection must not rely on color alone.

## 35. Valuation strategy

Valuation presentation should label values as estimated or unavailable according to stored fields. It should avoid fake trend/gain/loss and should separate market evidence from stored value. Pricing ranges and confidence should appear only when `PricingInfo` or `MarketSummary` supports them.

## 36. Metadata strategy

Metadata should render only present fields, grouped by identification, condition/edition, and system/sync where genuinely useful. Missing metadata should not be fabricated or hidden in misleading defaults.

## 37. AI-summary strategy

Use stored `primaryMatch`, `confidenceExplanation`, `detectionQuality`, `aiReasoning`, and `alternativeMatches`. If none exist, render an honest absent AI review state. Do not synthesize narrative summary text.

## 38. Notes/actions strategy

Notes remain local portfolio data and save through `PortfolioController.updateItem()`. Actions must be grouped by intent: edit/notes/wishlist, gallery actions, share placeholder, and destructive delete. Delete remains clearly destructive and confirmed.

## 39. Empty/missing state strategy

Missing image, missing valuation, missing metadata, absent AI review, empty notes, and sync failure are not route errors by default. They should be labelled honestly and allow the rest of the record to remain usable.

## 40. Responsive rules

Validate narrow Android phone, typical phone, large phone, portrait, large text, gesture navigation, three-button navigation, shell content bounds, and landscape only if current support is no worse than before. Image hero, thumbnails, value labels, titles, metadata, and action buttons must not clip or overlap.

## 41. Accessibility rules

Images should announce position, role, and primary state. Full-screen review controls require labels. Unavailable value must be announced clearly. Favorite/wishlist state must not rely on color. Delete must be clearly destructive. Reading order should follow image, identity, value, actions, AI review, metadata, notes, and secondary management.

## 42. Motion/reduced-motion rules

Motion may clarify image selection and route state but must not be continuous or required. Reduced motion must shorten or remove nonessential reveal/parallax/ticker animation. No artificial loading delay may be added.

## 43. Performance budget

Prefer bounded image surfaces, lazy thumbnail construction where practical, small widget boundaries, const widgets, cached derived lists/labels where simple, no continuous decorative animation, no direct repository calls from widgets, and no retained Detail subtree outside the active route.

## 44. Allowed files

Allowed for specification commit:

- `qa/reconstruction/sprint_07_detail_specification.md`

Potentially allowed after spec commit:

- `lib/features/portfolio/presentation/pages/collectible_detail_page.dart`
- `lib/core/ui/item_details/item_details_ui.dart` if used only for Detail presentation cleanup
- `test/widget_test.dart` focused Detail expectations
- `test/cloud_sync_status_widget_test.dart` focused Detail sync presentation expectations
- `test/scanner_widgets_test.dart` only if existing Detail gallery expectations must follow the reconstructed Detail surface
- runtime evidence under `qa/screenshots/reconstruction/sprint_07_detail/`
- `qa/reconstruction/sprint_07_runtime_comparison.md`

## 45. Prohibited files

Prohibited unless separately approved:

- backend, analyzer, Supabase, cloud config, schema/migrations, native config, signing, environment files, secrets;
- Portfolio domain/repository/service/controller business-rule rewrites;
- `lib/shared/domain/entities/collectible_item.dart`;
- `lib/shared/domain/collectible_sorting.dart`;
- Scanner, Settings, Authentication, App Shell lifecycle/navigation, Home, Onboarding, Bootstrap, and router framework changes;
- original dirty worktree `C:\Users\hario\Desktop\projects\collectiq_ai`.

## 46. Test plan

Run:

- `flutter analyze`
- Sprint 01 bootstrap tests
- Sprint 02 onboarding tests
- Sprint 03 App Shell tests
- Sprint 04 Home tests
- focused Sprint 05 Scanner suite
- focused Sprint 06 Portfolio tests
- focused Detail tests
- full suite, compared with Sprint 06 frozen baseline: 534 passed, 16 failed

Focused Detail coverage should include open from Portfolio/Home, Header/top composition, primary image, gallery thumbnails, selected image, full-screen review, image count, fallback order, missing image, title/category, unavailable valuation, genuine zero value, stored AI review, absent AI review, metadata only when present, notes save, wishlist/favorite honesty, share placeholder, delete confirmation, delete success/failure, guest/local mode, light/dark, large text, narrow viewport, reduced motion, rapid action taps, and no auth gate/router migration.

## 47. Runtime evidence plan

Device: Samsung SM E625F, Android 13 / API 33, device id `RZ8R213M8ZL`.

Evidence directory:

- `qa/screenshots/reconstruction/sprint_07_detail/`

Runtime QA should cover Detail opened from Portfolio, primary image, multi-image gallery, thumbnail selection, full-screen review, image count, unavailable valuation, genuine zero valuation if safely reproducible, metadata groups, stored AI review, absent AI review, notes, wishlist/favorite state, share placeholder or supported share state, delete confirmation, safe delete success/failure where reproducible, return to Portfolio, scanner-added multi-image item, app restart persistence, Home to Portfolio to Detail, Scanner to Portfolio to Detail, no overflow, no blank frame, no route lock, no input lock, no ANR, and no frozen sprint regression.

Create `qa/reconstruction/sprint_07_runtime_comparison.md` after runtime validation. Do not fabricate unavailable states.

## 48. Rollback boundary

Rollback is limited to Sprint 07 specification, Detail presentation files, focused Detail tests, Sprint 07 runtime comparison, Sprint 07 runtime evidence, and later Sprint 07 freeze governance.

Rollback must not require data migration, backend rollback, Supabase rollback, analyzer rollback, scanner rollback, Portfolio rollback, auth rollback, router rollback, App Shell rollback, Home rollback, or frozen Sprint 01-06 rollback.

## 49. Explicit non-goals

- no Detail business-logic rewrite;
- no Portfolio reconstruction;
- no Scanner reconstruction;
- no Settings reconstruction;
- no App Shell redesign;
- no Home redesign;
- no auth redesign;
- no auth guard;
- no router migration;
- no backend/Supabase contract change;
- no fabricated valuation/confidence/AI data;
- no artificial loading delay;
- no speculative price-history feature;
- no unsupported image-editing feature;
- no Capture System promotion;
- no push;
- no merge;
- no Sprint 08 work.

## Detail file inventory

| Path | Responsibility | Classification | Runtime usage | Current/legacy status | Duplication | State owner | Tests | Safe to modify |
|---|---|---|---|---|---|---|---|---|
| `lib/features/portfolio/presentation/pages/collectible_detail_page.dart` | Canonical Detail route, image hero, gallery review, edit dialog, notes, wishlist, price alerts, metadata, delete | presentation with action coordination | pushed from Portfolio/Home | canonical but overgrown | contains many internal duplicate card/action treatments | route-local + providers | broad widget, scanner widget, cloud sync status | yes, Detail-only |
| `lib/core/ui/item_details/item_details_ui.dart` | Legacy/candidate item-detail hero/action/metadata widgets | shared presentation candidate | not currently imported by canonical Detail | legacy/candidate | overlaps Detail hero/action/value treatments | caller-owned | indirect or none | yes only if retained/reused safely |
| `lib/features/portfolio/presentation/portfolio_screen.dart` | Opens Detail and supplies delete callback | frozen Portfolio presentation | Portfolio grid item tap/menu | current frozen Sprint 06 | no Detail duplicate | Portfolio screen + controller | Portfolio tests | no except proven Detail handoff defect |
| `lib/features/home/presentation/pages/home_page.dart` | Opens existing Detail from recent items | frozen Home presentation | Home recent item tap | current frozen Sprint 04 | no Detail duplicate | Home + Portfolio provider | Home tests | no |
| `lib/features/portfolio/presentation/controllers/portfolio_controller.dart` | Portfolio state/update/delete/cloud sync owner | controller/business | canonical item update/delete owner | current | none | `portfolioControllerProvider` | broad/domain tests | no except proven integration defect |
| `lib/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart` | Local persistence at `portfolio_items` | data/business | canonical persistence | current | none | repository | domain/widget tests | no |
| `lib/features/portfolio/presentation/widgets/portfolio_local_image*.dart` | Local image rendering abstraction | shared Portfolio/Detail presentation | Detail and Portfolio thumbnails | current | no | path input | widget tests | yes only for image presentation bug |
| `lib/shared/domain/entities/collectible_item.dart` | Item/gallery/valuation/sync serialization | domain | canonical data contract | current | none | immutable entity | domain/widget tests | no |
| `lib/features/wishlist/**` | Wishlist status persistence/providers | feature business/presentation | Detail wishlist status section | current | separate from local Favorite toggle | wishlist repository/provider | widget/domain tests | no |
| `lib/features/price_alerts/**` | Local price alert persistence/providers | feature business/presentation | Detail price alerts | current | separate from fake price history | price alert repository/provider | price alert tests | no |

No obsolete Detail presentation file is proven unreachable enough to delete in the specification step.

## Data and valuation audit

| User-facing value | Source field/provider | Calculation owner | Units/currency | Null behaviour | Zero behaviour | Unavailable/partial behaviour | Guest behaviour | Status | Rename safety |
|---|---|---|---|---|---|---|---|---|---|
| Title | `CollectibleItem.title` | scanner/user edit/domain | text | required by JSON | displayed as text | must not fabricate | local | real | label safe |
| Category | `CollectibleItem.category` | scanner/user edit/domain | text | required by JSON | n/a | fallback only as unknown label | local | real | label safe |
| Estimated value | `estimatedValue`, `valuationStatus`, `pricing` | analyzer/save/edit | currency | no null | current helpers treat `<=0` unavailable | must distinguish unavailable from genuine zero where possible | local | real/derived | label must say estimated |
| Market wording | `pricing`, `marketSummary`, `valuationStatus` | analyzer/backend/edit | currency and dates | omit when absent | zero should not become market proof | unavailable when no market match | local/cloud optional | real if stored | safe with honesty |
| Confidence | `confidence`, market/pricing confidence fields | analyzer/backend | percent | required by JSON | 0% possible | show only as analyzer confidence, not readiness | local | real analyzer field | label safe |
| Condition | `condition` | scanner/user edit | text | required but may be empty | n/a | omit/unknown if empty | local | real | safe |
| Year | `year` | analyzer/user edit | text/year | omit if null | n/a | missing not fabricated | local | real when stored | safe |
| Brand/model/series | `brand`, `series`, related fields | analyzer/user edit | text | omit if null | n/a | missing not fabricated | local | real when stored | safe |
| Edition/serial/card number | `edition`, `cardNumber`, related fields | analyzer/user edit | text | omit if null | n/a | missing not fabricated | local | real when stored | safe |
| Notes | `notes` | user edit via Portfolio controller | text | empty editor | n/a | empty notes are not error | local | real | label safe |
| AI review | `primaryMatch`, `confidenceExplanation`, `detectionQuality`, `aiReasoning`, `alternativeMatches` | analyzer/backend | text/percent | honest absent state | n/a | no generated replacement | local | real when stored | label safe |
| Created/saved date | `createdAt`/`savedAt` JSON mapping | repository/domain | date | required/fallback in entity parser | n/a | show only if useful | local | real | label safe |
| Image count | `effectiveGalleryImages.length` | entity/presentation | count | zero possible | zero means no renderable image | legacy one-image fallback counts as one | local | derived real | safe |
| Primary image | `imagePath`, `CollectibleImage.isPrimary` | scanner/detail update | path/bool | empty path allowed | n/a | placeholder when not renderable | local/cloud optional | real | no |
| Favorite | `_isFavorited` route-local | Detail widget state | bool | false initial | false | not persisted | local only | ephemeral | must not imply persistence |
| Wishlist | `wishlistStatusForItemProvider` | wishlist repository | enum | fallback/error currently Owned selector | n/a | async errors are local | local | real when saved | label safe |
| Sync metadata | `syncStatus`, `lastSyncedAt`, `syncError` | cloud sync/entity | enum/date/text | localOnly default | n/a | show as degraded only when stored | guest sees localOnly | real | safe with caution |
| Price alerts | price alert providers | price alert repository | local alert rules | empty list message | n/a | push unavailable copy is honest | local | real local feature | label safe |
| Price history | `_pricesFor(item)` | current Detail presentation | fabricated months/value | n/a | clamps to at least 1 | unsupported speculative feature | local | placeholder/fabricated | must remove or replace |
