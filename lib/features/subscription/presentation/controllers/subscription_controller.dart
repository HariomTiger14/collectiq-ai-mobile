import 'package:collectiq_ai/features/subscription/data/repositories/google_play_billing_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/shared_preferences_entitlement_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/shared_preferences_usage_repository.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/unavailable_billing_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_exception.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
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
    this.dailyFreeScanLimit = 25,
  });

  /// Whether local/dev builds should avoid blocking scanner testing.
  final bool developmentUnlimited;

  /// Daily scan limit used when unlimited mode is disabled.
  final int dailyFreeScanLimit;

  /// Build config from dart-define values.
  factory UsageLimitConfig.fromEnvironment() {
    return const UsageLimitConfig(
      developmentUnlimited: bool.fromEnvironment(
        'COLLECTIQ_USAGE_UNLIMITED',
        defaultValue: true,
      ),
      dailyFreeScanLimit: int.fromEnvironment(
        'COLLECTIQ_DAILY_FREE_SCAN_LIMIT',
        defaultValue: 25,
      ),
    );
  }

  /// Limit model for the active config.
  UsageLimit get usageLimit {
    return UsageLimit(
      dailyFreeScanLimit: dailyFreeScanLimit,
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

/// Provides billing repository.
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final config = ref.watch(googlePlayBillingConfigProvider);
  if (!config.enabled) {
    return const UnavailableBillingRepository();
  }

  return GooglePlayBillingRepository(config: config);
});

/// Provides entitlement persistence.
final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return const SharedPreferencesEntitlementRepository();
});

/// Provides user entitlements.
final userEntitlementsProvider = Provider<UserEntitlements>((ref) {
  return UserEntitlements.forPlan(
    plan: UserEntitlements.developmentFree.plan,
    freeLimit: ref.watch(usageLimitConfigProvider).usageLimit,
    paymentsConfigured: ref.watch(googlePlayBillingConfigProvider).enabled,
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
    this.isLoading = false,
    this.errorMessage,
  }) : entitlements = entitlements ?? UserEntitlements.developmentFree,
       usage =
           usage ??
           UsageTracker.fromLimit(
             limit: UserEntitlements.developmentFree.usageLimit,
             scansUsedToday: 0,
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

  /// Creates a copy.
  SubscriptionState copyWith({
    UserEntitlements? entitlements,
    UsageTracker? usage,
    List<BillingProduct>? products,
    bool? isBillingAvailable,
    String? purchaseMessage,
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
  late final GooglePlayBillingConfig _billingConfig;

  @override
  SubscriptionState build() {
    _usageRepository = ref.watch(usageRepositoryProvider);
    _entitlementRepository = ref.watch(entitlementRepositoryProvider);
    _billingRepository = ref.watch(billingRepositoryProvider);
    _usageConfig = ref.watch(usageLimitConfigProvider);
    _billingConfig = ref.watch(googlePlayBillingConfigProvider);
    final entitlements = ref.watch(userEntitlementsProvider);
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
        scansUsedToday: 0,
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
      final used = await _usageRepository.scansUsedToday();
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
        paymentsConfigured: _billingConfig.enabled,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        entitlements: entitlements,
        usage: UsageTracker.fromLimit(
          limit: entitlements.usageLimit,
          scansUsedToday: used,
        ),
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
      'Daily free scan limit reached. Your scans reset ${_formatResetDate(state.usage.resetAt)}.',
    );
  }

  /// Records a successful analysis.
  Future<void> recordSuccessfulAnalysis() async {
    try {
      final used = await _usageRepository.incrementScansUsedToday();
      state = state.copyWith(
        usage: UsageTracker.fromLimit(
          limit: state.entitlements.usageLimit,
          scansUsedToday: used,
        ),
        clearErrorMessage: true,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] increment usage failed: $error');
      state = state.copyWith(errorMessage: 'Usage tracking will update later.');
    }
  }

  /// Purchases a paid plan through Google Play Billing.
  Future<void> purchasePlan(SubscriptionPlan plan) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearPurchaseMessage: true,
    );
    try {
      final result = await _billingRepository.purchase(plan);
      await _applyPurchaseResult(result);
    } on BillingException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
        purchaseMessage: error.message,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] purchase failed: $error');
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
      await _entitlementRepository.savePlan(plan);
      final entitlements = UserEntitlements.forPlan(
        plan: plan,
        freeLimit: _usageConfig.usageLimit,
        paymentsConfigured: _billingConfig.enabled,
      );
      state = state.copyWith(
        entitlements: entitlements,
        usage: UsageTracker.fromLimit(
          limit: entitlements.usageLimit,
          scansUsedToday: state.usage.scansUsedToday,
        ),
        isLoading: false,
        purchaseMessage: result.message,
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

  String _formatResetDate(DateTime resetAt) {
    final hour = resetAt.hour.toString().padLeft(2, '0');
    final minute = resetAt.minute.toString().padLeft(2, '0');
    return 'at $hour:$minute tomorrow';
  }
}

/// Provides subscription state.
final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );
