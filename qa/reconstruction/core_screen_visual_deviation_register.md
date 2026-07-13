# Core Screen Visual Deviation Register

Date: 2026-07-13
Branch: rebuild/product-language-v1
Starting HEAD: 1f58ea48fba0745405070298a41fd6c61be2d263
Scope: planning register only. No implementation decisions are made here.

This register consolidates the 49 recovered deviations from Home, Scanner, Portfolio, and Detail. Shared root causes are deduplicated in classification, but every source deviation remains present so remediation can close the original evidence records.

## Counts

| Count type | Total |
|---|---:|
| Source deviations | 49 |
| Shared-root deviations | 21 |
| Screen-specific deviations | 28 |
| Critical | 6 |
| High | 22 |
| Medium | 18 |
| Low | 3 |

## Shared Root Taxonomy

| Shared root | Description | Affected screens |
|---|---|---|
| SR-01 Screen composition authority gap | Product Language or sprint-written compositions were treated as whole-screen approval | Home, Scanner, Portfolio, Detail |
| SR-02 Dark surface/token mismatch | Runtime uses light/generic Material or over-raised surfaces inside approved dark boards | Home, Scanner, Portfolio, Detail |
| SR-03 First-viewport density drift | Approved compact mobile boards became tall card-heavy pages | Home, Scanner, Portfolio, Detail |
| SR-04 Header/navigation mismatch | Header copy/composition or bottom navigation differs from approved boards | Home, Portfolio, Detail, App Shell |
| SR-05 Shared sheet/dialog gap | Sort/filter/delete/gallery overlays exist without approved shared overlay authority | Portfolio, Detail |
| SR-06 Missing state evidence | Approved states were not reproduced in current runtime evidence | Home, Scanner, Portfolio, Detail |
| SR-07 Valuation semantics | Unavailable valuation and true zero value are not always visually distinct | Home, Portfolio, Detail |
| SR-08 Candidate component promotion risk | Candidate Capture/Portfolio/Detail compositions may be mistaken for approved Product Language | Scanner, Portfolio, Detail |

## Register

| Global ID | Screen | Source deviation ID | Severity | Type | Approved authority | Current Flutter area | Shared or screen-specific | Root cause | Required fix | Dependencies | Behavioural risk | Data-flow risk | Camera risk | Regression risk | Validation method | Proposed remediation phase |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| CVD-001 | Home | HVD-001 | Critical | Wrong composition | Volume_02_Home S02 | home_page empty hero | Shared SR-01/SR-02 | PL Hero used as empty-state authority | Replace S02 empty leading card with approved dark empty composition | Phase 0 surfaces | Medium scan callback placement | Low | None | Medium | Fresh empty screenshot/XML and order test | Phase 1 |
| CVD-002 | Home | HVD-002 | High | Missing state | Volume_02_Home S02 | home_page first viewport | Screen-specific | S02 secondary/category content not mapped | Add Try a Sample Scan and Popular Categories or record exclusion | Product clarification for sample action | Medium | Low | None | Medium | First-viewport comparison and action test | Phase 1 |
| CVD-003 | Home | HVD-003 | High | Wrong hierarchy | Volume_02_Home S03/action principles | large EntryTiles | Shared SR-03 | EntryTile approval treated as layout approval | Replace or move large action tiles with compact approved actions | Phase 0 spacing/actions | Low | Low | None | Low | XML visual order and screenshot | Phase 1 |
| CVD-004 | Home | HVD-004 | Medium | Wrong spacing | Volume_02_Home S02 | first viewport/nav fold | Shared SR-03 | Leading surfaces consume viewport | Reduce vertical weight and clear nav | Phase 0 safe area | Low | Low | None | Low | Bounds comparison | Phase 1 |
| CVD-005 | Home | HVD-005 | Low | Unsupported content | Volume_02_Home header | PackLoxHeader fallback | Shared SR-04 | Profile data unavailable | Keep fallback or wire profile-backed greeting | Profile decision | Low | Low | None | Low | Header fixture test | Phase 1 |
| CVD-006 | Home | HVD-006 | Medium | Missing state | Volume_02_Home notification | disabled notification button | Shared SR-04 | Notifications out of scope | Wire existing notification only if product-approved, otherwise document disabled state | Notifications/Search clarification | Medium | Low | None | Medium | XML enabled state and smoke test | Phase 0/1 |
| CVD-007 | Home | HVD-007 | Medium | Missing evidence | Volume_02_Home S03-S05 | populated Home | Shared SR-06 | No fresh populated fixture | Capture populated fixture and align states | Fixture strategy | Low | Medium | None | Low | Seeded populated screenshots/XML | Phase 1 |
| CVD-008 | Home | HVD-008 | Medium | Missing state | Volume_02_Home S06-S08 | Home async states | Product clarification | Local-first Home has no async state owner | Decide implement, adapt, or exclude loading/offline/sync | Product clarification | High | Medium | None | High | Architecture review plus state evidence | Phase 0/1 |
| CVD-009 | Home | HVD-009 | Medium | Navigation mismatch | Volume_02_Home bottom nav | App Shell four tabs | Shared SR-04 | Board has Search tab, shell froze four tabs | Hold until Search/App Shell decision | Product clarification | High | Medium | None | High | App Shell authority review | Phase 0 wait |
| CVD-010 | Home | HVD-010 | High | Missing state | Volume_02_Home S09/S10 | valuation note | Shared SR-07 | Insights/no-valuation variants not mapped | Add S09/S10 mappings or defer with authority | Valuation semantics | Medium | Medium | None | Medium | State fixture tests/screenshots | Phase 1 |
| CVD-011 | Scanner | SCN-001 | Critical | Missing state | Volume_03_Scanner S01-S10 | scanner non-hub states | Shared SR-01/SR-06 | S01 was treated as near-full proof | Complete S02-S10 mapping/remediation | Phase 0 candidate rules | Medium | Medium | Medium | Medium | Full Scanner state screenshots | Phase 4 |
| CVD-012 | Scanner | SCN-002 | High | Missing state | Volume_03_Scanner S02 | camera permission entry | Screen-specific | Permission gate blocked comparison | Capture camera-ready after permission and align S02 | Device/camera test plan | Low | Low | High | High | Camera-ready screenshot/XML/logcat | Phase 4 |
| CVD-013 | Scanner | SCN-003 | High | Wrong composition | Volume_03_Scanner S05-S07 | scan_workspace_screen | Shared SR-03 | Long Material workspace | Rebuild compact workspace layout | Preserve controller state | Medium | High | Low | Medium | Workspace comparison | Phase 4 |
| CVD-014 | Scanner | SCN-004 | High | Wrong filmstrip | Volume_03_Scanner S05-S07 | CaptureWorkspace/filmstrip | Screen-specific | Candidate filmstrip oversized | Align thumbnails/progress/add-photo tiles | Multi-image fixture | Medium | High | Low | Medium | Filmstrip comparison | Phase 4 |
| CVD-015 | Scanner | SCN-005 | High | Wrong analysis treatment | Volume_03_Scanner S08 | AnalyzeAnimationOverlay | Screen-specific | Local overlay not S08 ring | Replace visual treatment only | Analyzer flow stable | Low | Medium | Low | Low | Analysis comparison | Phase 4 |
| CVD-016 | Scanner | SCN-006 | High | Wrong result treatment | Volume_03_Scanner S09 | ScanResultScreen | Shared SR-03 | Long Material result | Align result summary/confidence to S09 | Save handoff | Medium | Medium | Low | Medium | Result comparison | Phase 4 |
| CVD-017 | Scanner | SCN-007 | Medium | Wrong confirmation treatment | Volume_03_Scanner S10 | save confirmation | Shared SR-02 | Functional but unproven visual | Align confirmation surface | Portfolio save path | Medium | High | Low | Medium | Save comparison | Phase 4 |
| CVD-018 | Scanner | SCN-008 | High | Missing state | Volume_03_Scanner S04 | ImageEnhancementPreviewPage | Shared SR-06 | Sample path bypassed review | Capture and align Original/AI Enhance review | Camera/image enhancement | Medium | Medium | Medium | Medium | Review screenshot/XML | Phase 4 |
| CVD-019 | Scanner | SCN-009 | Medium | Wrong hierarchy | Volume_03_Scanner S03 | workspace guidance | Screen-specific | Guidance rendered as role chips/copy | Recompose approved guidance checklist | Capture roles | Low | Low | Low | Low | S03 comparison | Phase 4 |
| CVD-020 | Scanner | SCN-010 | Medium | Missing state | Volume_03_Scanner S06/S07 | one-image sample | Shared SR-06 | Multi-image not reproduced | Capture safe multi-image fixture | Device/gallery plan | Medium | High | Medium | Medium | Multi-image evidence | Phase 4 |
| CVD-021 | Scanner | SCN-011 | Low | Responsive mismatch | Volume_03_Scanner S01 | Scan Hub | Screen-specific | Device aspect/spacing | Tune Scan Hub proportions after full flow | None | Low | Low | Low | Low | S01 comparison | Phase 4 |
| CVD-022 | Scanner | SCN-012 | Critical | Product-contract clarification | Volume_03_Scanner S02-S10 | Capture System candidates | Shared SR-08 | Candidate treatments risk promotion | Keep Capture System candidate until approved | Product clarification | Governance | Medium | Medium | High | Docs and implementation review | Phase 0 wait/Phase 4 |
| CVD-023 | Portfolio | PVD-001 | High | Missing state | Volume_06_Portfolio S01 | empty first entry | Shared SR-06 | No populated runtime fixture | Capture populated S01 and align overview | Fixture/data setup | Medium | Medium | None | Medium | Populated screenshot/XML | Phase 2 |
| CVD-024 | Portfolio | PVD-002 | Critical | Wrong token/surface | Volume_06_Portfolio S01/S04 | summary card | Shared SR-02 | Light Material summary inside dark board | Rebuild summary with dark compact surfaces | Phase 0 surfaces | Medium | Medium | None | Medium | First viewport comparison | Phase 2 |
| CVD-025 | Portfolio | PVD-003 | Medium | Missing state | Volume_06_Portfolio S01/S02 | hidden search when empty | Product clarification | Empty Portfolio search visibility differs | Decide empty search behavior | Search clarification | Low | Low | None | Low | Empty/populated captures | Phase 0 wait/Phase 2 |
| CVD-026 | Portfolio | PVD-004 | High | Wrong composition | Volume_06_Portfolio S03 | sort sheet | Shared SR-05 | Bright modal invented outside board | Darken/align or replace with in-screen sort | Shared sheet policy | Medium | Low | None | Medium | Sheet comparison | Phase 2 |
| CVD-027 | Portfolio | PVD-005 | High | Wrong token/surface | Volume_06_Portfolio S03 | filter sheet | Shared SR-05 | Bright modal with unapproved CTA | Darken/align or create overlay authority | Shared sheet policy | Medium | Low | None | Medium | Sheet comparison | Phase 2 |
| CVD-028 | Portfolio | PVD-006 | High | Missing state | Volume_06_Portfolio S05 | item grid | Shared SR-06 | No populated evidence | Capture and tune populated grid | Fixture/data setup | Low | Medium | None | Low | Grid screenshot/XML | Phase 2 |
| CVD-029 | Portfolio | PVD-007 | High | Wrong valuation treatment | Volume_06_Portfolio S05/value states | PortfolioGridTile | Shared SR-07 | Currency formatting ignores valuation status | Distinguish unavailable from zero | Shared valuation rule | Medium | High | None | Medium | Widget fixture and runtime capture | Phase 2 |
| CVD-030 | Portfolio | PVD-008 | Medium | Wrong component | Board favorite examples | wishlist badge | Product clarification | Wishlist and favorite authority differ | Clarify favorite vs wishlist treatment | Product decision | Low | Low | None | Low | Item-card comparison | Phase 0 wait/Phase 2 |
| CVD-031 | Portfolio | PVD-009 | Medium | Missing state | Portfolio item/gallery prompt | grid card | Product clarification | Gallery count not mapped | Add or formally exclude indicator | Detail/Portfolio image policy | Low | Medium | None | Low | Gallery item fixture | Phase 2 |
| CVD-032 | Portfolio | PVD-010 | Medium | Navigation mismatch | Volume_06 bottom nav | App Shell four tabs | Shared SR-04 | Board has Search tab | Hold pending App Shell/Search decision | Product clarification | High | Medium | None | High | App Shell review | Phase 0 wait |
| CVD-033 | Portfolio | PVD-011 | Medium | Wrong hierarchy | Empty component | empty state below summary | Shared SR-03 | Summary/controls precede empty message | Compact/reorder empty first viewport | Phase 0 spacing | Low | Low | None | Low | Empty screenshot/XML | Phase 2 |
| CVD-034 | Portfolio | PVD-012 | Medium | Missing state | Volume_06 S06-S10 | bulk/share/export states | Product clarification | Features not implemented/captured | Decide scope before freeze | Product decision | Medium | Medium | None | Medium | Feature availability review | Phase 0 wait |
| CVD-035 | Detail | DET-001 | Critical | Wrong composition | Volume_07 S01-S10 | single long-scroll page | Shared SR-01/SR-03 | Sprint local composition, not board tabs | Rebuild around approved Detail states/tabs | Portfolio remediation and App Shell stability | High | High | None | High | S01-S10 screenshots and tab tests | Phase 3 |
| CVD-036 | Detail | DET-002 | High | Wrong hierarchy | Volume_07 S01 | AppBar plus PackLoxHeader | Shared SR-04 | Generic header stack | Create board-matched local Detail header | Back/edit affordances | Medium | Low | None | Medium | First viewport screenshot/XML | Phase 3 |
| CVD-037 | Detail | DET-003 | High | Wrong sizing | Volume_07 S01/S02 | PremiumDetailHero | Shared SR-03 | Oversized rounded hero | Match approved hero size/surface | Gallery selection | Medium | Medium | None | Medium | Hero comparison | Phase 3 |
| CVD-038 | Detail | DET-004 | Medium | Wrong image treatment | Volume_07 S02 | gallery review modal | Shared SR-05 | Runtime-only dialog chrome | Align modal chrome/actions to gallery vocabulary | Image edit/delete | Medium | Medium | None | Medium | Gallery review screenshot/XML | Phase 3 |
| CVD-039 | Detail | DET-005 | High | Wrong valuation treatment | Volume_07 S04 | hero/value/evidence sections | Shared SR-07 | Value split and unavailable reads as $0 | Approved Market & Value state plus unavailable adaptation | Shared valuation rule | High | High | None | High | Valuation fixtures/screenshots | Phase 3 |
| CVD-040 | Detail | DET-006 | High | Wrong component | Volume_07 S05 | AiSummarySection | Screen-specific | Linear AI block | Replace with approved AI insight/confidence treatment | Stored AI evidence | Medium | Medium | None | Medium | S05 comparison | Phase 3 |
| CVD-041 | Detail | DET-007 | High | Wrong component | Volume_07 S03/S06 | metadata chips/sections | Screen-specific | Chip-heavy long-scroll fields | Map to attribute rows/condition bars | Data completeness | Medium | Medium | None | Medium | S03/S06 comparisons | Phase 3 |
| CVD-042 | Detail | DET-008 | Medium | Missing state | Volume_07 S09 | notes/tags | Screen-specific | Tags absent/unmapped | Add approved notes/tags treatment | Notes persistence | Low | Low | None | Low | S09 comparison/test | Phase 3 |
| CVD-043 | Detail | DET-009 | High | Wrong hierarchy | Volume_07 S10 | body actions/delete dialog | Shared SR-05 | Large buttons and generic dialog | Use approved Actions Menu and styled destructive adaptation | Delete safety | Medium | Low | None | Medium | S10 comparison/delete test | Phase 3 |
| CVD-044 | Detail | DET-010 | High | Missing state | Volume_07 S07/S08 | similar/price history | Shared SR-06 | Not state-specific tabs | Add tabs or empty adaptations | Data fixtures | Medium | Medium | None | Medium | Data/no-data state captures | Phase 3 |
| CVD-045 | Detail | DET-011 | Medium | Wrong spacing | Volume_07 S01-S10 | all sections | Shared SR-03 | AppSpacing long vertical stacking | Measure/apply compact board spacing | Phase 0 spacing | Medium | Low | None | Medium | Proportion comparison | Phase 3 |
| CVD-046 | Detail | DET-012 | Medium | Wrong surface | Volume_07 S01-S10 | dialogs/surfaces | Shared SR-02/SR-05 | Default Material surfaces | Apply approved dark Detail surfaces locally | Shared sheet/dialog policy | Low | Low | None | Low | Dark/light screenshot comparison | Phase 3 |
| CVD-047 | Detail | DET-013 | Medium | Missing state | Volume_07 S01/S02 adaptation | missing-image placeholder | Shared SR-06 | No explicit missing-image crop | Define allowed placeholder adaptation | Image policy | Low | Medium | None | Low | Missing-image screenshot | Phase 3 |
| CVD-048 | Detail | DET-014 | Low | Unsupported content | Volume_07 S10 | share feedback | Product clarification | Share incomplete but equal visual weight | Make disabled/coming-soon semantics clear | Product decision | Low | Low | None | Low | Share action test/screenshot | Phase 3 |
| CVD-049 | Detail | DET-015 | Critical | Legacy residue/governance | Volume_07 S01-S10 | prior freeze evidence | Shared SR-01 | Sprint freeze was not authority-mapped | Keep Detail visual freeze reopened until remediation passes | Freeze policy | Governance | Low | None | High | Freeze reassessment update | Phase 5 |

## Deduplication Notes

Shared issues are not removed from the register because each screen has different approved crops, runtime evidence, and rollback boundaries. Deduplication happens through the shared remediation map and Phase 0 foundation work.
