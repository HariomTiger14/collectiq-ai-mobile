import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_bootstrap_surface.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _qaCaptureRequested = bool.fromEnvironment('PACKLOX_QA_CAPTURE');
const _qaAppEnvironment = String.fromEnvironment('APP_ENV');
const _qaScreen = String.fromEnvironment('PACKLOX_QA_SCREEN');
const _qaScroll = String.fromEnvironment('PACKLOX_QA_SCROLL');

const packloxQaCaptureActive =
    kDebugMode && _qaCaptureRequested && _qaAppEnvironment == 'sit';

class PackLoxQaCaptureApp extends StatelessWidget {
  const PackLoxQaCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PackLox QA Capture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: PackLoxQaCaptureScreen(screen: _qaScreen, scroll: _qaScroll),
    );
  }
}

class PackLoxQaCaptureScreen extends StatelessWidget {
  const PackLoxQaCaptureScreen({
    required this.screen,
    required this.scroll,
    super.key,
  });

  final String screen;
  final String scroll;

  static void _noop() {}

  double get _scrollOffset {
    return switch (scroll) {
      'mid' || 'mid_scroll' => 720,
      'bottom' || 'bottom_scroll' => 2400,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final normalized = screen.trim();
    return switch (normalized) {
      'native_splash' ||
      'bootstrap' => const Scaffold(body: PackLoxBootstrapSurface.loading()),
      'app_shell_home_nav' => _QaShellFrame(
        selectedIndex: AppShellTabController.homeTab,
        child: HomePage(
          onScanPressed: _noop,
          onSampleScanPressed: _noop,
          onImportPhotoPressed: _noop,
          onPortfolioPressed: _noop,
          previewScenario: HomePreviewScenario.defaultData,
          qaInitialScrollOffset: _scrollOffset,
        ),
      ),
      'app_shell_portfolio_nav' => _QaShellFrame(
        selectedIndex: AppShellTabController.portfolioTab,
        child: PortfolioScreen(
          onScanPressed: _noop,
          previewScenario: PortfolioPreviewScenario.defaultData,
          qaInitialScrollOffset: _scrollOffset,
        ),
      ),
      'auth_welcome' => const AuthWelcomeScreen(),
      'auth_sign_in' => const AuthSignInScreen(
        initialEmail: 'collector@example.com',
      ),
      'auth_sign_up_start' => const AuthSignUpScreen(),
      'auth_verify_email' => const AuthVerifyEmailScreen(
        email: 'collector@example.com',
      ),
      'auth_forgot_password' => const AuthForgotPasswordScreen(
        initialEmail: 'collector@example.com',
      ),
      'home_default' => HomePage(
        onScanPressed: _noop,
        onSampleScanPressed: _noop,
        onImportPhotoPressed: _noop,
        onPortfolioPressed: _noop,
        previewScenario: HomePreviewScenario.defaultData,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'home_empty' => HomePage(
        onScanPressed: _noop,
        onSampleScanPressed: _noop,
        onImportPhotoPressed: _noop,
        onPortfolioPressed: _noop,
        previewScenario: HomePreviewScenario.empty,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'home_loading' => HomePage(
        onScanPressed: _noop,
        onSampleScanPressed: _noop,
        onImportPhotoPressed: _noop,
        onPortfolioPressed: _noop,
        previewScenario: HomePreviewScenario.loading,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'home_error' => HomePage(
        onScanPressed: _noop,
        onSampleScanPressed: _noop,
        onImportPhotoPressed: _noop,
        onPortfolioPressed: _noop,
        previewScenario: HomePreviewScenario.error,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'home_partial' => HomePage(
        onScanPressed: _noop,
        onSampleScanPressed: _noop,
        onImportPhotoPressed: _noop,
        onPortfolioPressed: _noop,
        previewScenario: HomePreviewScenario.partial,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_default' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.defaultData,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_empty' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.empty,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_loading' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.loading,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_error' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.error,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_partial' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.partial,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_filtered_empty' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.filteredEmpty,
        qaInitialScrollOffset: _scrollOffset,
      ),
      _ => _UnknownQaScreen(screen: normalized),
    };
  }
}

class _QaShellFrame extends StatelessWidget {
  const _QaShellFrame({required this.selectedIndex, required this.child});

  final int selectedIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: PackLoxTokens.background,
        systemNavigationBarDividerColor: PackLoxTokens.background,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: PackLoxTokens.background,
        body: child,
        bottomNavigationBar: GlassBottomNavBar(
          currentIndex: selectedIndex,
          onTap: (_) {},
          items: const [
            NavBarItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              iconAsset: PackLoxAssets.navHome,
              label: 'Home',
              isActive: false,
            ),
            NavBarItem(
              icon: Icons.camera_alt_outlined,
              selectedIcon: Icons.camera_alt_rounded,
              iconAsset: PackLoxAssets.navScan,
              label: 'Scan',
              isActive: false,
            ),
            NavBarItem(
              icon: Icons.inventory_2_outlined,
              selectedIcon: Icons.inventory_2_rounded,
              iconAsset: PackLoxAssets.navPortfolio,
              label: 'Portfolio',
              isActive: false,
            ),
            NavBarItem(
              icon: Icons.search_outlined,
              selectedIcon: Icons.search_rounded,
              label: 'Search',
              isActive: false,
            ),
            NavBarItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              iconAsset: PackLoxAssets.navSettings,
              label: 'Settings',
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownQaScreen extends StatelessWidget {
  const _UnknownQaScreen({required this.screen});

  final String screen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PackLoxTokens.background,
      body: Center(
        child: Text(
          'Unknown QA screen: $screen',
          style: const TextStyle(color: PackLoxTokens.textPrimary),
        ),
      ),
    );
  }
}
