# First Dataset Review

This is a human-review draft for the local validation images in `validation/images/local_sample/`. Labels are intentionally conservative: uncertain fields are marked `Unknown`, left blank, or assigned `Low` confidence in `validation/manifests/local_sample_draft.json`.

## Summary

- Total images processed: 7
- High confidence images: 3
- Medium confidence images: 4
- Low confidence images: 0
- Estimated dataset readiness: Draft review set. Useful for a first local validation pass, but not ready as a golden dataset until the manual review fields below are confirmed.

## Images

### 1998 National Geographic “Mola Pillow” Curiosity Kits Activity Complete Open Box.jpg

- Reference: `validation/images/local_sample/1998 National Geographic “Mola Pillow” Curiosity Kits Activity Complete Open Box.jpg`
- Proposed collectible name: National Geographic Curiosity Kits Mola Pillow Activity Kit
- Category: Craft Activity Kit
- Overall confidence: Medium
- Fields requiring manual review: year, manufacturer, open-box/complete status, exact variant
- Reasoning: The front of the box is readable and supports the National Geographic Curiosity Kits and Mola Pillow identification. The year and complete/open-box status appear to come from the filename/context, not from readable image text.
- Better image recommendation: Add side/back photos showing barcode, copyright date, manufacturer, and contents.

### 980s 'Pogo Ball Classic' by Hasboro Toys still in the box..jpg

- Reference: `validation/images/local_sample/980s 'Pogo Ball Classic' by Hasboro Toys still in the box..jpg`
- Proposed collectible name: Pogo Bal Classic
- Category: Toy
- Overall confidence: Medium
- Fields requiring manual review: brand spelling, manufacturer, exact year, boxed variant
- Reasoning: The front reads Pogo Bal Classic clearly. The brand/manufacturer and decade are inferred from filename/context and need confirmation from box text.
- Better image recommendation: Add side/back photos showing Hasbro branding, date, UPC, and product details.

### Australia 1955 UnitedNation 50th Anniversary 20c.jpg

- Reference: `validation/images/local_sample/Australia 1955 UnitedNation 50th Anniversary 20c.jpg`
- Proposed collectible name: United Nations Fiftieth Anniversary 20 cents coin
- Category: Coin
- Overall confidence: Medium
- Fields requiring manual review: country, year, mint, denomination authority, exact commemorative issue
- Reasoning: The visible side shows United Nations Fiftieth Anniversary and 20 cents. The country/year/mint are not readable in this view, so the filename was not treated as confirmed truth.
- Better image recommendation: Add a clear obverse image and a closer reverse image with all rim text visible.

### HEMAN.jpeg

- Reference: `validation/images/local_sample/HEMAN.jpeg`
- Proposed collectible name: He-Man action figure
- Category: Action Figure
- Overall confidence: Medium
- Fields requiring manual review: exact figure release, year, manufacturer, variant, packaging/set name
- Reasoning: The figure resembles He-Man and the backdrop indicates Masters of the Universe. Exact release details are obscured by glare, acrylic cases, price tags, and nearby items.
- Better image recommendation: Photograph the single figure straight-on with less glare, plus any package/label/back card details.

### Owner's Pokémon (TCG).jpg

- Reference: `validation/images/local_sample/Owner's Pokémon (TCG).jpg`
- Proposed collectible name: Brock's Sandslash
- Category: Pokemon Trading Card
- Overall confidence: High
- Fields requiring manual review: set, variant
- Reasoning: Card name, HP, card number 23/132, English language, and Wizards copyright/manufacturer line are readable. The set is inferred from the card style/numbering and should be confirmed.
- Better image recommendation: Use a sharper full-card front image and, if variant matters, include the card back or a close-up of symbols/foil texture.

### Petretti's Coca-cola Collectables Price Guide.webp

- Reference: `validation/images/local_sample/Petretti's Coca-cola Collectables Price Guide.webp`
- Proposed collectible name: Petretti's Coca-Cola Collectibles Price Guide, 10th Edition
- Category: Collectibles Reference Book
- Overall confidence: High
- Fields requiring manual review: publication year, publisher/manufacturer metadata
- Reasoning: The cover title, 10th Edition label, subtitle, and author are readable. Publication year and publisher are not shown on the cover image.
- Better image recommendation: Add copyright page or back cover with publisher/date.

### Pokémon's Pikachu Illustrator card.jpg

- Reference: `validation/images/local_sample/Pokémon's Pikachu Illustrator card.jpg`
- Proposed collectible name: Pikachu Illustrator Holo CoroCoro Comics Promo
- Category: Pokemon Trading Card
- Overall confidence: High
- Fields requiring manual review: card number, manufacturer, any certification metadata needed for golden labels
- Reasoning: The PSA label identifies the item as 1998 P.M. Japanese Promo Illustrator-Holo CoroCoro Comics, Gem MT 10. Card number/manufacturer are not visible.
- Better image recommendation: Add a closer front image and certification close-up if PSA cert validation is part of the dataset.

## Dataset Readiness

This local sample can be used as a draft validation pass for category/name recognition, but it should remain separate from the golden manifest until manual review confirms the uncertain fields.

Recommended next steps:

1. Confirm the Medium-confidence fields from the physical item, packaging, or trusted collection records.
2. Add obverse/back/side images for items where year, manufacturer, variant, or mint cannot be seen.
3. Keep using `validation/manifests/local_sample_draft.json` for review, then copy reviewed labels into the validated manifest only after confirmation.
