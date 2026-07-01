import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:collectiq_ai/core/cloud/firebase/firebase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/services/analytics_service.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({required this.bootstrap, this.analytics});

  final FirebaseBootstrap bootstrap;
  final FirebaseAnalytics? analytics;

  FirebaseAnalytics get _firebaseAnalytics =>
      analytics ?? FirebaseAnalytics.instance;

  @override
  String get providerName => 'Firebase Analytics';

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return;
    }
    await _firebaseAnalytics.logEvent(
      name: _safeName(name),
      parameters: _safeParameters(properties),
    );
  }

  String _safeName(String value) {
    final sanitized = value.trim().toLowerCase().replaceAll(
      RegExp('[^a-z0-9_]'),
      '_',
    );
    return sanitized.isEmpty ? 'unnamed_event' : sanitized;
  }

  Map<String, Object> _safeParameters(Map<String, Object?> properties) {
    final safe = <String, Object>{};
    for (final entry in properties.entries) {
      final key = _safeName(entry.key);
      final value = entry.value;
      if (value is String || value is num || value is bool) {
        safe[key] = value as Object;
      }
    }
    return safe;
  }
}
