# Portfolio Phase 2 Contract Clarifications

Date: 2026-07-14

Branch: `rebuild/product-language-v1`

Scope: Portfolio visual remediation only.

## Authority

Primary authority:

- `C:\Users\hario\Desktop\projects\packlox-design-platform\releases\v1.0\design_bible\Volume_06_Portfolio\images\portfolio_flow_master.png`

The approved Portfolio board controls supported Portfolio visual composition. It does not authorize changing App Shell architecture, backend contracts, routing, authentication, repositories, or Detail ownership.

## Clarifications And Dispositions

| Authority element | Current runtime contract | Phase 2 disposition |
| --- | --- | --- |
| Five-tab navigation with Search | Frozen App Shell has four tabs: Home, Portfolio, Scan, Settings. | `DEFERRED PRODUCT CONTRACT`. Do not add Search tab in Phase 2. |
| Combined Filter & Sort screen | Runtime has separate Sort and Filter modal sheets. | Preserve separate behaviour; align sheets to dark board surfaces as `ACCEPTABLE RESPONSIVE/BEHAVIOURAL ADAPTATION`. |
| Bulk Select | No Portfolio bulk selection controller or multi-select state exists. | `DEFERRED PRODUCT CONTRACT`. Do not fake checkmarks or bulk actions. |
| Collections | Runtime supports category filters, not user-created collection groups. | `DEFERRED PRODUCT CONTRACT`. Do not add collection management. |
| Share Collection | No share-link/channel/visibility contract exists. | `DEFERRED PRODUCT CONTRACT`. Do not add share UI. |
| Export / Backup | Export/backup is Settings/cloud scope, not Portfolio runtime scope. | `DEFERRED PRODUCT CONTRACT`. Do not add Portfolio export/backup controls. |
| Total value trend chart | Runtime has item values and market summaries, but no reliable portfolio time-series chart contract in Portfolio screen. | Show real total value and valued/unvalued counts; do not fabricate trend lines or gains. |
| Recent scans | Runtime Portfolio does not own scan history rows. | Defer; do not fabricate recent scans. |
| Top category | Runtime can derive real category count, but not an approved top-category analytics contract in Portfolio screen. | Show real category count only; top category deferred unless backed by existing analytics. |
| Favorite heart | Runtime has wishlist/favorite semantics mostly in Detail and wishlist status badges. | Preserve existing wishlist/favorite behaviour; do not introduce new favorite state from Portfolio card. |
| Gallery count badge | Runtime item model has gallery images. | Show badge only when count is backed by real primary/gallery/legacy image data. |
| Empty search visibility | Existing runtime hides search when no items exist. | Phase 2 may show search in empty Portfolio because it does not change search semantics; no-results still depends on existing filtering. |
| Missing-image item | Runtime image fallback order exists. | Preserve fallback order and show placeholder only when no real image path exists. |
| Unavailable versus zero valuation | Runtime item model has `valuationStatus` and `estimatedValue`. | Display unavailable labels for unavailable statuses unless a positive fallback exists; genuine zero remains `$0`. |

## Behaviour Preserved

- `portfolioControllerProvider` remains the Portfolio data owner.
- SharedPreferences/local repository ownership remains unchanged.
- Item identity, ordering, search, filter, sort, category, wishlist, valuation, image fallback, Detail navigation, scanner-to-portfolio handoff, and delete confirmation remain unchanged.
- No backend, Supabase, router, authentication, App Shell, Product Language definition, Home, Detail, Scanner, Settings, Search, or Notification implementation is changed by this clarification.

## Runtime Evidence Boundary

Physical before evidence captured the honest local device empty state. Populated runtime evidence may use only existing approved local/demo mechanisms when safely exposed by the app. Forced preference injection is not treated as user-real evidence.
