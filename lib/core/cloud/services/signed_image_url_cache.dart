import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final signedImageUrlCacheProvider = Provider<SignedImageUrlCache>((ref) {
  final registry = ref.watch(cloudServiceRegistryProvider);
  return SignedImageUrlCache(registry.cloudStorageService);
});

/// Caches freshly-resolved image URLs for portfolio images stored in a
/// private Supabase Storage bucket. A signed URL expires (currently one
/// hour, server-side) so it can never be treated as a permanent value --
/// this cache exists purely to avoid re-requesting one on every rebuild or
/// scroll within a session, not to persist it across app restarts.
class SignedImageUrlCache {
  SignedImageUrlCache(this._storageService);

  final CloudStorageService _storageService;
  final Map<String, _CachedUrl> _cache = {};

  // Refresh comfortably before the server-side expiry so a URL already on
  // screen doesn't go stale mid-session.
  static const _cacheDuration = Duration(minutes: 40);

  Future<String?> resolve(String storagePath) async {
    final trimmed = storagePath.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final cached = _cache[trimmed];
    final now = DateTime.now();
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.url;
    }

    final url = await _storageService.getImageUrl(trimmed);
    if (url == null) {
      _cache.remove(trimmed);
      return null;
    }

    _cache[trimmed] = _CachedUrl(url: url, expiresAt: now.add(_cacheDuration));
    return url;
  }
}

class _CachedUrl {
  const _CachedUrl({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
