import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// PackLox Header 1.0.1 (PLX-CMP-HEADER@1.0.1).
class PackLoxHeader extends StatelessWidget {
  const PackLoxHeader({
    required this.firstName,
    required this.onNotifications,
    this.greetingText,
    this.now = DateTime.now,
    this.fallbackName = 'Collector',
    this.notificationUnreadCount = 0,
    this.profileLoading = false,
    super.key,
  });
  final String firstName;
  final String? greetingText;
  final DateTime Function() now;
  final String fallbackName;
  final int notificationUnreadCount;
  final VoidCallback? onNotifications;
  final bool profileLoading;

  String get greeting =>
      greetingText ??
      switch (now().hour) {
        >= 5 && < 12 => 'Good morning',
        >= 12 && < 17 => 'Good afternoon',
        _ => 'Good evening',
      };
  @override
  Widget build(BuildContext context) {
    final name = firstName.trim().isEmpty ? fallbackName : firstName.trim();
    final notificationLabel = notificationUnreadCount > 0
        ? 'Notifications, $notificationUnreadCount unread'
        : 'Notifications';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: PackLoxTokens.textSecondary,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (profileLoading)
                  const SizedBox(width: 160, height: 32)
                else
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        name,
                        key: const ValueKey('scan-hub-title'),
                        style: const TextStyle(
                          color: PackLoxTokens.textPrimary,
                          fontSize: 30,
                          height: 1.18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.05,
                        ),
                      ),
                      const ExcludeSemantics(
                        child: Text(
                          '\u{1F44B}',
                          style: TextStyle(fontSize: 24, height: 1),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Semantics(
          button: true,
          enabled: onNotifications != null,
          label: notificationLabel,
          excludeSemantics: true,
          child: Tooltip(
            message: notificationLabel,
            child: SizedBox.square(
              dimension: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: IconButton(
                      key: const ValueKey('scan-hub-notifications-button'),
                      onPressed: onNotifications,
                      icon: SvgPicture.asset(
                        PackLoxAssets.notificationBell,
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          PackLoxTokens.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      color: PackLoxTokens.textPrimary,
                      style: IconButton.styleFrom(
                        backgroundColor: PackLoxTokens.surfaceRaised,
                        side: BorderSide(
                          color: PackLoxTokens.border.withValues(alpha: .95),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  if (notificationUnreadCount > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: ExcludeSemantics(
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: PackLoxTokens.amber,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: PackLoxTokens.background,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            notificationUnreadCount > 99
                                ? '99+'
                                : '$notificationUnreadCount',
                            style: const TextStyle(
                              color: PackLoxTokens.background,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
