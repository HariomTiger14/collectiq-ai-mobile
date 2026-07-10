# PackLox Motion System Specification

Post-premium UI foundation motion specification for PackLox. This document records the shared motion primitives, timing values, curves, parallax behavior, reveal/stagger rules, and screen-level motion patterns currently used by the Flutter app.

## 1. Motion Primitives

### MotionElasticHero

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Gives hero regions a premium elastic stretch during negative scroll/overscroll.
- Keeps hero height deterministic in widget tests.
- Designed for top-of-screen hero surfaces, not ordinary cards.

Parameters:

- `baseHeight`: required fixed resting height.
- `scrollOffset`: current scroll position.
- `maxOverscroll`: defaults to 80.
- `stretchFactor`: defaults to 0.35.

Behavior:

- If `scrollOffset < 0`, overscroll is clamped to `0..maxOverscroll`.
- Final height is `baseHeight + overscroll * stretchFactor`.
- In test mode, returns a fixed-height `SizedBox` with no elastic stretch.

### MotionParallax

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Applies scroll-driven vertical translation to hero or image content.
- Creates depth without changing layout constraints.

Parameters:

- `depth`: defaults to `PackLoxMotionTheme.heroParallaxDepth` (18).
- `maxScroll`: defaults to 160.
- `scrollOffset`: clamped into `0..maxScroll`.

Behavior:

- Progress is `scrollOffset / maxScroll`.
- Translation is `Offset(0, -depth * progress)`.
- It is deterministic and has no duration because it is scroll-position driven.

### MotionAmbientGradient

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Animates ambient hero/card gradients.
- Gives premium surfaces soft life without drawing attention away from content.

Parameters:

- `gradientBuilder`: `Gradient Function(double t)`.
- `child`: surface content.

Behavior:

- Uses an `AnimationController` with duration `PackLoxMotionTheme.waveDuration * 3`.
- Repeats while ambient motion is enabled.
- Uses `Curves.easeInOut` on controller value before building the gradient.
- In test mode, returns `child` directly.

### MotionReveal

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Standard entry animation for cards, rows, thumbnails, and grouped content.
- Combines opacity reveal with vertical translation.

Parameters:

- `offset`: defaults to 14.
- `duration`: defaults to `PackLoxMotionTheme.medium` (220ms).
- `curve`: defaults to `PackLoxMotionTheme.revealCurve` (`Curves.easeOutCubic`).
- `delay`: defaults to zero.

Behavior:

- Tween value runs from 0 to 1 over `duration + delay`.
- Active reveal progress starts after delay.
- Opacity equals active progress.
- Translate offset equals `offset * (1 - active)`.
- In test mode, returns `child` directly.

### MotionStagger

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Sequences multiple `MotionReveal` children.
- Used for quick actions, grouped cards, lists, and scanner/result sections.

Behavior:

- Wraps each child in `MotionReveal`.
- Delay is `PackLoxMotionTheme.revealStagger * index`.
- Global token is currently 60ms.
- Portfolio grid entry polish also uses local 40ms-style stagger where tile index is available.

### MotionTapScale

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Shared tactile press response.
- Used for action tiles, rows, cloud sync buttons, item actions, and navigation affordances.

Defaults:

- Scale: `PackLoxMotionTheme.tapScale` (0.96)
- Duration: `PackLoxMotionTheme.fast` (120ms)
- Curve: `PackLoxMotionTheme.tapCurve` (`Curves.easeOutCubic`)

Behavior:

- Sets pressed state on tap down.
- Restores on tap cancel/up.
- Calls `onTap` on tap up.

### MotionHoverGlow

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Optional desktop/web hover glow wrapper.
- Provides consistent hover depth around cards and buttons.

Defaults:

- Opacity: `PackLoxMotionTheme.hoverOpacity` (0.08)
- Blur radius: `PackLoxMotionTheme.hoverBlurRadius` (14)
- Offset: `Offset(0, 10)`
- Duration: `PackLoxMotionTheme.medium` (220ms)
- Curve: `PackLoxMotionTheme.hoverCurve` (`Curves.easeOutQuad`)

### MotionPulse

Location: `lib/core/ui/motion/motion_widgets.dart`

Purpose:

- Repeating pulse for icon halos, brand emphasis, and active premium affordances.

Defaults:

- Scale: `1.0..1.06`
- Opacity: `0.72..1.0`
- Duration: `PackLoxMotionTheme.pulseDuration` (1800ms)
- Curve transform: `PackLoxMotionTheme.transitionCurve`

Behavior:

- Repeats forward/reverse when ambient motion is enabled.
- Holds midpoint in reduced/test motion.

### AnimatedGlow: AI Insights

Location: `lib/features/home/presentation/home_screen.dart`

Purpose:

- Gives the Home AI Insights card a distinct premium identity.

Behavior:

- Uses `TweenAnimationBuilder<double>` from 0.72 to 1.0.
- Duration: 900ms.
- Curve: `Curves.easeOutCubic`.
- Drives violet gradient alpha and shadow alpha.
- AI Insights icon uses `AnimatedScale` for a 150ms press response.

### ScanWaveAnimation

Location: `lib/core/ui/scan/scan_ui.dart`

Purpose:

- Ambient scanner wave and scan-line motion for scanner surfaces.

Behavior:

- Uses an `AnimationController` with duration `PackLoxMotionTheme.waveDuration * 3`.
- Repeats when scan motion is enabled.
- Custom painter draws layered horizontal waves.
- `ScanPreviewFrame` can also draw scan-line waves while analyzing.

### AnalyzeAnimationOverlay

Location: `lib/features/scanner/presentation/widgets/analyze_animation.dart`

Purpose:

- Premium transition from Workspace to Result.

Behavior:

- Blurs workspace with `ImageFilter.blur(sigmaX: 24, sigmaY: 24)`.
- Adds black overlay at 0.18 alpha.
- Shows primary image silhouette at 30% opacity.
- Silhouette scales from 0.9 to 1.0 in the first 12.5% of a 1200ms controller.
- Progress ring animates across the full 1200ms with `Curves.easeOut`.
- Ring glow uses stroke blur radius 12.

### ConfidenceMeterAnimation

Locations:

- `lib/features/scanner/presentation/pages/scan_result_screen.dart`
- `lib/features/portfolio/presentation/pages/collectible_detail_page.dart`

Purpose:

- Shows confidence as a stable horizontal meter.

Current behavior:

- Scan result confidence meter uses `LinearProgressIndicator` with immediate value and metadata fade-in.
- Portfolio detail confidence meter uses `TweenAnimationBuilder<double>` over 200ms.
- Meter colors shift by confidence band in Portfolio Detail:
  - High: green/success
  - Medium: yellow/amber
  - Low: red/error

## 2. Timing Curves And Durations

### Global Curves

Defined in `PackLoxMotionTheme`.

- Default interaction curve: `Curves.easeOutCubic`
- Tap-scale curve: `Curves.easeOutCubic`
- Reveal curve: `Curves.easeOutCubic`
- Stagger curve: `Curves.easeOutCubic` through `MotionReveal`
- Transition/pulse curve: `Curves.easeInOutCubic`
- Hover curve: `Curves.easeOutQuad`
- Navigation state curve: `Curves.easeOutCubic`
- Navigation spring curve: `Curves.easeOutBack`
- Ambient gradient curve: local `Curves.easeInOut`
- Analyze progress curve: local `Curves.easeOut`

### Global Durations

Defined in `PackLoxMotionTheme`.

- `fast`: 120ms
- `medium`: 220ms
- `slow`: 320ms
- `navSpringDuration`: 260ms
- `revealStagger`: 60ms
- `pulseDuration`: 1800ms
- `waveDuration`: 2600ms

### Product-Specific Durations

- Hero elasticity: scroll-driven, no time duration.
- Parallax: scroll-driven, no time duration.
- Reveal duration: 220ms by default.
- Stagger interval: 60ms globally; local grid/tile polish may use 40ms when index-based tile reveal is required.
- Tap-scale duration: 120ms globally; local camera/enhance/home press treatments use 150 to 160ms.
- Glow pulse duration: 1800ms globally; Enhance button uses a slower 3000ms pulse.
- Scan wave duration: 7800ms (`waveDuration * 3`).
- Analyze animation: 1200ms.
- Result metadata fade-in: 150ms with 0/30/60/90ms local delays.
- Result Add to Portfolio slide/opacity: 200ms.
- Portfolio detail metadata fade: 150ms in, 100ms out where `AnimatedSwitcher` is used.
- Confidence meter fill: 200ms in Portfolio Detail.

## 3. Motion Tokens

Current concrete implementation is `PackLoxMotionTheme`. The following semantic token mapping should be used in specs and future migrations.

### MotionDuration

- `MotionDuration.short`: 120ms, maps to `PackLoxMotionTheme.fast`
- `MotionDuration.medium`: 220ms, maps to `PackLoxMotionTheme.medium`
- `MotionDuration.long`: 320ms, maps to `PackLoxMotionTheme.slow`
- `MotionDuration.stagger`: 40 to 60ms, use 60ms globally and 40ms for dense grid tiles
- `MotionDuration.pulse`: 1800ms
- `MotionDuration.wave`: 2600ms base, 7800ms ambient cycle
- `MotionDuration.analyze`: 1200ms

### MotionCurve

- `MotionCurve.default`: `Curves.easeOutCubic`
- `MotionCurve.elastic`: scroll-driven elasticity; use `Curves.easeOutBack` only for explicit spring/nav transitions
- `MotionCurve.reveal`: `Curves.easeOutCubic`
- `MotionCurve.stagger`: `Curves.easeOutCubic`
- `MotionCurve.parallax`: scroll-position linear mapping
- `MotionCurve.transition`: `Curves.easeInOutCubic`
- `MotionCurve.hover`: `Curves.easeOutQuad`
- `MotionCurve.glowPulse`: `Curves.easeInOutCubic`

## 4. Parallax And Elasticity Rules

### Parallax Depth Values

- Hero parallax depth: 18.
- Card parallax depth: 6.
- Scan preview frame local depth: 10.
- Item detail hero local depth: `heroParallaxDepth * 1.6` (28.8).
- Default max scroll normalization: 160.

Rules:

- Hero copy and hero imagery may use parallax.
- Dense form controls and interactive content should not parallax.
- Parallax must not change layout size; use transform only.
- Depth should stay subtle enough that text remains readable during scroll.

### Hero Elasticity

Defaults:

- Max overscroll: 80.
- Stretch factor: 0.35.
- Maximum added height at default settings: 28.

Rules:

- Use only for full-width hero regions.
- Pair with a stable `baseHeight`.
- Disable/flatten in tests through `PackLoxMotionTheme.isTestMode`.
- Avoid elastic stretch on cards, grids, and rows.

### Ambient Gradient Motion

Defaults:

- Controller duration: `waveDuration * 3` (7800ms).
- Interpolation input: `Curves.easeInOut`.
- Blue/indigo and purple/deep-blue ambient gradients are provided by `PackLoxMotionTheme`.

Rules:

- Use for hero surfaces and a small number of premium status cards.
- Do not use on every card; preserve visual calm.
- Ambient motion must be disabled/simplified in tests.

### Decorative Circle Motion Rules

- Decorative circles should live inside hero stacks or `HeroSurfaceContainerHighest.decorativeChildren`.
- Circles may shift subtly with parallax if already controlled by scroll.
- Decorative circles should not animate independently unless part of a larger hero ambient treatment.
- Opacity should remain low, usually 0.08 to 0.18.

## 5. Reveal And Stagger Rules

### Reveal Threshold

Current `MotionReveal` is mount-based, not viewport-threshold based.

Rules:

- Use reveal on newly mounted cards, thumbnails, and grouped content.
- Do not reveal content that appears as the result of tiny state changes unless it would clarify the transition.
- Avoid nested reveal wrappers that compound opacity or translation.

### Reveal Opacity Curve

- Opacity follows active reveal progress from 0 to 1.
- Active progress is delayed by `delay`.
- Translation starts at `offset` and resolves to zero.
- Default offset is 14.

### Stagger Sequencing

Global pattern:

- `MotionStagger` applies `delay = revealStagger * index`.
- Current global interval is 60ms.

Dense grid pattern:

- Portfolio/grid tile entry may use index-based 40ms delay for snappier dense grids.
- Cap perceived delay for very long lists; do not make item 40 wait dramatically longer than item 4.

### Grid/List Stagger Patterns

- Quick action grids: group-level `MotionStagger`.
- Portfolio lists: item-level `MotionStagger`.
- Portfolio grid thumbnails: local `MotionReveal` for thumbnail framing.
- Scanner result sections: short local fade delays of 30ms increments.
- Advanced sections: reveal only the containing section, not every row.

## 6. Screen-By-Screen Motion Summary

### Home

- Hero uses `MotionElasticHero` and `MotionParallax`.
- Quick Actions use `MotionStagger`.
- Section headers use `MotionReveal`.
- AI Insights uses animated glow over 900ms and icon press scale over 150ms.
- Recent Activity uses compact row hierarchy with motion-light presentation.

### Portfolio

- Hero uses `MotionElasticHero`, `MotionParallax`, and `MotionAmbientGradient`.
- Hero surface uses `HeroSurfaceContainerHighest` and decorative circle.
- Portfolio grid/list entries use `MotionStagger`/`MotionReveal`.
- Grid thumbnail frame uses `MotionReveal`.
- Overflow menu uses Material menu elevation/shadow rather than custom motion.

### Portfolio Detail

- Hero image uses elastic/parallax in the shared item UI and local fade/scale polish on updated gallery images.
- Thumbnail carousel uses 150ms refresh/selection motion.
- Metadata and hero updates use 150ms fade transitions.
- Confidence meter fill animates over 200ms.
- Full-screen carousel navigation uses page/swipe motion from Flutter page view patterns.

### Scan

- Scan hero uses `MotionAmbientGradient` and `MotionReveal`.
- Camera overlay grid uses fade animation.
- Enhance button uses 3000ms glow pulse and 150ms tap scale.
- Capture suggestion bubble uses short fade and slight upward motion.
- Scan wave animation uses `waveDuration * 3`.

### Workspace

- Workspace fades to 40% opacity during analyze state over 150ms.
- Analyze overlay enters via 180ms opacity animation.
- Metadata updates use 150ms switch/fade patterns.
- Filmstrip selection uses 150ms scale/container changes.
- Primary photo highlight uses selected scale and shadow/glow changes.

### Analyze

- Analyze overlay blurs workspace at 24px.
- Primary image silhouette appears at 30% opacity.
- Silhouette scale runs 0.9 to 1.0 in 150ms.
- Progress ring runs over 1200ms with ease-out curve.
- Overlay fades out when analysis completes.

### Result

- Metadata fades in over 150ms.
- Metadata sequence uses 0, 30, 60, and 90ms delays.
- Add to Portfolio button slides up and fades in over 200ms.
- Confidence meter is stable on scan result; portfolio detail meter animates fill over 200ms.
- Image hero uses shadow and badge presence rather than continuous motion.

### Settings

- Settings hero uses elastic/ambient treatment.
- Settings groups use `MotionStagger`.
- Rows use modern interaction states and safe local status transitions.
- Buttons follow global tap and Material theme timing.

### Cloud Sync

- Hero uses `MotionElasticHero`, `MotionParallax`, and `MotionAmbientGradient`.
- Sync status icon rotates while syncing.
- Synced state can pulse.
- Cloud sync wave painter runs on `waveDuration * 3`.
- Action button uses `MotionTapScale` plus hover glow/gradient shadow.

### About

- Hero uses `MotionElasticHero`, `MotionParallax`, and `MotionAmbientGradient`.
- Back button uses `MotionTapScale` and 120ms hover transition.
- App icon card uses `MotionPulse`.
- Brand card accent line reveals over local 1100ms controller.
- Info/link tiles use tap scale and 220ms hover containers.

## 7. Test Coverage

### Motion Wrapper Presence Tests

- Portfolio hero test asserts `MotionElasticHero`, `MotionParallax`, and `MotionAmbientGradient`.
- Portfolio grid tests assert `MotionReveal` around premium grid content.
- Home and route smoke tests verify motion-wrapped screens mount without layout failure.

### Reveal And Stagger Tests

- Portfolio grid premium tests cover thumbnail reveal wrappers.
- Home quick action and dashboard tests exercise `MotionStagger` paths.
- Scanner result tests exercise fade-in metadata sections through rendered result content.

### Hero Motion Tests

- Portfolio hero premium system test validates hero height, motion wrappers, decorative circle, and text hierarchy.
- Responsive smoke tests cover hero mounting at small and large phone sizes.

### Parallax Tests

- Motion wrapper presence tests cover parallax inclusion.
- Scroll-driven transform math is currently covered indirectly by widget construction rather than isolated unit tests.

### Tap-Scale Tests

- Enhance button tests verify pulse, glow, and tap-scale animation keys.
- Camera/scan tests exercise capture and enhancement button interaction.
- Item/action row tests indirectly exercise `MotionTapScale` through tap flows.

### Analyze Motion Tests

- Analyze animation tests cover blur overlay, silhouette, progress ring, and fade-out behavior.
- Workspace to result tests verify analyze transition remains connected to result rendering.

### Confidence Motion Tests

- Result tests assert confidence meter presence.
- Portfolio detail tests assert premium summary and confidence metadata rendering.
- Portfolio detail confidence fill animation is currently covered through widget presence and rendered value rather than precise frame-by-frame interpolation.

## Current Notes

- The global motion implementation lives in `PackLoxMotionTheme` and `motion_widgets.dart`; there are no separate `MotionDuration` or `MotionCurve` classes yet.
- Use the semantic token names in this spec for new designs, but map them to `PackLoxMotionTheme` until dedicated token classes are introduced.
- Prefer shared primitives over ad-hoc animation wrappers.
- Keep motion subtle, short, and purposeful; PackLox should feel premium and responsive rather than playful or noisy.
