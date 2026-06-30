import 'package:collectiq_ai/features/subscription/data/repositories/shared_preferences_usage_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_exception.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/user_entitlements.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_tracker.dart';
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

/// Provides user entitlements.
final userEntitlementsProvider = Provider<UserEntitlements>((ref) {
  return UserEntitlements(
    plan: UserEntitlements.developmentFree.plan,
    usageLimit: ref.watch(usageLimitConfigProvider).usageLimit,
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

  /// Whether usage state is loading.
  final bool isLoading;

  /// User-safe subscription error.
  final String? errorMessage;

  /// User-facing remaining scan value.
  String get remainingLabel =>
      usage.isUnlimited ? 'Unlimited' : usage.remainingScans.toString();

  /// Payment status shown in Settings.
  String get paymentStatusLabel =>
      entitlements.paymentsConfigured ? 'Configured' : 'Not configured';

  /// Creates a copy.
  SubscriptionState copyWith({
    UserEntitlements? entitlements,
    UsageTracker? usage,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SubscriptionState(
      entitlements: entitlements ?? this.entitlements,
      usage: usage ?? this.usage,
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
  late final UserEntitlements _entitlements;

  @override
  SubscriptionState build() {
    _usageRepository = ref.watch(usageRepositoryProvider);
    _entitlements = ref.watch(userEntitlementsProvider);
    Future.microtask(loadUsage);
    return SubscriptionState(
      entitlements: _entitlements,
      usage: UsageTracker.fromLimit(
        limit: _entitlements.usageLimit,
        scansUsedToday: 0,
      ),
    );
  }

  /// Loads current local usage.
  Future<void> loadUsage() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final used = await _usageRepository.scansUsedToday();
      state = state.copyWith(
        entitlements: _entitlements,
        usage: UsageTracker.fromLimit(
          limit: _entitlements.usageLimit,
          scansUsedToday: used,
        ),
        isLoading: false,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] load usage failed: $error');
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
          limit: _entitlements.usageLimit,
          scansUsedToday: used,
        ),
        clearErrorMessage: true,
      );
    } on Object catch (error) {
      debugPrint('[Subscription] increment usage failed: $error');
      state = state.copyWith(errorMessage: 'Usage tracking will update later.');
    }
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
