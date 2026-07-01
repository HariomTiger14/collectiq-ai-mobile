abstract interface class RemoteConfigService {
  String get providerName;

  Future<void> refresh();

  bool getBool(String key, {bool defaultValue = false});

  String getString(String key, {String defaultValue = ''});

  int getInt(String key, {int defaultValue = 0});

  double getDouble(String key, {double defaultValue = 0});
}
