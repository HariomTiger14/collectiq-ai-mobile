# Scanner S01 micro-polish value delta

| Refinement | Current | Target | Actual | Delta | Source | Responsive impact |
|---|---:|---:|---:|---:|---|---|
| Scanner hero outer padding | 24 px; 20 px at ≤360 | Reduce card height 8–10% without typography changes | 20 px; 16 px at ≤360 | −4 px per edge | `packlox_hero.dart` | Equal reduction at all supported widths; scroll behavior retained |
| Scanner hero eyebrow/title and title/subtitle gaps | 12 px each | Contribute to 8–10% footprint reduction | 8 px each | −4 px each | `packlox_hero.dart` | Total vertical reduction is 16 px, approximately 8.8% of the prior ~181 px runtime card |
| Scanner hero icon container | 44 px | Reduce prominence 3–5% | 42 px | −2 px / −4.55% | `packlox_hero.dart` | Alignment remains top-aligned; 24 px glyph unchanged |
| Scanner hero icon glyph | 24 px | Preserve approved icon language | 24 px | 0 | `packlox_hero.dart` | Readability preserved |
| Notification border | `#334155`, 100% opacity, 1 px | Soften visual weight ~5% | `#334155`, 95% opacity, 1 px | −5% opacity | `packlox_header.dart` | 48 px touch target, 22 px icon, unread badge and semantics unchanged; no shadow existed |
| S01 tile-to-tile spacing | 12 px | Reduce by 6–8 px | 6 px | −6 px / −50% | `scan_hub_presentation.dart` | Tile height and internal padding unchanged; two gaps save 12 px vertically |

Only the scanner hero variant receives the compact hero values. Other hero variants retain their existing spacing and 44 px icon container.
