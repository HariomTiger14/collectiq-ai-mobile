# Platform Feedback: Shared Shell and Scanner S01

## Missing token

A named token for the shared bottom safe-area/system-inset surface and Android navigation divider is absent. Recommendation: bind both to an approved dark shell surface token with light/dark-mode rules.

## Missing canonical component detail

Bottom navigation is canonical but has no measured anatomy. Recommendation: encode container height, external margins, internal padding, indicator geometry, icon/label type, and allowed safe-area expansion.

## Missing ownership rule

S01 identifies shell/system ownership as unresolved. Recommendation: map `AppShell` to root scaffold/background/system overlay and `GlassBottomNavBar` to navigation container plus bottom SafeArea.

## Missing safe-area rule

Recommendation: state that the navigation parent must paint continuously through external margins and runtime bottom inset, and define gesture/three-button behavior.

## Missing responsive rule

Recommendation: specify how navigation label scaling and container height respond to text scale while retaining 44 px tap targets.

## Missing visual tolerance

Pixel, geometry, and colour tolerances are null. Recommendation: publish normalized region tolerances for the extracted reference and a declared Samsung baseline.

## Provisional S01 values

Hero gradient stops and per-entry icon treatments remain explicitly unresolved. Approve and encode them before exact-fidelity certification.
