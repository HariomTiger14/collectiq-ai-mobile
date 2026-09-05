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
    this.pushRegistrationStatus = PushNotificationRegistrationStatus.idle,
    this.lastMessage,
    this.lastNotificationAt,
    this.isLoading = false,
  });

  final bool enabled;
  final PriceAlertNotificationPermissionStatus permissionStatus;
  final PriceAlertNotificationDeliveryStatus lastDeliveryStatus;
  final PushNotificationRegistrationStatus pushRegistrationStatus;
  final String? lastMessage;
  final DateTime? lastNotificationAt;
  final bool isLoading;

  String get settingsStatusLabel {
    if (!enabled) {
      return 'Off';
    }
    // Cloud push is the real alert channel, so a registered device is "On"
    // even where on-device local notifications aren't available (e.g. sim).
    if (pushRegistrationStatus ==
        PushNotificationRegistrationStatus.registered) {
      return 'On';
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

  /// True when alerts are enabled but won't actually fire (permission
  /// missing or denied) -- worth flagging distinctly from a routine "Off"/
  /// "On" status.
  bool get settingsStatusNeedsAttention {
    if (!enabled) {
      return false;
    }
    if (pushRegistrationStatus ==
        PushNotificationRegistrationStatus.registered) {
      return false;
    }
    return permissionStatus == PriceAlertNotificationPermissionStatus.denied ||
        permissionStatus == PriceAlertNotificationPermissionStatus.unknown;
  }

  String get settingsSubtitle {
    if (!enabled) {
      return 'Turn on notifications to get alerts when your prices move.';
    }
    if (pushRegistrationStatus ==
        PushNotificationRegistrationStatus.registered) {
      return "You'll be notified when a price alert triggers.";
    }
    if (permissionStatus == PriceAlertNotificationPermissionStatus.denied) {
      return 'Enable notifications in Settings to get price alerts.';
    }
    if (permissionStatus ==
        PriceAlertNotificationPermissionStatus.notSupported) {
      return "Alerts aren't available on this device yet.";
    }
    if (!permissionStatus.canNotify) {
      // Permission has never been asked for. Say so plainly rather than
      // describing a future that cannot happen yet -- the row is tappable in
      // this state, and the old copy promised notifications that could never
      // arrive.
      return 'Allow notifications so price alerts can reach you.';
    }
    return "You'll be notified when a saved price alert triggers.";
  }

  PriceAlertNotificationState copyWith({
    bool? enabled,
    PriceAlertNotificationPermissionStatus? permissionStatus,
    PriceAlertNotificationDeliveryStatus? lastDeliveryStatus,
    PushNotificationRegistrationStatus? pushRegistrationStatus,
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
      pushRegistrationStatus:
          pushRegistrationStatus ?? this.pushRegistrationStatus,
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

enum PushNotificationRegistrationStatus {
  idle(label: 'Not registered'),
  registered(label: 'Cloud ready'),
  permissionRequired(label: 'Needs permission'),
  unavailable(label: 'Unavailable'),
  failed(label: 'Failed');

  const PushNotificationRegistrationStatus({required this.label});

  final String label;
}

class PushNotificationToken {
  const PushNotificationToken({
    required this.token,
    required this.provider,
    required this.platform,
    required this.createdAt,
  });

  final String token;
  final String provider;
  final String platform;
  final DateTime createdAt;

  bool get isValid => token.trim().isNotEmpty;
}
