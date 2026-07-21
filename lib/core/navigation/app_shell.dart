import 'dart:async';

import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/navigation/app_shell_destination.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_bootstrap_surface.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/guest_mode_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:collectiq_ai/features/home/presentation/home_screen.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_hub_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:collectiq_ai/features/search/presentation/search_screen.dart';
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

  void _chooseGuestMode() {
    unawaited(ref.read(guestModeControllerProvider.notifier).chooseGuestMode());
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
      iconAsset: PackLoxAssets.navHome,
      builder: (_) => HomeScreen(
        onScanPressed: _startNewScan,
        onImportPhotoPressed: _startGalleryImport,
        onPortfolioPressed: _openPortfolio,
      ),
    ),
    AppShellDestination(
      index: AppShellTabController.scanTab,
      label: 'Scan',
      icon: Icons.camera_alt_outlined,
      selectedIcon: Icons.camera_alt_rounded,
      iconAsset: PackLoxAssets.navScan,
      builder: (_) => ScanHubPage(
        onViewPortfolio: () => _selectTab(
          AppShellTabController.portfolioTab,
          reason: 'scan-view-portfolio',
        ),
      ),
    ),
    AppShellDestination(
      index: AppShellTabController.portfolioTab,
      label: 'Portfolio',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      iconAsset: PackLoxAssets.navPortfolio,
      builder: (_) => PortfolioScreen(onScanPressed: _startNewScan),
    ),
    const AppShellDestination(
      index: AppShellTabController.searchTab,
      label: 'Search',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search_rounded,
      builder: _buildSearchDestination,
    ),
    const AppShellDestination(
      index: AppShellTabController.settingsTab,
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      iconAsset: PackLoxAssets.navSettings,
      builder: _buildSettingsDestination,
    ),
  ];

  static Widget _buildSettingsDestination(BuildContext context) {
    return const SettingsScreen();
  }

  static Widget _buildSearchDestination(BuildContext context) {
    return const SearchScreen();
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
            iconAsset: destination.iconAsset,
            label: destination.label,
            isActive: false,
          ),
      ],
    );
    return selectedIndex == _scanTabIndex
        ? ScannerFocusTheme(child: navigation)
        : navigation;
  }

  Widget _buildOnboardingEntry() {
    return PackLoxEntryTransition(
      stateKey: 'entry-onboarding',
      child: OnboardingScreen(
        onStartScanning: _completeOnboardingAndStartScan,
        onExploreDashboard: _completeOnboardingAndExploreDashboard,
      ),
    );
  }

  Widget _buildShellEntry({
    required int selectedIndex,
    required bool hideBottomNavigation,
  }) {
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
            systemNavigationBarDividerColor: ScannerVisualTheme.backgroundDeep,
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
          extendBody: true,
          backgroundColor: shellBackground,
          body: _buildActiveDestination(selectedDestination),
          bottomNavigationBar: hideBottomNavigation
              ? null
              : _buildBottomNavigationBar(selectedIndex),
        ),
      ),
    );
  }

  Widget _buildLoadingEntry() {
    return const PackLoxEntryTransition(
      stateKey: 'entry-loading',
      child: Scaffold(body: PackLoxBootstrapSurface.loading()),
    );
  }

  Widget _buildEntryError({
    required int selectedIndex,
    required VoidCallback onRetry,
  }) {
    return PackLoxEntryTransition(
      stateKey: 'entry-error',
      child: Scaffold(
        key: const ValueKey('app-shell'),
        body: PackLoxBootstrapSurface.recoverableError(onRetry: onRetry),
        bottomNavigationBar: _buildBottomNavigationBar(selectedIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final guestMode = ref.watch(guestModeControllerProvider);
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

    return guestMode.when(
      data: (guestModeChosen) {
        final authResolving =
            authState.isLoading ||
            authState.status == AuthFlowStatus.sessionRestoring;
        if (authResolving) {
          return _buildLoadingEntry();
        }

        if (authState.isSignedIn) {
          return _buildShellEntry(
            selectedIndex: selectedIndex,
            hideBottomNavigation: hideBottomNavigation,
          );
        }

        if (!guestModeChosen) {
          return PackLoxEntryTransition(
            stateKey: 'entry-auth-welcome',
            child: AuthWelcomeScreen(onExploreAsGuest: _chooseGuestMode),
          );
        }

        return onboardingCompleted.when(
          data: (completed) {
            if (!completed) {
              return _buildOnboardingEntry();
            }
            return _buildShellEntry(
              selectedIndex: selectedIndex,
              hideBottomNavigation: hideBottomNavigation,
            );
          },
          loading: _buildLoadingEntry,
          error: (_, _) => _buildEntryError(
            selectedIndex: selectedIndex,
            onRetry: () => ref.invalidate(onboardingControllerProvider),
          ),
        );
      },
      loading: _buildLoadingEntry,
      error: (_, _) => _buildEntryError(
        selectedIndex: selectedIndex,
        onRetry: () => ref.invalidate(guestModeControllerProvider),
      ),
    );
  }
}
