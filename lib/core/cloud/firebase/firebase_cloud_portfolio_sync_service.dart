import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:collectiq_ai/core/cloud/firebase/firebase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

@Deprecated(
  'SupabaseCloudPortfolioSyncService is the primary DEV/STAGING metadata sync '
  'implementation. Firestore sync is retained only for reference and should '
  'not be selected by CloudServiceRegistry.',
)
class FirebaseCloudPortfolioSyncService implements CloudPortfolioSyncService {
  FirebaseCloudPortfolioSyncService({
    required this.bootstrap,
    required this.authService,
    this.firestore,
  });

  final FirebaseBootstrap bootstrap;
  final AuthService authService;
  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  String get providerName => 'Cloud Firestore Portfolio Sync';

  @override
  Future<void> syncItem(CollectibleItem item) async {
    final userId = await _signedInUserId();
    if (userId == null) {
      return;
    }
    await _itemDocument(userId, item.id).set({
      ...item.toJson(),
      'lastSyncedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteItem(String itemId) async {
    final userId = await _signedInUserId();
    if (userId == null) {
      return;
    }
    await _itemDocument(userId, itemId).delete();
  }

  @override
  Future<List<CollectibleItem>> fetchItems() async {
    final userId = await _signedInUserId();
    if (userId == null) {
      return const [];
    }
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('portfolio_items')
        .get();
    return [
      for (final doc in snapshot.docs)
        CollectibleItem.fromJson({...doc.data(), 'id': doc.id}),
    ];
  }

  @override
  Future<CollectibleItem> markSynced(CollectibleItem item) async {
    return item.copyWithCloudSync(
      syncStatus: CloudItemSyncStatus.synced,
      lastSyncedAt: DateTime.now(),
      clearSyncError: true,
    );
  }

  @override
  Future<CloudPortfolioSyncStatus> getSyncStatus() async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return CloudPortfolioSyncStatus(enabled: false, message: ready.message);
    }
    final userId = await authService.currentUserId();
    if (userId == null || userId.trim().isEmpty) {
      return const CloudPortfolioSyncStatus(
        enabled: false,
        message: 'Cloud sync skipped: no signed-in Firebase user.',
      );
    }
    return CloudPortfolioSyncStatus(
      enabled: true,
      message: 'Cloud portfolio sync ready.',
      userId: userId,
    );
  }

  DocumentReference<Map<String, dynamic>> _itemDocument(
    String userId,
    String itemId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('portfolio_items')
        .doc(itemId);
  }

  Future<String?> _signedInUserId() async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || !await authService.isSignedIn()) {
      return null;
    }
    final userId = await authService.currentUserId();
    if (userId == null || userId.trim().isEmpty) {
      return null;
    }
    return userId;
  }
}
