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

class _AppShellState extends ConsumerState<AppShell> with RestorationMixin {
  final RestorableInt _selectedIndex = RestorableInt(0);

  @override
  String? get restorationId => 'app_shell';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedIndex, 'selected_tab_index');
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  void _startNewScan() {
    ref.read(scannerControllerProvider.notifier).resetWhenStartingNewScan();
    _selectTab(1);
  }

  void _selectTab(int index) {
    if (_selectedIndex.value == 1 && index != 1) {
      ref.read(scannerControllerProvider.notifier).resetAfterSaved();
    }

    setState(() {
      _selectedIndex.value = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeScreen(onScanPressed: _startNewScan),
      ScannerScreen(onViewPortfolio: () => _selectTab(2)),
      PortfolioScreen(onScanPressed: _startNewScan),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex.value, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex.value,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
