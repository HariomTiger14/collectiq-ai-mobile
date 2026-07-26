import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/push_device_registration_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SupabasePushDeviceRegistrationRepository
    implements PushDeviceRegistrationRepository {
  const SupabasePushDeviceRegistrationRepository({
    required this.authService,
    required this.supabaseDataGateway,
    this.tableName = 'push_device_registrations',
  });

  final AuthService authService;
  final SupabaseDataGateway supabaseDataGateway;
  final String tableName;

  @override
  Future<PushNotificationRegistrationStatus> registerToken(
    PushNotificationToken token,
  ) async {
    if (!token.isValid || !supabaseDataGateway.isConfigured) {
      return PushNotificationRegistrationStatus.unavailable;
    }
    final session = await supabaseDataGateway.currentSession();
    if (session == null ||
        session.isAnonymous ||
        !await authService.isSignedIn()) {
      return PushNotificationRegistrationStatus.permissionRequired;
    }

    try {
      await supabaseDataGateway.authenticatedPostWithSession<List<dynamic>>(
        '/rest/v1/$tableName',
        session: session,
        queryParameters: const {'on_conflict': 'user_id,device_token'},
        data: [supabaseRowForPushToken(token, session.userId)],
        options: Options(
          headers: const {
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
        ),
      );
      return PushNotificationRegistrationStatus.registered;
    } on Object catch (error) {
      debugPrint('[Push] device registration failed: $error');
      return PushNotificationRegistrationStatus.failed;
    }
  }
}

@visibleForTesting
Map<String, dynamic> supabaseRowForPushToken(
  PushNotificationToken token,
  String userId,
) {
  final now = DateTime.now().toIso8601String();
  return {
    'user_id': userId,
    'device_token': token.token,
    'provider': token.provider,
    'platform': token.platform,
    'enabled': true,
    'last_seen_at': now,
    'raw_json': {
      'provider': token.provider,
      'platform': token.platform,
      'createdAt': token.createdAt.toIso8601String(),
    },
    'updated_at': now,
  };
}
