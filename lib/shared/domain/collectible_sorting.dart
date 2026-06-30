import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

DateTime collectibleDisplayTimestamp(CollectibleItem item) {
  return item.createdAt;
}

int compareCollectiblesNewestFirst(
  CollectibleItem left,
  CollectibleItem right,
) {
  final timestampComparison = collectibleDisplayTimestamp(
    right,
  ).compareTo(collectibleDisplayTimestamp(left));
  if (timestampComparison != 0) {
    return timestampComparison;
  }

  return right.id.compareTo(left.id);
}

List<CollectibleItem> collectiblesNewestFirst(Iterable<CollectibleItem> items) {
  return [...items]..sort(compareCollectiblesNewestFirst);
}
