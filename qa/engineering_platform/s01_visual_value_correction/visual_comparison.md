# Visual comparison

`runtime_before.png` is copied from the provenance audit and intentionally includes its magenta route probe. Use the S01 content below that probe for comparison. `runtime_after.png` is a fresh probe-free capture from the clean-installed value-correction APK.

Visible changes:

- Greeting spacing: outer top rhythm increases to 24 logical px; the greeting/name group uses an explicit 8px gap and 28px name line box.
- Header→hero: increases from 16 to 24 logical px on the captured device.
- Hero proportions: the prior taller content-led card is replaced by a 2.25–2.55 bounded card; the captured hero is visibly shorter and more deliberate.
- Hero grid: title region narrows from 64% to 56%, preserving the reference two-line title while allowing a wider subtitle column.
- Hero icon: 42→44 and remains optically centered in the trailing region.
- Option rhythm: hero→heading increases 16→24.
- Tile anatomy: page margins increase to 24 and icon→text separation increases 12→16, making the icon cell and text block read as distinct anatomy rather than a generic list tile.
- Icon treatment: gallery changes from a photo-library glyph to the approved-meaning image-frame outline.
- Typography rhythm: name line box 26→28; title/subtitle remain 32/20 line boxes with fixed 8px hierarchy gap.

The fresh hierarchy confirms `Good afternoon, Collector`, the two-line hero title, all three entry actions, selected Scan navigation, and package `com.collectiq.ai.sit`.
