import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// The real telemetry provider: Crashlytics + Analytics, plus a second
/// lane reporting errors to the PackLox backend so they land in
/// ops_error_events and surface in the admin portal's error feed next to
/// API and cron failures.
///
/// Two lanes on purpose: Crashlytics is where crash forensics live
/// (grouped stacks, device/OS breakdowns, crash-free rates -- the
/// Firebase console does this better than anything worth rebuilding),
/// while the backend lane is what makes app failures VISIBLE where the
/// team already looks. Neither lane may ever break the app or each
/// other -- every call here is best-effort.
/// Late-bound access-token hook: assigned where the app's Supabase
/// gateway is available (cloudServiceRegistryProvider), read at report
/// time. Lets the telemetry service be constructed at the very start of
/// main() -- before any provider graph exists -- and still authenticate
/// its backend reports once the app is fully wired.
Future<String?> Function()? telemetryAccessTokenProvider;

/// One-time registration called from main() before telemetry is created.
void registerFirebaseTelemetryBuilder({
  required String apiBaseUrl,
  String? appVersion,
}) {
  firebaseTelemetryBuilder = (config) => FirebaseTelemetryService(
        config: config,
        backendReporter: BackendErrorReporter(
          apiBaseUrl: apiBaseUrl,
          accessTokenProvider: () async =>
              await telemetryAccessTokenProvider?.call(),
          appVersion: appVersion,
        ),
      );
}

class FirebaseTelemetryService implements AppTelemetryService {
  FirebaseTelemetryService({
    required this.config,
    this.backendReporter,
  });

  final TelemetryConfig config;
  final BackendErrorReporter? backendReporter;

  Future<bool>? _initialization;

  Future<bool> _ensureInitialized() {
    // Firebase.initializeApp is idempotent, but racing two first-calls
    // (telemetry vs push notifications) can throw duplicate-app; memoize
    // so this service only ever initializes once, and never fails the
    // caller -- an uninitialized Firebase just means events are dropped.
    return _initialization ??= () async {
      try {
        await Firebase.initializeApp();
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(true);
        return true;
      } catch (error) {
        debugPrint('[Telemetry] Firebase init failed: $error');
        return false;
      }
    }();
  }

  @override
  TelemetryStatus get status => TelemetryStatus(
        provider: 'Firebase',
        enabled: true,
        crashReportingEnabled: true,
        analyticsEnabled: true,
        message: 'Crashlytics + Analytics active; errors also reported to '
            'the PackLox ops feed.',
      );

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!await _ensureInitialized()) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: sanitizeTelemetryName(name),
        parameters: sanitizeTelemetryProperties(properties),
      );
    } catch (error) {
      debugPrint('[Telemetry] trackEvent($name) failed: $error');
    }
  }

  @override
  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  }) async {
    if (await _ensureInitialized()) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: reason,
          information: sanitizeTelemetryProperties(properties)
              .entries
              .map((entry) => '${entry.key}=${entry.value}')
              .toList(),
        );
      } catch (crashlyticsError) {
        debugPrint('[Telemetry] Crashlytics record failed: $crashlyticsError');
      }
    }
    // The backend lane runs even when Firebase init failed -- the two are
    // independent by design.
    unawaited(backendReporter?.report(
      error,
      stackTrace: stackTrace,
      reason: reason,
    ));
  }
}

/// Fire-and-forget reporter into POST /api/ops/client-errors, the
/// endpoint that lands app errors in ops_error_events for the admin
/// portal's error feed. Authenticated with the user's own Supabase
/// bearer token (same session the rest of the app uses); reports are
/// silently dropped when signed out, offline, or rejected -- telemetry
/// never gets retries or queues that could themselves misbehave.
class BackendErrorReporter {
  BackendErrorReporter({
    required this.apiBaseUrl,
    required this.accessTokenProvider,
    this.appVersion,
  });

  final String apiBaseUrl;
  final Future<String?> Function() accessTokenProvider;
  final String? appVersion;

  static const _stackCap = 8000;

  Future<void> report(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
  }) async {
    try {
      final token = await accessTokenProvider();
      if (token == null || token.isEmpty) {
        return;
      }
      final base = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      if (base.isEmpty) {
        return;
      }
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      try {
        final request =
            await client.postUrl(Uri.parse('$base/api/ops/client-errors'));
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Authorization', 'Bearer $token');
        request.write(jsonEncode({
          'errorClass': error.runtimeType.toString(),
          'message': error.toString(),
          'stack': stackTrace?.toString().substring(
                0,
                (stackTrace.toString().length).clamp(0, _stackCap),
              ),
          'context': {
            'reason': ?reason,
            'platform': Platform.operatingSystem,
            'appVersion': ?appVersion,
          },
        }));
        final response = await request.close();
        await response.drain<void>();
      } finally {
        client.close(force: true);
      }
    } catch (reportingError) {
      debugPrint('[Telemetry] backend report failed: $reportingError');
    }
  }
}
