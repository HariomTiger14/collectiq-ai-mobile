import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/capture_event.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_plan.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scanner_constants.dart'
    as scanner_constants;

class ScanSession {
  const ScanSession({
    required this.sessionId,
    required this.scanGoal,
    required this.capturePlan,
    required this.capturedImages,
    required this.confidenceTarget,
    required this.scannerUxVersion,
    required this.startTime,
    this.confidenceAchieved,
    this.category,
    this.endTime,
    this.events = const [],
  });

  factory ScanSession.start({
    required String sessionId,
    required ScanGoal scanGoal,
    required ScanCapturePlan capturePlan,
    DateTime? startTime,
  }) {
    final startedAt = startTime ?? DateTime.now();
    return ScanSession(
      sessionId: sessionId,
      scanGoal: scanGoal,
      capturePlan: capturePlan,
      capturedImages: const [],
      confidenceTarget: scanGoal.confidenceTarget,
      scannerUxVersion: scanner_constants.scannerUxVersion,
      startTime: startedAt,
      events: [
        CaptureEvent(
          type: CaptureEventType.sessionStarted,
          timestamp: startedAt,
          metadata: {'scanGoal': scanGoal.id},
        ),
      ],
    );
  }

  final String sessionId;
  final ScanGoal scanGoal;
  final ScanCapturePlan capturePlan;
  final List<CapturedScanImage> capturedImages;
  final double confidenceTarget;
  final double? confidenceAchieved;
  final String? category;
  final String scannerUxVersion;
  final DateTime startTime;
  final DateTime? endTime;
  final List<CaptureEvent> events;

  ScanSession copyWith({
    ScanGoal? scanGoal,
    ScanCapturePlan? capturePlan,
    List<CapturedScanImage>? capturedImages,
    double? confidenceTarget,
    double? confidenceAchieved,
    String? category,
    DateTime? endTime,
    List<CaptureEvent>? events,
    bool clearConfidenceAchieved = false,
    bool clearEndTime = false,
  }) {
    return ScanSession(
      sessionId: sessionId,
      scanGoal: scanGoal ?? this.scanGoal,
      capturePlan: capturePlan ?? this.capturePlan,
      capturedImages: capturedImages ?? this.capturedImages,
      confidenceTarget: confidenceTarget ?? this.confidenceTarget,
      confidenceAchieved: clearConfidenceAchieved
          ? null
          : confidenceAchieved ?? this.confidenceAchieved,
      category: category ?? this.category,
      scannerUxVersion: scannerUxVersion,
      startTime: startTime,
      endTime: clearEndTime ? null : endTime ?? this.endTime,
      events: events ?? this.events,
    );
  }

  ScanSession addEvent(CaptureEvent event) {
    return copyWith(events: [...events, event]);
  }
}
