import 'dart:convert';
import 'dart:io';

import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerDraftRepository {
  const ScannerDraftRepository();

  static const draftKey = 'packlox.scanner.pending_draft.v1';

  Future<List<ScannerPhotoSlot>> loadDraftImages() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(draftKey);
    if (encoded == null || encoded.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    final rawImages = decoded['images'];
    if (rawImages is! List) {
      return const [];
    }

    return rawImages
        .whereType<Map<String, dynamic>>()
        .map(_slotFromJson)
        .where((slot) {
          final path = slot.path.trim();
          return path.isNotEmpty && File(path).existsSync();
        })
        .toList(growable: false);
  }

  Future<void> saveDraftImages(List<ScannerPhotoSlot> images) async {
    final localImages = images
        .where((slot) {
          final path = slot.path.trim();
          return path.isNotEmpty &&
              !path.startsWith('sample://') &&
              File(path).existsSync();
        })
        .toList(growable: false);

    if (localImages.isEmpty) {
      await clearDraft();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      draftKey,
      jsonEncode({
        'updatedAt': DateTime.now().toIso8601String(),
        'images': [for (final slot in localImages) _slotToJson(slot)],
      }),
    );
  }

  Future<void> clearDraft() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(draftKey);
  }

  ScannerPhotoSlot _slotFromJson(Map<String, dynamic> json) {
    final preset = ImageEnhancementPreset.values.firstWhere(
      (candidate) => candidate.id == json['enhancementPreset'],
      orElse: () => ImageEnhancementPreset.original,
    );
    final path = json['path'] as String? ?? '';
    final originalPath = json['originalPath'] as String?;
    return ScannerPhotoSlot(
      role: json['role'] as String? ?? 'front',
      label: json['label'] as String? ?? 'Front / Obverse',
      path: path,
      source: json['source'] as String? ?? 'restored',
      originalPath: originalPath?.trim().isEmpty == true
          ? path
          : originalPath ?? path,
      enhancementPreset: preset,
      enhancedImagePath: json['enhancedImagePath'] as String?,
      qualityMetadata: Map<String, Object?>.from(
        json['qualityMetadata'] as Map? ?? const {},
      ),
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? ''),
    );
  }

  Map<String, Object?> _slotToJson(ScannerPhotoSlot slot) {
    return {
      'role': slot.role,
      'label': slot.label,
      'path': slot.path,
      'source': slot.source,
      'originalPath': slot.originalPath,
      'enhancementPreset': slot.enhancementPreset.id,
      'enhancedImagePath': slot.enhancedImagePath,
      'qualityMetadata': slot.qualityMetadata,
      'capturedAt': slot.capturedAt?.toIso8601String(),
    };
  }
}
