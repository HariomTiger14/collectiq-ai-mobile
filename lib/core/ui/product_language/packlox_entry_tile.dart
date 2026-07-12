import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:flutter/material.dart';

enum PackLoxEntryTileVariant {
  standard,
  primary,
  scanner,
  portfolio,
  analysis,
  navigation,
}

enum PackLoxEntryTileState {
  normal,
  disabled,
  loading,
  success,
  warning,
  error,
}

/// PackLox Entry Tile 1.0.0 (PLX-CMP-ENTRY-TILE@1.0.0).
class PackLoxEntryTile extends StatelessWidget {
  const PackLoxEntryTile({
    required this.icon,
    required this.title,
    required this.supportingText,
    required this.onTap,
    this.variant = PackLoxEntryTileVariant.standard,
    this.state = PackLoxEntryTileState.normal,
    this.badge,
    this.value,
    this.semanticLabel,
    this.showTrailing = true,
    this.compatibilityKey,
    super.key,
  });
  final IconData icon;
  final String title, supportingText;
  final VoidCallback? onTap;
  final PackLoxEntryTileVariant variant;
  final PackLoxEntryTileState state;
  final String? badge, value, semanticLabel;
  final bool showTrailing;
  final Key? compatibilityKey;
  @override
  Widget build(BuildContext context) {
    final enabled =
        state != PackLoxEntryTileState.disabled &&
        state != PackLoxEntryTileState.loading &&
        onTap != null;
    final statusColor = switch (state) {
      PackLoxEntryTileState.success => PackLoxTokens.success,
      PackLoxEntryTileState.warning => PackLoxTokens.amber,
      PackLoxEntryTileState.error => PackLoxTokens.error,
      _ => PackLoxTokens.border,
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? '$title. $supportingText',
      value: state == PackLoxEntryTileState.loading ? 'Loading' : null,
      excludeSemantics: true,
      child: Material(
        key: compatibilityKey,
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width <= 360 ? 16 : 18,
            ),
            decoration: BoxDecoration(
              color: PackLoxTokens.surfaceRaised.withValues(
                alpha: enabled ? 1 : .55,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: PackLoxTokens.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PackLoxTokens.border),
                  ),
                  child: state == PackLoxEntryTileState.loading
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: PackLoxTokens.cyan,
                          ),
                        )
                      : Icon(icon, size: 23, color: PackLoxTokens.textPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: PackLoxTokens.textPrimary,
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        supportingText,
                        style: const TextStyle(
                          color: PackLoxTokens.textSecondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          badge!,
                          style: const TextStyle(
                            color: PackLoxTokens.cyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: PackLoxTokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (showTrailing)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: PackLoxTokens.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
