# S01 Samsung Visual Comparison

Primary reference: Engineering Platform extracted `Volume_03_Scanner/screens/01_scan_hub.png`

Before: `qa/s01_platform_validation_samsung.png`

After: `runtime_after.png`

## Critical regions

| Region | Before | After | Decision |
|---|---|---|---|
| Header | Dynamic copy correct; oversized/loose; status icons low contrast | Compact token spacing; dynamic greeting preserved; light status icons on dark surface | Fixed materially; minor device font variation |
| Hero | Oversized height, padding, text, and icon | Reduced token padding/minimum height/icon size; hierarchy and copy preserved | Fixed materially; exact gradient remains a contract gap |
| Entry tiles | Cards/icon boxes and gaps oversized | 64 px minimum, content-driven height, smaller icon container, compact token gaps | Fixed materially |
| Shared bottom navigation | Dark nav floated inside a white/light surround | Shared dark surface paints margins and SafeArea; Scan remains selected | Blocker fixed |
| Bottom safe-area/system inset | White strip between app navigation and Android bar | Continuous dark app/system composition with dark divider and light system icons | Blocker fixed |

## Fixed differences

- Removed the light/white navigation surround at the shared owner.
- Painted the runtime bottom inset intentionally.
- Bound Scanner status/navigation system-bar styling.
- Reduced navigation, hero, option, and icon-container density.
- Preserved contract copy and dynamic greeting.

## Remaining differences

- Blockers: none observed in the fresh Samsung capture.
- Major: none observed that can be actioned under current contracts.
- Minor/platform: Samsung font metrics/rasterization, status icons/time, Android three-button system navigation height.
- Contract gaps: executable visual tolerance, exact hero gradient stops, exact tile icon treatments, measured shared-navigation anatomy, explicit Flutter ownership mapping for system overlays.

## Side-by-side and overlay

The authoritative reference is a 124 x 315 extracted raster while the runtime is a 1080 x 2173 device capture with live system bars. A naive rescale/overlay would create misleading differences, so the source images are retained separately and the five critical regions are compared factually above. No difference image is claimed as deterministic evidence.

## Compliance

The result is materially compliant for this foundation sprint. Exact/full visual compliance remains uncertifiable until the platform supplies executable tolerances and resolves the provisional visual values.
