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
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_hub_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  static const _scanTabIndex = AppShellTabController.scanTab;

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  void _startNewScan() {
    ref.read(scannerControllerProvider.notifier).resetWhenStartingNewScan();
    _selectTab(_scanTabIndex, reason: 'start-new-scan');
  }

  void _startGalleryImport() {
    ref.read(scannerControllerProvider.notifier).resetWhenStartingNewScan();
    _selectTab(_scanTabIndex, reason: 'home-import-photo');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        ref
            .read(scannerControllerProvider.notifier)
            .pickImageFromGallery(context: context),
      );
    });
  }

  void _openPortfolio() {
    _selectTab(AppShellTabController.portfolioTab, reason: 'home-portfolio');
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
  }

  Widget _buildActiveTab(int index) {
    return switch (index) {
      AppShellTabController.homeTab => HomeScreen(
        onScanPressed: _startNewScan,
        onImportPhotoPressed: _startGalleryImport,
        onPortfolioPressed: _openPortfolio,
      ),
      AppShellTabController.portfolioTab => PortfolioScreen(
        onScanPressed: _startNewScan,
      ),
      AppShellTabController.scanTab => ScanHubPage(
        onViewPortfolio: () => _selectTab(
          AppShellTabController.portfolioTab,
          reason: 'scan-view-portfolio',
        ),
      ),
      AppShellTabController.settingsTab => const SettingsScreen(),
      _ => HomeScreen(
        onScanPressed: _startNewScan,
        onImportPhotoPressed: _startGalleryImport,
        onPortfolioPressed: _openPortfolio,
      ),
    };
  }

  List<NavBarItem> get _navItems => const [
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
  ];

  Widget _buildBottomNavigationBar(int selectedIndex) {
    final navigation = GlassBottomNavBar(
      key: const ValueKey('bottom-navigation'),
      currentIndex: selectedIndex,
      onTap: (index) => _selectTab(index, reason: 'bottom-navigation'),
      items: _navItems,
    );
    return selectedIndex == _scanTabIndex
        ? ScannerFocusTheme(child: navigation)
        : navigation;
  }

  @override
  Widget build(BuildContext context) {
    final onboardingCompleted = ref.watch(onboardingControllerProvider);
    final selectedIndex = ref.watch(appShellTabControllerProvider);
    final scannerState = ref.watch(scannerControllerProvider);
    final hasActiveScannerSession =
        scannerState.scanResult != null ||
        scannerState.captureImages.isNotEmpty ||
        scannerState.selectedImagePath != null ||
        scannerState.isLoading ||
        scannerState.isPreparingImage ||
        scannerState.errorMessage != null;
    final hideBottomNavigation =
        selectedIndex == _scanTabIndex &&
        hasActiveScannerSession &&
        scannerState.scanResult == null;

    return onboardingCompleted.when(
      data: (completed) {
        if (!completed) {
          return OnboardingScreen(
            onStartScanning: _completeOnboardingAndStartScan,
            onExploreDashboard: _completeOnboardingAndExploreDashboard,
          );
        }

        final scannerSelected = selectedIndex == _scanTabIndex;
        final shellBackground = scannerSelected
            ? ScannerVisualTheme.background
            : Theme.of(context).scaffoldBackgroundColor;
        final overlayStyle = scannerSelected
            ? const SystemUiOverlayStyle(
                statusBarColor: ScannerVisualTheme.background,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: ScannerVisualTheme.backgroundDeep,
                systemNavigationBarDividerColor:
                    ScannerVisualTheme.backgroundDeep,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarContrastEnforced: false,
              )
            : SystemUiOverlayStyle.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Scaffold(
            key: const ValueKey('app-shell'),
            backgroundColor: shellBackground,
            body: _buildActiveTab(selectedIndex),
            bottomNavigationBar: hideBottomNavigation
                ? null
                : _buildBottomNavigationBar(selectedIndex),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        key: const ValueKey('app-shell'),
        body: const HomeScreen(),
        bottomNavigationBar: _buildBottomNavigationBar(selectedIndex),
      ),
    );
  }
}
