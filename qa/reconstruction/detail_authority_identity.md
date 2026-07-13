# Detail Authority Identity

Date: 2026-07-13
Branch: rebuild/product-language-v1
Starting HEAD: d78cdc7f88df9ba56791853020e3811d5b33cc22
Task: Detail Approved Visual Authority Recovery

## Selected Authority

The selected approved and frozen Detail authority is:

`C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_07_Collectible_Detail/images/collectible_detail_flow_master.png`

This is the only Detail candidate selected for recovery because the Design Bible volume identifies it as the complete Collectible Detail master board, and the volume README states that the master board is contractual and must not be treated as inspiration.

## Release And Approval Evidence

- Release: Design Bible v1.0
- Release manifest: `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/MANIFEST.md`
- Release import date: 2026-07-11
- Release scope: 11 Design Bible volumes, 11 approved master images, 96 extracted application screens
- Volume: `Volume_07_Collectible_Detail`
- Volume manifest: `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_07_Collectible_Detail/manifest.json`
- Visual inventory: `C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_07_Collectible_Detail/visual_inventory.md`
- Inventory status: Approved contractual reference
- Component inventory status: Visible on the approved master board
- Freeze status: Frozen by Design Bible v1.0 release association
- Superseded status: No superseding Detail authority found during this recovery pass

## Master Image Metadata

- Original filename: `collectible detail flow.png`
- Stored filename: `collectible_detail_flow_master.png`
- Version: 1.0
- Import date: 2026-07-11
- Dimensions: 1536x1024 pixels
- SHA256: `9fb59e44d860b17b9c3e5671062857087543ef2614b7987625dac6e2c0d924b7`
- File size: 1870678 bytes
- Theme: dark product board
- Target viewport/device: bounded mobile app crops, approved for iOS and Android by the volume README
- Represented flow: overview, gallery, attributes, market value, AI insights, condition, similar items, price history, notes, tags, and actions

## Approved Crop List

| ID | State | File | Dimensions | SHA256 |
|---|---|---|---:|---|
| S01 | Item Overview | `01_item_overview.png` | 137x368 | `f9e0325184f1eba3d4d617272122e7bda57fefb323ed96bf2667801b33497f5a` |
| S02 | Image Gallery | `02_image_gallery.png` | 137x368 | `af35b11260d4322dfa750c8e61f4e80f333ed4df7f35be7b1eb86a43f3892aca` |
| S03 | Details & Info | `03_details_info.png` | 137x368 | `69406c03cd9ea6b6a85a58508824a01cfd12539ae9b4f147889ad54b849d0988` |
| S04 | Market & Value | `04_market_value.png` | 137x368 | `e4beea30e10b74c24274c7988e0a07da18622412946cee83baceb12f8a2c9278` |
| S05 | AI Insights | `05_ai_insights.png` | 137x368 | `d2128b12ef8017746d7d612de8e1c88ef4c0414ffef938c245518b3043e969aa` |
| S06 | Condition | `06_condition.png` | 137x368 | `fe5e8b0837795a69469279abfebe9dd25da98d63f096670d3b5252312b608ef1` |
| S07 | Similar Items | `07_similar_items.png` | 137x368 | `a425bf4ca3d903fe2223a0f96db65531ebd1155a1a9de411f75c1161aff2f07d` |
| S08 | Price History | `08_price_history.png` | 137x368 | `b6410102b1285ce5dd79a26c284a50547ee82a8cc96ac604f0aa1b8e7f924534` |
| S09 | Notes & Tags | `09_notes_tags.png` | 137x368 | `91144ad836f6d27c96f7eb303bda425b116c4d5db42442cc8d15f6887478a2d9` |
| S10 | Actions Menu | `10_actions_menu.png` | 165x368 | `6f987af4dad21a2fb4d6cf5c14152f4d43c1b31f40ae10b9252f0a125701dff9` |

## Candidate References Rejected

Prior Sprint 07 runtime screenshots, written specification files, Product Language primitives, shared `item_details_ui.dart` helpers, and earlier `qa/screenshots/ui_conformance/detail/approved_reference/no_authoritative_image_found.md` are not selected authorities. They are implementation or audit artifacts and are superseded for visual authority by the recovered Design Bible v1.0 Collectible Detail board.

## Completeness

The approved authority represents ten Detail states. It covers the major visual system for item overview, gallery, details, value, AI insights, condition, similar items, price history, notes/tags, and actions. It does not separately show a Flutter-specific unavailable valuation screen, zero valuation screen, missing image placeholder, or delete confirmation dialog; those states must be adapted without contradicting the approved Detail surface, hierarchy, tabs, and dark visual treatment.
