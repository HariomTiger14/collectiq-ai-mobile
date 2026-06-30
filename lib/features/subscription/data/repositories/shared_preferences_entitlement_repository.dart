import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local entitlement persistence for restored/purchased plans.
class SharedPreferencesEntitlementRepository implements EntitlementRepository {
  /// Creates a local entitlement repository.
  const SharedPreferencesEntitlementRepository();

  static const _planKey = 'subscription_active_plan';

  @override
  Future<SubscriptionPlan> loadPlan() async {
    final preferences = await SharedPreferences.getInstance();
    return SubscriptionPlan.fromName(preferences.getString(_planKey));
  }

  @override
  Future<void> savePlan(SubscriptionPlan plan) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_planKey, plan.name);
  }
}
