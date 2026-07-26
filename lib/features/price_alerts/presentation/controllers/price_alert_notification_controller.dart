import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/price_alerts/data/repositories/supabase_push_device_registration_repository.dart';
import 'package:collectiq_ai/features/price_alerts/data/repositories/shared_preferences_price_alert_notification_repository.dart';
import 'package:collectiq_ai/features/price_alerts/data/services/method_channel_price_alert_notification_service.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_notification_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/push_device_registration_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_dispatcher.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_service.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final priceAlertNotificationRepositoryProvider =
    Provider<PriceAlertNotificationRepository>((ref) {
      return const SharedPreferencesPriceAlertNotificationRepository();
    });

final priceAlertNotificationServiceProvider =
    Provider<PriceAlertNotificationService>((ref) {
      return const MethodChannelPriceAlertNotificationService();
    });

final pushDeviceRegistrationRepositoryProvider =
    Provider<PushDeviceRegistrationRepository>((ref) {
      final gateway = ref.watch(supabaseServiceProvider);
      if (!gateway.isConfigured) {
        return const NoOpPushDeviceRegistrationRepository();
      }
      return SupabasePushDeviceRegistrationRepository(
        authService: ref.watch(cloudServiceRegistryProvider).authService,
        supabaseDataGateway: gateway,
      );
    });

final priceAlertNotificationDispatcherProvider =
    Provider<PriceAlertNotificationDispatcher>((ref) {
      return PriceAlertNotificationDispatcher(
        ref.watch(priceAlertNotificationRepositoryProvider),
        ref.watch(priceAlertNotificationServiceProvider),
        ref.watch(appTelemetryServiceProvider),
      );
    });

final priceAlertNotificationControllerProvider =
    NotifierProvider<
      PriceAlertNotificationController,
      PriceAlertNotificationState
    >(PriceAlertNotificationController.new);

class PriceAlertNotificationController
    extends Notifier<PriceAlertNotificationState> {
  late final PriceAlertNotificationRepository _repository;
  late final PriceAlertNotificationService _service;
  late final PushDeviceRegistrationRepository _pushRegistrationRepository;

  @override
  PriceAlertNotificationState build() {
    _repository = ref.watch(priceAlertNotificationRepositoryProvider);
    _service = ref.watch(priceAlertNotificationServiceProvider);
    _pushRegistrationRepository = ref.watch(
      pushDeviceRegistrationRepositoryProvider,
    );
    Future.microtask(load);
    return const PriceAlertNotificationState(
      enabled: true,
      permissionStatus: PriceAlertNotificationPermissionStatus.unknown,
      lastDeliveryStatus: PriceAlertNotificationDeliveryStatus.idle,
      isLoading: true,
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final preferences = await _repository.getPreferences();
    await _service.initialize();
    final permissionStatus = await _service.getPermissionStatus();
    if (!ref.mounted) {
      return;
    }
    state = PriceAlertNotificationState(
      enabled: preferences.enabled,
      permissionStatus: permissionStatus,
      lastDeliveryStatus: preferences.lastDeliveryStatus,
      lastMessage: preferences.lastMessage,
      lastNotificationAt: preferences.lastNotificationAt,
    );
    await registerPushDevice();
  }

  Future<void> setEnabled(bool enabled) async {
    await _repository.setEnabled(enabled);
    state = state.copyWith(enabled: enabled);
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true);
    await _service.initialize();
    final permissionStatus = await _service.requestPermission();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      permissionStatus: permissionStatus,
      isLoading: false,
    );
    await registerPushDevice();
  }

  Future<void> refreshPermissionStatus() async {
    final permissionStatus = await _service.getPermissionStatus();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(permissionStatus: permissionStatus);
  }

  Future<void> registerPushDevice() async {
    if (!state.enabled || !state.permissionStatus.canNotify) {
      state = state.copyWith(
        pushRegistrationStatus:
            PushNotificationRegistrationStatus.permissionRequired,
      );
      return;
    }
    final token = await _service.getPushToken();
    if (!ref.mounted) {
      return;
    }
    if (token == null) {
      state = state.copyWith(
        pushRegistrationStatus: PushNotificationRegistrationStatus.unavailable,
      );
      return;
    }
    final status = await _pushRegistrationRepository.registerToken(token);
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(pushRegistrationStatus: status);
  }
}
