# Phase 3 Detail Test Regression Analysis

Date: 2026-07-14
Branch: `rebuild/product-language-v1`
Starting HEAD: `3a90d00f76345daa456d4e4af1a9a632500c559e`
Final validation HEAD before this document commit: `3a90d00f76345daa456d4e4af1a9a632500c559e`

## State Verification

- `git branch --show-current`: `rebuild/product-language-v1`.
- Current HEAD at verification: `3a90d00f76345daa456d4e4af1a9a632500c559e` (`docs: amend detail visual freeze`).
- Expected Phase 3 commits are present: `5b90b77`, `b0b7157`, `183006f`, `56ddc5a`, `38d662b`, `3a90d00`.
- `git status --short` was clean before capturing regression artifacts.
- `git diff --check` was clean.
- No push, merge, or Phase 4 Scanner alignment was performed.
- Work was confined to `collectiq_ai_reconstruction`; the original `collectiq_ai` worktree was not modified.

## Full-Suite Regression Finding

The blocker described an observed Phase 3 result of `565 passed, 17 failed`. That result is not reproduced at the current HEAD.

Runs performed in this remediation pass:

- `flutter test --reporter=expanded`: `567 passed, 15 failed`.
- `flutter test --reporter=json`: 15 failing tests identified from complete JSON events.
- Final `flutter test --reporter=compact`: `567 passed, 15 failed`.

The accepted Phase 2 ceiling was `562 passed, 16 failed`. Current Phase 3 is therefore non-regressive against that ceiling and improves the failure count by one while adding Detail coverage.

## Current Failure Inventory

| # | Test file | Test name | Failure summary | Stack location | Classification |
|---|---|---|---|---|---|
| 1 | `test/analyzer_service_test.dart` | `MockAnalyzerProvider consumes the backend analyzer contract when configured` | Expected selected provider `gemini`; actual `null`. | `test/analyzer_service_test.dart:289` | unrelated deterministic baseline failure |
| 2 | `test/domain_unit_test.dart` | `DioAiBackendApiService FastAPI detail error preserves analyzer error code` | Expected backend detail message `Real AI analysis requires uploaded image bytes.`; actual safe generic backend message. | `test/domain_unit_test.dart:1874` | unrelated deterministic baseline failure |
| 3 | `test/domain_unit_test.dart` | `Supabase foundation SIT scripts pass required dart defines without hardcoded secrets` | Expected `--dart-define=AI_ANALYSIS_PROVIDER=%AI_ANALYSIS_PROVIDER%`; script currently hardcodes `mock`. | `test/domain_unit_test.dart:2361` | environment/configuration dependency |
| 4 | `test/widget_test.dart` | `scan capture flashes and shows next capture suggestion` | Expected `One more photo recommended`; none found. | `test/widget_test.dart:1501` | outdated legacy contract |
| 5 | `test/widget_test.dart` | `workspace capture next opens camera for the back photo` | Timed out waiting for `Review your photos`. | `test/widget_test.dart:1630` | outdated legacy contract |
| 6 | `test/widget_test.dart` | `capture review acceptance returns to updated workspace` | Could not reveal key `workspace-capture-next`. | `test/widget_test.dart:1657` | outdated legacy contract |
| 7 | `test/widget_test.dart` | `full workspace scan review analyze loop uses updated photo list` | Could not reveal key `workspace-capture-next`. | `test/widget_test.dart:1696` | outdated legacy contract |
| 8 | `test/widget_test.dart` | `camera denied UI shows friendly message` | Expected `Try again`; none found. | `test/widget_test.dart:1876` | outdated legacy contract |
| 9 | `test/widget_test.dart` | `gallery import confirms enhancement before adding photo` | Expected `Enhanced` inside `enhancement-preview-surface`; none found. | `test/widget_test.dart:2210` | outdated legacy contract |
| 10 | `test/widget_test.dart` | `gallery import follows review workspace analyze result portfolio flow` | Timed out waiting for `Review your photos`. | `test/widget_test.dart:2335` | outdated legacy contract |
| 11 | `test/widget_test.dart` | `enhancement preview shows only Original and Enhanced` | Timed out waiting for `Enhanced`. | `test/widget_test.dart:2428` | outdated legacy contract |
| 12 | `test/widget_test.dart` | `enhancement preview can switch Enhanced back to Original` | Timed out waiting for `Enhanced`. | `test/widget_test.dart:2475` | outdated legacy contract |
| 13 | `test/widget_test.dart` | `saving enhanced scan preserves portfolio gallery metadata` | Expected `Enhanced`; none found. | `test/widget_test.dart:2572` | outdated legacy contract |
| 14 | `test/widget_test.dart` | `scan preview remains mounted during analyze` | Expected no `Gallery image`; one `Gallery image` label remained mounted. | `test/widget_test.dart:2916` | outdated legacy contract |
| 15 | `test/widget_test.dart` | `premium result shows Enhanced badge when photo is enhanced` | Expected `Enhanced`; none found. | `test/widget_test.dart:3080` | outdated legacy contract |

## Newly Failing Test

None at the current HEAD.

Required fields:

- Test file: not applicable.
- Exact test name: not applicable.
- Assertion/failure message: not applicable.
- Stack location: not applicable.
- Passes individually: not applicable because no new failing test exists.
- Fails in containing file: not applicable because no new failing test exists.
- Fails only in full suite: not applicable because no new failing test exists.
- Classification: `unrelated deterministic baseline failure` for analyzer/backend failures, `environment/configuration dependency` for the SIT script assertion, and `outdated legacy contract` for scanner/enhancement widget expectations.

The Detail-adjacent failure named in earlier baseline records, `portfolio carousel edit updates image enhancement metadata`, now passes both inside the targeted Detail widget group and in the full suite. This accounts for the current failure count dropping below the accepted Phase 2 ceiling rather than increasing above it.

## Phase 3 Test Migration Review

| Area | Old assertion | New assertion | Authority reason | Behaviour protected | Weakened? | Matcher note |
|---|---|---|---|---|---|---|
| Focused Detail tests | No focused Phase 3 Detail file existed. | `test/detail_screen_test.dart` asserts authority header, overview, tabs, gallery switching, unavailable vs saved-zero valuation, metadata, stored AI evidence, notes, and delete action. | Approved Detail authority is compact and sectioned rather than a single legacy long page. | Item identity, gallery ordering, active preview, valuation semantics, metadata, AI evidence, notes, and delete flow. | No. Coverage was added. | Uses stable `ValueKey`s and state/text assertions. |
| Broad navigation | `Collectible Details` copy. | `collectible-detail-authority-header` key. | Legacy page title was removed by approved compact Detail header. | Route opens the real Detail page and return navigation still works. | No. | Key is more stable than copy. |
| Detail information surface | `AI Analysis`, `Raw Diagnostics`, `Primary Metadata`, `Market Evidence`, `Market Summary`. | Section tabs: `insights`, `notes`, `details`, `market`, with specific saved evidence assertions. | Approved authority separates Detail content into tabs and forbids fabricated diagnostics/price history. | Stored AI evidence, sync status, metadata, valuation range, recommendation, and no fabricated dates. | No. | Tab keys plus content assertions avoid brittle legacy copy. |
| Rarity/presentation | Gradient rarity badge shell/fill expectations. | Stored rarity text and compact AI-enhanced badge where saved. | Authority no longer requires legacy badge treatment; stored rarity remains visible when present. | Stored item metadata remains protected. | Slightly less style-specific by design; no data weakening. | Widget/key assertions retained for meaningful surfaces. |
| Valuation | Legacy value-evidence section and price-history copy. | `Market & Value`, value range, confidence, trend, and explicit non-fabrication copy. | Approved authority preserves saved market evidence without inventing price history. | Unavailable and saved zero remain distinct; saved market data remains shown. | No. | Copy assertion is intentional contract text for non-fabrication. |
| Gallery | Legacy direct image/gallery assumptions. | Hero and thumbnail keys tied to saved image paths; full-screen review still opens; primary/delete persist. | Authority keeps primary-image ownership and gallery order. | Image order, active image, full-screen review, primary update, deletion, final-image guard. | No. | Path-derived keys are stable state assertions. |
| Edit/notes | Notes visible on long page. | Notes tab and `collectible-detail-notes-field`; edit persists local fields and image path. | Notes live in the approved Notes section. | Notes persistence and edit flow. | No. | Key-based field assertions. |
| Wishlist/favorite/actions | Legacy action placement. | Header/action tab keys for share, favorite, delete, price alerts. | Actions moved into compact authority surfaces. | Wishlist/favorite state, share feedback, delete confirmation, price alert creation. | No. | Action keys avoid copy-only brittleness. |
| Sync status | `Raw Diagnostics` expansion. | Notes tab status rows. | Raw diagnostics was removed from the approved authority; sync status remains in Notes/Status. | Synced, queued, failed labels and failure message. | No. | Stable tab key plus status text. |
| Home/Portfolio/App Shell handoffs | Legacy Detail title and diagnostics copy after navigation. | Authority header and relevant tab content. | Handoffs should prove route identity without restoring old Detail structure. | Home recent and Portfolio grid still navigate to Detail and return correctly. | No. | Key-based route identity. |

No migrated expectation weakens item identity, image ordering, gallery review, valuation semantics, notes persistence, wishlist/favorite, sync status, delete behaviour, or return navigation.

## Actual Detail Contract Trace

The current Detail production contract remains:

- Item identity: title/category/value metadata come from the saved `CollectibleItem`.
- Primary-image ownership: `imagePath` and normalized `galleryImages` drive the hero image.
- Gallery ordering: `effectiveGalleryImages` order is preserved; selected thumbnail changes the hero.
- Full-screen review: image preview opens carousel review; edit, primary, and delete image controls remain available.
- Unavailable valuation: `ValuationStatus.unavailable` renders unavailable/no-saved-valuation copy.
- Real saved zero valuation: saved market-estimated zero renders `$0` with saved market-data explanation.
- Metadata visibility: saved fields render under Details; absent metadata renders honest empty copy.
- Stored AI evidence: Insights shows only saved reasoning/evidence or explicit unavailable copy.
- Notes: notes field and save action persist local notes.
- Wishlist/favorite: status and favorite actions remain wired to existing providers/storage.
- Alerts: price alert creation remains reachable from Notes/Status.
- Edit/share/delete: header/actions tab preserve existing edit/share/delete flows.
- Sync status: Notes/Status renders queued/synced/failed states and failure message.
- Return to Portfolio: broad widget tests and frozen group confirm navigation return remains intact.

No fabricated AI, rarity, price-history, similar-item, or confidence UI was restored.

## Validation

Targeted validation:

- Newly failing test individually: none exists in current HEAD.
- Previously documented Detail-adjacent baseline case `portfolio carousel edit updates image enhancement metadata`: passed in targeted Detail widget group.
- Containing Detail widget group: 16 selected `test/widget_test.dart` Detail/navigation/gallery/edit/notes/action/responsive tests passed.
- Focused Detail visual tests plus sync-status tests: 6 passed.
- Home/Portfolio/Detail/App Shell visual group: 39 passed.
- Frozen Scanner group: `test/scanner_widgets_test.dart` 22 passed; `test/scanner_volume_03_structure_test.dart` 5 passed.
- `flutter analyze`: passed, no issues found.
- Final full suite: `567 passed, 15 failed`.

## Decision

Phase 3 regression approval is granted for the current HEAD because the full-suite failure count is below the accepted `562 passed, 16 failed` Phase 2 ceiling and no unexplained Detail-related failure remains.

Detail visual freeze may be treated as final for Phase 3. This does not make the full suite green; the remaining 15 failures are documented non-Detail baseline debt.
