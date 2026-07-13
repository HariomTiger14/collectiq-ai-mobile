# Scanner Visual Deviation Matrix

| ID | Approved reference | Runtime location | Issue | Severity | Type | Root cause | Required correction | Behaviour risk | Camera-lifecycle risk | Validation method |
|---|---|---|---|---|---|---|---|---|---|---|
| SCN-001 | S01-S10 | non-hub captures | Sprint 05 proved S01 strongly but did not prove full S02-S10 board conformance | Critical | missing state | Scan Hub was treated as strongest reference while Capture System stayed candidate | Complete S02-S10 mapping/remediation | Medium | Medium | Full state screenshots |
| SCN-002 | S02 | `10_camera_entry` | Camera-ready viewport was not captured; only OS permission prompt | High | missing state | Permission gate blocked camera comparison | Capture after granting permission and compare S02 | Low | High | camera-ready screenshot/XML |
| SCN-003 | S05-S07 | `03_sample_workspace_analysis_ready` | Workspace is long-scroll Material layout, not compact approved workflow | High | wrong composition | Local workspace components | Rebuild workspace layout to S05-S07 | Medium | Low | workspace comparison |
| SCN-004 | S05-S07 | `03_sample_workspace_analysis_ready` | Filmstrip/role cards are oversized and lower than approved flow | High | wrong filmstrip treatment | Candidate capture workspace | Align filmstrip/progress/add-photo tiles | Medium | Low | filmstrip comparison |
| SCN-005 | S08 | `04_analysis_in_progress` | Runtime overlay differs from approved analysis progress ring | High | wrong analysis treatment | Local animation overlay | Match S08 progress treatment | Low | Low | analysis comparison |
| SCN-006 | S09 | `05_analysis_result`, `06_result_actions` | Result page is long Material result with large confidence/value sections | High | wrong result treatment | Local result handoff | Align result summary card and confidence indicator | Medium | Low | result comparison |
| SCN-007 | S10 | `07_save_confirmation` | Save confirmation functional but visual conformance unproven | Medium | wrong confirmation treatment | Existing result/save UI | Match S10 confirmation | Medium | Low | save comparison |
| SCN-008 | S04 | not captured | Original/AI Enhance review not freshly captured | High | missing state | Sample path bypassed review | Capture safe image review path | Medium | Medium | review screenshot/XML |
| SCN-009 | S03 | workspace guidance | Guidance is copy/role-chip based, not proven S03 checklist | Medium | wrong hierarchy | Candidate guidance composition | Recompose to approved guidance checklist | Low | Low | S03 comparison |
| SCN-010 | S06/S07 | runtime one-image sample | Multi-image state not physically reproduced | Medium | missing state | Safe sample path only | Use approved demo/physical capture for multi-image | Medium | Medium | multi-image evidence |
| SCN-011 | S01 | `02_scan_hub` | Minor scan hub spacing/device-ratio differences remain | Low | responsive mismatch | device aspect ratio/platform metrics | Tune if needed after full remediation | Low | Low | S01 comparison |
| SCN-012 | S02-S10 | all non-hub states | Capture System candidate treatments risk being mistaken for frozen authority | Critical | product-contract clarification | Sprint 05 candidate classification | Keep Capture System unpromoted until approved | Governance | docs and implementation review |

## Severity Counts

- Critical: 2
- High: 6
- Medium: 3
- Low: 1

## Notes

The runtime path was stable and behaviourally useful. Deviations are visual-authority and evidence-coverage issues, not a request to alter controller, camera lifecycle, analyzer, or portfolio handoff contracts.
