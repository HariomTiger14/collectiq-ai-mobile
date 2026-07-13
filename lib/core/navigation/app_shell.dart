import 'dart:async';

import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/navigation/app_shell_destination.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_bootstrap_surface.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
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
  final PageStorageBucket _shellPageStorageBucket = PageStorageBucket();

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

  List<AppShellDestination> get _destinations => [
    AppShellDestination(
      index: AppShellTabController.homeTab,
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      builder: (_) => HomeScreen(
        onScanPressed: _startNewScan,
        onImportPhotoPressed: _startGalleryImport,
        onPortfolioPressed: _openPortfolio,
      ),
    ),
    AppShellDestination(
      index: AppShellTabController.portfolioTab,
      label: 'Portfolio',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      builder: (_) => PortfolioScreen(onScanPressed: _startNewScan),
    ),
    AppShellDestination(
      index: AppShellTabController.scanTab,
      label: 'Scan',
      icon: Icons.camera_alt_outlined,
      selectedIcon: Icons.camera_alt_rounded,
      builder: (_) => ScanHubPage(
        onViewPortfolio: () => _selectTab(
          AppShellTabController.portfolioTab,
          reason: 'scan-view-portfolio',
        ),
      ),
    ),
    const AppShellDestination(
      index: AppShellTabController.settingsTab,
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      builder: _buildSettingsDestination,
    ),
  ];

  static Widget _buildSettingsDestination(BuildContext context) {
    return const SettingsScreen();
  }

  AppShellDestination _destinationFor(int index) {
    return _destinations.firstWhere(
      (destination) => destination.index == index,
      orElse: () => _destinations.first,
    );
  }

  Widget _buildActiveDestination(AppShellDestination destination) {
    return PageStorage(
      bucket: _shellPageStorageBucket,
      child: KeyedSubtree(
        key: ValueKey('shell-destination-${destination.label.toLowerCase()}'),
        child: destination.builder(context),
      ),
    );
  }

  Widget _buildBottomNavigationBar(int selectedIndex) {
    final navigation = GlassBottomNavBar(
      key: const ValueKey('bottom-navigation'),
      currentIndex: selectedIndex,
      onTap: (index) => _selectTab(index, reason: 'bottom-navigation'),
      items: [
        for (final destination in _destinations)
          NavBarItem(
            key: ValueKey('nav-${destination.label.toLowerCase()}'),
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
            label: destination.label,
            isActive: false,
          ),
      ],
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
          return PackLoxEntryTransition(
            stateKey: 'entry-onboarding',
            child: OnboardingScreen(
              onStartScanning: _completeOnboardingAndStartScan,
              onExploreDashboard: _completeOnboardingAndExploreDashboard,
            ),
          );
        }

        final scannerSelected = selectedIndex == _scanTabIndex;
        final selectedDestination = _destinationFor(selectedIndex);
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
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: PackLoxTokens.background,
                systemNavigationBarDividerColor: PackLoxTokens.background,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarContrastEnforced: false,
              );

        return PackLoxEntryTransition(
          stateKey: 'entry-shell',
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: Scaffold(
              key: const ValueKey('app-shell'),
              backgroundColor: shellBackground,
              body: _buildActiveDestination(selectedDestination),
              bottomNavigationBar: hideBottomNavigation
                  ? null
                  : _buildBottomNavigationBar(selectedIndex),
            ),
          ),
        );
      },
      loading: () => const PackLoxEntryTransition(
        stateKey: 'entry-loading',
        child: Scaffold(body: PackLoxBootstrapSurface.loading()),
      ),
      error: (_, _) => PackLoxEntryTransition(
        stateKey: 'entry-error',
        child: Scaffold(
          key: const ValueKey('app-shell'),
          body: PackLoxBootstrapSurface.recoverableError(
            onRetry: () => ref.invalidate(onboardingControllerProvider),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(selectedIndex),
        ),
      ),
    );
  }
}
