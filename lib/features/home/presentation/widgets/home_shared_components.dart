import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeTokens {
  const HomeTokens._();

  static const background = Color(0xFF030B14);
  static const surface = Color(0xFF071827);
  static const surfaceRaised = Color(0xFF0A2033);
  static const surfaceInteractive = Color(0xFF0C2740);
  static const border = Color(0xFF17324A);
  static const accent = Color(0xFF0087FF);
  static const accentStrong = Color(0xFF0067E8);
  static const categoryCards = Color(0xFF22D3EE);
  static const categoryCoins = Color(0xFFF4B740);
  static const categoryFigures = Color(0xFF9B7CFF);
  static const categoryMore = Color(0xFF00D88A);
  static const textPrimary = Color(0xFFF4F8FC);
  static const textSecondary = Color(0xFFA7B5C5);
  static const textMuted = Color(0xFF6F8295);
  static const positive = Color(0xFF00D88A);
  static const warning = Color(0xFFF4B740);

  static const pageGutter = 16.0;
  static const cardPadding = 14.0;
  static const sectionGap = 16.0;
  static const cardGap = 10.0;
  static const maxContentWidth = 600.0;
  static const bottomContentClearance = 80.0;
  static const cardRadius = 14.0;
  static const controlRadius = 10.0;
}

class HomeBrandLockup extends StatelessWidget {
  const HomeBrandLockup({
    this.showAlert = false,
    this.onAlertPressed,
    super.key,
  });

  final bool showAlert;
  final VoidCallback? onAlertPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          PackLoxAssets.brandV2Emblem,
          key: const ValueKey('home-brand-emblem'),
          width: 42,
          height: 42,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'PackLox',
            key: const ValueKey('home-brand-wordmark'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ),
        if (showAlert)
          IconButton(
            key: const ValueKey('home-alert-button'),
            tooltip: 'Collection alert',
            onPressed: onAlertPressed,
            icon: const Icon(Icons.priority_high_rounded),
            color: HomeTokens.warning,
            style: IconButton.styleFrom(
              backgroundColor: HomeTokens.surfaceRaised,
              side: const BorderSide(color: HomeTokens.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              fixedSize: const Size.square(54),
            ),
          ),
      ],
    );
  }
}

class HomeTitleBlock extends StatelessWidget {
  const HomeTitleBlock({required this.subtitle, super.key});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home',
          key: const ValueKey('home-title'),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: HomeTokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          subtitle,
          key: const ValueKey('home-state-subtitle'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: HomeTokens.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class HomeAuthorityHero extends StatelessWidget {
  const HomeAuthorityHero({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.icon,
    this.onPressed,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String ctaLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return HomeSurface(
      keyPrefix: 'home',
      keySeed: 'authority-hero',
      semanticLabel: '$eyebrow. $title. $body',
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      radius: 24,
      backgroundColor: HomeTokens.surfaceRaised.withValues(alpha: .92),
      borderColor: HomeTokens.border,
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: 28,
            child: ExcludeSemantics(
              child: Container(
                width: 76,
                height: 58,
                decoration: BoxDecoration(
                  color: HomeTokens.accent.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: const Color(0xFF8BC7FF), size: 34),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF67B6FF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HomeTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  key: const ValueKey('home-primary-scan'),
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: enabled ? onPressed : null,
                    icon: const Icon(Icons.photo_camera_outlined, size: 19),
                    label: Text(
                      ctaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeTokens.accentStrong,
                      disabledBackgroundColor: HomeTokens.accentStrong
                          .withValues(alpha: .38),
                      foregroundColor: HomeTokens.textPrimary,
                      disabledForegroundColor: HomeTokens.textPrimary
                          .withValues(alpha: .68),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeMetricTile extends StatelessWidget {
  const HomeMetricTile({
    required this.label,
    required this.value,
    required this.supportingText,
    super.key,
  });

  final String label;
  final String value;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    return HomeSurface(
      keySeed: 'metric-${label.toLowerCase().replaceAll(' ', '-')}',
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            supportingText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeTokens.positive,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeActionRow extends StatelessWidget {
  const HomeActionRow({
    required this.keySeed,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = const Color(0xFF8BC7FF),
    this.onTap,
    super.key,
  });

  final String keySeed;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MotionTapScale(
      onTap: onTap,
      child: Semantics(
        button: onTap != null,
        enabled: onTap != null,
        label: '$title. $subtitle',
        excludeSemantics: true,
        child: Container(
          key: ValueKey('home-action-$keySeed'),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HomeTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HomeTokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HomeTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HomeTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: onTap == null
                    ? HomeTokens.textMuted
                    : const Color(0xFF8BC7FF),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeSkeletonBlock extends StatelessWidget {
  const HomeSkeletonBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('home-loading-skeleton'),
      children: const [
        _SkeletonSurface(height: 230),
        SizedBox(height: HomeTokens.sectionGap),
        _SkeletonSurface(height: 100),
        SizedBox(height: HomeTokens.cardGap),
        _SkeletonSurface(height: 100),
      ],
    );
  }
}

class _SkeletonSurface extends StatelessWidget {
  const _SkeletonSurface({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: HomeTokens.surfaceRaised.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HomeTokens.border.withValues(alpha: .62)),
      ),
    );
  }
}

class HomeErrorPanel extends StatelessWidget {
  const HomeErrorPanel({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return HomeSurface(
      keyPrefix: 'home',
      keySeed: 'error-panel',
      padding: const EdgeInsets.all(22),
      semanticLabel: 'Home error. $message',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: HomeTokens.warning,
            size: 32,
          ),
          const SizedBox(height: 18),
          Text(
            'Collection could not load',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('home-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    required this.firstName,
    required this.onNotifications,
    this.greetingText,
    this.fallbackName = 'Collector',
    this.notificationUnreadCount = 0,
    this.profileLoading = false,
    super.key,
  });

  final String firstName;
  final String? greetingText;
  final String fallbackName;
  final int notificationUnreadCount;
  final VoidCallback? onNotifications;
  final bool profileLoading;

  @override
  Widget build(BuildContext context) {
    return PackLoxHeader(
      firstName: firstName,
      greetingText: greetingText,
      fallbackName: fallbackName,
      notificationUnreadCount: notificationUnreadCount,
      profileLoading: profileLoading,
      onNotifications: onNotifications,
    );
  }
}

class HomeStateContainer extends StatelessWidget {
  const HomeStateContainer({
    required this.sections,
    this.controller,
    this.topPadding = AppSpacing.xs,
    this.bottomClearance = HomeTokens.bottomContentClearance,
    super.key,
  });

  final List<Widget> sections;
  final ScrollController? controller;
  final double topPadding;
  final double bottomClearance;

  static double gutterForWidth(double width) {
    if (width < 360) {
      return 14;
    }
    if (width <= 430) {
      return HomeTokens.pageGutter;
    }
    if (width < 600) {
      return 20;
    }
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = gutterForWidth(constraints.maxWidth);
        return CustomScrollView(
          key: const PageStorageKey<String>('home-scroll-position'),
          controller: controller,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(top: topPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  for (final section in sections)
                    _HomeConstrainedSection(gutter: gutter, child: section),
                  SizedBox(height: bottomClearance),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class HomeSection extends StatelessWidget {
  const HomeSection({
    required this.child,
    this.topPadding = AppSpacing.sm,
    this.bottomPadding = 0,
    super.key,
  });

  final Widget child;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: child,
    );
  }
}

class _HomeConstrainedSection extends StatelessWidget {
  const _HomeConstrainedSection({required this.gutter, required this.child});

  final double gutter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: HomeTokens.maxContentWidth,
          ),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class HomeSurface extends StatelessWidget {
  const HomeSurface({
    required this.child,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(HomeTokens.cardPadding),
    this.radius = HomeTokens.cardRadius,
    this.backgroundColor = HomeTokens.surfaceRaised,
    this.borderColor = HomeTokens.border,
    this.keySeed,
    this.keyPrefix = 'home-surface',
    super.key,
  });

  final Widget child;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final String? keySeed;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      key: keySeed == null ? null : ValueKey('$keyPrefix-$keySeed'),
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: AppElevation.level1,
      ),
      child: child,
    );

    if (semanticLabel == null) {
      return content;
    }

    return Semantics(container: true, label: semanticLabel, child: content);
  }
}

class HomeEmptyCollectionHero extends StatelessWidget {
  const HomeEmptyCollectionHero({
    this.onScanPressed,
    this.onSampleScanPressed,
    super.key,
  });

  final VoidCallback? onScanPressed;
  final VoidCallback? onSampleScanPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sampleSupported = onSampleScanPressed != null;

    return HomeSurface(
      keyPrefix: 'home',
      keySeed: 'empty-authority-card',
      semanticLabel:
          'Empty collection. Your collection is waiting. Scan your first item to get started.',
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      radius: HomeTokens.cardRadius,
      backgroundColor: HomeTokens.surfaceRaised,
      borderColor: HomeTokens.border,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: const ValueKey('home-empty-hero-icon-circle'),
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeTokens.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: HomeTokens.accent.withValues(alpha: .4),
              ),
            ),
            child: Image.asset(
              PackLoxAssets.brandV2Emblem,
              key: const ValueKey('home-empty-hero-archive-icon'),
              width: 34,
              height: 34,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 190,
            child: Text(
              'Your collection is waiting',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: HomeTokens.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.10,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan your first item to get started.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.24,
            ),
          ),
          const SizedBox(height: 10),
          _HomeHeroPrimaryButton(onPressed: onScanPressed),
          const SizedBox(height: 2),
          Semantics(
            button: true,
            enabled: sampleSupported,
            label: sampleSupported
                ? 'Try a Sample Scan'
                : 'Sample Scan unavailable',
            excludeSemantics: true,
            child: TextButton(
              key: const ValueKey('home-sample-scan'),
              onPressed: onSampleScanPressed,
              style: TextButton.styleFrom(
                foregroundColor: sampleSupported
                    ? HomeTokens.accent
                    : HomeTokens.textMuted,
                minimumSize: const Size.fromHeight(28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(
                sampleSupported
                    ? 'Try a Sample Scan'
                    : 'Sample Scan unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeroPrimaryButton extends StatelessWidget {
  const _HomeHeroPrimaryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Scan a Collectible',
      excludeSemantics: true,
      child: SizedBox(
        key: const ValueKey('home-primary-scan'),
        height: 42,
        width: double.infinity,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.photo_camera_outlined, size: 19),
          label: const Text(
            'Scan a Collectible',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: TextButton.styleFrom(
            backgroundColor: enabled
                ? HomeTokens.accentStrong
                : HomeTokens.accentStrong.withValues(alpha: .45),
            foregroundColor: HomeTokens.textPrimary,
            disabledForegroundColor: HomeTokens.textPrimary.withValues(
              alpha: .74,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: HomeTokens.accent.withValues(alpha: .68)),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: onAction == null
                  ? HomeTokens.textMuted
                  : HomeTokens.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class HomeSectionSurface extends StatelessWidget {
  const HomeSectionSurface({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.keySeed,
    this.backgroundColor = HomeTokens.surfaceRaised,
    this.borderColor = HomeTokens.border,
    super.key,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? keySeed;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return HomeSurface(
      keySeed: keySeed ?? title.toLowerCase().replaceAll(' ', '-'),
      keyPrefix: 'home-section',
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(
            title: title,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class HomeCollectionStripItem {
  const HomeCollectionStripItem({
    required this.id,
    required this.title,
    required this.imagePath,
    this.subtitle,
    this.onTap,
  });

  final String id;
  final String title;
  final String imagePath;
  final String? subtitle;
  final VoidCallback? onTap;
}

class HomeCollectionStrip extends StatelessWidget {
  const HomeCollectionStrip({
    required this.title,
    required this.itemCount,
    required this.items,
    this.onViewAll,
    this.maxVisibleItems = 4,
    super.key,
  });

  final String title;
  final int itemCount;
  final List<HomeCollectionStripItem> items;
  final VoidCallback? onViewAll;
  final int maxVisibleItems;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(maxVisibleItems).toList(growable: false);
    final overflow = itemCount - visible.length;

    return HomeSectionSurface(
      title: title,
      actionLabel: onViewAll == null ? null : 'View all',
      onAction: onViewAll,
      keySeed: 'collection-strip',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length + (overflow > 0 ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index >= visible.length) {
                  return _HomeOverflowTile(count: overflow);
                }
                return _HomeStripTile(item: visible[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeStripTile extends StatelessWidget {
  const _HomeStripTile({required this.item});

  final HomeCollectionStripItem item;

  @override
  Widget build(BuildContext context) {
    return MotionTapScale(
      onTap: item.onTap,
      child: Semantics(
        button: item.onTap != null,
        label: item.subtitle == null
            ? item.title
            : '${item.title}, ${item.subtitle}',
        excludeSemantics: true,
        child: SizedBox(
          width: 82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: PortfolioThumbnail(imagePath: item.imagePath, size: 72),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: HomeTokens.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeOverflowTile extends StatelessWidget {
  const _HomeOverflowTile({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count more items',
      child: Container(
        key: const ValueKey('home-collection-strip-overflow'),
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HomeTokens.surfaceInteractive,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: HomeTokens.border),
        ),
        child: Text(
          '+$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: HomeTokens.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class HomeValueMetricCard extends StatelessWidget {
  const HomeValueMetricCard({
    required this.label,
    required this.value,
    this.isUnavailable = false,
    this.changeLabel,
    this.trendValues = const [],
    super.key,
  });

  final String label;
  final String value;
  final bool isUnavailable;
  final String? changeLabel;
  final List<double> trendValues;

  @override
  Widget build(BuildContext context) {
    final hasTrend = trendValues.length >= 2;
    return HomeSurface(
      keySeed: 'value-metric',
      semanticLabel: isUnavailable ? '$label unavailable' : '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isUnavailable ? 'Unavailable' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isUnavailable
                  ? HomeTokens.textSecondary
                  : HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (changeLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              changeLabel!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HomeTokens.positive,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (hasTrend) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              key: const ValueKey('home-value-metric-trend'),
              height: 42,
              width: double.infinity,
              child: CustomPaint(
                painter: _HomeSparklinePainter(
                  values: trendValues,
                  color: HomeTokens.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeSparklinePainter extends CustomPainter {
  const _HomeSparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final span = maxValue - minValue;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = span == 0 ? 0.5 : (values[i] - minValue) / span;
      points.add(Offset(x, size.height - size.height * normalized));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeSparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

enum HomeCategoryKind { cards, coins, figures, more }

class HomeCategoryTile extends StatelessWidget {
  const HomeCategoryTile({
    required this.label,
    required this.icon,
    required this.semanticMeaning,
    required this.iconColor,
    required this.assetPath,
    this.onTap,
    super.key,
  });

  factory HomeCategoryTile.cards({VoidCallback? onTap}) {
    return HomeCategoryTile(
      label: 'Cards',
      icon: Icons.style_outlined,
      assetPath: PackLoxAssets.categoryCards,
      semanticMeaning: 'trading cards',
      iconColor: HomeTokens.categoryCards,
      onTap: onTap,
    );
  }

  factory HomeCategoryTile.coins({VoidCallback? onTap}) {
    return HomeCategoryTile(
      label: 'Coins',
      icon: Icons.album_outlined,
      assetPath: PackLoxAssets.categoryCoins,
      semanticMeaning: 'collectible coins and medallions',
      iconColor: HomeTokens.categoryCoins,
      onTap: onTap,
    );
  }

  factory HomeCategoryTile.figures({VoidCallback? onTap}) {
    return HomeCategoryTile(
      label: 'Figures',
      icon: Icons.smart_toy_outlined,
      assetPath: PackLoxAssets.categoryFigures,
      semanticMeaning: 'figurines and action figures',
      iconColor: HomeTokens.categoryFigures,
      onTap: onTap,
    );
  }

  factory HomeCategoryTile.more({VoidCallback? onTap}) {
    return HomeCategoryTile(
      label: 'More',
      icon: Icons.grid_view_outlined,
      assetPath: PackLoxAssets.categoryMore,
      semanticMeaning: 'more categories grid',
      iconColor: HomeTokens.categoryMore,
      onTap: onTap,
    );
  }

  final String label;
  final IconData icon;
  final String assetPath;
  final String semanticMeaning;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Popular category $label, $semanticMeaning',
      excludeSemantics: true,
      child: MotionTapScale(
        onTap: onTap,
        child: Container(
          key: ValueKey('home-popular-category-${label.toLowerCase()}'),
          constraints: const BoxConstraints(minHeight: 74, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HomeTokens.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: HomeTokens.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                key: ValueKey(
                  'home-popular-category-${label.toLowerCase()}-icon',
                ),
                assetPath,
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: HomeTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeCategoryGrid extends StatelessWidget {
  const HomeCategoryGrid({
    required this.categories,
    this.spacing = 12,
    super.key,
  });

  final List<HomeCategoryTile> categories;
  final double spacing;

  factory HomeCategoryGrid.popular() {
    return HomeCategoryGrid(
      categories: [
        HomeCategoryTile.cards(),
        HomeCategoryTile.coins(),
        HomeCategoryTile.figures(),
        HomeCategoryTile.more(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final screenWidth = MediaQuery.sizeOf(context).width;
        final fourColumnTileWidth = (constraints.maxWidth - spacing * 3) / 4;
        final columns =
            screenWidth >= 360 && fourColumnTileWidth >= 68 && textScale <= 1.35
            ? 4
            : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in categories)
              SizedBox(width: tileWidth, child: category),
          ],
        );
      },
    );
  }
}

class HomeQuickAction {
  const HomeQuickAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.onTap,
  });

  final String key;
  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
}

class HomeQuickActionTile extends StatelessWidget {
  const HomeQuickActionTile({required this.action, super.key});

  final HomeQuickAction action;

  @override
  Widget build(BuildContext context) {
    final enabled = action.onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: action.semanticLabel,
      excludeSemantics: true,
      child: MotionTapScale(
        onTap: action.onTap,
        child: Container(
          key: ValueKey('home-quick-action-${action.key}'),
          constraints: const BoxConstraints(minHeight: 58, minWidth: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: HomeTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: HomeTokens.border),
          ),
          child: Row(
            children: [
              Icon(
                action.icon,
                color: enabled ? HomeTokens.accent : HomeTokens.textMuted,
                size: AppIconSizes.md,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: enabled
                        ? HomeTokens.textPrimary
                        : HomeTokens.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: HomeTokens.textSecondary,
                size: AppIconSizes.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeQuickActionGrid extends StatelessWidget {
  const HomeQuickActionGrid({required this.actions, super.key});

  final List<HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.35;
        final columns = compact ? 2 : 3;
        final tileWidth =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final action in actions)
              SizedBox(
                width: tileWidth,
                child: HomeQuickActionTile(action: action),
              ),
          ],
        );
      },
    );
  }
}

class HomeRecentItemCard extends StatelessWidget {
  const HomeRecentItemCard({
    required this.id,
    required this.title,
    required this.category,
    required this.imagePath,
    required this.valueLabel,
    this.condition,
    this.addedLabel,
    this.valueUnavailable = false,
    this.onTap,
    this.backgroundColor = HomeTokens.surfaceRaised,
    this.borderColor = HomeTokens.border,
    super.key,
  });

  final String id;
  final String title;
  final String category;
  final String imagePath;
  final String valueLabel;
  final String? condition;
  final String? addedLabel;
  final bool valueUnavailable;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final detail = [
      category,
      if (condition != null && condition!.trim().isNotEmpty) condition!,
    ].join(' / ');

    return MotionTapScale(
      onTap: onTap,
      child: Semantics(
        button: onTap != null,
        label: '$title, $detail, $valueLabel',
        excludeSemantics: true,
        child: Container(
          key: ValueKey('home-recent-$id'),
          constraints: const BoxConstraints(minHeight: 86),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: PortfolioThumbnail(imagePath: imagePath, size: 64),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: HomeTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HomeTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (addedLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        addedLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: HomeTokens.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 74,
                child: Text(
                  valueLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: valueUnavailable
                        ? HomeTokens.textSecondary
                        : HomeTokens.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
