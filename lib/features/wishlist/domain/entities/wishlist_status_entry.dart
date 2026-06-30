import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';

class WishlistStatusEntry {
  const WishlistStatusEntry({
    required this.itemId,
    required this.title,
    required this.category,
    required this.status,
    required this.updatedAt,
  });

  final String itemId;
  final String title;
  final String category;
  final WishlistStatus status;
  final DateTime updatedAt;

  factory WishlistStatusEntry.fromJson(Map<String, dynamic> json) {
    return WishlistStatusEntry(
      itemId: json['itemId'] as String? ?? '',
      title: json['title'] as String? ?? 'Collectible',
      category: json['category'] as String? ?? 'Other',
      status: wishlistStatusFromName(json['status'] as String?),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'title': title,
      'category': category,
      'status': status.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class WishlistSummary {
  const WishlistSummary({
    required this.counts,
    required this.entries,
    required this.recommendations,
  });

  final Map<WishlistStatus, int> counts;
  final List<WishlistStatusEntry> entries;
  final List<String> recommendations;

  int countFor(WishlistStatus status) => counts[status] ?? 0;
}

WishlistStatus wishlistStatusFromName(String? value) {
  for (final status in WishlistStatus.values) {
    if (status.name == value) {
      return status;
    }
  }
  return WishlistStatus.owned;
}

extension WishlistStatusLabel on WishlistStatus {
  String get label {
    return switch (this) {
      WishlistStatus.owned => 'Owned',
      WishlistStatus.wanted => 'Wanted',
      WishlistStatus.missing => 'Missing',
    };
  }
}
