# PackLox UI Architecture Snapshot

Post-premium cleanup snapshot for the Flutter UI system. This document captures the shared tokens, motion primitives, premium components, responsive rules, screen patterns, and test coverage currently used across PackLox.

## 1. Global Tokens

### Spacing

Defined in `lib/core/theme/design_system.dart` as `AppSpacing`.

- `xs`: 4
- `sm`: 8
- `md`: 12
- `lg`: 16
- `xl`: 24
- `xxl`: 32

Usage intent:

- Hero horizontal padding: `AppSpacing.xl` to `AppSpacing.xxl`
- Content surface padding: `AppSpacing.lg` to `AppSpacing.xl`
- Compact card padding: `AppSpacing.md` to `AppSpacing.lg`
- Section rhythm: usually 20 to 28 logical pixels, implemented with `AppSpacing.xl`, `AppSpacing.lg`, and local section gaps where needed
- Small inline gaps: `AppSpacing.xs` and `AppSpacing.sm`

### Radius

Defined in `AppRadius`.

- `sm`: 8, used for badges, small chips, compact icon containers
- `md`: 12, used for compact controls and secondary tiles
- `lg`: 16, used for thumbnails, buttons, and smaller cards
- `xl`: 24, used for premium cards and surfaces
- `xxl`: 32, used for full-width hero surfaces
- `pill`: 999, used for fully rounded pills

### Typography

Base text styles are defined in `AppTextStyles` and mapped into `AppTheme`.

- `headlineLarge`: based on `AppTextStyles.h1`, 34px, 1.06 line height, w800
- `headlineMedium`: 30px hero/title scale, used with w900 for premium hero titles
- `headlineSmall` / `titleLarge`: based on `AppTextStyles.h2`, 24px, w800
- `titleMedium`: based on `AppTextStyles.h3`, 18px, w700
- `titleSmall`: 14px title treatment for compact cards
- `bodyLarge`: 16px body text
- `bodyMedium`: 14px card/body copy
- `bodySmall`: 12px supporting copy
- `labelLarge`: 13px, w700, CTAs and compact labels
- `labelSmall`: 11px, used by badges with w600

Premium hierarchy:

- Hero title: `headlineMedium`, w900, height 1.05
- Hero subtitle: `bodyLarge`, w600, opacity near 0.82 on hero foreground
- Hero caption: `bodySmall`, w600, opacity near 0.68 on hero foreground
- Section headers: `titleMedium` or `titleSmall`, w700 to w800
- Card content: `bodyMedium`
- Badges: `labelSmall`, w600

### Color And Surface Tokens

Defined in `AppColors` and `AppTheme`.

- Ink: `AppColors.ink` `#111827`
- Muted ink: `AppColors.mutedInk` `#6B7280`
- Canvas: `AppColors.canvas` `#F6F8FB`
- Surface: `AppColors.surface` `#FFFFFF`
- Muted surface: `AppColors.surfaceMuted` `#EFF4FA`
- Border: `AppColors.border` `#DDE5EF`
- Primary/accent: `AppColors.accent` `#0A84FF`
- Deep accent: `AppColors.accentDeep` `#1456D9`
- Secondary accent: `AppColors.secondaryAccent` `#14B8A6`
- Violet: `AppColors.violet` `#7C3AED`
- Glass: `AppColors.glass` `#BFFFFFFF`
- Success: `AppColors.success` `#16A34A`
- Danger: `AppColors.danger` `#DC2626`

Material surface roles:

- `colorScheme.surface`: app canvas/background
- `colorScheme.surfaceContainerHighest`: premium cards, badges, menus, thumbnails
- `colorScheme.surfaceContainerLow`: secondary surfaces when available from Material 3 runtime
- `colorScheme.outlineVariant`: borders and dividers
- `colorScheme.primaryContainer`, `secondaryContainer`, `tertiaryContainer`: premium badge backgrounds

### Shadows

Defined in `AppElevation`.

- `level1`: light card shadow, blur 22, offset 0/10
- `level2`: premium card shadow, blur 34, offset 0/18, plus subtle white edge
- `level3`: high-emphasis value/hero card shadow, blur 46, offset 0/24
- `accentGlow`: blue accent glow, blur 34, offset 0/16

Hero surfaces also use gradient-aware shadows, usually `gradientColors.last` with alpha 0.20 to 0.32, blur 32 to 46, offset 0/20 to 0/24.

### Gradients

Defined in `AppGradients` and `PackLoxGradients`.

- `AppGradients.primary`: blue to indigo to violet
- `AppGradients.premium`: dark navy to blue to indigo to teal
- `GradientStyle.blueIndigo`: light `#0A84FF -> #1456D9 -> #5E5CE6`, dark `#07111F -> #1E40AF -> #5E5CE6`
- `GradientStyle.purpleDeepBlue`: light `#8B5CF6 -> #5E5CE6 -> #0A84FF`, dark `#1A103D -> #5B21B6 -> #1E40AF`
- `GradientStyle.tealEmerald`: light `#0A84FF -> #14B8A6 -> #10B981`, dark `#062D35 -> #0F766E -> #047857`

All new shared gradient lookups should use `PackLoxGradients.build(style, context)` for dark-mode consistency.

### Motion Timing And Curves

Defined in `PackLoxMotionTheme`.

- `fast`: 120ms
- `medium`: 220ms
- `slow`: 320ms
- `navSpringDuration`: 260ms
- `revealStagger`: 60ms
- `pulseDuration`: 1800ms
- `waveDuration`: 2600ms
- Tap scale: 0.96
- Hover opacity: 0.08
- Hover blur radius: 14
- Hero parallax depth: 18
- Card parallax depth: 6
- Tap/reveal/nav curve: `Curves.easeOutCubic`
- Transition curve: `Curves.easeInOutCubic`
- Hover curve: `Curves.easeOutQuad`
- Navigation spring curve: `Curves.easeOutBack`

Motion is disabled or simplified in widget tests through `PackLoxMotionTheme.isTestMode`.

## 2. Premium Systems

### MotionElasticHero

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Gives hero surfaces elastic overscroll stretch.
- Accepts `baseHeight`, `scrollOffset`, `maxOverscroll`, and `stretchFactor`.
- In tests, returns a fixed-height `SizedBox` for deterministic layout.

Used by:

- Home hero
- Portfolio hero
- Item detail hero image
- Cloud Sync hero
- About hero

### MotionParallax

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Moves hero/card content vertically based on scroll progress.
- Defaults to `PackLoxMotionTheme.heroParallaxDepth`.
- Keeps premium hero surfaces from feeling static.

### MotionAmbientGradient

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Applies animated gradient decoration from a `Gradient Function(double t)`.
- Repeats only when ambient motion is enabled.
- Used by hero surfaces and premium status cards.

### MotionReveal

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Fade plus upward translate reveal.
- Supports delay and custom curve.
- Used by grid tiles, list panels, scan cards, and thumbnail frames.

### MotionStagger

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Applies `MotionReveal` to a list of children with `revealStagger` delays.
- Used for quick actions, scan card groups, portfolio item lists, and grouped page sections.

### PremiumBadge

Location: `lib/core/design_system/layout_components.dart`

Purpose:

- Shared badge system for category, confidence, trend, wishlist, neutral labels, and custom badges.
- Constructors: `PremiumBadge.confidence`, `PremiumBadge.trend`, `PremiumBadge.wishlist`, `PremiumBadge.category`, and base `PremiumBadge`.
- Uses `AppRadius.sm`, `labelSmall` w600, color scheme containers, `AppSpacing.xs`, compact icon sizing, and max-width truncation.

Current uses:

- Portfolio grid cards
- Scan result chips
- Capture workspace enhanced and role badges

### HeroDecorativeCircle

Location: `lib/core/widgets/gradient_header.dart`

Purpose:

- Shared decorative ring for premium hero headers.
- Parameterized by diameter, stroke width, and opacity.
- Used by Portfolio hero header after premium hero migration.

### HeroSurfaceContainerHighest

Location: `lib/core/widgets/gradient_header.dart`

Purpose:

- Shared full-width hero surface container.
- Uses `AppRadius.xxl` bottom radius, `PackLoxGradients.build`, gradient-aware shadow, and stacked decorative children.
- Current canonical use is `PortfolioHeroHeader`.

### PackLoxGradients.build()

Location: `lib/core/widgets/gradient_header.dart`

Purpose:

- Central dark/light gradient resolver for `GradientStyle`.
- Replaced local gradient color builders in shared gradient header usage.
- Should be preferred over new manual gradient switch statements.

## 3. Shared Components

### Hero Headers

- `HomeHeroHeader`: collection hub hero with metrics, wrapped by `MotionElasticHero` and `MotionParallax` in `HomeScreen`.
- `PortfolioHeroHeader`: canonical premium hero using `MotionElasticHero`, `MotionParallax`, `MotionAmbientGradient`, `HeroSurfaceContainerHighest`, and `HeroDecorativeCircle`.
- `ScanHeroHeader`: scanner hero with ambient gradient, premium gradient, glow disks, and reveal text.
- `SettingsHeroHeader`: settings premium hero surface with motion treatment.
- `AboutHeroHeader`: elastic/parallax/ambient hero with back-button support.
- `CloudSyncHeroHeader`: elastic/parallax/ambient hero with sync icon and gradient shadow.
- `ItemHeroImage`: portfolio detail image hero with elastic height, parallax, cover image, overlay, and shimmer.
- Result hero: scan result screen uses a large primary image surface, AI Enhanced badge, value card, confidence meter, and summary-first metadata.

### Section Surfaces

- `_HomeSurface` / `_HomeSectionSurface`: unified Home page section surfaces for Quick Actions, Portfolio Overview, Recent Activity, AI Insights, and CTA.
- `PortfolioSectionCard`: compact portfolio section surface with reveal animation.
- `CloudSyncSectionCard`: cloud sync page grouped surface.
- `AppInfoSection` and `AppProfileSection`: reusable frosted/premium information surfaces.
- `GlassCard`: older glass card shell still used by scan groupings and some legacy sections.

### Premium Cards

- `PortfolioGridTile`: premium collectible card with `surfaceContainerHighest`, `AppRadius.xl`, `AppElevation.level2`, premium thumbnail, badges, value row, and menu.
- `PortfolioSummaryCard`: compact portfolio metrics and total value gradient card.
- `AiInsightsCard`: home insights card with violet glow and icon motion.
- `CloudSyncStatusCard`: animated sync state card with ambient gradient and responsive metric group.
- `AppPriceHero`: premium gradient price/value card.

### Premium Grids

- `HomeQuickActionsGrid`: responsive `Wrap` grid, 2 columns under 720px and 4 columns above.
- `PortfolioItemsGrid`: staggered list/grid wrapper for portfolio items.
- Portfolio `SliverGrid`: responsive cross-axis count and tuned aspect ratios for 1, 2, and tablet columns.
- `_CompactMetricGrid`: portfolio metrics grid, 2 columns under 620px and 4 above.
- Scanner filmstrip and workspace photo set grids use fixed-format thumbnails and active selection state.

### Premium List Rows

- Recent Activity rows: larger thumbnails, softer chevrons, badges, compact value hierarchy.
- `CloudSyncDiagnosticTile`: hoverable/tappable diagnostic row with icon container and truncation.
- `AboutInfoTile` / `AboutLinkTile`: frosted row shell with icon, title, subtitle, and trailing affordance.
- `ModernSettingsRow`: settings row pattern for local messages and actions.
- `ItemAttributeRow`: item detail metadata/action row with hover surface and tap scale.

### Premium Thumbnails

- `PortfolioThumbnail` and `_PortfolioGridThumbnail`: `AspectRatio(1)`, `ClipRRect`, `AppRadius.lg`, `BoxFit.cover`, gradient overlay, and `MotionReveal`.
- Portfolio detail gallery thumbnails: selected state, AI enhanced badge, full-screen carousel entry.
- Scanner workspace filmstrip thumbnails: active photo, primary photo, role badge, remove action, and capture-set state.
- Recent Activity thumbnails: compact cover image with stable sizing.

### Premium Badges

- `PremiumBadge.category`: category labels.
- `PremiumBadge.confidence`: confidence labels.
- `PremiumBadge.trend`: market trend labels.
- `PremiumBadge.wishlist`: wishlist/owned/missing labels.
- Base `PremiumBadge`: neutral chips such as AI Enhanced and result metadata.

Legacy local badges still exist in a few older row/card helpers. New work should migrate to `PremiumBadge`.

### Premium Value Rows

- Portfolio grid value row: `Expanded` label, numeric-only `FittedBox`, flexible value, soft chevron, compact overflow menu.
- Result value card: summary-first estimated value treatment with soft gradient.
- Portfolio detail value card: gradient value card with locale-aware currency and motion.
- Home Portfolio Overview: large numeric value with `FittedBox` for numeric scaling only.

### Premium CTAs

- Filled primary actions use global button theme: 48px minimum height and `AppRadius.lg`.
- Scan primary actions use gradient containers and filled buttons.
- Cloud sync action button uses gradient, hover glow, `MotionTapScale`, 52px height.
- Home small portfolio CTA adapts from row to stacked layout under 370px.
- Result screen Add to Portfolio CTA slides in and stays summary-first.

## 4. Responsive System

### Breakpoints

Current local breakpoints are intentionally simple and component-owned.

- 320px: smallest supported smoke width; rows must wrap or stack; long text must truncate or soft-wrap.
- 340px: metadata rows stack in `AppLabelValueRow`.
- 360px: small Android smoke target.
- 370px: Home small portfolio CTA stacks.
- 560px: portfolio glass item cards switch to compact layout.
- 600px: tablet boundary for several page constraints.
- 620px: responsive metrics switch from column/2-column to row/4-column.
- 640px: Scan action row switches secondary actions from wrap to row.
- 720px: Home quick actions switch from 2 to 4 columns.
- 960px: common max content width for premium pages.

### Wrap Rules

- Use `Wrap` for badges, chips, action groups, and metadata clusters.
- Avoid `Row` for unknown-length labels plus badges.
- Keep `spacing` and `runSpacing` tokenized with `AppSpacing.xs`, `sm`, or `md`.
- Empty optional role/capture groups should read as optional, not failed.

### Flexible And Expanded Rules

- Long titles use `Expanded` or `Flexible` and `maxLines: 2`.
- Numeric values may use `FittedBox`; long prose should not.
- Value rows should use `Expanded` label and `Flexible` numeric value.
- Metadata rows should stack under narrow widths through `LayoutBuilder`.
- Hero and thumbnail imagery should use `AspectRatio` or fixed-format constraints rather than free vertical growth.

### Small-Screen Adjustments

- At 320px, portfolio grid cards use more vertical aspect ratio to avoid overflow.
- Hero metric groups use compact widths, shorter line counts, or wrapping.
- CTAs stack where horizontal space would compress labels.
- Badges truncate within `PremiumBadge.maxWidth`.
- Detail pages use wrapped badges and responsive padding, usually 12 to 20 logical pixels.

### Tablet Adjustments

- Content is centered and constrained to about 960px on major pages.
- Home quick actions use 4 columns at wider widths.
- Metrics switch to row/4-column presentations near 620px.
- Portfolio grid increases column count based on available width while preserving thumbnail aspect ratio and card hierarchy.

## 5. Screen-By-Screen Summary

### Home

Architecture:

- `Scaffold`
- `SafeArea`
- `CustomScrollView`
- `MotionElasticHero` + `MotionParallax` wrapping `HomeHeroHeader`
- Unified surfaces: Quick Actions, Portfolio Overview, Recent Activity, AI Insights

Premium systems:

- Elastic/parallax hero
- Section surfaces with variant-specific opacity, divider, radius, shadow
- `MotionStagger` quick actions
- AI Insights animated glow and icon motion
- Compact recent activity with thumbnail, badges, soft chevron, and relative saved labels

### Portfolio

Architecture:

- `PortfolioHeroHeader`
- Portfolio summary
- Filters/search/sort controls
- Responsive `SliverGrid` of `PortfolioGridTile`
- Empty, no-results, and error states

Premium systems:

- Canonical premium hero system with ambient gradient and decorative circle
- Premium grid cards with `surfaceContainerHighest`, `AppRadius.xl`, `AppElevation.level2`
- Premium thumbnails with aspect ratio, cover image, gradient overlay, and reveal motion
- Shared `PremiumBadge` for category, confidence, trend, wishlist
- Responsive value row and premium overflow menu

### Portfolio Detail

Architecture:

- Summary-first hero image/gallery
- Thumbnail carousel
- Category/confidence/value/rarity summary
- Collapsible or lower-priority metadata sections
- Full-screen gallery review and edit flow

Premium systems:

- Hero image fade/scale polish
- AI Enhanced badges
- Value card, rarity badge, confidence meter
- Gallery thumbnail selected state and edit persistence
- Responsive wraps for metadata and badges

### Scan

Architecture:

- Camera capture page opens directly from Scan.
- Camera page owns camera initialization and capture.
- Captured/gallery image enters review and workspace flow.
- Legacy scanner shell still owns some fallback/sample flows.

Premium systems:

- Immersive camera chrome with reduced top/bottom padding
- Enhance button pulse/glow/tap scale
- Auto-detect pill and capture suggestion bubble
- Grid overlay fade
- Scan status and action systems use motion, gradients, and responsive wrapping

### Workspace

Architecture:

- Captured photo workspace after camera/gallery review
- Active preview
- Filmstrip/photo set
- Metadata panel
- Recommended next best photo
- Analyze action

Premium systems:

- Animated filmstrip insertion
- Primary photo scale/glow
- Metadata `AnimatedSwitcher` transitions
- Recommended angle badge
- Smart Scan Guidance output replaces static instructions
- Analyzer payload uses selected enhanced image where available

### Analyze

Architecture:

- Workspace remains context layer.
- Analyze overlay blurs workspace and fades it to reduced opacity.
- Primary photo silhouette, progress ring, and haptic cue lead into result navigation.

Premium systems:

- `AnalyzeAnimation`
- Blurred background
- Centered item silhouette
- Circular progress ring with glow
- Smooth fade-out to result

### Result

Architecture:

- Summary-first result page
- Large primary image
- Item name, category, confidence, value
- One-sentence AI summary
- Add to Portfolio CTA
- Gallery filmstrip for multiple photos
- Advanced sections lower/collapsible where applicable

Premium systems:

- AI Enhanced badge
- Rarity badge
- Value card
- Confidence meter
- Metadata fade-in
- Add to Portfolio slide-up
- Gallery preview switching

### Settings

Architecture:

- Premium settings hero
- Grouped settings cards
- Auth/cloud/subscription/local actions
- About/help cards

Premium systems:

- Hero treatment aligned with motion system
- `SettingsCardGroup` with `MotionStagger`
- Modern settings rows
- User-safe status labels and local-only/cloud states

### About

Architecture:

- `AboutHeroHeader`
- App icon card
- Brand card
- Info/link tiles

Premium systems:

- Elastic/parallax/ambient hero
- Back button with tap scale and hover treatment
- Frosted surfaces
- App icon pulse
- Brand accent line reveal

### Cloud Sync

Architecture:

- `CloudSyncHeroHeader`
- Sync status card
- Metrics
- Diagnostics
- Action button
- Optional wave animation

Premium systems:

- Elastic/parallax/ambient hero
- Animated sync icon states
- Responsive metric group
- Cloud sync wave painter
- Gradient action button with hover glow

## 6. Test Coverage Summary

### Hero Tests

- Home dashboard content smoke.
- Portfolio hero uses premium motion hero system.
- Portfolio hero header checks for `MotionElasticHero`, `MotionParallax`, `MotionAmbientGradient`, global height, decorative circle, and text hierarchy.
- About and Cloud Sync routes render premium headers through route smoke tests.

### Grid Tests

- Portfolio grid renders local thumbnails and overflow actions.
- Portfolio grid premium cards fit at 320px.
- Portfolio grid falls back to gallery thumbnail image.
- Portfolio renders 500 seeded demo items without crashing.
- Home quick actions and dashboard content render.

### Badge Tests

- `PremiumBadge` uses global spacing, radius, and typography tokens.
- Portfolio grid premium badge expectations use the shared `premium-badge-*` keys.
- Scan result and capture workspace tests cover enhanced/result badge visibility through end-to-end flows.

### Responsive Tests

- Responsive smoke renders key screens on small phone and large phone.
- Portfolio detail legacy one-image layout renders without overflow.
- Scan result long title is safe on small Android width.
- Portfolio detail/gallery tests cover wrapped metadata and safe final-image handling.

### Motion Tests

- Portfolio hero motion system coverage.
- Camera/enhance tests cover pulse, glow, and tap scale behavior.
- Scan capture tests cover flash, suggestion motion, and camera overlays.
- Analyze animation tests cover blur, silhouette, progress ring, and fade behavior.

### Surface Tests

- Home unified surfaces render for Quick Actions, Portfolio Overview, Recent Activity, and AI Insights.
- Portfolio premium card tests assert thumbnail framing, value row hierarchy, menu styling, and `MotionReveal` wrappers.
- Cloud sync status widget tests cover sync status labels and failure messaging.

### Typography Tests

- Premium badge test asserts `labelSmall`-based w600 label treatment.
- Hero hierarchy tests assert headline/subtitle/caption structure in premium heroes.
- Scan/result/portfolio detail tests assert long text truncation, no overflow, and summary-first rendering.

## Current Migration Notes

- The premium system is strongest in Portfolio hero, Portfolio grid, Home surfaces, Scan Workspace, Analyze, Result, and Portfolio Detail.
- A few older local badge and gradient helpers remain in legacy widgets. New UI work should migrate those to `PremiumBadge` and `PackLoxGradients.build()`.
- Prefer shared motion widgets over ad-hoc `TweenAnimationBuilder` unless the animation is intentionally local and not reusable.
- Preserve the responsive principles: tokenized spacing, wrapped badges, flexible text, aspect-ratio imagery, and numeric-only `FittedBox`.
