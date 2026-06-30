enum PriceAlertNotificationPermissionStatus {
  unknown(label: 'Unknown'),
  granted(label: 'Allowed'),
  denied(label: 'Denied'),
  notSupported(label: 'Not supported');

  const PriceAlertNotificationPermissionStatus({required this.label});

  final String label;

  bool get canNotify => this == PriceAlertNotificationPermissionStatus.granted;

  static PriceAlertNotificationPermissionStatus fromName(String? value) {
    for (final status in PriceAlertNotificationPermissionStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return PriceAlertNotificationPermissionStatus.unknown;
  }
}

enum PriceAlertNotificationDeliveryStatus {
  idle(label: 'Ready'),
  disabled(label: 'Disabled'),
  delivered(label: 'Delivered'),
  permissionDenied(label: 'Permission denied'),
  failed(label: 'Failed');

  const PriceAlertNotificationDeliveryStatus({required this.label});

  final String label;

  static PriceAlertNotificationDeliveryStatus fromName(String? value) {
    for (final status in PriceAlertNotificationDeliveryStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return PriceAlertNotificationDeliveryStatus.idle;
  }
}

class PriceAlertNotificationPreferences {
  const PriceAlertNotificationPreferences({
    required this.enabled,
    required this.notifiedAlertTokens,
    this.lastDeliveryStatus = PriceAlertNotificationDeliveryStatus.idle,
    this.lastMessage,
    this.lastNotificationAt,
  });

  final bool enabled;
  final Set<String> notifiedAlertTokens;
  final PriceAlertNotificationDeliveryStatus lastDeliveryStatus;
  final String? lastMessage;
  final DateTime? lastNotificationAt;

  static const defaults = PriceAlertNotificationPreferences(
    enabled: true,
    notifiedAlertTokens: {},
  );

  PriceAlertNotificationPreferences copyWith({
    bool? enabled,
    Set<String>? notifiedAlertTokens,
    PriceAlertNotificationDeliveryStatus? lastDeliveryStatus,
    String? lastMessage,
    DateTime? lastNotificationAt,
    bool clearLastMessage = false,
    bool clearLastNotificationAt = false,
  }) {
    return PriceAlertNotificationPreferences(
      enabled: enabled ?? this.enabled,
      notifiedAlertTokens: notifiedAlertTokens ?? this.notifiedAlertTokens,
      lastDeliveryStatus: lastDeliveryStatus ?? this.lastDeliveryStatus,
      lastMessage: clearLastMessage ? null : lastMessage ?? this.lastMessage,
      lastNotificationAt: clearLastNotificationAt
          ? null
          : lastNotificationAt ?? this.lastNotificationAt,
    );
  }
}

class PriceAlertNotificationState {
  const PriceAlertNotificationState({
    required this.enabled,
    required this.permissionStatus,
    required this.lastDeliveryStatus,
    this.lastMessage,
    this.lastNotificationAt,
    this.isLoading = false,
  });

  final bool enabled;
  final PriceAlertNotificationPermissionStatus permissionStatus;
  final PriceAlertNotificationDeliveryStatus lastDeliveryStatus;
  final String? lastMessage;
  final DateTime? lastNotificationAt;
  final bool isLoading;

  String get settingsStatusLabel {
    if (!enabled) {
      return 'Off';
    }
    if (permissionStatus == PriceAlertNotificationPermissionStatus.denied) {
      return 'Denied';
    }
    if (permissionStatus ==
        PriceAlertNotificationPermissionStatus.notSupported) {
      return 'Unavailable';
    }
    return permissionStatus.canNotify ? 'On' : 'Needs permission';
  }

  String get settingsSubtitle {
    if (!enabled) {
      return 'Price alert notifications are disabled on this device.';
    }
    if (permissionStatus == PriceAlertNotificationPermissionStatus.denied) {
      return 'Enable notifications in Android settings to receive local alerts.';
    }
    if (permissionStatus ==
        PriceAlertNotificationPermissionStatus.notSupported) {
      return 'Local notifications are not supported on this platform.';
    }
    return 'Local notifications are shown only when saved price alerts trigger.';
  }

  PriceAlertNotificationState copyWith({
    bool? enabled,
    PriceAlertNotificationPermissionStatus? permissionStatus,
    PriceAlertNotificationDeliveryStatus? lastDeliveryStatus,
    String? lastMessage,
    DateTime? lastNotificationAt,
    bool? isLoading,
    bool clearLastMessage = false,
    bool clearLastNotificationAt = false,
  }) {
    return PriceAlertNotificationState(
      enabled: enabled ?? this.enabled,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastDeliveryStatus: lastDeliveryStatus ?? this.lastDeliveryStatus,
      lastMessage: clearLastMessage ? null : lastMessage ?? this.lastMessage,
      lastNotificationAt: clearLastNotificationAt
          ? null
          : lastNotificationAt ?? this.lastNotificationAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PriceAlertNotificationResult {
  const PriceAlertNotificationResult({
    required this.status,
    required this.message,
    this.deliveredCount = 0,
  });

  final PriceAlertNotificationDeliveryStatus status;
  final String message;
  final int deliveredCount;
}
