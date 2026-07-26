import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';

abstract class PushDeviceRegistrationRepository {
  Future<PushNotificationRegistrationStatus> registerToken(
    PushNotificationToken token,
  );
}

class NoOpPushDeviceRegistrationRepository
    implements PushDeviceRegistrationRepository {
  const NoOpPushDeviceRegistrationRepository();

  @override
  Future<PushNotificationRegistrationStatus> registerToken(
    PushNotificationToken token,
  ) async {
    return PushNotificationRegistrationStatus.unavailable;
  }
}
