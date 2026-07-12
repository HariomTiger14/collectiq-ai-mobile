# S01 behavior-preservation checklist

This checklist was completed before presentation replacement.

- [x] Take a photo: `ScannerController.startCameraScan(context, imageRole: 'front')`.
- [x] Gallery: `ScannerController.pickImageFromGallery(context: context, imageRole: 'front')`.
- [x] Sample: `ScannerController.useSampleScan`.
- [x] Notification: injected nullable `VoidCallback onNotifications`; disabled semantics when absent.
- [x] Active session: any result, captured image, selected path, loading/preparing state, or error hands off to `ScannerScreen`.
- [x] Startup recovery: one post-frame `recoverLostPickerData(reason: 'scan-hub-startup')` call.
- [x] Shell route: `AppShell` selects `ScanHubPage` for Scan and owns all four tab callbacks.
- [x] Scan selected state: `GlassBottomNavBar.currentIndex` comes from `AppShellTabController`.
- [x] Profile: `authControllerProvider`, signed-in `displayName`, first trimmed token.
- [x] Greeting: device-local hour from injected `now`; morning/afternoon/evening; fallback `Collector`.
- [x] Loading/error/disabled: controller state drives active-session handoff; notification remains disabled when callback is null.
- [x] Permissions: remain inside `CameraService`, `GalleryService`, and controller flows.
- [x] Dependencies: Riverpod `scannerControllerProvider` and `authControllerProvider` remain unchanged.
- [x] Analyzer, persistence, portfolio, and result integrations remain downstream of `ScannerScreen`/controller and untouched.
- [x] Existing keys, semantics labels, compatibility keys, and approved copy remain available to tests and automation.
