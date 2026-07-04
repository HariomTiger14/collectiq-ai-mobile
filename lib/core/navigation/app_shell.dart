import 'dart:async';

import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/home/presentation/home_screen.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
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
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      unawaited(
        ref
            .read(appTelemetryServiceProvider)
            .trackEvent(
              TelemetryEventNames.appOpen,
              properties: const {'surface': 'app_shell'},
            ),
      );
    });
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

  Future<void> _completeOnboardingAndStartScan() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (!mounted) {
      return;
    }
    _startNewScan();
  }

  Future<void> _completeOnboardingAndExploreDashboard() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (!mounted) {
      return;
    }
    _selectTab(AppShellTabController.homeTab, reason: 'onboarding-dashboard');
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
    final onboardingCompleted = ref.watch(onboardingControllerProvider);
    final selectedIndex = ref.watch(appShellTabControllerProvider);
    final tabs = <Widget>[
      KeyedSubtree(
        key: const ValueKey('screen-home'),
        child: HomeScreen(onScanPressed: _startNewScan),
      ),
      KeyedSubtree(
        key: const ValueKey('screen-portfolio'),
        child: PortfolioScreen(onScanPressed: _startNewScan),
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
      const KeyedSubtree(
        key: ValueKey('screen-settings'),
        child: SettingsScreen(),
      ),
    ];

    final shell = Scaffold(
      key: const ValueKey('app-shell'),
      body: IndexedStack(
        key: const ValueKey('app-shell-indexed-stack'),
        index: selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: GlassBottomNavBar(
        key: const ValueKey('bottom-navigation'),
        currentIndex: selectedIndex,
        onTap: (index) => _selectTab(index, reason: 'bottom-navigation'),
        items: const [
          NavBarItem(
            key: ValueKey('nav-home'),
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: false,
          ),
          NavBarItem(
            key: ValueKey('nav-portfolio'),
            icon: Icons.inventory_2_rounded,
            label: 'Portfolio',
            isActive: false,
          ),
          NavBarItem(
            key: ValueKey('nav-scan'),
            icon: Icons.camera_alt_rounded,
            label: 'Scan',
            isActive: false,
            gradientStyle: GradientStyle.purpleDeepBlue,
          ),
          NavBarItem(
            key: ValueKey('nav-settings'),
            icon: Icons.settings_rounded,
            label: 'Settings',
            isActive: false,
          ),
        ],
      ),
    );

    return onboardingCompleted.when(
      data: (completed) {
        if (completed) {
          return shell;
        }

        return OnboardingScreen(
          onStartScanning: _completeOnboardingAndStartScan,
          onExploreDashboard: _completeOnboardingAndExploreDashboard,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => shell,
    );
  }
}
