import 'package:collectiq_ai/features/price_alerts/data/repositories/shared_preferences_price_alert_notification_repository.dart';
import 'package:collectiq_ai/features/price_alerts/data/services/method_channel_price_alert_notification_service.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_notification_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_dispatcher.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final priceAlertNotificationRepositoryProvider =
    Provider<PriceAlertNotificationRepository>((ref) {
      return const SharedPreferencesPriceAlertNotificationRepository();
    });

final priceAlertNotificationServiceProvider =
    Provider<PriceAlertNotificationService>((ref) {
      return const MethodChannelPriceAlertNotificationService();
    });

final priceAlertNotificationDispatcherProvider =
    Provider<PriceAlertNotificationDispatcher>((ref) {
      return PriceAlertNotificationDispatcher(
        ref.watch(priceAlertNotificationRepositoryProvider),
        ref.watch(priceAlertNotificationServiceProvider),
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

  @override
  PriceAlertNotificationState build() {
    _repository = ref.watch(priceAlertNotificationRepositoryProvider);
    _service = ref.watch(priceAlertNotificationServiceProvider);
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
    state = PriceAlertNotificationState(
      enabled: preferences.enabled,
      permissionStatus: permissionStatus,
      lastDeliveryStatus: preferences.lastDeliveryStatus,
      lastMessage: preferences.lastMessage,
      lastNotificationAt: preferences.lastNotificationAt,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await _repository.setEnabled(enabled);
    state = state.copyWith(enabled: enabled);
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true);
    await _service.initialize();
    final permissionStatus = await _service.requestPermission();
    state = state.copyWith(
      permissionStatus: permissionStatus,
      isLoading: false,
    );
  }

  Future<void> refreshPermissionStatus() async {
    final permissionStatus = await _service.getPermissionStatus();
    state = state.copyWith(permissionStatus: permissionStatus);
  }
}
