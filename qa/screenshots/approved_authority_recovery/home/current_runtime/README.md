# Current Home Runtime Evidence

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
App rendered mode: dark PackLox surface
Status bar: visible, 92 px top inset
System navigation bar: visible, 135 px bottom inset
Display cutout: top center cutout, 92 px inset

Fresh captures:

| File | Purpose | State |
|---|---|---|
| 01_launch.png | First viewport Home capture after fresh install and launcher start | Empty collection |
| 01_launch.xml | Hierarchy for first viewport | Empty collection |
| 02_scroll_mid.png | Home after vertical scroll gesture | Empty collection lower content |
| 02_scroll_mid.xml | Hierarchy for scrolled state | Empty collection lower content |
| 03_scroll_end.png | Home after second vertical scroll gesture | Empty collection lower content |
| 03_scroll_end.xml | Hierarchy for second scrolled state | Empty collection lower content |

Observed hierarchy landmarks from 01_launch.xml:

- Header content descriptions: Your collection, Collector.
- Disabled notification button is present.
- Hero semantic content: Empty collection, START YOUR COLLECTION, Your collection starts here, Scan a collectible.
- Collection actions group contains Import photo and Open portfolio.
- Collection snapshot appears below the first viewport fold and contains No collectibles saved yet.
- Primary navigation contains Home, Portfolio, Scan, Settings; Home is selected.

Populated state note:

A populated Home state was not safely reproduced in this audit-only pass because creating one would require mutating local app data through scan/save or preference seeding. Existing historical populated captures were not promoted as fresh evidence for this recovery packet.
