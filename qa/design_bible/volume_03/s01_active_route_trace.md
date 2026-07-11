# S01 active route trace

## Runtime path

1. `lib/core/navigation/app_shell.dart` — `AppShell._buildBottomNavigationBar` renders `GlassBottomNavBar`; the Scan item selects `AppShellTabController.scanTab`.
2. `lib/core/navigation/app_shell.dart` — `AppShell._buildActiveTab` maps `scanTab` directly to `ScanHubPage`.
3. `lib/features/scanner/presentation/pages/scan_hub_page.dart` — `ScanHubPage` is the first rendered scanner widget while scanner state is idle.
4. `ScanHubPage` watches `scannerControllerProvider`. Once a result, capture, selected image, loading/preparation state, or error exists, it hands off to `ScannerScreen`.
5. `ScanHubPage._startCameraScan` calls `ScannerController.startCameraScan(context, imageRole: 'front')`, which launches the existing camera flow.
6. `ScanHubPage._pickFromGallery` calls `ScannerController.pickImageFromGallery(context: context, imageRole: 'front')`.
7. The sample action calls `ScannerController.useSampleScan`.

## Flags and duplicates

No feature flag gates the Scan-tab mapping. `lib/features/scanner/presentation/scanner_screen.dart` is an export shim for `pages/scanner_screen.dart`; it is not a second hub. `ScannerScreen` and `ScanWorkspaceScreen` are active-session/workspace implementations, not S01. The current device can show workspace UI if scanner controller state persists as active, but the Scan tab itself does not point at an obsolete route.

## Change boundary

Visual changes are confined to `scan_hub_page.dart` and its focused test. Business logic remains in `scanner_controller.dart`, scanner services, repositories, analyzer code, and active-session screens and is intentionally unchanged.
