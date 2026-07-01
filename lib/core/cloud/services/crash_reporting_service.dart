abstract interface class CrashReportingService {
  String get providerName;

  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  });
}
