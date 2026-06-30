enum PriceAlertStatus {
  active(label: 'Active'),
  triggered(label: 'Triggered'),
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
  });

  final PriceAlertRuleType type;
  final double? amount;
  final double? percentage;
  final double? baselineValue;
  final int? staleAfterDays;

  factory PriceAlertRule.fromJson(Map<String, dynamic> json) {
    return PriceAlertRule(
      type: PriceAlertRuleType.fromName(json['type'] as String?),
      amount: (json['amount'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      baselineValue: (json['baselineValue'] as num?)?.toDouble(),
      staleAfterDays: (json['staleAfterDays'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'amount': amount,
      'percentage': percentage,
      'baselineValue': baselineValue,
      'staleAfterDays': staleAfterDays,
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

  bool get isTriggered => status == PriceAlertStatus.triggered;

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
