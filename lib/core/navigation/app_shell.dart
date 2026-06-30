import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/home/presentation/home_screen.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_screen.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with RestorationMixin, WidgetsBindingObserver {
  static const _scanTabIndex = AppShellTabController.scanTab;
  final RestorableInt _restoredIndex = RestorableInt(
    AppShellTabController.homeTab,
  );

  @override
  String? get restorationId => 'app_shell';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restoredIndex, 'selected_tab_index');
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      ref
          .read(appShellTabControllerProvider.notifier)
          .selectTab(_restoredIndex.value, reason: 'state-restoration');
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoredIndex.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(
      '[AppShell] lifecycle $state selectedTab='
      '${ref.read(appShellTabControllerProvider)}',
    );
  }

  void _startNewScan() {
    debugPrint(
      '[AppShell] Home/CTA starting new scan from tab '
      '${ref.read(appShellTabControllerProvider)}',
    );
    ref.read(scannerControllerProvider.notifier).resetWhenStartingNewScan();
    _selectTab(_scanTabIndex, reason: 'start-new-scan');
  }

  void _selectTab(int index, {String reason = 'navigation'}) {
    final previousIndex = ref.read(appShellTabControllerProvider);
    if (previousIndex == _scanTabIndex && index != _scanTabIndex) {
      ref.read(scannerControllerProvider.notifier).resetAfterSaved();
    }

    ref
        .read(appShellTabControllerProvider.notifier)
        .selectTab(index, reason: reason);
    _restoredIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(appShellTabControllerProvider);
    final tabs = <Widget>[
      KeyedSubtree(
        key: const ValueKey('screen-home'),
        child: HomeScreen(onScanPressed: _startNewScan),
      ),
      KeyedSubtree(
        key: const ValueKey('screen-scan'),
        child: ScannerScreen(
          onViewPortfolio: () => _selectTab(
            AppShellTabController.portfolioTab,
            reason: 'scan-view-portfolio',
          ),
        ),
      ),
      KeyedSubtree(
        key: const ValueKey('screen-portfolio'),
        child: PortfolioScreen(onScanPressed: _startNewScan),
      ),
      const KeyedSubtree(
        key: ValueKey('screen-settings'),
        child: SettingsScreen(),
      ),
    ];

    return Scaffold(
      key: const ValueKey('app-shell'),
      body: IndexedStack(
        key: const ValueKey('app-shell-indexed-stack'),
        index: selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('bottom-navigation'),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            _selectTab(index, reason: 'bottom-navigation'),
        destinations: const [
          NavigationDestination(
            key: ValueKey('nav-home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            key: ValueKey('nav-scan'),
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            key: ValueKey('nav-portfolio'),
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Portfolio',
          ),
          NavigationDestination(
            key: ValueKey('nav-settings'),
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
