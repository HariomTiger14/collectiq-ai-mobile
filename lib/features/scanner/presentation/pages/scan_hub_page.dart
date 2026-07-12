import 'dart:async';

import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_entry_tile.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scanner_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scan_hub_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design Bible Volume 03, S01 scanner entry hub behavior coordinator.
class ScanHubPage extends ConsumerStatefulWidget {
  const ScanHubPage({
    this.onViewPortfolio,
    this.onNotifications,
    this.now = DateTime.now,
    super.key,
  });
  final VoidCallback? onViewPortfolio;
  final VoidCallback? onNotifications;
  final DateTime Function() now;

  @override
  ConsumerState<ScanHubPage> createState() => _ScanHubPageState();
}

class _ScanHubPageState extends ConsumerState<ScanHubPage> {
  bool _hasRecoveredLostPickerData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasRecoveredLostPickerData) return;
      _hasRecoveredLostPickerData = true;
      unawaited(
        ref
            .read(scannerControllerProvider.notifier)
            .recoverLostPickerData(reason: 'scan-hub-startup'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider);
    final hasActiveScan =
        scannerState.scanResult != null ||
        scannerState.captureImages.isNotEmpty ||
        scannerState.selectedImagePath != null ||
        scannerState.isLoading ||
        scannerState.isPreparingImage ||
        scannerState.errorMessage != null;
    if (hasActiveScan) {
      return ScannerScreen(onViewPortfolio: widget.onViewPortfolio);
    }

    final greeting = _scanHubGreeting(
      ref.watch(authControllerProvider),
      widget.now(),
    );
    return ScannerPageScaffold(
      period: greeting.period,
      firstName: greeting.firstName,
      onNotifications: widget.onNotifications,
      cameraTile: PackLoxEntryTile(
        key: const ValueKey('scan-hub-capture-button'),
        compatibilityKey: const ValueKey('scan-primary-Scan with Camera'),
        semanticLabel: 'Take a photo. Use your camera to scan an item.',
        icon: Icons.photo_camera_outlined,
        title: 'Take a photo',
        supportingText: 'Use your camera to scan an item',
        variant: PackLoxEntryTileVariant.scanner,
        onTap: () => unawaited(_startCameraScan(context)),
      ),
      galleryTile: PackLoxEntryTile(
        key: const ValueKey('scan-hub-gallery-button'),
        compatibilityKey: const ValueKey('scan-secondary-Gallery'),
        semanticLabel: 'Choose from gallery. Select an existing photo.',
        icon: Icons.image_outlined,
        title: 'Choose from gallery',
        supportingText: 'Select an existing photo',
        variant: PackLoxEntryTileVariant.scanner,
        onTap: () => unawaited(_pickFromGallery(context)),
      ),
      sampleTile: PackLoxEntryTile(
        key: const ValueKey('scan-hub-sample-button'),
        compatibilityKey: const ValueKey('scan-secondary-Use Sample Scan'),
        semanticLabel: 'Try a sample scan. See how PackLox works.',
        icon: Icons.science_outlined,
        title: 'Try a sample scan',
        supportingText: 'See how PackLox works',
        variant: PackLoxEntryTileVariant.scanner,
        onTap: ref.read(scannerControllerProvider.notifier).useSampleScan,
      ),
    );
  }

  Future<void> _startCameraScan(BuildContext context) => ref
      .read(scannerControllerProvider.notifier)
      .startCameraScan(context, imageRole: 'front');
  Future<void> _pickFromGallery(BuildContext context) => ref
      .read(scannerControllerProvider.notifier)
      .pickImageFromGallery(context: context, imageRole: 'front');
}

({String period, String firstName}) _scanHubGreeting(
  AuthState authState,
  DateTime now,
) {
  final displayName = authState.isSignedIn
      ? authState.user?.displayName.trim() ?? ''
      : '';
  final firstName = displayName.isEmpty
      ? 'Collector'
      : displayName.split(RegExp(r'\s+')).first;
  final period = switch (now.hour) {
    < 12 => 'Good morning',
    < 18 => 'Good afternoon',
    _ => 'Good evening',
  };
  return (period: period, firstName: firstName);
}
