# PackLox Home Phase H0 Component Mapping

Date: 2026-07-16

Authority: Volume 02 Home Flow master board, SHA256 `EC3F05A833FA2B7BA25ED81531E09DA011D1882BF2805D0E512EBBA3AA866C4A`.

Design System: `packlox-design-platform` commit `5571512a99a925788a7fce0b3c4f4fd53fce7485`.

Phase H0 maps and builds shared presentation components only. It does not correct H02, add state branching, or change App Shell/Search.

| Authority component | Current equivalent | Classification | H0 action |
| --- | --- | --- | --- |
| Home App Bar | `PackLoxHeader` in `home_page.dart`; older `HomeDashboardAppBar` exists but is not active | refine existing | Wrap the active header in a Home-local `HomeAppBar` adapter using real greeting/profile fallback and no fake badge. |
| Welcome Hero | Onboarding owns first launch; older inactive `WelcomeSection` / `HomeHeroHeader` exist | prohibited in H0 | Document only. H01 state composition belongs to a later phase. |
| Empty Collection Hero | Private `_EmptyCollectionCard` family in `home_page.dart` | extract from Home | Keep current output and behavior; do not correct to master-board H02 in H0. |
| Section Header | Private `_SectionSurface` title row | extract from Home | Create `HomeSectionHeader` and reuse inside shared surfaces. |
| Collection Strip | Private `_SnapshotContent`, `_TopCollectiblePreview`, recent item preview logic | create new Home-local shared component | Build reusable `HomeCollectionStrip` for later populated states; do not integrate into current screen unless visually neutral. |
| Value Metric Card | Private snapshot value text and analytics fields | create new Home-local shared component | Build `HomeValueMetricCard` with unavailable and optional real trend support. |
| Quick Action Grid | Private `_CompactQuickActions`, `_CompactHomeAction` | extract from Home | Build callback-driven `HomeQuickActionGrid` / `HomeQuickActionTile`; current Home exposes only Scan, Import, Portfolio. |
| Category Tile | Private `_CategoryChip` | extract from Home | Build semantic `HomeCategoryTile` with Cards, Coins, Figures, More factories. |
| Category Grid | Private `_PopularCategoriesSection` wrap layout | extract from Home | Build responsive `HomeCategoryGrid`; preserve current visible labels. |
| Category Breakdown Bars | `CategoryAllocationVisual` in `portfolio_visual_analytics.dart` | blocked by missing data contract | Do not implement H0 production UI; H04/H09 need state-specific contract and authority comparison. |
| Recent Item Card | Private `_RecentCollectibleTile`; `PortfolioThumbnail` provides real/fallback image | extract from Home | Build reusable `HomeRecentItemCard` with real image path, title/category/value, and unavailable value semantics. |
| Collection Health Card | Analytics service has `CollectionHealthScore`; no board-aligned active Home card | blocked by missing data contract | Do not add. Requires product approval for when health is shown. |
| Skeleton Card | Bootstrap loading exists; no Home-specific skeleton | blocked by missing data contract | Do not add production Home skeleton in H0. |
| Offline State | No Home-specific offline trigger found | blocked by missing data contract | Do not add UI or fake offline state. |
| Syncing State | Cloud sync services exist; no Home-specific syncing contract | blocked by missing data contract | Do not add UI or fake progress. |
| Insights Card | Analytics/insight services and portfolio visual widgets exist | blocked by missing data contract | Do not add H09 state UI in H0. |
| No Valuation Card | Per-item valuation status and private missing-valuation card exist | blocked by missing data contract | Do not add whole-state H10 UI until trigger is defined. |
| Bottom Navigation dependency | `AppShell` and `GlassBottomNavBar` have four tabs, Search missing | prohibited in H0 | No App Shell change. Search dependency remains separate. |

## Boundary

Allowed H0 code changes are limited to reusable Home presentation widgets, neutral extraction from current Home, and focused component tests. Controllers, providers, repositories, router, backend, App Shell, Search, and Product Language definitions are out of scope.
