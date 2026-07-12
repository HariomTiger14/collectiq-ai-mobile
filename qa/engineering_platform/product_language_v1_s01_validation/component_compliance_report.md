# Component compliance report

Micro-polish preserves Header 1.0.1 anatomy and 48 px notification target, Hero 1.0.1 title/subtitle typography, Entry Tile 1.0.0 height/internal padding, and all semantics. Only the scanner hero spacing/icon container, header border opacity, and composition-owned tile gaps changed. No clones or API changes were introduced.

| Component | Flutter path | S01 variant | Status | Variance |
| --- | --- | --- | --- | --- |
| Header 1.0.1 | `lib/core/ui/product_language/packlox_header.dart` | canonical | Implemented, runtime validated | Material rounded bell is provisional pending Icon Language |
| Hero 1.0.1 | `lib/core/ui/product_language/packlox_hero.dart` | scanner | Implemented, runtime validated | Hero CTA omitted to avoid behavior duplication |
| Entry Tile 1.0.0 | `lib/core/ui/product_language/packlox_entry_tile.dart` | scanner | Implemented, runtime validated | Material rounded outline icons are provisional |
| Button 1.0.0 | `lib/core/ui/product_language/packlox_button.dart` | available to Hero | Implemented, tested | Spinner rasterization is platform-owned |

No pixel-perfect claim is made. Final compliance remains blocked on test/build/device evidence.
