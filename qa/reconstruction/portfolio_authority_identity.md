# Portfolio Authority Identity

Scope: Portfolio only.

## Selected Authority

Primary approved authority: C:/Users/hario/Desktop/projects/packlox-design-platform/releases/v1.0/design_bible/Volume_06_Portfolio/images/portfolio_flow_master.png

Release: Design Bible v1.0
Import date: 2026-07-11
Original filename: portfolio flow.png
Approved filename: portfolio_flow_master.png
Dimensions: 1536x1024 px
SHA256: 40e22e960b9e73835a4463aeb2d72b6ed4f9bf32de98f1171b6c3f43376324b4
File size: 1795346 bytes
Theme: dark product board
Target platform: iOS and Android mobile frames
Status: approved contractual reference
Freeze status: frozen by Design Bible v1.0 release
Superseded: no later Portfolio authority found in this recovery pass

## Release And Freeze Evidence

- releases/v1.0/MANIFEST.md records Release v1.0, import date 2026-07-11, 11 approved master images, and 96 extracted application screens.
- Volume_06_Portfolio/README.md states the board defines collection browsing, organization, bulk management, sharing, and backup.
- Volume_06_Portfolio/README.md states grid, list, and compact modes are approved options and the master board is contractual.
- Volume_06_Portfolio/manifest.json records version, import date, master dimensions, SHA256, and volume association.
- Volume_06_Portfolio/visual_inventory.md records Status: Approved contractual reference and marks S01 through S10 Approved.
- Volume_06_Portfolio/qa/golden_mapping.md records the master board as the contractual source and the extracted screens as convenience references.

## Approved Portfolio States

| Screen ID | Title | Source crop | Dimensions | Flow state | Complete or partial |
|---|---|---|---:|---|---|
| S01 | Portfolio Home | screens/01_portfolio_home.png | 134x402 | Overview | Complete for visible overview crop |
| S02 | Search | screens/02_search.png | 134x402 | Find items | Complete for visible search crop |
| S03 | Filter & Sort | screens/03_filter_sort.png | 134x402 | Refine view | Complete for visible filter/sort crop; bottom sheets are not separately shown |
| S04 | Collection Stats | screens/04_collection_stats.png | 134x402 | At a glance | Complete for visible stats crop |
| S05 | Item Grid | screens/05_item_grid.png | 134x402 | Browse items | Complete for visible item grid crop |
| S06 | Bulk Select | screens/06_bulk_select.png | 134x402 | Manage multiple | Complete for visible bulk selection crop |
| S07 | Item Options | screens/07_item_options.png | 134x402 | Quick actions | Complete for visible item options crop |
| S08 | Collections | screens/08_collections.png | 134x402 | Group and organize | Complete for visible collections crop |
| S09 | Share Collection | screens/09_share_collection.png | 134x402 | Showcase | Complete for visible share crop |
| S10 | Export / Backup | screens/10_export_backup.png | 202x402 | Keep safe | Complete for visible export/backup crop |

## Included And Excluded Scope

Included: Portfolio overview, search, filter/sort controls, collection stats, item grid, bulk select, item options, collections, sharing, export, backup, empty state, no-results state, bottom navigation context, and floating action examples visible on the master board.

Filter/sort sheets: the board includes filter dropdown, range slider, sort control, and view mode/sort option documentation. It does not include separate full-height Flutter modal sheet screenshots, so sheet implementation requires derived contract plus design clarification.

Detail excluded: Collectible Detail is a dependency and exit path. Detail screens belong to Volume_07_Collectible_Detail and are not part of this Portfolio recovery authority.
