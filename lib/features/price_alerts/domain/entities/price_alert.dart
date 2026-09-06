enum PriceAlertStatus {
  active(label: 'Active'),
  triggered(label: 'Triggered'),
  // Server-side terminal state after a push has been sent for a trigger, so the
  // dispatcher never re-pushes the same trigger. Treated as "fired" in the app
  // (see [PriceAlert.isTriggered]); the server re-arms it back to `active` once
  // the condition clears.
  notified(label: 'Notified'),
  paused(label: 'Paused');

  const PriceAlertStatus({required this.label});

  final String label;

  static PriceAlertStatus fromName(String? value) {
    for (final status in PriceAlertStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return PriceAlertStatus.active;
  }
}

enum PriceAlertRuleType {
  priceRisesAboveAmount(label: 'Rises above'),
  priceDropsBelowAmount(label: 'Drops below'),
  percentageIncrease(label: 'Increases by'),
  percentageDecrease(label: 'Decreases by'),
  stalePricingReminder(label: 'Pricing stale');

  const PriceAlertRuleType({required this.label});

  final String label;

  static PriceAlertRuleType fromName(String? value) {
    for (final type in PriceAlertRuleType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return PriceAlertRuleType.priceRisesAboveAmount;
  }
}

class PriceAlertRule {
  const PriceAlertRule({
    required this.type,
    this.amount,
    this.percentage,
    this.baselineValue,
    this.staleAfterDays,
    this.displayCurrency,
    this.normalizedAmountUsd,
    this.exchangeRateUsed,
    this.exchangeRateDate,
  });

  final PriceAlertRuleType type;

  /// The threshold as the collector entered it, in [displayCurrency].
  ///
  /// This is intent, not a comparison value: "alert me at AUD 50" stays AUD
  /// 50 however the item is priced, and is what the app shows back.
  final double? amount;
  final double? percentage;
  final double? baselineValue;
  final int? staleAfterDays;

  /// The currency [amount] was entered in. Null on alerts created before
  /// currencies were tracked, which were all AUD.
  final String? displayCurrency;

  /// [amount] converted to USD, which is what item prices are stored in, so
  /// the server compares two figures in the same currency. Null means the
  /// alert predates this and its [amount] is compared as-is.
  final double? normalizedAmountUsd;

  /// The rate and date behind [normalizedAmountUsd], so the conversion can be
  /// checked or redone later rather than being an unexplained number.
  final double? exchangeRateUsed;
  final DateTime? exchangeRateDate;

  /// The currency to show [amount] in: what the collector chose, falling back
  /// to AUD for alerts created before this was recorded.
  String get effectiveDisplayCurrency =>
      (displayCurrency?.trim().isNotEmpty ?? false)
      ? displayCurrency!.trim().toUpperCase()
      : 'AUD';

  /// The figure the server should compare against a USD item price.
  double? get comparisonAmountUsd => normalizedAmountUsd ?? amount;

  factory PriceAlertRule.fromJson(Map<String, dynamic> json) {
    final rateDate = json['exchangeRateDate'];
    return PriceAlertRule(
      type: PriceAlertRuleType.fromName(json['type'] as String?),
      amount: (json['amount'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      baselineValue: (json['baselineValue'] as num?)?.toDouble(),
      staleAfterDays: (json['staleAfterDays'] as num?)?.toInt(),
      displayCurrency: (json['displayCurrency'] as String?)?.trim(),
      normalizedAmountUsd: (json['normalizedAmountUsd'] as num?)?.toDouble(),
      exchangeRateUsed: (json['exchangeRateUsed'] as num?)?.toDouble(),
      exchangeRateDate: rateDate is String ? DateTime.tryParse(rateDate) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'amount': amount,
      'percentage': percentage,
      'baselineValue': baselineValue,
      'staleAfterDays': staleAfterDays,
      'displayCurrency': displayCurrency,
      'normalizedAmountUsd': normalizedAmountUsd,
      'exchangeRateUsed': exchangeRateUsed,
      'exchangeRateDate': exchangeRateDate?.toIso8601String(),
    };
  }
}

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.rule,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.triggeredAt,
    this.message,
  });

  final String id;
  final String itemId;
  final String itemTitle;
  final PriceAlertRule rule;
  final PriceAlertStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? triggeredAt;
  final String? message;

  // "Fired" covers both the freshly-triggered state and the post-push
  // `notified` state, so the app keeps showing an alert (inbox + Home count)
  // after the server has sent its push.
  bool get isTriggered =>
      status == PriceAlertStatus.triggered ||
      status == PriceAlertStatus.notified;

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      itemTitle: json['itemTitle'] as String? ?? 'Collectible',
      rule: json['rule'] is Map<String, dynamic>
          ? PriceAlertRule.fromJson(json['rule'] as Map<String, dynamic>)
          : PriceAlertRule.fromJson(const {}),
      status: PriceAlertStatus.fromName(json['status'] as String?),
      createdAt: _dateFromJson(json['createdAt']),
      updatedAt: _dateFromJson(json['updatedAt']),
      triggeredAt: _optionalDateFromJson(json['triggeredAt']),
      message: _optionalString(json['message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'rule': rule.toJson(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'triggeredAt': triggeredAt?.toIso8601String(),
      'message': message,
    };
  }

  PriceAlert copyWith({
    String? itemTitle,
    PriceAlertRule? rule,
    PriceAlertStatus? status,
    DateTime? updatedAt,
    DateTime? triggeredAt,
    String? message,
    bool clearTriggeredAt = false,
    bool clearMessage = false,
  }) {
    return PriceAlert(
      id: id,
      itemId: itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      rule: rule ?? this.rule,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      triggeredAt: clearTriggeredAt ? null : triggeredAt ?? this.triggeredAt,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class PriceAlertEvaluation {
  const PriceAlertEvaluation({
    required this.alert,
    required this.triggered,
    required this.message,
  });

  final PriceAlert alert;
  final bool triggered;
  final String message;
}

class PriceAlertSummary {
  const PriceAlertSummary({
    required this.alerts,
    required this.triggeredAlerts,
    required this.activeAlerts,
    required this.messages,
  });

  final List<PriceAlert> alerts;
  final List<PriceAlert> triggeredAlerts;
  final List<PriceAlert> activeAlerts;
  final List<String> messages;

  int get totalCount => alerts.length;
  int get triggeredCount => triggeredAlerts.length;
  int get activeCount => activeAlerts.length;
}

DateTime _dateFromJson(Object? value) {
  return _optionalDateFromJson(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _optionalDateFromJson(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value);
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
