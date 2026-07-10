import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/features/market/data/providers/market_provider_factory.dart';
import 'package:collectiq_ai/features/market/data/providers/market_pricing_provider_factory.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_provider.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_pricing_provider.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_result_enrichment_service.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_quality_gate_service.dart';
import 'package:collectiq_ai/features/scanner/services/camera_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/services/image_enhancement_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the scanner camera service.
final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(service.disposeCamera);
  return service;
});

/// Provides the scanner gallery service.
final galleryServiceProvider = Provider<GalleryService>((ref) {
  return GalleryService();
});

final scanCapturePlanServiceProvider = Provider<ScanCapturePlanService>((ref) {
  return const ScanCapturePlanService();
});

final scanQualityGateServiceProvider = Provider<ScanQualityGateService>((ref) {
  return const ScanQualityGateService();
});

final imageEnhancementServiceProvider = Provider<ImageEnhancementService>((
  ref,
) {
  return const ImageEnhancementService();
});

final marketProviderProvider = Provider<MarketProvider>((ref) {
  return const MarketProviderFactory().create();
});

/// Provides the active future market-pricing provider type.
final marketPricingProviderTypeProvider = Provider<MarketPricingProviderType>((
  ref,
) {
  return MarketPricingProviderType.mock;
});

/// Provides the future market-pricing provider.
///
/// This is not wired into scan analysis yet; mock analysis remains unchanged.
final marketPricingProviderProvider = Provider<MarketPricingProvider>((ref) {
  return const MarketPricingProviderFactory().create(
    provider: ref.watch(marketPricingProviderTypeProvider),
  );
});

/// Provides the scan-result enrichment pipeline.
final scanResultEnrichmentServiceProvider =
    Provider<ScanResultEnrichmentService>((ref) {
      return ScanResultEnrichmentService(
        marketPricingProvider: ref.watch(marketPricingProviderProvider),
        telemetryService: ref.watch(appTelemetryServiceProvider),
      );
    });
