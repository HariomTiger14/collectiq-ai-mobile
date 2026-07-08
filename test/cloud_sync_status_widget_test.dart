import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('collectible detail renders sync status labels', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setTallDetailSurface(tester);

    for (final entry in <CloudItemSyncStatus, String>{
      CloudItemSyncStatus.localOnly: 'Local only',
      CloudItemSyncStatus.pendingUpload: 'Pending upload',
      CloudItemSyncStatus.synced: 'Synced',
      CloudItemSyncStatus.failed: 'Sync failed',
    }.entries) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CollectibleDetailPage(item: _item(syncStatus: entry.key)),
          ),
        ),
      );

      await _showRawDiagnostics(tester, entry.value);
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('collectible detail renders sync failure message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setTallDetailSurface(tester);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CollectibleDetailPage(
            item: _item(
              syncStatus: CloudItemSyncStatus.failed,
              syncError: 'Upload failed for this item.',
            ),
          ),
        ),
      ),
    );

    await _showRawDiagnostics(tester, 'Sync failed');
    expect(find.text('Sync failed'), findsOneWidget);
    expect(find.text('Upload failed for this item.'), findsOneWidget);
  });
}

Future<void> _showRawDiagnostics(
  WidgetTester tester,
  String expectedValue,
) async {
  if (find.text(expectedValue).evaluate().isNotEmpty) {
    return;
  }
  await tester.tap(find.text('Raw Diagnostics'));
  await tester.pumpAndSettle();
}

void _setTallDetailSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

CollectibleItem _item({
  required CloudItemSyncStatus syncStatus,
  String? syncError,
}) {
  return CollectibleItem(
    id: 'item-sync-test',
    title: 'Sync Test Card',
    category: 'Trading Card',
    estimatedValue: 42,
    confidence: 0.87,
    condition: 'Good',
    recommendation: 'Keep in a sleeve.',
    imagePath: 'missing-image.jpg',
    createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
    syncStatus: syncStatus,
    syncError: syncError,
  );
}
