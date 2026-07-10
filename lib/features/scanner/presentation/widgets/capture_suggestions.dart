import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class CaptureSuggestionBubble extends StatelessWidget {
  const CaptureSuggestionBubble({
    required this.label,
    required this.visible,
    super.key,
  });

  final String label;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      key: const ValueKey('scan-capture-suggestion-slide'),
      offset: visible ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        key: const ValueKey('scan-capture-suggestion'),
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                label,
                key: const ValueKey('scan-capture-suggestion-label'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
