import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:flutter/material.dart';

enum ScanGoal {
  identifyValue,
  detailedAnalysis,
  prepareForSale;

  String get id {
    return switch (this) {
      ScanGoal.identifyValue => 'identifyValue',
      ScanGoal.detailedAnalysis => 'detailedAnalysis',
      ScanGoal.prepareForSale => 'prepareForSale',
    };
  }

  String get title {
    return switch (this) {
      ScanGoal.identifyValue => 'Identify & Value',
      ScanGoal.detailedAnalysis => 'Detailed Analysis',
      ScanGoal.prepareForSale => 'Prepare for Sale',
    };
  }

  String get subtitle {
    return switch (this) {
      ScanGoal.identifyValue => 'Fast ID and valuation',
      ScanGoal.detailedAnalysis => 'More guided detail',
      ScanGoal.prepareForSale => 'Listing-ready photos',
    };
  }

  IconData get icon {
    return switch (this) {
      ScanGoal.identifyValue => Icons.auto_awesome_outlined,
      ScanGoal.detailedAnalysis => Icons.fact_check_outlined,
      ScanGoal.prepareForSale => Icons.storefront_outlined,
    };
  }

  double get confidenceTarget {
    return switch (this) {
      ScanGoal.identifyValue => 0.90,
      ScanGoal.detailedAnalysis => 0.98,
      ScanGoal.prepareForSale => 0.95,
    };
  }

  String get description {
    return switch (this) {
      ScanGoal.identifyValue =>
        'Identify the collectible and estimate value quickly.',
      ScanGoal.detailedAnalysis =>
        'Collect additional angles and details for higher confidence.',
      ScanGoal.prepareForSale =>
        'Capture the views buyers expect before creating a listing.',
    };
  }

  ScanCaptureRole get defaultCaptureIntent {
    return switch (this) {
      ScanGoal.identifyValue ||
      ScanGoal.detailedAnalysis ||
      ScanGoal.prepareForSale => ScanCaptureRole.front,
    };
  }

  static ScanGoal fromId(String? value) {
    return switch (value?.trim()) {
      'detailedAnalysis' => ScanGoal.detailedAnalysis,
      'prepareForSale' => ScanGoal.prepareForSale,
      _ => ScanGoal.identifyValue,
    };
  }
}
