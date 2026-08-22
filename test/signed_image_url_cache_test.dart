import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/core/cloud/services/signed_image_url_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignedImageUrlCache', () {
    test('resolves through the storage service on first request', () async {
      final storage = _CountingCloudStorageService();
      final cache = SignedImageUrlCache(storage);

      final url = await cache.resolve('users/u/portfolio_images/item-1.jpg');

      expect(url, 'https://example.test/item-1.jpg?token=call-1');
      expect(storage.callCount, 1);
    });

    test(
      'reuses a cached URL for the same path instead of re-resolving on '
      'every rebuild (the real reason this cache exists -- a signed URL '
      'is safe to reuse for a while, and re-requesting one on every scroll '
      'frame would hammer the sign endpoint for no reason)',
      () async {
        final storage = _CountingCloudStorageService();
        final cache = SignedImageUrlCache(storage);

        final first = await cache.resolve('users/u/portfolio_images/item-1.jpg');
        final second = await cache.resolve(
          'users/u/portfolio_images/item-1.jpg',
        );

        expect(first, second);
        expect(storage.callCount, 1);
      },
    );

    test('resolves each distinct storage path independently', () async {
      final storage = _CountingCloudStorageService();
      final cache = SignedImageUrlCache(storage);

      final first = await cache.resolve('users/u/portfolio_images/item-1.jpg');
      final second = await cache.resolve(
        'users/u/portfolio_images/item-2.jpg',
      );

      expect(first, isNot(second));
      expect(storage.callCount, 2);
    });

    test('returns null and does not cache when the storage service fails', () async {
      final storage = _CountingCloudStorageService(alwaysFails: true);
      final cache = SignedImageUrlCache(storage);

      final url = await cache.resolve('users/u/portfolio_images/item-1.jpg');

      expect(url, isNull);
      expect(storage.callCount, 1);
    });

    test('empty storage path resolves to null without calling the service', () async {
      final storage = _CountingCloudStorageService();
      final cache = SignedImageUrlCache(storage);

      final url = await cache.resolve('   ');

      expect(url, isNull);
      expect(storage.callCount, 0);
    });
  });
}

class _CountingCloudStorageService implements CloudStorageService {
  _CountingCloudStorageService({this.alwaysFails = false});

  final bool alwaysFails;
  var callCount = 0;

  @override
  String get providerName => 'Counting Fake';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteImage(String path) async {}

  @override
  Future<String?> getImageUrl(String path) async {
    callCount += 1;
    if (alwaysFails) {
      return null;
    }
    return 'https://example.test/${path.split('/').last}?token=call-$callCount';
  }
}
