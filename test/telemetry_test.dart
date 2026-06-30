import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTelemetryService', () {
    test('noop telemetry does not crash', () async {
      const service = NoopTelemetryService();

      await service.trackEvent('app_open', properties: {'screen': 'home'});
      await service.recordNonFatalError(
        StateError('backend unavailable'),
        reason: 'backend_unavailable',
      );

      expect(service.status.analyticsEnabled, isFalse);
      expect(service.status.crashReportingEnabled, isFalse);
    });

    test('events are emitted through abstraction when configured', () async {
      final service = PlaceholderTelemetryService(
        config: const TelemetryConfig(
          enabled: true,
          providerType: TelemetryProviderType.sentry,
          firebaseConfigured: false,
          sentryConfigured: true,
        ),
      );

      await service.trackEvent(
        TelemetryEventNames.analyzeSuccess,
        properties: {'source': 'camera', 'latency_ms': 123},
      );

      expect(service.debugEvents, hasLength(1));
      expect(service.debugEvents.single['name'], 'analyze_success');
      expect(service.debugEvents.single['source'], 'camera');
      expect(service.debugEvents.single['latency_ms'], 123);
    });

    test('errors are sanitized', () async {
      final service = PlaceholderTelemetryService(
        config: const TelemetryConfig(
          enabled: true,
          providerType: TelemetryProviderType.sentry,
          firebaseConfigured: false,
          sentryConfigured: true,
        ),
      );

      await service.recordNonFatalError(
        Exception('Failed for harry@example.com at C:\\secret\\image.jpg'),
        reason: 'scan_error',
        properties: {
          'imagePath': 'C:\\secret\\image.jpg',
          'category': 'Trading Card',
          'apiKey': 'abc123',
        },
      );

      expect(service.debugErrors, hasLength(1));
      expect(service.debugErrors.single['error'], '[redacted]');
      expect(service.debugErrors.single.containsKey('imagepath'), isFalse);
      expect(service.debugErrors.single.containsKey('apikey'), isFalse);
      expect(service.debugErrors.single['category'], 'Trading Card');
    });

    test('disabled telemetry skips external calls', () async {
      final service = PlaceholderTelemetryService(
        config: const TelemetryConfig(
          enabled: false,
          providerType: TelemetryProviderType.sentry,
          firebaseConfigured: false,
          sentryConfigured: true,
        ),
      );

      await service.trackEvent(TelemetryEventNames.syncStarted);
      await service.recordNonFatalError(Exception('sync failed'));

      expect(service.status.enabled, isFalse);
      expect(service.debugEvents, isEmpty);
      expect(service.debugErrors, isEmpty);
    });

    test('missing provider configuration keeps telemetry disabled', () async {
      final service = createAppTelemetryService(
        const TelemetryConfig(
          enabled: true,
          providerType: TelemetryProviderType.firebase,
          firebaseConfigured: false,
          sentryConfigured: false,
        ),
      );

      expect(service.status.enabled, isFalse);
      expect(service.status.message, contains('not configured'));
    });

    test('firebase disabled without config falls back safely', () async {
      final service = createAppTelemetryService(
        const TelemetryConfig(
          enabled: true,
          providerType: TelemetryProviderType.firebase,
          firebaseConfigured: false,
          sentryConfigured: false,
        ),
      );

      expect(service, isA<NoopTelemetryService>());
      expect(service.status.provider, 'Firebase');
      expect(service.status.analyticsEnabled, isFalse);
      expect(service.status.crashReportingEnabled, isFalse);
    });

    test('firebase configured uses Firebase telemetry service', () {
      final service = createAppTelemetryService(
        const TelemetryConfig(
          enabled: true,
          providerType: TelemetryProviderType.firebase,
          firebaseConfigured: true,
          sentryConfigured: false,
          firebaseApiKey: 'test-api-key',
          firebaseAppId: '1:123456789:android:abcdef',
          firebaseMessagingSenderId: '123456789',
          firebaseProjectId: 'collectiq-test',
        ),
      );

      expect(service, isA<FirebaseTelemetryService>());
      expect(service.status.provider, 'Firebase');
      expect(service.status.analyticsEnabled, isTrue);
      expect(service.status.crashReportingEnabled, isTrue);
    });
  });
}
