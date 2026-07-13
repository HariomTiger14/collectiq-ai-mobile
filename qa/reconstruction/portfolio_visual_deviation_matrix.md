# Portfolio Visual Deviation Matrix

| ID | Approved reference location | Current runtime location | Issue | Severity | Type | Classification | Root cause | Required correction | Regression risk | Validation method |
|---|---|---|---|---|---|---|---|---|---|---|
| PVD-001 | S01 Portfolio Home | 01_first_entry.png | Runtime first entry is empty-state layout, not approved Portfolio Home overview | High | missing state | Missing evidence plus likely implementation gap | Device has no items; Sprint 06 was written-spec led | Capture populated state and align to S01 | Medium | Fresh populated screenshot/XML |
| PVD-002 | S01/S04 | 01_first_entry.png | Large light Collection summary card conflicts with dark approved surface language | Critical | wrong token | Genuine visual defect against dark board | Runtime uses light Material surface inside dark root | Rebuild summary with dark board-aligned surfaces | Medium | First viewport comparison |
| PVD-003 | S01/S02 | 01_first_entry.png | Search is absent when Portfolio is empty | Medium | missing state | Product-contract clarification | Flutter hides search if items empty | Decide whether search appears for empty Portfolio | Low | Empty and populated captures |
| PVD-004 | S03 Filter & Sort | 02_sort_sheet.png | Sort sheet is bright/light and separate from approved dark filter/sort screen | High | wrong composition | Genuine defect unless overlay authority is approved | Modal sheet invented outside board authority | Darken/align or replace with in-screen control | Medium | Sheet comparison |
| PVD-005 | S03 Filter & Sort | 03_filter_sheet.png | Filter sheet is bright/light and uses large gradient CTA not shown on board | High | wrong token | Genuine defect unless overlay authority is approved | Modal sheet invented outside board authority | Darken/align or create approved overlay | Medium | Sheet comparison |
| PVD-006 | S05 Item Grid | No fresh populated runtime | Item-grid conformance not proven | High | missing state | Missing evidence | No fresh populated data available | Capture populated state before freeze | Low | Populated grid screenshot/XML |
| PVD-007 | S05 Item Card | Source mapping | Item cards do not distinguish unavailable valuation from zero value | High | wrong valuation treatment | Behaviour-contract mismatch | _formatAud used without status branch | Add explicit valuation display contract | Medium | Widget fixture and runtime capture |
| PVD-008 | Board item/favorite examples | Source mapping | Favorite/heart treatment represented as wishlist badge | Medium | wrong component | Design ambiguity | Wishlist implementation differs from favorite component | Clarify favorite vs wishlist authority | Low | Item-card comparison |
| PVD-009 | Board gallery prompt | Source mapping | No grid gallery/image-count indicator | Medium | missing state | Missing authority detail | Gallery handled in Detail, not Portfolio grid | Add or formally exclude indicator | Low | Gallery item fixture |
| PVD-010 | Board bottom nav | 01_first_entry.png | Runtime App Shell has four tabs; board shows five with Search | Medium | responsive mismatch | Outside Portfolio-only scope | Sprint 03 shell differs from board | Separate App Shell review; do not change here | High | App Shell authority review |
| PVD-011 | Empty State component | 01_first_entry.png | Empty state sits after large summary/add controls and is partly low in viewport | Medium | wrong hierarchy | Genuine visual issue for empty Portfolio | Summary and command bar precede empty message | Reorder or compact empty first viewport | Low | Empty screenshot/XML |
| PVD-012 | S06/S07/S08/S09/S10 | No current runtime | Bulk select, item options, collections, share, export/backup not implemented/captured | Medium | missing state | Product-contract clarification | Sprint 06 focused local portfolio presentation | Decide scope before visual freeze | Medium | Feature availability review |

Severity count:

- Critical: 1
- High: 5
- Medium: 6
- Low: 0
