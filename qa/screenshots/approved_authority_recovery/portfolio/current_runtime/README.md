# Current Portfolio Runtime Evidence

Device: Samsung SM E625F
Device ID: RZ8R213M8ZL
Android: 13 / API 33
Build artifact: build/app/outputs/flutter-apk/app-prod-debug.apk
Package: com.collectiq.ai
Capture date: 2026-07-13 local session
Physical screen: 1080x2400
Physical density: 450 dpi
Text scale: 1.0
Orientation: portrait
Device UI night mode: no
App rendered mode: mixed: dark Portfolio root with light summary/sheet surfaces
Status bar: visible, 92 px top inset
System navigation bar: visible, 135 px bottom inset
Display cutout: top center cutout, 92 px inset

Fresh captures:

| File | Purpose | State |
|---|---|---|
| 01_first_entry.png | Immediate Portfolio entry from App Shell | Empty Portfolio |
| 01_first_entry.xml | Hierarchy for first entry | Empty Portfolio |
| 02_sort_sheet.png | Sort bottom sheet | Empty Portfolio, sort sheet open |
| 02_sort_sheet.xml | Hierarchy for sort sheet | Empty Portfolio, sort sheet open |
| 03_filter_sheet.png | Filter bottom sheet | Empty Portfolio, filter sheet open |
| 03_filter_sheet.xml | Hierarchy for filter sheet | Empty Portfolio, filter sheet open |
| 04_empty_scroll.png | Empty Portfolio after scroll gesture | Empty Portfolio lower content |
| 04_empty_scroll.xml | Hierarchy for empty scroll | Empty Portfolio lower content |

Unavailable fresh states:

- Populated Portfolio was not naturally available on the device.
- Search active and search no-results were not available because current Flutter hides search controls when the portfolio is empty.
- Category filter state, post-filter results, post-sort results, gallery/multi-image item, missing-image item, unavailable valuation item, and zero valuation item were not safely reproducible without seeding or creating portfolio data.
- This audit did not seed data through Scanner or modify production code.
