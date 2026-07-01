class CloudStoragePaths {
  const CloudStoragePaths._();

  static String portfolioImage({
    required String userId,
    required String itemId,
    String extension = '.jpg',
  }) {
    return 'users/${safePathSegment(userId)}/portfolio_images/'
        '${safePathSegment(itemId)}${normalizedImageExtension(extension)}';
  }

  static String safePathSegment(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '-')
        .replaceAll(RegExp('-+'), '-');
  }

  static String normalizedImageExtension(String extension) {
    final normalized = extension.trim().toLowerCase();
    if (normalized == '.png' ||
        normalized == '.webp' ||
        normalized == '.jpeg') {
      return normalized;
    }
    return '.jpg';
  }
}
