# Approved S01 visual anatomy

Measurements use the 124 × 315 approved crop. Because the crop is a compact raster, ratios and token relationships are authoritative; runtime safe areas remain platform-driven.

## Header

- Content begins about 7/124 (5.6%) from each side, represented by the approved 16 logical-pixel token.
- Greeting begins near y=10 after the depicted status inset; the name follows with a small but visible gap of roughly half the greeting line height.
- Name is about 1.4× the greeting size and materially heavier; emoji shares the name baseline with a small optical offset.
- Bell is right aligned to content and centered optically against the two-line greeting, inside at least a 44 logical-pixel target.
- Header-to-hero gap is one 16-point step.

## Hero

- Same width as content/tiles: about 106/124 (85.5%) of viewport in the crop.
- Height is about 72 crop pixels versus roughly 34–35 per tile: approximately 2.05–2.1 tile heights.
- Evidence-backed responsive target: content-driven, normally about 132–136 logical pixels at standard scale.
- Internal padding maps to 16 logical pixels. Title occupies roughly 60% of the interior; icon occupies the right quarter.
- Title is exactly two lines; subtitle is two lines; their gap is one 8-point step.
- Scanner icon is approximately one third of the hero height and vertically centered.
- Radius maps to 12; border is a thin primary-blue line; gradient runs top-left toward bottom-right.

## Option section

- Hero-to-heading gap is 16; heading-to-first-tile gap is 8.
- Heading aligns with the hero/tile left edge.

## Entry tiles

- Same outer width as hero; reference height is roughly 34–35 crop pixels with 6–7 pixel inter-tile gaps.
- Runtime target is minimum 64 logical pixels, content-driven upward; tile gap is 8.
- Internal horizontal padding is 12–16; icon container is about 40 logical pixels; icon-to-text gap is 12.
- Title/subtitle use 14/12 hierarchy with a small 2–4 logical-pixel baseline gap.
- Radius is 12 with thin slate border; content is vertically centered.

## Bottom navigation

- Reference outer width is about 114/124 (92%) with narrow margins, height about 31 crop pixels, and a large rounded outer radius.
- Four equal destinations; active Scan has a compact rounded blue/purple capsule, icon above label.
- Shared dark surface continues through the system inset. Runtime insets, not crop coordinates, are authoritative.
