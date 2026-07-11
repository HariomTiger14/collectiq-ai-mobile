# Shared Shell and Scanner S01 Gap Report

Date: 2026-07-12

Reference: Engineering Platform extracted `Volume_03_Scanner/screens/01_scan_hub.png`

Runtime: `qa/s01_platform_validation_samsung.png`, Samsung SM-E625F

This report was created before implementation. The extracted S01 image is the primary visual authority. The screen contracts explicitly leave the hero gradient, some icon treatments, and shared-shell ownership details unresolved; those values are identified as provisional below.

## Repository baseline

| Repository | Branch | HEAD | Staged | Unstaged | Untracked | State |
|---|---|---|---|---|---|---|
| Engineering Platform | `master` | `2f872983813bd7687befcdf72c712c6c7acc9309` | none | none | none | clean |
| Flutter | `main` | `08cf0ef49fe3bd40bb27a3d8f2c7a9e2f42b0c0a` | none | many pre-existing files, including `app_shell.dart` and `glass_bottom_nav_bar.dart` | many pre-existing files, including scanner theme and QA assets | dirty |

The complete Flutter baseline is retained in `git_status.txt`. No pre-existing work may be discarded or broadly staged.

## Current ownership trace

`AppShell.build` owns the root `Scaffold`, active-tab body, and `bottomNavigationBar`. `AppShell._buildActiveTab` selects `ScanHubPage`; `_buildBottomNavigationBar` selects and themes `GlassBottomNavBar`. `GlassBottomNavBar.build` currently owns the bottom `SafeArea`, external minimum margin, rounded navigation container, and selected item rendering. `ScanHubPage` owns its page scaffold/background and top safe area only.

The root scaffold has no explicit dark background. The navigation's `SafeArea` is outside its rounded dark container and does not paint a background. Consequently the root scaffold/theme surface is visible in the outer margins and bottom inset. No application-level `SystemUiOverlayStyle` currently binds Android status/navigation colors to this composition.

## Gap matrix

| Region | Reference expectation | Current Samsung runtime | Owner | Severity | Intended fix location | Platform-defined? |
|---|---|---|---|---|---|---|
| Top safe area | Dark background through runtime inset; reference 44 px is illustrative | Dark, but status icons have low/incorrect contrast | shared shell/system | major | `AppShell` system overlay | Partly; inset rule yes, exact overlay unresolved |
| Greeting/header | Compact top-led greeting; secondary period, strong first name | Content correct but substantially oversized and vertically loose | scanner/shared greeting primitive | major | scanner header primitive | Semantic types only; exact geometry from reference |
| Notification | Small aligned outline bell with 44 px tap target | 48 px control appears visually oversized/dim | scanner header primitive | minor | scanner header primitive | Component and icon style; exact geometry not measured |
| Scanner hero | Compact full-width blue card, large radius/border, left copy and right scan icon | Card is much taller and text/icon scale larger than reference | scanner hero primitive | major | reusable scanner hero | Background/radius tokens; gradient unresolved/provisional |
| Section heading | Compact heading and token gap | Heading too large with excess vertical gap | scanner section primitive | major | reusable scanner section heading | Typography/spacing tokens |
| Action tiles | Three compact cards, outlined icon boxes, title/subtitle hierarchy | Tiles are much taller and typography/icon boxes oversized | scanner entry primitives | major | reusable scanner entry tile/icon | Card/radius tokens; exact icon colours unresolved |
| Bottom navigation | Shared dark compact navigation, Scan selected | Dark rounded nav exists but is oversized and floats inside a light parent | shared shell/navigation | blocker | `AppShell` + `GlassBottomNavBar` | Canonical component exists; exact measured geometry absent |
| Bottom system inset | One intentional dark composition through device inset | White strip surrounds nav and separates it from black system bar | shared shell/system | blocker | shell background, SafeArea owner, overlay style | Dark surface requirement explicit; implementation owner unresolved |
| Vertical rhythm | All S01 content and navigation visible in compact reference viewport | Large fixed-looking geometry pushes nav far below content and leaves disproportionate whitespace | scanner primitives/shared nav | major | tokenized primitive spacing | 8-point/token behavior defined; exact values inferred |
| Typography | Foundation semantic hierarchy at compact approved density | Runtime type is significantly larger/bolder | scanner primitives | major | primitive text bindings | Semantic tokens defined; exact sizes not machine-measured |
| Copy | Contract-driven dynamic greeting and approved action copy | Correct after prior S01 sprint | scanner content/auth | acceptable | no change | Yes |
| Border radius | Approved large hero/tile radius, compact nav radius | General shape matches; runtime scale/radius feels oversized | scanner/nav primitives | minor | token bindings | Radius tokens defined |
| Icon containers | Compact outlined square boxes | Boxes and icons are oversized | scanner entry icon primitive | major | reusable icon container | Treatment partly unresolved |
| Colours | Near-black page, blue hero, dark tiles/navigation, no light bottom surface | Screen colours broadly match; white bottom parent violates exact-colour region | shared shell/scanner theme | blocker | shell surface and system overlay | Core colours defined; gradient unresolved |
| Responsive behavior | 360/390/412/430, content-driven tiles, wrapping, scroll, runtime insets | Only 360 widget coverage; current scale risks height/text failures | scanner page/primitives/tests | major | responsive widget tests and content-driven constraints | Explicit |

## Pre-implementation decision

Implementation may proceed only at the shared shell/navigation owner for the bottom defect and through reusable Scanner S01 primitives for feature geometry. No scanner-only bottom patch is permitted. Unresolved gradient and icon values will remain explicitly provisional rather than being represented as contract-defined.
