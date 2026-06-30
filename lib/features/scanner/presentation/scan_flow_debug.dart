import 'package:flutter/foundation.dart';

const collectIqScanFlowTag = 'COLLECTIQ_SCAN_FLOW';

void logCollectIqScanFlow(
  String event, {
  String? selectedImagePath,
  bool? isLoading,
  bool? isPreparingImage,
  bool? isPickerActive,
  bool? isRecoveringLostData,
  int? currentTabIndex,
  Object? error,
  StackTrace? stackTrace,
  Map<String, Object?> details = const {},
}) {
  final detailText = details.entries
      .map((entry) => '${entry.key}=${_formatValue(entry.value)}')
      .join(' ');
  debugPrint(
    '$collectIqScanFlowTag event=$event '
    'selectedImagePath=${_formatValue(selectedImagePath)} '
    'isLoading=${_formatValue(isLoading)} '
    'isPreparingImage=${_formatValue(isPreparingImage)} '
    'isPickerActive=${_formatValue(isPickerActive)} '
    'isRecoveringLostData=${_formatValue(isRecoveringLostData)} '
    'currentTabIndex=${_formatValue(currentTabIndex)}'
    '${detailText.isEmpty ? '' : ' $detailText'}'
    '${error == null ? '' : ' error=${_formatValue(error)}'}',
  );
  if (stackTrace != null) {
    debugPrint('$collectIqScanFlowTag stackTrace=$stackTrace');
  }
}

String _formatValue(Object? value) {
  if (value == null) {
    return 'null';
  }
  final text = value.toString().replaceAll('\n', ' ');
  return text.isEmpty ? 'empty' : text;
}
