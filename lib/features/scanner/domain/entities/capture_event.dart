enum CaptureEventType {
  sessionStarted,
  goalSelected,
  roleRequested,
  roleCaptured,
  qualityGatePassed,
  qualityGateWarning,
  qualityGateBlocked,
  analyzeTriggered,
  analyzeCompleted,
  sessionCompleted,
}

class CaptureEvent {
  const CaptureEvent({
    required this.type,
    required this.timestamp,
    this.role,
    this.metadata = const {},
  });

  final CaptureEventType type;
  final DateTime timestamp;
  final String? role;
  final Map<String, Object?> metadata;
}
