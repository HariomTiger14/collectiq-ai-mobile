# Detail Visual Deviation Matrix

Date: 2026-07-13
Authority: Design Bible v1.0 `Volume_07_Collectible_Detail`
Runtime evidence: `qa/screenshots/approved_authority_recovery/detail/current_runtime/`

| ID | Approved reference | Runtime location | Issue | Severity | Type | Root cause | Required correction | Regression risk | Validation method |
|---|---|---|---|---|---|---|---|---|---|
| DET-001 | S01-S10 | `04_detail_first_viewport.png`, scroll captures | Runtime is single long-scroll page; approved authority is tabbed Detail flow | Critical | wrong composition | Sprint 07 used written spec/local composition instead of board | Rebuild structure around approved bottom Detail tabs/states | High | S01-S10 runtime screenshots and tab navigation tests |
| DET-002 | S01 | `04_detail_first_viewport.png` | Standard AppBar plus PackLoxHeader replaces approved Detail header | High | wrong hierarchy | Generic app shell/header reuse | Create board-matched Detail header | Medium | First viewport screenshot/XML |
| DET-003 | S01/S02 | `04_detail_first_viewport.png`, `07_detail_gallery_state.png` | Hero consumes too much first viewport and uses rounded Material card | High | wrong sizing | `_PremiumDetailHero` local design | Match approved hero size/surface | Medium | Hero comparison PNG |
| DET-004 | S02 | `08_gallery_review.png` | Full-screen gallery modal is runtime-only and not visually matched to S02 | Medium | wrong image treatment | Local dialog implementation | Align modal chrome/actions with approved gallery language | Medium | Gallery review screenshot/XML |
| DET-005 | S04 | `06_detail_actions_value.png`, `16_minimal_missing_image_unavailable_value.png` | Value presentation is split between hero and later evidence; unavailable appears as `$0` | High | wrong valuation treatment | Data status not reflected in visual state | Create approved Market & Value state and explicit unavailable adaptation | High | Valuation fixtures and screenshot comparison |
| DET-006 | S05 | `05_detail_ai_metadata_notes.png` | Runtime AI Review is a linear copy block, missing approved AI card/confidence ring | High | wrong component | Local section composition | Replace with approved AI insight card/confidence treatment | Medium | S05 comparison |
| DET-007 | S03/S06 | `05_detail_ai_metadata_notes.png`, `10_detail_action_controls.png` | Metadata uses chips/long-scroll fields instead of approved attribute rows/condition bar | High | wrong component | Local chip section | Map fields into approved Details & Info and Condition states | Medium | S03/S06 comparisons |
| DET-008 | S09 | `10_detail_action_controls.png` | Notes are presented as large freeform field without visible approved tag-chip composition | Medium | missing state | Tags not implemented in captured runtime | Add approved notes/tags treatment | Low | S09 comparison and notes persistence test |
| DET-009 | S10 | `10_detail_action_controls.png`, `13_delete_confirmation.png` | Actions are large body buttons and Material dialog, not approved actions menu | High | wrong hierarchy | Local `_DetailActionSection` | Implement approved Actions Menu, keep confirmation as styled adaptation | Medium | S10 comparison and delete safety test |
| DET-010 | S07/S08 | `06_detail_actions_value.png` and lower runtime not fully separate | Similar items and price history are not presented as approved state-specific tabs | High | missing state | Long-scroll sections and missing price-history series | Add S07/S08 tab states; distinguish missing data | Medium | State capture with data and no-data fixtures |
| DET-011 | S01-S10 | all runtime captures | Runtime spacing is much taller and more card-heavy than compact crops | Medium | wrong spacing | Generic `AppSpacing.lg` stacked sections | Measure and apply board spacing | Medium | pixel/proportion comparison |
| DET-012 | S01-S10 | `13_delete_confirmation.png` and surface captures | Some surfaces/dialogs are generic Material rather than approved dark Detail surfaces | Medium | wrong surface | Default Material components | Apply approved Detail surface tokens locally | Low | dark/light screenshot comparison |
| DET-013 | S01/S02 adaptation | `16_minimal_missing_image_unavailable_value.png` | Missing-image placeholder is functional but not proven against authority | Medium | missing state | No explicit approved missing-image crop | Define allowed placeholder adaptation | Low | Missing-image screenshot |
| DET-014 | S10 | `12_share_feedback.png` | Share action is coming soon but visually equal to active actions | Low | unsupported content | Feature incomplete | Keep disabled/coming-soon semantics visually clear | Low | Share action test/screenshot |
| DET-015 | S01-S10 | runtime vs approved references | Current freeze evidence cannot prove Design Bible conformance | Critical | legacy residue | Prior freeze was sprint-scoped, not authority-mapped | Reopen Detail visual freeze until remediation passes | Governance | Freeze reassessment update |

## Severity Counts

- Critical: 2
- High: 7
- Medium: 5
- Low: 1

## Acceptable Adaptations

Android status/navigation bars, debug-only seed data, local image placeholders, confirmation before destructive delete, and disabled share behavior are acceptable only if styled inside the approved Detail visual system.

## Authority Ambiguity

The approved crops do not separately show unavailable valuation, zero valuation, missing AI evidence, missing image, or delete confirmation. These require local adaptation or new approval before freeze closure.
