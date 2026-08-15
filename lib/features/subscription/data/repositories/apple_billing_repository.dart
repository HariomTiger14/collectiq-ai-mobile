import 'dart:async';

import 'package:collectiq_ai/features/subscription/domain/entities/billing_exception.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/purchase_result.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/billing_repository.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Apple App Store (StoreKit2) billing product configuration.
class AppleBillingConfig {
  /// Creates billing config.
  const AppleBillingConfig({
    this.enabled = false,
    this.proProductId = 'collectiq_pro_monthly_test',
    this.premiumProductId = 'collectiq_premium_monthly_test',
  });

  /// Whether billing should be enabled for this build.
  final bool enabled;

  /// App Store product id for Pro.
  final String proProductId;

  /// App Store product id for Premium.
  final String premiumProductId;

  /// Reads config from dart defines. Separate dart-defines from Google
  /// Play's (COLLECTIQ_APPLE_* vs COLLECTIQ_*) since App Store Connect
  /// product ids are configured independently and aren't guaranteed to
  /// match Play Console's, even though both currently default to the same
  /// string for simplicity until real App Store Connect products exist.
  factory AppleBillingConfig.fromEnvironment() {
    return const AppleBillingConfig(
      enabled: bool.fromEnvironment(
        'COLLECTIQ_BILLING_ENABLED',
        defaultValue: false,
      ),
      proProductId: String.fromEnvironment(
        'COLLECTIQ_APPLE_PRO_PRODUCT_ID',
        defaultValue: 'collectiq_pro_monthly_test',
      ),
      premiumProductId: String.fromEnvironment(
        'COLLECTIQ_APPLE_PREMIUM_PRODUCT_ID',
        defaultValue: 'collectiq_premium_monthly_test',
      ),
    );
  }

  /// Product ids to query in the App Store.
  Set<String> get productIds => {proProductId, premiumProductId};

  /// Plan for a product id.
  SubscriptionPlan? planForProductId(String productId) {
    if (productId == proProductId) {
      return SubscriptionPlan.pro;
    }
    if (productId == premiumProductId) {
      return SubscriptionPlan.premium;
    }
    return null;
  }

  /// Product id for a plan.
  String? productIdForPlan(SubscriptionPlan plan) {
    return switch (plan) {
      SubscriptionPlan.free => null,
      SubscriptionPlan.pro => proProductId,
      SubscriptionPlan.premium => premiumProductId,
    };
  }
}

/// iOS App Store Billing implementation, via the same federated
/// `in_app_purchase` plugin GooglePlayBillingRepository uses -- its iOS
/// platform implementation (in_app_purchase_storekit) already defaults to
/// StoreKit2, so this needs no separate StoreKit-specific plugin calls,
/// only Apple-specific config/product ids and a different `source`.
///
/// The one real difference from Android: what
/// `verificationData.serverVerificationData` actually contains. On Android
/// it's Google Play's opaque purchase token; on iOS under StoreKit2 it's
/// the transaction's JWS representation (jwsRepresentation) -- confirmed by
/// reading in_app_purchase_storekit's own SK2Transaction wrapper source,
/// which explicitly documents `receiptData`/`serverVerificationData` as
/// "the JWS representation of the transaction". The backend verifies that
/// JWS signature locally rather than treating it as an opaque token.
class AppleBillingRepository implements BillingRepository {
  /// Creates an Apple App Store billing repository.
  AppleBillingRepository({
    required this.config,
    InAppPurchase? inAppPurchase,
    this.purchaseTimeout = const Duration(minutes: 2),
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  /// Billing config.
  final AppleBillingConfig config;
  final InAppPurchase _inAppPurchase;
  final Duration purchaseTimeout;

  List<ProductDetails> _products = const [];

  @override
  Future<bool> isAvailable() async {
    if (!config.enabled) {
      return false;
    }
    return _inAppPurchase.isAvailable();
  }

  @override
  Future<List<BillingProduct>> loadProducts() async {
    if (!await isAvailable()) {
      throw const BillingException(
        'App Store Billing is not available for this build.',
      );
    }

    final response = await _inAppPurchase.queryProductDetails(
      config.productIds,
    );
    if (response.error != null) {
      throw BillingException(
        response.error?.message ?? 'Unable to load billing products.',
      );
    }
    if (response.productDetails.isEmpty) {
      throw const BillingException(
        'No App Store subscription products are configured.',
      );
    }

    _products = response.productDetails;
    return [
      for (final product in response.productDetails)
        if (config.planForProductId(product.id) != null)
          BillingProduct(
            id: product.id,
            plan: config.planForProductId(product.id)!,
            title: product.title,
            description: product.description,
            price: product.price,
            currencyCode: product.currencyCode,
          ),
    ];
  }

  @override
  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    if (plan == SubscriptionPlan.free) {
      return const PurchaseResult(
        status: PurchaseResultStatus.success,
        plan: SubscriptionPlan.free,
        message: 'Free plan is active.',
      );
    }

    if (!await isAvailable()) {
      return const PurchaseResult(
        status: PurchaseResultStatus.failed,
        message: 'Payments are not configured for this build.',
      );
    }

    if (_products.isEmpty) {
      await loadProducts();
    }

    final productId = config.productIdForPlan(plan);
    final product = _products
        .where((details) => details.id == productId)
        .firstOrNull;
    if (product == null) {
      return PurchaseResult(
        status: PurchaseResultStatus.failed,
        message: '${plan.displayName} is not configured in the App Store.',
      );
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    final completer = Completer<PurchaseResult>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = _inAppPurchase.purchaseStream.listen(
      (detailsList) async {
        for (final details in detailsList) {
          if (details.productID != product.id || completer.isCompleted) {
            continue;
          }

          final result = await _resultForPurchase(details, restored: false);
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.complete(
            PurchaseResult(
              status: PurchaseResultStatus.failed,
              message: 'Purchase failed: $error',
            ),
          );
        }
      },
    );

    try {
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      if (!started && !completer.isCompleted) {
        completer.complete(
          const PurchaseResult(
            status: PurchaseResultStatus.cancelled,
            message: 'Purchase was cancelled.',
          ),
        );
      }

      return await completer.future.timeout(
        purchaseTimeout,
        onTimeout: () {
          return const PurchaseResult(
            status: PurchaseResultStatus.pending,
            message: 'Purchase is pending in the App Store.',
          );
        },
      );
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!await isAvailable()) {
      return const PurchaseResult(
        status: PurchaseResultStatus.failed,
        message: 'Payments are not configured for this build.',
      );
    }

    final completer = Completer<PurchaseResult>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = _inAppPurchase.purchaseStream.listen(
      (detailsList) async {
        for (final details in detailsList) {
          final plan = config.planForProductId(details.productID);
          if (plan == null || completer.isCompleted) {
            continue;
          }

          final result = await _resultForPurchase(details, restored: true);
          if (result.grantsEntitlement && !completer.isCompleted) {
            completer.complete(result);
            return;
          }
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.complete(
            PurchaseResult(
              status: PurchaseResultStatus.failed,
              message: 'Restore failed: $error',
            ),
          );
        }
      },
    );

    try {
      await _inAppPurchase.restorePurchases();
      return await completer.future.timeout(
        purchaseTimeout,
        onTimeout: () {
          return const PurchaseResult(
            status: PurchaseResultStatus.failed,
            message: 'No active App Store purchases were found.',
          );
        },
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<PurchaseResult> _resultForPurchase(
    PurchaseDetails details, {
    required bool restored,
  }) async {
    if (details.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(details);
    }

    final plan = config.planForProductId(details.productID);
    // See the class doc comment -- under StoreKit2 this is the
    // transaction's JWS representation, not an opaque token.
    final signedTransaction = details.verificationData.serverVerificationData;
    return switch (details.status) {
      PurchaseStatus.purchased => PurchaseResult(
        status: restored
            ? PurchaseResultStatus.restored
            : PurchaseResultStatus.success,
        plan: plan,
        message: '${plan?.displayName ?? 'Purchase'} is active.',
        source: 'app_store',
        purchaseToken: signedTransaction,
      ),
      PurchaseStatus.restored => PurchaseResult(
        status: PurchaseResultStatus.restored,
        plan: plan,
        message: '${plan?.displayName ?? 'Purchase'} restored.',
        source: 'app_store',
        purchaseToken: signedTransaction,
      ),
      PurchaseStatus.pending => const PurchaseResult(
        status: PurchaseResultStatus.pending,
        message: 'Purchase is pending in the App Store.',
      ),
      PurchaseStatus.canceled => const PurchaseResult(
        status: PurchaseResultStatus.cancelled,
        message: 'Purchase was cancelled.',
      ),
      PurchaseStatus.error => PurchaseResult(
        status: PurchaseResultStatus.failed,
        message: details.error?.message ?? 'App Store purchase failed.',
      ),
    };
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
