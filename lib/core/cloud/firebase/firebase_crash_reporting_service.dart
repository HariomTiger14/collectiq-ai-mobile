import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:collectiq_ai/core/cloud/firebase/firebase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/services/crash_reporting_service.dart';

class FirebaseCrashReportingService implements CrashReportingService {
  FirebaseCrashReportingService({required this.bootstrap, this.crashlytics});

  final FirebaseBootstrap bootstrap;
  final FirebaseCrashlytics? crashlytics;

  FirebaseCrashlytics get _firebaseCrashlytics =>
      crashlytics ?? FirebaseCrashlytics.instance;

  @override
  String get providerName => 'Firebase Crashlytics';

  @override
  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  }) async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return;
    }
    for (final entry in properties.entries) {
      final value = entry.value;
      if (value is String || value is num || value is bool) {
        await _firebaseCrashlytics.setCustomKey(
          _safeKey(entry.key),
          value as Object,
        );
      }
    }
    await _firebaseCrashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  String _safeKey(String value) {
    final sanitized = value.trim().toLowerCase().replaceAll(
      RegExp('[^a-z0-9_]'),
      '_',
    );
    return sanitized.isEmpty ? 'context' : sanitized;
  }
}
