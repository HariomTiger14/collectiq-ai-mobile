# S01 reconstruction source of truth

Date: 2026-07-12

## Repository safety baseline

- Engineering Platform: `master`, `2f872983813bd7687befcdf72c712c6c7acc9309`, clean, no staged/unstaged/untracked files.
- Flutter: `main`, `b6e56ab097a059f883a10ec661d48a1d8b62b2d4`, no staged files; extensive unrelated unstaged backend, AI, portfolio, scanner-flow, platform-generated, and test work plus extensive untracked assets/QA evidence.
- Risk: broad staging or cleanup would capture unrelated user work. Only explicit S01 presentation, focused test, and reconstruction-report paths may be staged.

## Authority order

1. Approved `Volume_03_Scanner/screens/01_scan_hub.png` and full Scanner flow board.
2. S01 Screen Intelligence content, component tree, token bindings, responsive, accessibility, ownership, and visual-acceptance contracts.
3. Foundation tokens and canonical greeting, notification, scan-entry-card, and bottom-navigation definitions.
4. Product Intelligence behavior/workflow and Platform Core traceability.
5. Flutter Intelligence mapping for `ScanHubPage`, `ScannerController`, `AppShell`, and `GlassBottomNavBar`.
6. Latest Samsung evidence and prior reports as implementation evidence, never as design authority.

## Contract summary

- Page and system inset are near-black; no light bottom strip is permitted.
- Content order is header, hero, option heading, three entry tiles, shared navigation.
- Horizontal padding is 16 logical pixels; vertical rhythm follows the 8-point system.
- Foundation type is 24/32 display, 16/22 heading, 14/20 body, and 10/14 overline.
- Hero and tiles use large 12 logical-pixel radii; tiles use Surface 1 and border treatment.
- Icons use line forms with rounded corners. Exact gradient stops and per-tile icon colour remain unresolved.
- Heights are content-driven; supported widths are 360/390/412/430; text must remain usable at 200%.
- Shared `AppShell`/`GlassBottomNavBar` owns navigation and bottom safe-area painting.
