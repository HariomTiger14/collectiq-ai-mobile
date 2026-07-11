# Scanner S01 visual-language gap report

Date: 2026-07-12

This report was completed before implementation. The approved Design Bible crop is the visual authority; the latest Samsung runtime is `qa/engineering_platform/shared_shell_s01/runtime_after.png`.

| Classification | Region | Remaining difference | Refinement decision |
|---|---|---|---|
| Critical | None | The prior shared-shell and bottom-inset blocker is resolved. | No critical implementation work. |
| Major | Greeting hierarchy | The 2 px period-to-name gap feels cramped while the 24 px header-to-hero gap is comparatively loose. The two-line greeting does not have the relaxed internal rhythm of the reference. | Use responsive, text-scale-aware internal spacing and rebalance the following gap. |
| Major | Icon language | S01 uses outlined Material glyphs, but their apparent bounds and weights are not explicitly coordinated. | Standardise visible S01 icons on the existing Material outlined family with explicit optical sizes. |
| Major | Component rhythm | Hero and entry primitives are responsive, but their internal proportions remain heavier than the approved compact visual language. | Refine reusable primitive padding, minimum sizes, and text leading without changing copy or behavior. |
| Minor | Notification | The 48 logical-pixel control is accessible but its glyph reads too strongly against the greeting. | Preserve the touch target and reduce only optical glyph emphasis. |
| Minor | Hero | Copy and scanner glyph compete for attention; subtitle leading is slightly loose. | Preserve geometry and copy while refining optical size, spacing, and line height. |
| Minor | Entry tiles | Titles and subtitles are separated by only 2 px, producing cramped baselines; icon boxes are visually dense. | Add token-derived breathing room and rebalance icon/container sizes. |
| Minor | Navigation | Shared navigation icons are visually heavier than content icons. | Document only; navigation is shared and already contract-compliant. |
| Ignore | Device chrome | Samsung status-bar metrics, three-button navigation, font rasterisation, and live clock differ from the reference artwork. | Accept as platform variation. |
| Ignore | Exact pixels | The source crop is 124 x 315 while runtime is a live high-DPI device capture. | Judge hierarchy, proportion, rhythm, and balance rather than raster equality. |

## Guardrails

- Preserve the shared shell, navigation ownership, scanner actions, copy, semantics, and dynamic greeting.
- Keep content-driven heights, scrolling, runtime SafeArea behavior, and 360/390/412/430 logical-width support.
- Do not introduce a new icon package or change unresolved Design Bible gradient values.
