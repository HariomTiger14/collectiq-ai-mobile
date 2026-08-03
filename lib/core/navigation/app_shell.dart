import 'dart:async';

import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/navigation/app_shell_destination.dart';
import 'package:collectiq_ai/core/navigation/push_notification_navigation.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_bootstrap_surface.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/home_dashboard_providers.dart';
import 'package:collectiq_ai/features/home/presentation/home_screen.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_hub_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:collectiq_ai/features/search/presentation/search_screen.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
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
  final PushNotificationNavigationCoordinator
  _pushNotificationNavigationCoordinator =
      PushNotificationNavigationCoordinator();
  String? _lastPostSignInSyncUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      unawaited(
        _pushNotificationNavigationCoordinator.start(
          onIntent: _handlePushNotificationNavigationIntent,
        ),
      );
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
    unawaited(_pushNotificationNavigationCoordinator.dispose());
    super.dispose();
  }

  // Re-sync the cloud portfolio when the app returns to the foreground so that
  // server-side changes made while backgrounded (fresh valuations, newly
  // triggered price alerts) surface promptly on reopen — not only on a full
  // relaunch. Throttled via the shared marker so a quick background/foreground
  // toggle doesn't hammer the network.
  static const _resumeSyncThrottle = Duration(minutes: 2);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _maybeSyncOnResume();
    }
  }

  void _maybeSyncOnResume() {
    if (!ref.read(authControllerProvider).isSignedIn) {
      return;
    }
    final last = ref.read(homeLastAutoSyncProvider);
    final now = DateTime.now();
    if (last != null && now.difference(last) < _resumeSyncThrottle) {
      return;
    }
    ref.read(homeLastAutoSyncProvider.notifier).mark(now);
    unawaited(
      ref.read(portfolioControllerProvider.notifier).syncCloudPortfolioNow(),
    );
  }

  void _startNewScan() {
    ref.read(scannerControllerProvider.notifier).resetWhenStartingNewScan();
    _selectTab(_scanTabIndex, reason: 'start-new-scan');
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

  void _handleAuthChanged(AuthState? previous, AuthState next) {
    if (!next.isSignedIn) {
      _lastPostSignInSyncUserId = null;
      return;
    }

    final userId = next.user?.id;
    if (userId == null ||
        userId.isEmpty ||
        _lastPostSignInSyncUserId == userId) {
      return;
    }
    _lastPostSignInSyncUserId = userId;
    unawaited(_syncLocalPortfolioAfterSignIn(userId: userId));
  }

  Future<void> _syncLocalPortfolioAfterSignIn({required String userId}) async {
    try {
      await ref.read(portfolioControllerProvider.notifier).loadItems();
      await ref
          .read(portfolioControllerProvider.notifier)
          .syncCloudPortfolioNow();
      await ref.read(syncControllerProvider.notifier).loadStatus();
      unawaited(
        ref
            .read(appTelemetryServiceProvider)
            .trackEvent(
              'auth_post_sign_in_portfolio_sync',
              properties: {'user_id_present': userId.isNotEmpty},
            ),
      );
    } on Object catch (error, stackTrace) {
      unawaited(
        ref
            .read(appTelemetryServiceProvider)
            .recordNonFatalError(
              error,
              stackTrace: stackTrace,
              reason: 'auth_post_sign_in_portfolio_sync_failed',
            ),
      );
    }
  }

  Future<void> _handlePushNotificationNavigationIntent(
    PushNotificationNavigationIntent intent,
  ) async {
    if (!mounted) {
      return;
    }
    switch (intent.target) {
      case PushNotificationNavigationTarget.settings:
        _selectTab(
          AppShellTabController.settingsTab,
          reason: 'push-notification-test',
        );
        _popToShellRoot();
      case PushNotificationNavigationTarget.home:
        _selectTab(
          AppShellTabController.homeTab,
          reason: 'push-notification-home',
        );
        _popToShellRoot();
      case PushNotificationNavigationTarget.portfolioItem:
        await _openPortfolioItemFromPush(intent.portfolioItemId);
    }
  }

  Future<void> _openPortfolioItemFromPush(String? itemId) async {
    if (itemId == null || itemId.isEmpty) {
      _selectTab(
        AppShellTabController.portfolioTab,
        reason: 'push-notification-missing-item-id',
      );
      _showShellSnackBar('Price alert item is no longer available.');
      return;
    }

    await ref.read(portfolioControllerProvider.notifier).syncCloudPortfolioNow();
    if (!mounted) {
      return;
    }
    final item = ref
        .read(portfolioControllerProvider)
        .items
        .where((candidate) => candidate.id == itemId)
        .firstOrNull;

    _selectTab(
      AppShellTabController.portfolioTab,
      reason: 'push-notification-price-alert',
    );
    _popToShellRoot();

    if (item == null) {
      _showShellSnackBar('Price alert item is no longer available.');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _pushPortfolioDetail(item);
    });
  }

  void _pushPortfolioDetail(CollectibleItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectibleDetailPage(
          item: item,
          onDelete: (itemId) async {
            await ref
                .read(portfolioControllerProvider.notifier)
                .removeItem(itemId);
            return true;
          },
        ),
        settings: RouteSettings(name: '/portfolio/${item.id}'),
      ),
    );
  }

  void _popToShellRoot() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showShellSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
          body: Stack(
            children: [
              Positioned.fill(
                child: _buildActiveDestination(selectedDestination),
              ),
              if (!hideBottomNavigation)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomNavigationBar(selectedIndex),
                ),
            ],
          ),
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
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: PackLoxBootstrapSurface.recoverableError(onRetry: onRetry),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNavigationBar(selectedIndex),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, _handleAuthChanged);

    final authState = ref.watch(authControllerProvider);
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
        selectedIndex == _scanTabIndex && hasActiveScannerSession;

    final authResolving =
        authState.isLoading ||
        authState.status == AuthFlowStatus.sessionRestoring;
    if (authResolving) {
      return _buildLoadingEntry();
    }

    if (!authState.isSignedIn) {
      return const PackLoxEntryTransition(
        stateKey: 'entry-auth-welcome',
        child: AuthWelcomeScreen(),
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
  }
}
