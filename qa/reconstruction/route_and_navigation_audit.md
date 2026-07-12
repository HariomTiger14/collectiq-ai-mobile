# Route and navigation audit

Architecture is a single unnamed `MaterialApp.home` with Riverpod tab state and direct `Navigator.push(MaterialPageRoute)` calls. There are no named routes, GoRouter, guards, auth redirects, or web route table.

Canonical contracts: `AppShellTabController` indices Home 0, Portfolio 1, Scan 2, Settings 3; settings pushes `CloudSyncScreen` and `AboutScreen`; portfolio/home push `CollectibleDetailPage`; `CameraService` pushes `CameraCapturePage`; review pushes `ImageEnhancementPreviewPage`. Portfolio uses delete dialogs plus filter/sort sheets; scanner uses edit/guidance sheets/dialogs. Active scanner state hides bottom navigation until a result and resets on leaving Scan.

Findings: authentication bypasses any entry guard by design; pushed pages bypass the shell body but correctly retain Navigator back behavior; transitions are default Material and not centrally controlled. `HomeScreen`/`HomePage` is a harmless alias. Scanner has ambiguous legacy ownership across two `scanner_screen.dart` files, `ScanHubPage`, `ScanWorkspaceScreen`, result page and inline result widgets. Search and notification routes do not exist. Password recovery has a web redirect but no mobile route. Email confirmation changes state without navigation, so feedback may be invisible until Settings.

Recommendation: **A—replace existing pages in place**, preserving widget constructors, provider contracts, tab indices and direct push destinations. Add versioned routing only if a screen requires parallel runtime approval; do not introduce a new router during visual reconstruction. Stabilize tests around semantic destinations before each replacement.

