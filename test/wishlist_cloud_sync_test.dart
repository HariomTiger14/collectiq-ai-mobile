import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/wishlist/data/repositories/supabase_wishlist_repository.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CollectibleItem item(String id, {String title = 'Charizard'}) {
    return CollectibleItem(
      id: id,
      title: title,
      category: 'Pokemon',
      estimatedValue: 0,
      confidence: 0,
      condition: 'Unknown',
      recommendation: '',
      imagePath: '',
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('wishlist row mapping', () {
    test('round-trips through supabase row + raw_json', () {
      final entry = WishlistStatusEntry(
        itemId: 'item-1',
        title: 'Blastoise',
        category: 'Pokemon',
        status: WishlistStatus.wanted,
        updatedAt: DateTime.utc(2026, 2, 1, 12),
      );

      final row = supabaseRowForWishlistEntry(entry, 'user-1');
      expect(row['user_id'], 'user-1');
      expect(row['portfolio_item_id'], 'item-1');
      expect(row['status'], 'wanted');
      expect(row['deleted'], false);

      final decoded = wishlistEntryFromSupabaseRow(row)!;
      expect(decoded.itemId, 'item-1');
      expect(decoded.title, 'Blastoise');
      expect(decoded.status, WishlistStatus.wanted);
    });

    test('falls back to columns when raw_json missing', () {
      final decoded = wishlistEntryFromSupabaseRow({
        'portfolio_item_id': 'item-9',
        'title': 'Mewtwo',
        'category': 'Pokemon',
        'status': 'missing',
        'updated_at': '2026-03-01T00:00:00.000Z',
      })!;
      expect(decoded.itemId, 'item-9');
      expect(decoded.status, WishlistStatus.missing);
    });
  });

  group('SupabaseWishlistRepository (signed in)', () {
    late _FakeLocalWishlistRepository local;
    late _CapturingGateway gateway;
    late SupabaseWishlistRepository repo;

    setUp(() {
      local = _FakeLocalWishlistRepository();
      gateway = _CapturingGateway();
      repo = SupabaseWishlistRepository(
        authService: _SignedInAuthService(),
        supabaseDataGateway: gateway,
        localRepository: local,
      );
    });

    test('saveStatus writes local + upserts cloud row', () async {
      await repo.saveStatus(item: item('item-1'), status: WishlistStatus.wanted);

      expect(local.entries.single.itemId, 'item-1');
      expect(gateway.lastPostPath, '/rest/v1/collector_wishlist_entries');
      expect(gateway.lastQuery?['on_conflict'], 'user_id,portfolio_item_id');
      final posted = gateway.lastPostedRows.single;
      expect(posted['status'], 'wanted');
      expect(posted['deleted'], false);
      expect(posted['user_id'], 'user-1');
    });

    test('deleteStatus soft-deletes cloud (deleted = true)', () async {
      await repo.deleteStatus('item-1');
      final posted = gateway.lastPostedRows.single;
      expect(posted['portfolio_item_id'], 'item-1');
      expect(posted['deleted'], true);
    });

    test('getEntries returns cloud rows and mirrors them locally', () async {
      gateway.getRows = [
        {
          'portfolio_item_id': 'item-7',
          'title': 'Venusaur',
          'category': 'Pokemon',
          'status': 'owned',
          'updated_at': '2026-04-01T00:00:00.000Z',
        },
      ];

      final entries = await repo.getEntries();
      expect(entries.single.itemId, 'item-7');
      expect(gateway.lastQuery?['deleted'], 'eq.false');
      // Cloud is the source of truth: local was replaced with the cloud set.
      expect(local.entries.single.itemId, 'item-7');
    });
  });

  group('SupabaseWishlistRepository (signed out)', () {
    test('falls back to local store, no cloud writes', () async {
      final local = _FakeLocalWishlistRepository();
      final gateway = _CapturingGateway();
      final repo = SupabaseWishlistRepository(
        authService: _SignedOutAuthService(),
        supabaseDataGateway: gateway,
        localRepository: local,
      );

      await repo.saveStatus(item: item('item-1'), status: WishlistStatus.owned);
      expect(local.entries.single.itemId, 'item-1');
      expect(gateway.lastPostPath, isNull); // never touched the cloud
    });
  });
}

class _FakeLocalWishlistRepository implements WishlistRepository {
  final List<WishlistStatusEntry> entries = [];

  @override
  Future<void> clear() async => entries.clear();

  @override
  Future<void> deleteStatus(String itemId) async =>
      entries.removeWhere((e) => e.itemId == itemId);

  @override
  Future<List<WishlistStatusEntry>> getEntries() async =>
      List.unmodifiable(entries);

  @override
  Future<WishlistStatus> getStatusForItem(String itemId) async {
    for (final e in entries) {
      if (e.itemId == itemId) return e.status;
    }
    return WishlistStatus.owned;
  }

  @override
  Future<void> saveStatus({
    required CollectibleItem item,
    required WishlistStatus status,
  }) async {
    entries
      ..removeWhere((e) => e.itemId == item.id)
      ..add(
        WishlistStatusEntry(
          itemId: item.id,
          title: item.title,
          category: item.category,
          status: status,
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
  }
}

class _SignedInAuthService implements AuthService {
  @override
  Future<bool> isSignedIn() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SignedOutAuthService implements AuthService {
  @override
  Future<bool> isSignedIn() async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CapturingGateway implements SupabaseDataGateway {
  List<Map<String, dynamic>> getRows = const [];
  String? lastPostPath;
  Map<String, dynamic>? lastQuery;
  List<Map<String, dynamic>> lastPostedRows = const [];

  @override
  bool get isConfigured => true;

  @override
  Future<SupabaseAuthSession?> currentSession() async =>
      const SupabaseAuthSession(
        userId: 'user-1',
        email: 'a@b.com',
        accessToken: 'token',
        displayName: 'Collector',
        isAnonymous: false,
        projectUrl: 'https://example.supabase.co',
      );

  @override
  Future<Response<T>> authenticatedGetWithSession<T>(
    String path, {
    required SupabaseAuthSession session,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastQuery = queryParameters;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: getRows as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> authenticatedPostWithSession<T>(
    String path, {
    required SupabaseAuthSession session,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPostPath = path;
    lastQuery = queryParameters;
    lastPostedRows = (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: const [] as T,
      statusCode: 201,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
