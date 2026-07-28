import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_bootstrap_surface.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/image_enhancement_preview_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_hub_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scan_result_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/analyze_animation.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/capture_workspace.dart';
import 'package:collectiq_ai/features/search/data/repositories/api_catalog_search_repository.dart';
import 'package:collectiq_ai/features/search/domain/entities/catalog_search_result.dart';
import 'package:collectiq_ai/features/search/domain/repositories/catalog_search_repository.dart';
import 'package:collectiq_ai/features/search/presentation/search_screen.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const _qaCaptureRequested = bool.fromEnvironment('PACKLOX_QA_CAPTURE');
const _qaAppEnvironment = String.fromEnvironment('APP_ENV');
const _qaScreen = String.fromEnvironment('PACKLOX_QA_SCREEN');
const _qaScroll = String.fromEnvironment('PACKLOX_QA_SCROLL');

const packloxQaCaptureActive =
    kDebugMode && _qaCaptureRequested && _qaAppEnvironment == 'sit';

const _qaProPlanLimits = PlanLimits(
  plan: SubscriptionPlan.pro,
  scanLimit: UsageLimit(dailyFreeScanLimit: 250),
  maxPortfolioItems: 1000,
  maxPhotosPerItem: 6,
  maxActivePriceAlerts: 25,
  monthlyPriceRefreshes: 100,
  canUseFullValueHistory: true,
  canExportPortfolio: true,
  canUseAdvancedFilters: true,
  canBulkRefreshValues: false,
  canUsePortfolioIntelligence: true,
);

class PackLoxQaCaptureApp extends StatelessWidget {
  const PackLoxQaCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'PackLox QA Capture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: PackLoxQaCaptureScreen(screen: _qaScreen, scroll: _qaScroll),
    );
    return app;
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
    final parsed = double.tryParse(scroll.trim());
    if (parsed != null) {
      return parsed;
    }
    return switch (scroll) {
      'mid' || 'mid_scroll' => 720,
      'bottom' || 'bottom_scroll' => 2400,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final normalized = screen.trim();
    final qaScreen = switch (normalized) {
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
      'app_shell_search_nav' => const _QaShellFrame(
        selectedIndex: AppShellTabController.searchTab,
        child: SearchScreen(),
      ),
      'app_shell_settings_nav' => _QaSettingsAuthScope(
        user: null,
        child: const _QaShellFrame(
          selectedIndex: AppShellTabController.settingsTab,
          child: SettingsScreen(),
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
      'search_default' => const SearchScreen(),
      'search_active' => const SearchScreen(
        previewState: SearchPreviewState.active,
      ),
      'search_results' => const SearchScreen(
        previewState: SearchPreviewState.results,
      ),
      'search_catalog_detail' => ProviderScope(
        overrides: [
          catalogSearchRepositoryProvider.overrideWithValue(
            const _QaCatalogSearchRepository(),
          ),
        ],
        child: CatalogResultDetailPreviewPage(
          result: _qaCatalogResult,
          qaInitialScrollOffset: _scrollOffset,
        ),
      ),
      'search_empty' => const SearchScreen(
        previewState: SearchPreviewState.empty,
      ),
      'settings_signed_out' => _QaSettingsScreen(
        scrollOffset: _scrollOffset,
        user: null,
      ),
      'settings_signed_in' => _QaSettingsScreen(
        scrollOffset: _scrollOffset,
        user: _qaSettingsUser,
      ),
      'settings_cloud_disabled' => _QaSettingsScreen(
        scrollOffset: _scrollOffset,
        user: _qaSettingsUser,
      ),
      'settings_danger_zone' => _QaSettingsScreen(
        scrollOffset: 6200,
        user: null,
      ),
      'portfolio_default' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.defaultData,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_default_pro' => ProviderScope(
        overrides: [
          activePlanLimitsProvider.overrideWithValue(_qaProPlanLimits),
        ],
        child: PortfolioScreen(
          onScanPressed: _noop,
          previewScenario: PortfolioPreviewScenario.defaultData,
          qaInitialScrollOffset: _scrollOffset,
        ),
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
      'portfolio_search_active' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.defaultData,
        qaInitialScrollOffset: _scrollOffset,
        qaSearchPreview: PortfolioSearchPreview.active,
      ),
      'portfolio_search_results' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.defaultData,
        qaInitialScrollOffset: _scrollOffset,
        qaSearchPreview: PortfolioSearchPreview.results,
      ),
      'portfolio_search_empty' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.defaultData,
        qaInitialScrollOffset: _scrollOffset,
        qaSearchPreview: PortfolioSearchPreview.empty,
      ),
      'portfolio_search_with_filter_empty' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.defaultData,
        qaInitialScrollOffset: _scrollOffset,
        qaSearchPreview: PortfolioSearchPreview.filterEmpty,
      ),
      'portfolio_delete_confirm' => CollectibleDetailPage(
        qaInitialScrollOffset: _scrollOffset,
        qaShowDeleteConfirmation: true,
        onDelete: (_) async => true,
        item: _qaDetailItem(
          id: 'qa-delete-confirm',
          title: 'Base Set Charizard',
          estimatedValue: 1850,
          valuationStatus: ValuationStatus.marketEstimated,
          imagePath: '',
          galleryImages: const [],
        ),
      ),
      'portfolio_delete_after_remove_empty' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.empty,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_edit_item' => CollectibleDetailPage(
        qaInitialScrollOffset: _scrollOffset,
        qaShowEditSheet: true,
        item: _qaDetailItem(
          id: 'qa-edit-item',
          title: 'PackLox Authority Coupe',
          estimatedValue: 245,
          valuationStatus: ValuationStatus.marketEstimated,
          imagePath: '',
          galleryImages: const [],
        ),
      ),
      'portfolio_edit_item_saved' => CollectibleDetailPage(
        qaInitialScrollOffset: _scrollOffset,
        item: _qaDetailItem(
          id: 'qa-edit-item-saved',
          title: 'Edited Authority Coupe',
          estimatedValue: 280,
          valuationStatus: ValuationStatus.marketEstimated,
          imagePath: '',
          galleryImages: const [],
        ),
      ),
      'portfolio_filter_sheet_default' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.defaultData,
        qaInitialSheet: PortfolioSheetPreview.defaultState,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_filter_sheet_selected' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.defaultData,
        qaInitialSheet: PortfolioSheetPreview.selected,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_filter_sheet_filtered_empty' => PortfolioScreen(
        onScanPressed: _noop,
        previewScenario: PortfolioPreviewScenario.filteredEmpty,
        qaInitialSheet: PortfolioSheetPreview.selected,
        qaInitialScrollOffset: _scrollOffset,
      ),
      'portfolio_detail_valued' => CollectibleDetailPage(
        qaInitialScrollOffset: _scrollOffset,
        item: _qaDetailItem(
          id: 'qa-detail-valued',
          title: 'PackLox Authority Coupe',
          estimatedValue: 245,
          valuationStatus: ValuationStatus.marketEstimated,
          imagePath: '',
          galleryImages: const [],
        ),
      ),
      'portfolio_detail_pending' => CollectibleDetailPage(
        qaInitialScrollOffset: _scrollOffset,
        item: _qaDetailItem(
          id: 'qa-detail-pending',
          title: 'Unmatched Collector Card',
          estimatedValue: 0,
          valuationStatus: ValuationStatus.noMarketMatch,
          imagePath: '',
          galleryImages: const [],
        ),
      ),
      'portfolio_detail_missing_image' => CollectibleDetailPage(
        qaInitialScrollOffset: _scrollOffset,
        item: _qaDetailItem(
          id: 'qa-detail-missing-image',
          title: 'Catalogued Mystery Item',
          estimatedValue: 0,
          valuationStatus: ValuationStatus.unavailable,
          imagePath: '',
          galleryImages: const [],
        ),
      ),
      'portfolio_detail_catalog_snapshot' => CollectibleDetailPage(
        qaInitialScrollOffset: _scrollOffset,
        item: _qaCatalogPortfolioItem,
      ),
      'scanner_hub' => ScanHubPage(now: () => DateTime(2026, 7, 23, 9)),
      'scanner_camera_mock' => const _QaScannerCameraMock(),
      'scanner_review_photo' => const _QaScannerReviewPhoto(),
      'scanner_workspace_single' => _QaScannerWorkspace(photoCount: 1),
      'scanner_workspace_multi' => _QaScannerWorkspace(photoCount: 3),
      'scanner_analyzing' => const _QaScannerAnalyzing(),
      'scanner_result' => _QaScannerResult(
        isSaved: false,
        result: _qaScanResult(),
        scrollOffset: _scrollOffset,
      ),
      'scanner_result_no_market' => _QaScannerResult(
        isSaved: false,
        result: _qaScanResultNoMarket(),
        scrollOffset: _scrollOffset,
      ),
      'scanner_result_close_match' => _QaScannerResult(
        isSaved: false,
        result: _qaScanResultCloseMatch(),
        scrollOffset: _scrollOffset,
      ),
      'scanner_result_low_confidence' => _QaScannerResult(
        isSaved: false,
        result: _qaScanResultLowConfidence(),
        scrollOffset: _scrollOffset,
      ),
      'scanner_save_confirmation' => _QaScannerResult(
        isSaved: true,
        result: _qaScanResult(),
        scrollOffset: _scrollOffset,
      ),
      'scanner_analysis_failure' => const _QaScannerAnalysisFailure(),
      'scanner_permission_denied' => const _QaScannerErrorState(
        title: 'Camera access needed',
        body:
            'PackLox needs camera access to capture a fresh scan. You can allow camera access or choose a saved photo.',
        primaryLabel: 'Try Camera Again',
        secondaryLabel: 'Choose Photo',
        icon: Icons.photo_camera_outlined,
      ),
      'scanner_camera_unavailable' => const _QaScannerErrorState(
        title: 'Camera unavailable',
        body:
            'The camera could not start on this device. Try again, or continue with a clear gallery photo.',
        primaryLabel: 'Try Again',
        secondaryLabel: 'Choose Photo',
        icon: Icons.videocam_off_outlined,
      ),
      'scanner_quality_gate_failure' => const _QaScannerErrorState(
        title: 'Photo needs a clearer view',
        body:
            'PackLox could not read enough usable image detail. Retake with the item fully in frame and avoid glare.',
        primaryLabel: 'Retake Photo',
        secondaryLabel: 'Choose Photo',
        icon: Icons.center_focus_strong_outlined,
      ),
      'scanner_lost_picker_recovery' => const _QaScannerErrorState(
        title: 'Photo recovery stopped',
        body:
            'PackLox could not recover the photo returned by the picker. Choose it again or start a fresh capture.',
        primaryLabel: 'Choose Again',
        secondaryLabel: 'New Scan',
        icon: Icons.restore_outlined,
      ),
      'scanner_usage_limit' => const _QaScannerErrorState(
        title: 'Scan limit reached',
        body:
            'This account has used its available AI scans for now. You can keep the photos here or start a new scan later.',
        primaryLabel: 'Try Again',
        secondaryLabel: 'New Scan',
        icon: Icons.lock_clock_outlined,
      ),
      _ => _UnknownQaScreen(screen: normalized),
    };
    if (normalized.startsWith('scanner_')) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: qaScreen,
      );
    }
    return qaScreen;
  }
}

const _qaSettingsUser = AppUser(
  id: 'qa-cloud-user',
  displayName: 'collector@example.com',
  email: 'collector@example.com',
  provider: AuthProviderType.emailPassword,
);

final _qaCatalogResult = CatalogSearchResult(
  id: '3666974',
  title: 'Charizard #10',
  category: 'Pokemon Cards',
  source: 'PriceCharting',
  setName: 'Pokemon Go',
  identifier: '10',
  currency: 'USD',
  marketValue: 3.89,
  lowEstimate: 3.31,
  highEstimate: 4.47,
  confidence: 0.82,
  lastUpdated: DateTime.utc(2026, 7, 26, 1, 18),
  attribution: 'Pricing data by PriceCharting',
  history: <CatalogPriceHistoryPoint>[
    CatalogPriceHistoryPoint(
      validFrom: DateTime.utc(2026, 7, 26, 1, 18),
      isCurrent: true,
      currency: 'USD',
      marketValue: 3.89,
      lowEstimate: 3.31,
      highEstimate: 4.47,
      sourceFile: 'pokemon.csv',
      sourceDownloadedAt: DateTime.utc(2026, 7, 26, 1, 18),
    ),
  ],
);

final _qaCatalogPortfolioItem = CollectibleItem(
  id: 'catalog-3666974-qa',
  title: 'Charizard #10',
  category: 'Pokemon Cards',
  estimatedValue: 3.89,
  confidence: 0.82,
  condition: 'Unspecified',
  recommendation:
      'Saved from catalog search. Add your own photos and condition notes to improve portfolio accuracy.',
  imagePath:
      'assets/packlox/icons/categories/3d/packlox_category_placeholder_card_v1.png',
  createdAt: DateTime.utc(2026, 7, 26, 1, 20),
  setName: 'Pokemon Go',
  cardNumber: '10',
  notes:
      'Catalog ID: 3666974\nSource: PriceCharting\n'
      'Pricing data by PriceCharting',
  valuationStatus: ValuationStatus.marketEstimated,
  valuationSource: 'pricecharting',
  valueAtScan: 3.89,
  lastValueRefreshedAt: DateTime.utc(2026, 7, 26, 1, 18),
  pricing: PricingInfo(
    estimatedMarketValue: 3.89,
    lowEstimate: 3.31,
    highEstimate: 4.47,
    currency: 'USD',
    pricingSource: 'PriceCharting',
    pricingConfidence: 0.82,
    lastUpdated: DateTime.utc(2026, 7, 26, 1, 18),
    valuationStatus: ValuationStatus.marketEstimated,
    valuationSource: 'pricecharting',
    pricingExplanation:
        'Saved from PackLox catalog search as a dated portfolio snapshot.',
    reasonCode: 'CATALOG_SEARCH_MATCH',
    valuationStrategy: 'catalog_lookup',
    attributionText: 'Pricing data by PriceCharting',
    displayString: 'USD \$3.89',
  ),
);

class _QaCatalogSearchRepository implements CatalogSearchRepository {
  const _QaCatalogSearchRepository();

  @override
  Future<List<CatalogSearchResult>> searchCatalog({
    required String query,
    int limit = 20,
  }) async {
    return [_qaCatalogResult];
  }

  @override
  Future<CatalogSearchResult> getCatalogDetail({
    required CatalogSearchResult result,
    int historyLimit = 30,
  }) async {
    return _qaCatalogResult;
  }
}

class _QaSettingsScreen extends StatelessWidget {
  const _QaSettingsScreen({required this.scrollOffset, required this.user});

  final double scrollOffset;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return _QaSettingsAuthScope(
      user: user,
      child: SettingsScreen(qaInitialScrollOffset: scrollOffset),
    );
  }
}

class _QaSettingsAuthScope extends StatelessWidget {
  const _QaSettingsAuthScope({required this.user, required this.child});

  final AppUser? user;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _QaSettingsAuthRepository(initialUser: user),
        ),
        authControllerProvider.overrideWith(
          () => _QaSettingsAuthController(user),
        ),
      ],
      child: child,
    );
  }
}

class _QaSettingsAuthController extends AuthController {
  _QaSettingsAuthController(this.user);

  final AppUser? user;

  @override
  AuthState build() {
    return AuthState(
      user: user,
      status: user != null ? AuthFlowStatus.signedIn : AuthFlowStatus.signedOut,
    );
  }
}

class _QaInitialScrollable extends StatefulWidget {
  const _QaInitialScrollable({
    required this.initialOffset,
    required this.child,
  });

  final double initialOffset;
  final Widget child;

  @override
  State<_QaInitialScrollable> createState() => _QaInitialScrollableState();
}

class _QaInitialScrollableState extends State<_QaInitialScrollable> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.initialOffset <= 0) {
        return;
      }
      final scrollable = Scrollable.maybeOf(context);
      final position = scrollable?.position;
      if (position == null || !position.hasPixels) {
        return;
      }
      position.jumpTo(
        widget.initialOffset.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _QaSettingsAuthRepository implements AuthRepository {
  _QaSettingsAuthRepository({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> signIn() => signInAnonymously();

  @override
  Future<AppUser> signInAnonymously() async {
    _user = const AppUser(
      id: 'qa-local-user',
      displayName: 'Local Collector',
      email: null,
      isAnonymous: true,
      isLocalOnly: true,
      provider: AuthProviderType.localAnonymous,
    );
    return _user!;
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _user = AppUser(
      id: 'qa-cloud-user',
      displayName: email,
      email: email,
      provider: AuthProviderType.emailPassword,
    );
    return _user!;
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw const AuthException('Sign up is not used in QA capture.');
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException('Google sign-in is not enabled.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException('Apple sign-in is not enabled.');
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }
}

class _QaScannerCameraMock extends StatelessWidget {
  const _QaScannerCameraMock();

  @override
  Widget build(BuildContext context) {
    return ScannerFocusTheme(
      child: Scaffold(
        backgroundColor: ScannerVisualTheme.backgroundDeep,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _QaScannerBackdrop()),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      key: const ValueKey('camera-close-button'),
                      onPressed: () {},
                      icon: const Icon(Icons.close),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.flash_off_outlined),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.cameraswitch_outlined),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: 122,
                child: ScannerStatusCard(
                  title: 'Front photo',
                  body:
                      'Center the collectible, avoid glare, and leave the edges visible.',
                  icon: Icons.photo_camera_outlined,
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                    const Spacer(),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () {},
                      icon: const Icon(Icons.grid_on_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QaScannerReviewPhoto extends StatelessWidget {
  const _QaScannerReviewPhoto();

  @override
  Widget build(BuildContext context) {
    return ScannerFocusTheme(
      child: Scaffold(
        backgroundColor: ScannerVisualTheme.backgroundDeep,
        body: SafeArea(
          child: ImageEnhancementPreviewSurface(
            image: XFile('sample://front'),
            initialPreset: ImageEnhancementPreset.original,
            title: 'Review photo',
            subtitle: 'Choose the clearest version for analysis.',
            onCancel: () {},
            onRetake: () {},
            onUsePhoto: (_) {},
          ),
        ),
      ),
    );
  }
}

class _QaScannerWorkspace extends StatelessWidget {
  const _QaScannerWorkspace({required this.photoCount});

  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final photos = _qaScannerSlots().take(photoCount).toList();
    final plan = const ScanCapturePlanService().buildPlan(
      ScanGoal.detailedAnalysis,
      CollectibleCategory.toyCar,
      const [],
    );
    return ScannerFocusTheme(
      child: Scaffold(
        backgroundColor: ScannerVisualTheme.background,
        appBar: AppBar(title: const Text('Scan Workspace')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              96,
            ),
            child: CaptureWorkspace(
              goal: ScanGoal.detailedAnalysis,
              category: CollectibleCategory.toyCar,
              plan: plan,
              slots: _latestQaSlots(photos),
              captureImages: photos,
              isBusy: false,
              hasResult: false,
              selectedPath: photos.last.path,
              activeRoleId: photos.last.role,
              selectedItemTitle: photos.last.label,
              selectedItemStatus: 'Ready for AI analysis',
              categoryLabel: 'Diecast / Toy car',
              onPrimaryCapture: () {},
              onAnalyze: () {},
              onCamera: (_) async {},
              onGallery: (_) async {},
              onSelectRole: (_) {},
              onPreview: (_) {},
              onUseAsPrimary: (_) {},
              onEnhance: (_, _) async {},
              onDelete: (_) {},
              onSample: () {},
              onReset: () {},
            ),
          ),
        ),
      ),
    );
  }
}

class _QaScannerAnalyzing extends StatelessWidget {
  const _QaScannerAnalyzing();

  @override
  Widget build(BuildContext context) {
    return ScannerFocusTheme(
      child: Scaffold(
        backgroundColor: ScannerVisualTheme.backgroundDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _QaScannerBackdrop(),
            const AnalyzeAnimationOverlay(
              imagePath: 'sample://front',
              qaProgress: 0.72,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ScannerStatusCard(
                    title: 'Analyzing collectible',
                    body: 'Matching photos, condition, and market signals.',
                    icon: Icons.auto_awesome_outlined,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QaScannerResult extends StatelessWidget {
  const _QaScannerResult({
    required this.isSaved,
    required this.result,
    required this.scrollOffset,
  });

  final bool isSaved;
  final ScanResult result;
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    return ScanResultScreen(
      result: result,
      activeSlot: _qaScannerSlots().first,
      isSaved: isSaved,
      isSaving: false,
      isRefreshingPricing: false,
      onSave: () async {},
      onScanAnother: () {},
      onViewPortfolio: () {},
      onApplyReviewEdits: (_) async => true,
      qaInitialScrollOffset: scrollOffset,
    );
  }
}

class _QaScannerAnalysisFailure extends StatelessWidget {
  const _QaScannerAnalysisFailure();

  @override
  Widget build(BuildContext context) {
    return ScannerFocusTheme(
      child: Scaffold(
        backgroundColor: ScannerVisualTheme.background,
        appBar: AppBar(title: const Text('Scan Workspace')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CaptureWorkspace(
                    goal: ScanGoal.detailedAnalysis,
                    category: CollectibleCategory.toyCar,
                    plan: const ScanCapturePlanService().buildPlan(
                      ScanGoal.detailedAnalysis,
                      CollectibleCategory.toyCar,
                      const [],
                    ),
                    slots: _latestQaSlots(_qaScannerSlots().take(1).toList()),
                    captureImages: _qaScannerSlots().take(1).toList(),
                    isBusy: false,
                    hasResult: false,
                    selectedPath: _qaScannerSlots().first.path,
                    activeRoleId: _qaScannerSlots().first.role,
                    selectedItemTitle: _qaScannerSlots().first.label,
                    selectedItemStatus: 'Analysis failed',
                    categoryLabel: 'Diecast / Toy car',
                    onPrimaryCapture: () {},
                    onAnalyze: () {},
                    onCamera: (_) async {},
                    onGallery: (_) async {},
                    onSelectRole: (_) {},
                    onPreview: (_) {},
                    onUseAsPrimary: (_) {},
                    onEnhance: (_, _) async {},
                    onDelete: (_) {},
                    onSample: () {},
                    onReset: () {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const ScannerStatusCard(
                    title: 'Scan interrupted',
                    body:
                        'PackLox could not complete analysis. Check the image and try again.',
                    icon: Icons.error_outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QaScannerErrorState extends StatelessWidget {
  const _QaScannerErrorState({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.icon,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final String secondaryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ScannerFocusTheme(
      child: Scaffold(
        backgroundColor: ScannerVisualTheme.backgroundDeep,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _QaScannerBackdrop(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 132),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: ScannerVisualTheme.border.withValues(alpha: 0.72),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: ScannerStatusCard(
                        title: title,
                        body: body,
                        icon: icon,
                        trailing: Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                key: const ValueKey('qa-scanner-error-primary'),
                                onPressed: () {},
                                child: Text(primaryLabel),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton(
                                key: const ValueKey(
                                  'qa-scanner-error-secondary',
                                ),
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      ScannerVisualTheme.textPrimary,
                                  side: BorderSide(
                                    color: ScannerVisualTheme.border.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                ),
                                child: Text(secondaryLabel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<ScannerPhotoSlot> _qaScannerSlots() {
  return const [
    ScannerPhotoSlot(
      role: 'front',
      label: 'Front / obverse',
      path: 'sample://front',
      source: 'sample',
      originalPath: 'sample://front',
      capturedAt: null,
      qualityMetadata: {'readinessScore': 92, 'source': 'qa'},
    ),
    ScannerPhotoSlot(
      role: 'back',
      label: 'Back / reverse',
      path: 'sample://back',
      source: 'sample',
      originalPath: 'sample://back',
      capturedAt: null,
      qualityMetadata: {'readinessScore': 88, 'source': 'qa'},
    ),
    ScannerPhotoSlot(
      role: 'detail',
      label: 'Close-up detail',
      path: 'sample://detail',
      source: 'sample',
      originalPath: 'sample://detail',
      enhancementPreset: ImageEnhancementPreset.autoEnhance,
      enhancedImagePath: 'sample://detail',
      capturedAt: null,
      qualityMetadata: {'readinessScore': 94, 'source': 'qa'},
    ),
  ];
}

Map<String, ScannerPhotoSlot> _latestQaSlots(List<ScannerPhotoSlot> photos) {
  return {for (final slot in photos) slot.role: slot};
}

ScanResult _qaScanResult() {
  return ScanResult(
    id: 'qa-scan-result',
    title: 'PackLox Authority Coupe',
    category: 'Diecast / Toy car',
    estimatedValue: 245,
    confidence: 0.91,
    condition: 'Near mint',
    thumbnail: 'sample://front',
    scanDate: DateTime(2026, 7, 23, 10),
    primaryMatch: 'PackLox Authority Coupe 1:64',
    alternativeMatches: const [
      ScanAlternativeMatch(
        title: 'PackLox Coupe prototype',
        category: 'Diecast / Toy car',
        confidence: 0.74,
        reason: 'Similar body shape and base markings.',
      ),
    ],
    confidenceExplanation:
        'Three photo angles support the model and condition.',
    detectionQuality: 'Clean edges, visible base, minor reflection.',
    aiReasoning:
        'The front, base, and detail shots match the known authority release.',
    pricing: PricingInfo(
      estimatedMarketValue: 245,
      lowEstimate: 220,
      highEstimate: 275,
      currency: 'AUD',
      pricingSource: 'QA preview provider',
      pricingConfidence: 0.82,
      lastUpdated: DateTime(2026, 7, 23),
      valuationStatus: ValuationStatus.marketEstimated,
      valuationSource: 'qa_preview_provider',
      aiEstimatedValue: 238,
      displayString: r'$245.00 AUD',
      originalPrice: 161,
      originalCurrency: 'USD',
      exchangeRateUsed: 1.52,
      exchangeRateDate: DateTime(2026, 7, 23),
    ),
    brand: 'PackLox Studio',
    series: 'Authority',
    year: '2026',
    rarity: 'Limited',
    estimatedGrade: 'Near mint',
    valuationStatus: ValuationStatus.marketEstimated,
    valuationSource: 'qa_preview_provider',
    aiEstimatedValue: 238,
    photosUsed: 3,
    photoRoles: const ['front', 'back', 'detail'],
  );
}

ScanResult _qaScanResultNoMarket() {
  return ScanResult(
    id: 'qa-scan-result-no-market',
    title: 'Mystery Authority Coupe',
    category: 'Diecast / Toy car',
    estimatedValue: 0,
    confidence: 0.84,
    condition: 'Good',
    thumbnail: 'sample://front',
    scanDate: DateTime(2026, 7, 23, 10),
    primaryMatch: 'Mystery Authority Coupe',
    alternativeMatches: const [
      ScanAlternativeMatch(
        title: 'Unmarked 1:64 coupe',
        category: 'Diecast / Toy car',
        confidence: 0.68,
        reason: 'Similar body shape, but no confirmed catalog identifier.',
      ),
    ],
    confidenceExplanation:
        'The item type is visible, but markings are not enough for a catalog match.',
    detectionQuality: 'Front photo is clear; base text is not readable.',
    aiReasoning:
        'PackLox can identify a diecast coupe, but cannot confirm the exact release.',
    pricing: PricingInfo(
      estimatedMarketValue: 0,
      lowEstimate: 0,
      highEstimate: 0,
      currency: 'AUD',
      pricingSource: 'PriceCharting catalog',
      pricingConfidence: 0,
      lastUpdated: DateTime(2026, 7, 23),
      valuationStatus: ValuationStatus.noMarketMatch,
      valuationSource: 'pricecharting_catalog',
      pricingExplanation:
          'No reliable catalog match was found for the detected title and visible identifiers.',
      reasonCode: 'NO_MARKET_MATCH',
      valuationStrategy: 'unavailable',
    ),
    brand: 'Unknown',
    series: 'Unconfirmed',
    year: 'Unknown',
    valuationStatus: ValuationStatus.noMarketMatch,
    valuationSource: 'pricecharting_catalog',
    photosUsed: 1,
    photoRoles: const ['front'],
  );
}

ScanResult _qaScanResultCloseMatch() {
  return ScanResult(
    id: 'qa-scan-result-close-match',
    title: 'PackLox Authority Coupe',
    category: 'Diecast / Toy car',
    estimatedValue: 245,
    confidence: 0.86,
    condition: 'Near mint',
    thumbnail: 'sample://front',
    scanDate: DateTime(2026, 7, 23, 10),
    primaryMatch: 'PackLox Authority Coupe 1:64',
    alternativeMatches: const [
      ScanAlternativeMatch(
        title: 'PackLox Authority Coupe chase variant',
        category: 'Diecast / Toy car',
        confidence: 0.80,
        reason:
            'Similar markings and packaging color; variant badge is unclear.',
      ),
      ScanAlternativeMatch(
        title: 'PackLox Coupe prototype',
        category: 'Diecast / Toy car',
        confidence: 0.73,
        reason: 'Same body casting with different base text.',
      ),
    ],
    confidenceExplanation:
        'The model is likely correct, but the variant badge is partially hidden.',
    detectionQuality:
        'Good front and base photos, packaging variant is unclear.',
    aiReasoning:
        'The main casting matches, while the visible packaging leaves a close variant possibility.',
    pricing: PricingInfo(
      estimatedMarketValue: 245,
      lowEstimate: 220,
      highEstimate: 275,
      currency: 'AUD',
      pricingSource: 'PriceCharting catalog',
      pricingConfidence: 0.76,
      lastUpdated: DateTime(2026, 7, 23),
      valuationStatus: ValuationStatus.marketEstimated,
      valuationSource: 'pricecharting_catalog',
      pricingExplanation:
          'Matched by title and category, but variant needs user confirmation.',
      displayString: r'$245.00 AUD',
      originalPrice: 161,
      originalCurrency: 'USD',
    ),
    brand: 'PackLox Studio',
    series: 'Authority',
    year: '2026',
    rarity: 'Variant unclear',
    valuationStatus: ValuationStatus.marketEstimated,
    valuationSource: 'pricecharting_catalog',
    photosUsed: 3,
    photoRoles: const ['front', 'back', 'detail'],
  );
}

ScanResult _qaScanResultLowConfidence() {
  return ScanResult(
    id: 'qa-scan-result-low-confidence',
    title: 'PackLox Authority Coupe',
    category: 'Diecast / Toy car',
    estimatedValue: 245,
    confidence: 0.63,
    condition: 'Good',
    thumbnail: 'sample://front',
    scanDate: DateTime(2026, 7, 23, 10),
    primaryMatch: 'PackLox Authority Coupe 1:64',
    alternativeMatches: const [
      ScanAlternativeMatch(
        title: 'PackLox Coupe prototype',
        category: 'Diecast / Toy car',
        confidence: 0.55,
        reason: 'Blurred base text makes the exact release uncertain.',
      ),
    ],
    confidenceExplanation:
        'Low confidence because the base text and packaging details are blurred.',
    detectionQuality: 'Blurred base text; add a sharper back or base photo.',
    aiReasoning:
        'The silhouette and color are plausible, but identifiers need a clearer image.',
    pricing: PricingInfo(
      estimatedMarketValue: 245,
      lowEstimate: 220,
      highEstimate: 275,
      currency: 'AUD',
      pricingSource: 'PriceCharting catalog',
      pricingConfidence: 0.58,
      lastUpdated: DateTime(2026, 7, 23),
      valuationStatus: ValuationStatus.marketEstimated,
      valuationSource: 'pricecharting_catalog',
      pricingExplanation:
          'Pricing match exists, but the scan confidence is low and needs review.',
      displayString: r'$245.00 AUD',
      originalPrice: 161,
      originalCurrency: 'USD',
    ),
    brand: 'PackLox Studio',
    series: 'Authority',
    year: '2026',
    rarity: 'Unconfirmed',
    valuationStatus: ValuationStatus.marketEstimated,
    valuationSource: 'pricecharting_catalog',
    photosUsed: 2,
    photoRoles: const ['front', 'detail'],
  );
}

class _QaScannerBackdrop extends StatelessWidget {
  const _QaScannerBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('scanner-camera-mock-preview'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111827), Color(0xFF030712)],
        ),
      ),
      child: Center(
        child: Container(
          width: 190,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.view_in_ar_outlined,
            color: Colors.white54,
            size: 72,
          ),
        ),
      ),
    );
  }
}

CollectibleItem _qaDetailItem({
  required String id,
  required String title,
  required double estimatedValue,
  required ValuationStatus valuationStatus,
  required String imagePath,
  required List<CollectibleImage> galleryImages,
}) {
  return CollectibleItem(
    id: id,
    title: title,
    category: 'Trading Card',
    estimatedValue: estimatedValue,
    confidence: valuationStatus == ValuationStatus.noMarketMatch ? 0.74 : 0.91,
    condition: 'Near mint',
    recommendation: 'Keep the complete saved capture set.',
    imagePath: imagePath,
    createdAt: DateTime(2026, 7, 14),
    valuationStatus: valuationStatus,
    brand: 'PackLox Studio',
    series: 'QA Preview',
    year: '2026',
    rarity: 'Limited',
    notes: 'Preview item for Portfolio Detail visual QA.',
    aiReasoning: 'Stored scan reasoning appears here for review.',
    confidenceExplanation: 'Saved evidence matched the item category.',
    detectionQuality: 'Clean studio capture.',
    galleryImages: galleryImages,
    pricing: estimatedValue <= 0
        ? null
        : PricingInfo(
            estimatedMarketValue: estimatedValue,
            lowEstimate: estimatedValue * .9,
            highEstimate: estimatedValue * 1.1,
            currency: 'AUD',
            pricingSource: 'QA preview provider',
            pricingConfidence: .82,
            lastUpdated: DateTime(2026, 7, 14),
          ),
  );
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
