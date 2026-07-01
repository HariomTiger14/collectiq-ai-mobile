import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:collectiq_ai/core/cloud/firebase/firebase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/services/remote_config_service.dart';

class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService({required this.bootstrap, this.remoteConfig});

  final FirebaseBootstrap bootstrap;
  final FirebaseRemoteConfig? remoteConfig;
  bool _ready = false;

  FirebaseRemoteConfig get _firebaseRemoteConfig =>
      remoteConfig ?? FirebaseRemoteConfig.instance;

  @override
  String get providerName => 'Firebase Remote Config';

  @override
  Future<void> refresh() async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return;
    }
    await _firebaseRemoteConfig.fetchAndActivate();
    _ready = true;
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    if (!_ready) {
      return defaultValue;
    }
    try {
      return _firebaseRemoteConfig.getBool(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    if (!_ready) {
      return defaultValue;
    }
    try {
      final value = _firebaseRemoteConfig.getString(key);
      return value.isEmpty ? defaultValue : value;
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    if (!_ready) {
      return defaultValue;
    }
    try {
      return _firebaseRemoteConfig.getInt(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  double getDouble(String key, {double defaultValue = 0}) {
    if (!_ready) {
      return defaultValue;
    }
    try {
      return _firebaseRemoteConfig.getDouble(key);
    } catch (_) {
      return defaultValue;
    }
  }
}
