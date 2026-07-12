# Sprint 04 Home presentation specification

Status: implementation approved by task; specification precedes Dart changes.

Branch baseline: `7a288f23b2681369d62e2c68830fb1789ba9f9de`

## 1. Current Home architecture

`AppShell` builds `HomeScreen`, a compatibility subclass of `HomePage`, only while Home is the active shell destination. `HomePage` watches `portfolioControllerProvider`, reads its synchronously available `orderedItems`, calls the existing `CollectorDashboardAnalyticsService.build`, derives presentation-only `_HomeViewData`, and renders a `CustomScrollView` with a `PageStorageKey`. The shell owns destination selection; Home owns neither routing state nor persistence.

## 2. Data-source inventory

| Data | Owner/source | Contract |
|---|---|---|
| Ordered collectibles | `portfolioControllerProvider.orderedItems` | Real locally persisted portfolio entities; controller owns ordering and refresh |
| Dashboard analytics | `CollectorDashboardAnalyticsService.build(items)` | Existing domain calculation; unchanged |
| Category distribution | `CollectorDashboardAnalytics.categoryDistribution` | Existing derived domain result |
| Most recent item | `CollectorDashboardAnalytics.mostRecentItem` | Existing derived domain result |
| Detail data | `CollectibleItem` | Passed unchanged to existing `CollectibleDetailPage` |

No Home-specific backend request, stream, `AsyncValue`, offline flag, stale-data flag, or refresh error is exposed by the current Home contract.

## 3. Metric-definition inventory

| Label/value | Source/calculation | Units/currency | Null/zero and state behaviour | Nature | Rename allowance |
|---|---|---|---|---|---|
| Collection value | Sum of items whose positive value or valuation status makes the value displayable | Existing app display is whole-dollar `$`; effectively AUD-oriented but no currency field is available at aggregate level | No items: empty; items but none valued: `Value unavailable`; never turn unavailable into `$0` | Derived from real portfolio data | May clarify as estimated value only |
| Collectible count | `items.length` | Count | Zero means genuinely empty collection | Real count | Grammar may change without changing meaning |
| Category count | Count of positive category-distribution buckets | Count | Omitted when zero | Derived | May clarify wording only |
| Last scan | `mostRecentItem.createdAt`, relatively formatted | Relative time | Omitted when absent | Derived | May clarify wording only |
| Top collectible | Highest displayable `estimatedValue`; otherwise latest item | Item/value | Unvalued fallback is labelled latest and value unavailable | Derived selection of real item | Labels may distinguish top from latest |
| Recent collectibles | Existing ordered items, first four | Item rows | Hidden when empty | Real/cached local data | Section label may be clarified |
| Needs valuation | Item count minus display-valued item count | Count | Hidden at zero | Derived | Wording may change without implying a valuation exists |

No gain/loss, trend, confidence aggregate, cloud health, portfolio-history chart, or service status is authorized for display in Sprint 04.

## 4. Existing user actions

| Action | Existing callback/destination | Status and guest access |
|---|---|---|
| Scan a collectible | `onScanPressed` -> shell Scan destination | Functional; guest/local access preserved |
| Import photo | `onImportPhotoPressed`, falling back to `onScanPressed` | Functional existing scan entry; no Scanner reconstruction |
| Open portfolio / View all | `onPortfolioPressed` -> shell Portfolio destination | Functional; guest/local access preserved |
| Open collectible | Existing `Navigator.push` to `CollectibleDetailPage(item)` | Functional existing detail route |

Disabled callbacks remain visibly disabled and are not represented as successful actions.

## 5. Existing navigation contracts

Home does not own shell selection. It invokes the callbacks supplied by `AppShell`; collectible detail continues to use the existing `MaterialPageRoute`. No named router, auth guard, Search, Notifications, or new route is introduced.

## 6. Existing state model

Portfolio state is synchronously available from its controller. Supported states are: populated, genuinely empty, partially valued, and guest/local. A transient controller initialization state may contain no items and therefore follows the existing empty contract. There is no honest Home-specific loading, recoverable-error, unrecoverable-error, offline, degraded, stale, or refresh-in-progress signal to present. Sprint 04 must not manufacture any of those states.

## 7. Current visual hierarchy

The current order is bespoke greeting/hero, a large custom Scan surface, two custom secondary action cards, collection snapshot, recent collectibles, and a valuation insight. It duplicates Product Language responsibilities and places branding/greeting inside a custom hero rather than composing approved Header and Hero.

## 8. Current performance risks

The current Home uses `MotionElasticHero`, `MotionParallax`, repeated `MotionReveal`, gradients, shadows, broad rebuild from the portfolio watch, and a non-lazy sequence of sliver box adapters. It recalculates domain analytics on each portfolio-driven build. The data set displayed is bounded, but parallax/elastic overscroll and multiple reveal animations add scroll-time work without being required for comprehension.

## 9. Proposed information hierarchy

1. Approved Header: location/orientation and honest disabled Notifications affordance.
2. Approved Hero: collection summary and the single primary Scan action.
3. Compact quick actions: import and portfolio using approved Entry Tiles.
4. Collection snapshot: estimated value, counts, and top/latest item.
5. Recent collectibles: at most four real items.
6. Grounded valuation note only when unvalued items exist.

The first viewport contains Header, Hero, and the primary action inside Hero; it avoids competing primary cards.

## 10. Product Language composition

- Header: `PackLoxHeader` v1.0.1 (A: approved component).
- Hero: `PackLoxHero` v1.0.1, standard/empty-state composition (A).
- Quick actions: `PackLoxEntryTile` v1.0.0 (A).
- Primary action: approved `PackLoxButton` contained by `PackLoxHero` (A).
- Snapshot, recent rows, section surfaces, metric chips, and valuation note: B, composition of `PackLoxTokens`, `AppSpacing`, `AppRadius`, `AppElevation`, typography, Semantics, and existing thumbnail primitives. They are not promoted into Product Language.

No C candidate is required for this sprint.

## 11. First-viewport strategy

Header and Hero establish context, show a truthful summary, and expose one Scan action. Quick actions follow below. No extra greeting card, duplicate total, carousel, chart, or technical status appears.

## 12. Header strategy

Use approved `PackLoxHeader` with fallback identity `Collector`. No profile source exists in Home, so no name is fabricated. Notifications remain disabled because no route/callback exists; this is honest rather than adding a dead destination.

## 13. Hero strategy

Use approved `PackLoxHero`. Populated state shows item-count context and estimated aggregate only when at least one value is displayable. Empty state invites the first scan. The Hero primary action is the existing Scan callback. No parallax, elastic overscroll, continuous animation, or artificial delay remains.

## 14. Metrics strategy

Show only aggregate estimated value, item count, category count when non-zero, relative last scan when present, and the top/latest real collectible. Unavailable value remains unavailable; zero is not substituted for null/unavailable.

## 15. Quick-actions strategy

Use two approved Entry Tiles: Import photo and Open portfolio. Both preserve existing callbacks. Layout stacks naturally and remains readable at large text/narrow widths.

## 16. Insights strategy

Only the grounded fact that some saved items lack a display valuation is shown. No generated recommendation, trend, or forecast is added.

## 17. Recent-content strategy

Show up to four controller-ordered real collectibles, with existing detail navigation and optional View all callback. No horizontal carousel.

## 18. Loading-state strategy

No loading state is implemented because Home exposes no loading signal. No skeleton or timer is authorized.

## 19. Empty-state strategy

An empty portfolio is informational, not an error. Hero and collection section both provide truthful first-scan context using the same existing callback; no fabricated metrics appear.

## 20. Partial-data strategy

Valid item/count/category/recent data remains visible when some or all valuations are unavailable. Aggregate value is omitted when none are displayable, and individual unavailable values are labelled honestly.

## 21. Error-state strategy

No Home-specific error or retry contract exists. Sprint 04 does not fabricate an error panel or call an invented retry method. Existing portfolio/controller failures remain governed by their existing owner.

## 22. Offline/degraded-state strategy

No reliable offline/degraded/stale signal is exposed to Home. Local/guest behaviour remains the normal supported experience and is not labelled as an error.

## 23. Responsive rules

Use one vertical scroll view, shell-provided bounds, 16px narrow padding and 24px normal padding, maximum 960px content width, wrapping metrics, no fixed text-bearing heights, and vertically stacked Entry Tiles. Avoid double bottom safe-area ownership; retain Home's top safe-area protection while AppShell owns bottom navigation inset.

## 24. Accessibility rules

Maintain logical reading order; use semantic section headings; approved components provide button/selected semantics; each metric exposes label and value; decorative icons/thumbnails do not duplicate meaningful labels; touch targets meet component contracts; content supports text scaling without clipped values; unavailable and empty states are announced plainly.

## 25. Motion and reduced-motion rules

Remove custom elastic/parallax and staggered reveals. Approved component interaction motion may remain, governed by Product Language motion. State and navigation never depend on animation, so reduced motion is immediately usable.

## 26. Performance budget

- No active Home subtree off-tab (frozen shell rule).
- No `BackdropFilter`, blur, custom painter, chart, image predecode, continuous ticker, or Home animation controller.
- At most four recent rows and one top preview.
- One portfolio provider watch and one existing analytics-service build per portfolio state change.
- No calculations added to scrolling callbacks or widget animations.
- Device stress must show no app-attributable ANR, input timeout, or fatal exception.

## 27. Allowed files

- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/home/presentation/home_screen.dart` only if compatibility requires it
- Home-focused presentation helpers only if necessary
- `test/home_presentation_reconstruction_test.dart`
- existing Home presentation tests only for legitimate presentation expectations
- Sprint 04 QA specification, runtime comparison, and evidence

## 28. Prohibited files

Domain/data/controller/repository/service files; backend; analyzer; authentication; startup; onboarding; AppShell lifecycle/navigation; Scanner, Portfolio, Settings content; routing framework; Supabase contracts; native configuration; secrets; environment files; and the original dirty worktree.

## 29. Test plan

Verify approved Header/Hero/Entry Tile use; loaded, empty, and partially valued data integrity; no fabricated zero; real actions and detail navigation; disabled actions; guest/no-auth behaviour; light/dark, narrow/large-text, and reduced-motion compatibility; rapid action safety; tab recreation contract; frozen Sprint 01-03 suites; analyzer; full-suite baseline.

Loading/error/retry tests are explicitly inapplicable because no such controller state or safe retry contract exists. This absence is asserted in source/structure tests rather than simulated.

## 30. Runtime evidence plan

On the available Samsung Android device, capture populated or honest empty Home, hierarchy XML, Scan and Portfolio action handoffs, tab-away/back, scroll and tab-switch stress, and logcat. Capture only modes/states genuinely reproducible without contract changes. Store under `qa/screenshots/reconstruction/sprint_04_home/` and document observed versus widget-tested versus unverified evidence.

## 31. Rollback boundary

Rollback is limited to Home presentation composition, focused Home tests, this specification, Sprint 04 runtime comparison, and evidence. It requires no data migration, controller rollback, backend rollback, routing rollback, or frozen-sprint rollback.

## 32. Explicit non-goals

- no Home business-logic rewrite
- no metric-definition change
- no fabricated data
- no Scanner, Portfolio, Settings, App Shell, onboarding, or bootstrap reconstruction
- no authentication redesign or auth guard
- no router migration
- no backend change
- no artificial loading delay
- no speculative Home feature, chart, trend, Search, Notification, or cloud-health display

