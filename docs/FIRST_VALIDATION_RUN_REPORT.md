# First Validation Dataset Run Report

- Generated: 2026-07-01T00:37:23.7474739+10:00
- Image folder: `validation/images/local_sample/`
- Manifest: `validation/manifests/local_sample_manifest.json`
- Endpoint: http://127.0.0.1:8000/api/analyze

## Status

- Images found: 7
- Manifest rows: 7
- Dry-run validation: PASS
- Full validation: SKIPPED

## Metrics

| Metric | Value |
| --- | --- |
| Total images found | 7 |
| Total analyzed | 0 |
| Category accuracy | n/a |
| Name match accuracy | n/a |
| Confidence distribution | n/a |
| Pricing fallback usage | n/a |
| Average latency | n/a |
| Failures | 0 |

## Manifest Completeness

- 1998 National Geographic “Mola Pillow” Curiosity Kits Activity Complete Open Box.jpg is missing expected_name.
- 1998 National Geographic “Mola Pillow” Curiosity Kits Activity Complete Open Box.jpg is missing expected_category.
- 980s 'Pogo Ball Classic' by Hasboro Toys still in the box..jpg is missing expected_name.
- 980s 'Pogo Ball Classic' by Hasboro Toys still in the box..jpg is missing expected_category.
- Australia 1955 UnitedNation 50th Anniversary 20c.jpg is missing expected_name.
- Australia 1955 UnitedNation 50th Anniversary 20c.jpg is missing expected_category.
- HEMAN.jpeg is missing expected_name.
- HEMAN.jpeg is missing expected_category.
- Owner's Pokémon (TCG).jpg is missing expected_name.
- Owner's Pokémon (TCG).jpg is missing expected_category.
- Petretti's Coca-cola Collectables Price Guide.webp is missing expected_name.
- Petretti's Coca-cola Collectables Price Guide.webp is missing expected_category.
- Pokémon's Pikachu Illustrator card.jpg is missing expected_name.
- Pokémon's Pikachu Illustrator card.jpg is missing expected_category.

## Next Tuning Recommendations

1. Fill the missing required labels listed below before treating metrics as meaningful.
2. Required fields for scoring are `expected_name` and `expected_category`.
3. Rerun with `-RunFullValidation` after the backend is running.

## Safety Notes

- Do not commit image files.
- Do not scrape Google, eBay, marketplaces, or seller listings.
- Use user-owned, public-domain, or explicitly open/licensed images only.
- Automated validation must remain mock/default unless you intentionally run a local backend with real providers.

