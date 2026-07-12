# Remaining variances

- Exact icon family remains provisional in `icon_language.json`; Material outlined/rounded glyphs are used without claiming exact asset fidelity.
- Exact hero gradient stops remain provisional; existing `#123C8F → #082C67` stops were retained.
- The low-resolution approved crop cannot establish subpixel glyph metrics. Normal-scale hero copy therefore preserves authored two-line breaks, while large text reflows.
- Navigation remains 70px rather than the provisional 72px preference. It is inside the declared 64–88 range and was explicitly verification-only for this sprint.
- The Samsung is a tall three-button-navigation context, so the large flexible gap between content and shell navigation is device/layout-height behavior, not a blocker.

No remaining variance is classified as a major visual mismatch or blocker. Exact icon/gradient approval can occur in a future evidence-backed asset review without reopening S01 layout geometry.
