import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Reads/writes the plan against the server-owned entitlement
/// (`user_subscriptions`) so the subscription is a per-user attribute, not a
/// spoofable device-local flag. A local repository is used as an offline cache
/// and for optimistic updates; the server remains the source of truth.
class CloudEntitlementRepository implements EntitlementRepository {
  CloudEntitlementRepository({
    required this.baseUrl,
    required this.supabaseService,
    required this.cache,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String baseUrl;
  final SupabaseService supabaseService;

  /// Local cache used when offline / signed out and for optimistic writes.
  final EntitlementRepository cache;

  final Dio _dio;

  static const _timeout = Duration(seconds: 12);

  Future<String?> _accessToken() async {
    try {
      final session = await supabaseService.currentSession();
      if (session == null ||
          session.accessToken.isEmpty ||
          session.isAnonymous) {
        return null;
      }
      return session.accessToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SubscriptionPlan> loadPlan() async {
    final token = await _accessToken();
    // No signed-in user → free. The plan belongs to the account, so a signed
    // out / anonymous device is always free.
    if (token == null) {
      return SubscriptionPlan.free;
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/subscription/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      final plan = SubscriptionPlan.fromName(response.data?['plan'] as String?);
      await cache.savePlan(plan);
      return plan;
    } catch (error) {
      // Offline / transient failure — fall back to the last known plan so the
      // user isn't unexpectedly downgraded mid-session.
      debugPrint('[Entitlement] cloud load failed, using cache: $error');
      return cache.loadPlan();
    }
  }

  @override
  Future<void> savePlan(
    SubscriptionPlan plan, {
    String? source,
    String? purchaseToken,
  }) async {
    // Optimistic local cache first so the UI reflects the change immediately.
    await cache.savePlan(plan);
    final token = await _accessToken();
    if (token == null) {
      return;
    }
    try {
      await _dio.post<Map<String, dynamic>>(
        '$baseUrl/subscription/verify',
        data: {
          'plan': plan.name,
          'source': source ?? 'mock',
          if (purchaseToken != null) 'purchaseToken': purchaseToken,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
    } catch (error) {
      // The server didn't record it; the local cache keeps the UI consistent
      // and the next loadPlan() reconciles against the server.
      debugPrint('[Entitlement] cloud verify failed: $error');
    }
  }
}
