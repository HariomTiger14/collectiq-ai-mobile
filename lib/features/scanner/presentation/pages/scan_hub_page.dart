import 'dart:async';

import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scanner_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scan_hub_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _showSampleScan = bool.fromEnvironment('PACKLOX_SHOW_SAMPLE_SCAN');

/// Design Bible Volume 03, S01 scanner entry hub behavior coordinator.
class ScanHubPage extends ConsumerStatefulWidget {
  const ScanHubPage({this.onViewPortfolio, this.now = DateTime.now, super.key});
  final VoidCallback? onViewPortfolio;
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

    return ScannerPageScaffold(
      cameraTile: KeyedSubtree(
        key: const ValueKey('scan-hub-capture-button'),
        child: HomeActionRow(
          keySeed: 'scan-take-photo',
          icon: Icons.photo_camera_outlined,
          title: 'Take a photo',
          subtitle: 'Use your camera to scan an item.',
          onTap: () => unawaited(_startCameraScan(context)),
        ),
      ),
      galleryTile: KeyedSubtree(
        key: const ValueKey('scan-hub-gallery-button'),
        child: HomeActionRow(
          keySeed: 'scan-gallery',
          icon: Icons.image_outlined,
          title: 'Choose from gallery',
          subtitle: 'Select an existing photo.',
          iconColor: HomeTokens.categoryMore,
          onTap: () => unawaited(_pickFromGallery(context)),
        ),
      ),
      sampleTile: _showSampleScan
          ? KeyedSubtree(
              key: const ValueKey('scan-hub-sample-button'),
              child: HomeActionRow(
                keySeed: 'scan-sample',
                icon: Icons.science_outlined,
                title: 'Try a sample scan',
                subtitle: 'See how PackLox works.',
                iconColor: HomeTokens.categoryCoins,
                onTap: ref
                    .read(scannerControllerProvider.notifier)
                    .useSampleScan,
              ),
            )
          : null,
    );
  }

  Future<void> _startCameraScan(BuildContext context) => ref
      .read(scannerControllerProvider.notifier)
      .startCameraScan(context, imageRole: 'front');
  Future<void> _pickFromGallery(BuildContext context) => ref
      .read(scannerControllerProvider.notifier)
      .pickImageFromGallery(context: context, imageRole: 'front');
}
