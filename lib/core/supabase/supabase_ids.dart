String cloudUuidFor(String sourceId) {
  final bytes = _deterministicBytes(sourceId);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [
    for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
  ].join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

List<int> _deterministicBytes(String input) {
  final bytes = List<int>.filled(16, 0);
  for (var seed = 0; seed < 4; seed++) {
    var hash = 0x811c9dc5 ^ seed;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    for (var offset = 0; offset < 4; offset++) {
      bytes[(seed * 4) + offset] = (hash >> (offset * 8)) & 0xff;
    }
  }
  return bytes;
}
