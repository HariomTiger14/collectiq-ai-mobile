import 'dart:async';
import 'dart:io' show Platform;

import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/network/api_constants.dart' as net;
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/apple_billing_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/cloud_entitlement_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/google_play_billing_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/shared_preferences_entitlement_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/shared_preferences_usage_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/sit_dummy_billing_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/unavailable_billing_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_exception.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/purchase_result.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_exception.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/user_entitlements.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_tracker.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/billing_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/usage_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Usage limit configuration from build environment.
class UsageLimitConfig {
  /// Creates usage limit config.
  const UsageLimitConfig({
    this.developmentUnlimited = true,
    // Quiet monthly anti-abuse ceiling, not a marketed limit. The real free
    // wall is the saved-collectibles cap (kFreeMaxCollectibles). Matches the
    // server-side monthly cap enforced on /analyze
    // (SUBSCRIPTION_FREE_MONTHLY_SCAN_LIMIT, default 30) — this is a
    // client-side pre-check only, the server is authoritative.
    this.monthlyFreeScanLimit = 30,
  });

  /// Whether local/dev builds should avoid blocking scanner testing.
  final bool developmentUnlimited;

  /// Monthly scan limit used when unlimited mode is disabled.
  final int monthlyFreeScanLimit;

  /// Build config from dart-define values.
  factory UsageLimitConfig.fromEnvironment() {
    return const UsageLimitConfig(
      developmentUnlimited: bool.fromEnvironment(
        'COLLECTIQ_USAGE_UNLIMITED',
        defaultValue: true,
      ),
      monthlyFreeScanLimit: int.fromEnvironment(
        'COLLECTIQ_MONTHLY_FREE_SCAN_LIMIT',
        defaultValue: 30,
      ),
    );
  }

  /// Limit model for the active config.
  UsageLimit get usageLimit {
    return UsageLimit(
      monthlyFreeScanLimit: monthlyFreeScanLimit,
      isUnlimited: developmentUnlimited,
    );
  }
}

/// Provides subscription usage config.
final usageLimitConfigProvider = Provider<UsageLimitConfig>((ref) {
  return UsageLimitConfig.fromEnvironment();
});

/// Provides Google Play Billing config.
final googlePlayBillingConfigProvider = Provider<GooglePlayBillingConfig>((
  ref,
) {
  return GooglePlayBillingConfig.fromEnvironment();
});

/// Provides Apple App Store Billing config.
final appleBillingConfigProvider = Provider<AppleBillingConfig>((ref) {
  return AppleBillingConfig.fromEnvironment();
});

/// Provides SIT dummy billing config.
final sitDummyBillingConfigProvider = Provider<SitDummyBillingConfig>((ref) {
  return SitDummyBillingConfig.fromEnvironment();
});

/// Whether this build has any billing provider configured.
final paymentsConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(sitDummyBillingConfigProvider).enabled ||
      ref.watch(googlePlayBillingConfigProvider).enabled ||
      ref.watch(appleBillingConfigProvider).enabled;
});

/// Provides billing repository. Platform-specific below the SIT/unavailable
/// checks -- iOS gets StoreKit2 via AppleBillingRepository, everything else
/// (Android, and any other Platform.isIOS-false target) gets Play Billing.
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final sitConfig = ref.watch(sitDummyBillingConfigProvider);
  if (sitConfig.enabled) {
    return SitDummyBillingRepository(config: sitConfig);
  }

  if (Platform.isIOS) {
    final appleConfig = ref.watch(appleBillingConfigProvider);
    if (!appleConfig.enabled) {
      return const UnavailableBillingRepository();
    }
    return AppleBillingRepository(config: appleConfig);
  }

  final config = ref.watch(googlePlayBillingConfigProvider);
  if (!config.enabled) {
    return const UnavailableBillingRepository();
  }

  return GooglePlayBillingRepository(config: config);
});

/// Provides entitlement persistence. When cloud services are allowed, the plan
/// is read from and written to the server (per-user, cross-device, tamper-proof)
/// with the local store as an offline cache. Otherwise it stays purely local.
final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  const local = SharedPreferencesEntitlementRepository();
  final cloudAllowed = ref.watch(environmentConfigProvider).allowsCloudServices;
  if (!cloudAllowed) {
    return local;
  }
  return CloudEntitlementRepository(
    baseUrl: net.EnvironmentConfig.fromEnvironment().baseUrl,
    supabaseService: ref.watch(supabaseServiceProvider),
    cache: local,
  );
});

/// Provides user entitlements.
final userEntitlementsProvider = Provider<UserEntitlements>((ref) {
  return UserEntitlements.forPlan(
    plan: UserEntitlements.developmentFree.plan,
    freeLimit: ref.watch(usageLimitConfigProvider).usageLimit,
    paymentsConfigured: ref.watch(paymentsConfiguredProvider),
  );
});

/// Provides local usage persistence.
final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return const SharedPreferencesUsageRepository();
});

/// Subscription and usage presentation state.
class SubscriptionState {
  /// Creates subscription state.
  SubscriptionState({
    UserEntitlements? entitlements,
    UsageTracker? usage,
    this.products = const [],
    this.isBillingAvailable = false,
    this.purchaseMessage,
    this.priceRefreshesUsedThisMonth = 0,
    this.isLoading = false,
    this.errorMessage,
  }) : entitlements = entitlements ?? UserEntitlements.developmentFree,
       usage =
           usage ??
           UsageTracker.fromLimit(
             limit: UserEntitlements.developmentFree.usageLimit,
             scansUsedThisMonth: 0,
           );

  /// Current entitlements.
  final UserEntitlements entitlements;

  /// Current usage.
  final UsageTracker usage;

  /// Products loaded from Google Play Billing.
  final List<BillingProduct> products;

  /// Whether Google Play Billing is available and configured.
  final bool isBillingAvailable;

  /// Last purchase or restore message.
  final String? purchaseMessage;

  /// Manual price refreshes used in the current local month.
  final int priceRefreshesUsedThisMonth;

  /// Whether usage state is loading.
  final bool isLoading;

  /// User-safe subscription error.
  final String? errorMessage;

  /// User-facing remaining scan value.
  String get remainingLabel =>
      usage.isUnlimited ? 'Unlimited' : usage.remainingScans.toString();

  /// Payment status shown in Settings.
  String get paymentStatusLabel {
    if (isBillingAvailable) {
      return entitlements.isPaid ? 'Active' : 'Configured';
    }

    return 'Not configured';
  }

  /// Remaining manual price refreshes this month.
  int get remainingPriceRefreshes {
    final limit = entitlements.planLimits.monthlyPriceRefreshes;
    return (limit - priceRefreshesUsedThisMonth).clamp(0, 1 << 30);
  }

  /// User-facing monthly refresh usage label.
  String get priceRefreshUsageLabel {
    final limit = entitlements.planLimits.monthlyPriceRefreshes;
    if (limit >= kUnlimitedLabelThreshold) {
      return 'Unlimited';
    }
    return '$priceRefreshesUsedThisMonth / $limit';
  }

  /// Whether another manual price refresh is available.
  bool get canRefreshValue {
    return priceRefreshesUsedThisMonth <
        entitlements.planLimits.monthlyPriceRefreshes;
  }

  /// Creates a copy.
  SubscriptionState copyWith({
    UserEntitlements? entitlements,
    UsageTracker? usage,
    List<BillingProduct>? products,
    bool? isBillingAvailable,
    String? purchaseMessage,
    int? priceRefreshesUsedThisMonth,
    bool? isLoading,
    String? errorMessage,
    bool clearPurchaseMessage = false,
    bool clearErrorMessage = false,
  }) {
    return SubscriptionState(
      entitlements: entitlements ?? this.entitlements,
      usage: usage ?? this.usage,
      products: products ?? this.products,
      isBillingAvailable: isBillingAvailable ?? this.isBillingAvailable,
      purchaseMessage: clearPurchaseMessage
          ? null
          : purchaseMessage ?? this.purchaseMessage,
      priceRefreshesUsedThisMonth:
          priceRefreshesUsedThisMonth ?? this.priceRefreshesUsedThisMonth,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

/// Coordinates subscription and usage limits.
class SubscriptionController extends Notifier<SubscriptionState> {
  late final UsageRepository _usageRepository;
  late final EntitlementRepository _entitlementRepository;
  late final BillingRepository _billingRepository;
  late final UsageLimitConfig _usageConfig;
  late final bool _paymentsConfigured;
  late final AppTelemetryService _telemetry;

  @override
  SubscriptionState build() {
    _usageRepository = ref.watch(usageRepositoryProvider);
    _entitlementRepository = ref.watch(entitlementRepositoryProvider);
    _billingRepository = ref.watch(billingRepositoryProvider);
    _usageConfig = ref.watch(usageLimitConfigProvider);
    _paymentsConfigured = ref.watch(paymentsConfiguredProvider);
    _telemetry = ref.watch(appTelemetryServiceProvider);
    final entitlements = ref.watch(userEntitlementsProvider);
    // Reload the entitlement whenever the signed-in user changes (sign-in,
    // sign-out, or switching accounts) so the plan always reflects the current
    // user's server-owned entitlement rather than a stale device value.
    ref.listen(authControllerProvider.select((state) => state.user?.id), (
      previous,
      next,
    ) {
      if (previous == next) {
        return;
      }
      Future.microtask(() async {
        if (!ref.mounted) {
          return;
        }
        await loadUsage();
      });
    });
    Future.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await loadUsage();
    });
    return SubscriptionState(
      entitlements: entitlements,
      usage: UsageTracker.fromLimit(
        limit: entitlements.usageLimit,
        scansUsedThisMonth: 0,
      ),
    );
  }

  /// Loads current local usage.
  Future<void> loadUsage() async {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final used = await _usageRepository.scansUsedThisMonth();
      final refreshesUsed = await _usageRepository
          .priceRefreshesUsedThisMonth();
      final plan = await _entitlementRepository.loadPlan();
      final billingAvailable = await _billingRepository.isAvailable();
      var products = state.products;
      var errorMessage = state.errorMessage;
      if (billingAvailable) {
        try {
          products = await _billingRepository.loadProducts();
        } on BillingException catch (error) {
          debugPrint('[Subscription] load billing products failed: $error');
          errorMessage = error.message;
        } on Object catch (error) {
          debugPrint('[Subscription] load billing products failed: $error');
          errorMessage = 'Unable to load Google Play products.';
        }
      }
      final entitlements = UserEntitlements.forPlan(
        plan: plan,
        freeLimit: _usageConfig.usageLimit,
        paymentsConfigured: _paymentsConfigured,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        entitlements: entitlements,
        usage: UsageTracker.fromLimit(
          limit: entitlements.usageLimit,
          scansUsedThisMonth: used,
        ),
        priceRefreshesUsedThisMonth: refreshesUsed,
        products: products,
        isBillingAvailable: billingAvailable,
        isLoading: false,
        errorMessage: errorMessage,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] load usage failed: $error');
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Usage limits are unavailable. Scanning remains local.',
      );
    }
  }

  /// Throws if analysis is not allowed by the current limit.
  Future<void> ensureCanAnalyze() async {
    await loadUsage();
    if (state.usage.canAnalyze) {
      return;
    }

    throw SubscriptionException(
      'Monthly free scan limit reached. Your scans reset ${_formatResetDate(state.usage.resetAt)}.',
    );
  }

  /// Records a successful analysis.
  Future<void> recordSuccessfulAnalysis() async {
    try {
      final used = await _usageRepository.incrementScansUsedThisMonth();
      state = state.copyWith(
        usage: UsageTracker.fromLimit(
          limit: state.entitlements.usageLimit,
          scansUsedThisMonth: used,
        ),
        clearErrorMessage: true,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] increment usage failed: $error');
      state = state.copyWith(errorMessage: 'Usage tracking will update later.');
    }
  }

  /// Throws if a manual price refresh is not allowed by current monthly limits.
  Future<void> ensureCanRefreshValue() async {
    await loadUsage();
    if (state.canRefreshValue) {
      return;
    }

    throw SubscriptionException(
      'Monthly price refresh limit reached. Your ${state.entitlements.plan.displayName} plan includes ${state.entitlements.planLimits.monthlyPriceRefreshes} refreshes per month.',
    );
  }

  /// Records a successful manual value refresh.
  Future<void> recordSuccessfulPriceRefresh() async {
    try {
      final used = await _usageRepository.incrementPriceRefreshesThisMonth();
      state = state.copyWith(
        priceRefreshesUsedThisMonth: used,
        clearErrorMessage: true,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] increment price refresh failed: $error');
      state = state.copyWith(
        errorMessage: 'Refresh usage tracking will update later.',
      );
    }
  }

  /// Purchases a paid plan through Google Play Billing.
  Future<void> purchasePlan(SubscriptionPlan plan) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearPurchaseMessage: true,
    );
    _trackTelemetry(
      TelemetryEventNames.subscriptionPurchaseStarted,
      properties: {'plan': plan.name},
    );
    try {
      final result = await _billingRepository.purchase(plan);
      await _applyPurchaseResult(result);
    } on BillingException catch (error) {
      _recordTelemetryError(
        error,
        reason: 'billing_failure',
        properties: {'plan': plan.name},
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
        purchaseMessage: error.message,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] purchase failed: $error');
      _recordTelemetryError(
        error,
        reason: 'billing_failure',
        properties: {'plan': plan.name},
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Purchase failed. Please try again.',
        purchaseMessage: 'Purchase failed. Please try again.',
      );
    }
  }

  /// Restores previous Google Play purchases.
  Future<void> restorePurchases() async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearPurchaseMessage: true,
    );
    try {
      final result = await _billingRepository.restorePurchases();
      await _applyPurchaseResult(result);
    } on BillingException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
        purchaseMessage: error.message,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] restore failed: $error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Restore failed. Please try again.',
        purchaseMessage: 'Restore failed. Please try again.',
      );
    }
  }

  Future<void> _applyPurchaseResult(PurchaseResult result) async {
    if (result.grantsEntitlement) {
      final plan = result.plan!;
      await _entitlementRepository.savePlan(
        plan,
        source: result.source,
        purchaseToken: result.purchaseToken,
      );
      final entitlements = UserEntitlements.forPlan(
        plan: plan,
        freeLimit: _usageConfig.usageLimit,
        paymentsConfigured: _paymentsConfigured,
      );
      state = state.copyWith(
        entitlements: entitlements,
        usage: UsageTracker.fromLimit(
          limit: entitlements.usageLimit,
          scansUsedThisMonth: state.usage.scansUsedThisMonth,
        ),
        isLoading: false,
        purchaseMessage: result.message,
      );
      _trackTelemetry(
        TelemetryEventNames.subscriptionPurchaseSuccess,
        properties: {'plan': plan.name, 'source': result.status.name},
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      purchaseMessage: result.message,
      errorMessage: result.status == PurchaseResultStatus.failed
          ? result.message
          : null,
    );
  }

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatResetDate(DateTime resetAt) {
    return 'on ${_monthNames[resetAt.month - 1]} 1';
  }

  void _trackTelemetry(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) {
    unawaited(_telemetry.trackEvent(eventName, properties: properties));
  }

  void _recordTelemetryError(
    Object error, {
    String? reason,
    Map<String, Object?> properties = const {},
  }) {
    unawaited(
      _telemetry.recordNonFatalError(
        error,
        reason: reason,
        properties: properties,
      ),
    );
  }
}

/// Provides subscription state.
final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );

/// Provides the active feature limits for the current plan.
final activePlanLimitsProvider = Provider<PlanLimits>((ref) {
  return ref.watch(subscriptionControllerProvider).entitlements.planLimits;
});
