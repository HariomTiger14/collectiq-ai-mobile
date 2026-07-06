import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:flutter/material.dart';

class CaptureRoleGuide extends StatelessWidget {
  const CaptureRoleGuide({required this.role, this.compact = false, super.key});

  final ScanCaptureRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      key: ValueKey('capture-role-guide-${role.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(role.icon, size: compact ? 18 : 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            role.guidance,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
