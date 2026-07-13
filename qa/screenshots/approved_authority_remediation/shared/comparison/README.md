# shared/comparison

Phase 0 comparison result:
- App-level dark runtime background now resolves through the shared dark theme to PackLox approved background tokens.
- Shared raised Material defaults are covered by widget tests so Card, Dialog, BottomSheet, Divider, InputDecoration, and SnackBar do not fall back to default white in dark theme.
- App Shell non-scanner system bars now use dark surfaces with light icons.
- Header SafeArea remains parent-owned; bottom navigation owns bottom gesture clearance.
- Runtime tab-switch and scroll stress completed on RZ8R213M8ZL with after screenshots and logcat captured.

Deferred screen-specific findings:
- Portfolio summary/search/filter chips still show explicit light screen-owned surfaces. This is not treated as a Phase 0 shared default leak and remains in Portfolio authority remediation scope.
- Detail and Scanner authority alignment are not started in Phase 0.
- Shared modal sheet/dialog runtime capture was not successfully reached during this run; those defaults are validated by `test/shared_visual_foundations_test.dart`, and prior runtime sheet/dialog references remain in authority-recovery evidence.

Primary before/context references are listed in `../before/README.md`; after artifacts are listed in `../after/README.md`.
