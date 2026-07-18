import 'dart:async';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_entry_tile.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_backend_contract_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class AuthRouteNames {
  static const welcome = 'auth/welcome';
  static const createAccountEmail = 'auth/create-account/email';
  static const verifyEmail = 'auth/create-account/verify-email';
  static const createPassword = 'auth/create-account/create-password';
  static const signIn = 'auth/sign-in';
  static const forgotPasswordEmail = 'auth/forgot-password/email';
  static const guestHome = 'app/guest-home';
}

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({this.onExploreAsGuest, super.key});

  final VoidCallback? onExploreAsGuest;

  static Route<void> route({VoidCallback? onExploreAsGuest}) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: AuthRouteNames.welcome),
      builder: (_) => AuthWelcomeScreen(onExploreAsGuest: onExploreAsGuest),
    );
  }

  void _openCreateAccount(BuildContext context) {
    Navigator.of(context).push(AuthSignUpScreen.route());
  }

  void _openSignIn(BuildContext context) {
    Navigator.of(context).push(AuthSignInScreen.route());
  }

  void _exploreAsGuest(BuildContext context) {
    final handler = onExploreAsGuest;
    if (handler != null) {
      handler();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundTop = Color(0xFF050816);
    const backgroundMid = Color(0xFF0A1022);
    const backgroundBottom = Color(0xFF070A12);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundBottom,
        systemNavigationBarDividerColor: backgroundBottom,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const ValueKey('auth-welcome-screen'),
        backgroundColor: backgroundBottom,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .42, 1],
              colors: [backgroundTop, backgroundMid, backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 760;
                final heroHeight = compactHeight ? 224.0 : 286.0;
                final topGap = compactHeight ? 18.0 : 28.0;
                final heroGap = compactHeight ? 12.0 : 20.0;
                final actionGap = compactHeight ? 14.0 : 20.0;

                return SingleChildScrollView(
                  key: const ValueKey('auth-welcome-scroll-view'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    topGap,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight:
                            constraints.maxHeight - topGap - AppSpacing.lg,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _AuthWelcomeBrandLockup(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Identify. Value. Protect.',
                              key: const ValueKey('auth-welcome-tagline'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: PackLoxTokens.textPrimary.withValues(
                                  alpha: .84,
                                ),
                                fontSize: compactHeight ? 15 : 16,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: heroGap),
                            SizedBox(
                              key: const ValueKey('auth-welcome-hero'),
                              height: heroHeight,
                              child: const _PremiumCollectibleHero(),
                            ),
                            SizedBox(height: actionGap),
                            _GradientAuthButton(
                              key: const ValueKey(
                                'auth-welcome-create-account',
                              ),
                              label: 'Create Account',
                              semanticLabel: 'Create Account',
                              onPressed: () => _openCreateAccount(context),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _OutlineAuthButton(
                              key: const ValueKey('auth-welcome-sign-in'),
                              label: 'Sign In',
                              semanticLabel: 'Sign In',
                              onPressed: () => _openSignIn(context),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _QuietAuthAction(
                              key: const ValueKey('auth-welcome-explore-guest'),
                              label: 'Explore as Guest',
                              semanticLabel: 'Explore as Guest',
                              onPressed: () => _exploreAsGuest(context),
                            ),
                            const Spacer(),
                            const SizedBox(height: AppSpacing.lg),
                            const Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.xl),
                              child: _AuthWelcomeLegalCopy(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthWelcomeBrandLockup extends StatelessWidget {
  const _AuthWelcomeBrandLockup();

  static const _brandV2EmblemPath =
      'assets/packlox/brand/packlox_brand_v2_emblem_authority_v0_7.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'PackLox Brand v2 emblem and wordmark',
      child: Column(
        children: [
          SizedBox.square(
            key: const ValueKey('auth-welcome-brand-emblem'),
            dimension: 88,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                _brandV2EmblemPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(painter: _BrandV2EmblemPainter());
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(
                  text: 'Pack',
                  style: TextStyle(color: PackLoxTokens.textPrimary),
                ),
                TextSpan(
                  text: 'Lox',
                  style: TextStyle(color: Color(0xFF6FD3FF)),
                ),
              ],
            ),
            key: const ValueKey('auth-welcome-wordmark'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandV2EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final glowPaint = Paint()
      ..color = const Color(0xFF5E5CE6).withValues(alpha: .22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(rect.deflate(size.width * .08), glowPaint);

    final markRect = Rect.fromCenter(
      center: rect.center,
      width: size.width * .58,
      height: size.height * .72,
    );
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF58E2FF), Color(0xFF0A84FF), Color(0xFF7C3AED)],
    ).createShader(markRect);

    final path = Path()
      ..moveTo(markRect.left + markRect.width * .10, markRect.bottom)
      ..lineTo(markRect.left + markRect.width * .10, markRect.top)
      ..lineTo(markRect.left + markRect.width * .58, markRect.top)
      ..cubicTo(
        markRect.right,
        markRect.top,
        markRect.right,
        markRect.top + markRect.height * .52,
        markRect.left + markRect.width * .60,
        markRect.top + markRect.height * .52,
      )
      ..lineTo(
        markRect.left + markRect.width * .38,
        markRect.top + markRect.height * .52,
      )
      ..lineTo(markRect.left + markRect.width * .38, markRect.bottom)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill,
    );

    final cutout = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        markRect.left + markRect.width * .36,
        markRect.top + markRect.height * .17,
        markRect.width * .34,
        markRect.height * .22,
      ),
      Radius.circular(markRect.width * .11),
    );
    canvas.drawRRect(
      cutout,
      Paint()..color = const Color(0xFF071024).withValues(alpha: .94),
    );

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(markRect.left + markRect.width * .20, markRect.top + 4),
      Offset(markRect.left + markRect.width * .46, markRect.top + 4),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PremiumCollectibleHero extends StatelessWidget {
  const _PremiumCollectibleHero();

  static const _assetPath =
      'assets/packlox/s01_hero_premium_collectibles_v0_7.png';

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        image: true,
        label:
            'Premium acrylic collectible slab with supporting collector car and coin.',
        child: Image.asset(
          _assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              painter: _PremiumCollectibleHeroPainter(),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _PremiumCollectibleHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scene = Offset.zero & size;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .50, h * .53),
        width: w * .92,
        height: h * .82,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF225DFF).withValues(alpha: .26),
            const Color(0xFF5E5CE6).withValues(alpha: .12),
            Colors.transparent,
          ],
        ).createShader(scene),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .50, h * .92),
        width: w * .64,
        height: h * .10,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF68DFFF).withValues(alpha: .20),
            const Color(0xFF7C3AED).withValues(alpha: .14),
            Colors.transparent,
          ],
        ).createShader(scene)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .50, h * .86),
        width: w * .70,
        height: h * .16,
      ),
      Paint()
        ..color = const Color(0xFF5E5CE6).withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    _drawRearCoin(canvas, size);
    _drawRearCar(canvas, size);
    _drawCentralSlab(canvas, size);
  }

  void _drawRearCoin(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * .73, h * .48);
    final radius = w * .15;
    final coinRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5BFF), Color(0xFF6D48E7), Color(0xFF121A3F)],
        ).createShader(coinRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );
    canvas.drawCircle(
      center,
      radius * .93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color(0xFF83E7FF).withValues(alpha: .36),
    );
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .18),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .48),
      -1.8,
      2.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .16),
    );
    canvas.drawLine(
      Offset(center.dx - radius * .45, center.dy - radius * .50),
      Offset(center.dx + radius * .28, center.dy + radius * .42),
      Paint()
        ..color = Colors.white.withValues(alpha: .13)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawRearCar(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.translate(w * .26, h * .55);
    canvas.rotate(-.10);

    final bodyPath = Path()
      ..moveTo(-w * .22, h * .02)
      ..cubicTo(-w * .17, -h * .05, -w * .10, -h * .09, -w * .02, -h * .09)
      ..lineTo(w * .12, -h * .08)
      ..cubicTo(w * .18, -h * .07, w * .23, -h * .02, w * .26, h * .04)
      ..lineTo(w * .24, h * .075)
      ..lineTo(-w * .24, h * .075)
      ..cubicTo(-w * .27, h * .06, -w * .27, h * .035, -w * .22, h * .02)
      ..close();
    final bodyBounds = bodyPath.getBounds();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C1733),
            Color(0xFF174CC6),
            Color(0xFF2C2D91),
            Color(0xFF0A1025),
          ],
        ).createShader(bodyBounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF77DFFF).withValues(alpha: .25),
    );

    final cabin = Path()
      ..moveTo(-w * .075, -h * .080)
      ..lineTo(w * .02, -h * .135)
      ..lineTo(w * .13, -h * .080)
      ..lineTo(w * .09, -h * .03)
      ..lineTo(-w * .11, -h * .032)
      ..close();
    canvas.drawPath(
      cabin,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .22),
            const Color(0xFF5E5CE6).withValues(alpha: .10),
          ],
        ).createShader(cabin.getBounds()),
    );
    final wheelPaint = Paint()..color = const Color(0xFF080D1D);
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF73E5FF).withValues(alpha: .25);
    canvas
      ..drawCircle(Offset(-w * .13, h * .067), w * .040, wheelPaint)
      ..drawCircle(Offset(w * .15, h * .067), w * .040, wheelPaint)
      ..drawCircle(Offset(-w * .13, h * .067), w * .025, rimPaint)
      ..drawCircle(Offset(w * .15, h * .067), w * .025, rimPaint)
      ..drawLine(
        Offset(w * .18, h * .006),
        Offset(w * .24, h * .016),
        Paint()
          ..color = const Color(0xFF9FEAFF).withValues(alpha: .30)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    canvas.restore();
  }

  void _drawCentralSlab(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final slabRect = Rect.fromCenter(
      center: Offset(w * .50, h * .47),
      width: w * .38,
      height: h * .70,
    );
    final slabRadius = Radius.circular(slabRect.width * .12);
    final slab = RRect.fromRectAndRadius(slabRect, slabRadius);

    canvas.drawRRect(
      slab.shift(Offset(0, h * .012)),
      Paint()
        ..color = Colors.black.withValues(alpha: .30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawRRect(
      slab.inflate(7),
      Paint()
        ..color = const Color(0xFF5E5CE6).withValues(alpha: .15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawRRect(
      slab,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .24),
            const Color(0xFF0A84FF).withValues(alpha: .10),
            Colors.white.withValues(alpha: .08),
          ],
        ).createShader(slabRect),
    );
    canvas.drawRRect(
      slab.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = const LinearGradient(
          colors: [Color(0xFF7ADFFF), Color(0xFF5E5CE6)],
        ).createShader(slabRect),
    );
    canvas.drawRRect(
      slab.deflate(8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .11),
    );

    final cardRect = Rect.fromLTWH(
      slabRect.left + slabRect.width * .13,
      slabRect.top + slabRect.height * .22,
      slabRect.width * .74,
      slabRect.height * .64,
    );
    final card = RRect.fromRectAndRadius(
      cardRect,
      Radius.circular(cardRect.width * .06),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1630), Color(0xFF193FA4), Color(0xFF2A155D)],
        ).createShader(cardRect),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .10),
    );

    final artRect = cardRect.deflate(cardRect.width * .09);
    final collectibleShape = Path()
      ..moveTo(
        artRect.left + artRect.width * .18,
        artRect.top + artRect.height * .34,
      )
      ..cubicTo(
        artRect.left + artRect.width * .25,
        artRect.top + artRect.height * .08,
        artRect.left + artRect.width * .75,
        artRect.top + artRect.height * .10,
        artRect.left + artRect.width * .82,
        artRect.top + artRect.height * .34,
      )
      ..cubicTo(
        artRect.left + artRect.width * .86,
        artRect.top + artRect.height * .58,
        artRect.left + artRect.width * .30,
        artRect.top + artRect.height * .62,
        artRect.left + artRect.width * .18,
        artRect.top + artRect.height * .34,
      )
      ..close();
    canvas.drawPath(
      collectibleShape,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6EE7FF), Color(0xFF0A84FF), Color(0xFF7C3AED)],
        ).createShader(artRect),
    );
    canvas.drawPath(
      collectibleShape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: .18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          artRect.left,
          artRect.bottom - artRect.height * .24,
          artRect.width,
          artRect.height * .06,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: .18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          artRect.left + artRect.width * .13,
          artRect.bottom - artRect.height * .14,
          artRect.width * .74,
          artRect.height * .045,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF6FD3FF).withValues(alpha: .16),
    );

    canvas.drawLine(
      Offset(slabRect.left + slabRect.width * .18, slabRect.top + h * .05),
      Offset(slabRect.right - slabRect.width * .18, slabRect.top + h * .05),
      Paint()
        ..color = Colors.white.withValues(alpha: .20)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(slabRect.left + slabRect.width * .20, slabRect.top + h * .08),
      Offset(slabRect.right - slabRect.width * .20, slabRect.top + h * .08),
      Paint()
        ..color = const Color(0xFF6FD3FF).withValues(alpha: .22)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(slabRect.left + slabRect.width * .18, slabRect.top + h * .15),
      Offset(slabRect.right - slabRect.width * .09, slabRect.bottom - h * .09),
      Paint()
        ..color = Colors.white.withValues(alpha: .13)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    for (final corner in [
      Offset(
        slabRect.left + slabRect.width * .16,
        slabRect.top + slabRect.height * .10,
      ),
      Offset(
        slabRect.right - slabRect.width * .16,
        slabRect.top + slabRect.height * .10,
      ),
      Offset(
        slabRect.left + slabRect.width * .16,
        slabRect.bottom - slabRect.height * .08,
      ),
      Offset(
        slabRect.right - slabRect.width * .16,
        slabRect.bottom - slabRect.height * .08,
      ),
    ]) {
      canvas.drawCircle(
        corner,
        2.4,
        Paint()..color = Colors.white.withValues(alpha: .18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GradientAuthButton extends StatelessWidget {
  const _GradientAuthButton({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? AppGradients.primary
              : LinearGradient(
                  colors: [
                    PackLoxTokens.surfaceRaised.withValues(alpha: .92),
                    PackLoxTokens.surfaceRaised.withValues(alpha: .74),
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled
                ? Colors.transparent
                : Colors.white.withValues(alpha: .10),
          ),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: const Color(0xFF0A84FF).withValues(alpha: .30),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
          ],
        ),
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: enabled
                ? PackLoxTokens.textPrimary
                : const Color(0xFF93A4BC),
            disabledForegroundColor: const Color(0xFF93A4BC),
            minimumSize: const Size.fromHeight(58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(label, overflow: TextOverflow.visible)),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineAuthButton extends StatelessWidget {
  const _OutlineAuthButton({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: PackLoxTokens.textPrimary,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(
            color: Colors.white.withValues(alpha: .30),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _QuietAuthAction extends StatelessWidget {
  const _QuietAuthAction({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF9CCBFF),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AuthWelcomeLegalCopy extends StatelessWidget {
  const _AuthWelcomeLegalCopy();

  void _showPlaceholder(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is not configured yet.')));
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      color: Color(0xFFB6C3D7),
      fontSize: 12.5,
      height: 1.35,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    const linkStyle = TextStyle(
      color: Color(0xFF8DD9FF),
      fontSize: 12.5,
      height: 1.35,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );

    return Semantics(
      container: true,
      label:
          'By continuing, you agree to our Terms of Service and Privacy Policy.',
      child: Wrap(
        key: const ValueKey('auth-welcome-legal-copy'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('By continuing, you agree to our ', style: baseStyle),
          _InlineLegalLink(
            label: 'Terms of Service',
            style: linkStyle,
            onPressed: () => _showPlaceholder(context, 'Terms of Service'),
          ),
          const Text(' and ', style: baseStyle),
          _InlineLegalLink(
            label: 'Privacy Policy',
            style: linkStyle,
            onPressed: () => _showPlaceholder(context, 'Privacy Policy'),
          ),
          const Text('.', style: baseStyle),
        ],
      ),
    );
  }
}

class _AuthLegalConsentCopy extends StatelessWidget {
  const _AuthLegalConsentCopy();

  void _showPlaceholder(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is not configured yet.')));
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      color: Color(0xFFB6C3D7),
      fontSize: 12.5,
      height: 1.35,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    const linkStyle = TextStyle(
      color: Color(0xFF8DD9FF),
      fontSize: 12.5,
      height: 1.35,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );

    return Semantics(
      container: true,
      label:
          'By continuing, you agree to our Terms of Service and Privacy Policy.',
      child: Wrap(
        key: const ValueKey('auth-create-account-legal-copy'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('By continuing, you agree to our ', style: baseStyle),
          _InlineLegalLink(
            label: 'Terms of Service',
            style: linkStyle,
            onPressed: () => _showPlaceholder(context, 'Terms of Service'),
          ),
          const Text(' and ', style: baseStyle),
          _InlineLegalLink(
            label: 'Privacy Policy',
            style: linkStyle,
            onPressed: () => _showPlaceholder(context, 'Privacy Policy'),
          ),
          const Text('.', style: baseStyle),
        ],
      ),
    );
  }
}

class _InlineLegalLink extends StatelessWidget {
  const _InlineLegalLink({
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: style.color,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.only(left: 4),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          textStyle: style,
        ),
        child: Text(label),
      ),
    );
  }
}

class AuthSignInScreen extends ConsumerStatefulWidget {
  const AuthSignInScreen({this.initialEmail, super.key});

  final String? initialEmail;

  static Route<void> route({String? initialEmail}) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: AuthRouteNames.signIn,
        arguments: {'initialEmail': initialEmail},
      ),
      builder: (_) => AuthSignInScreen(initialEmail: initialEmail),
    );
  }

  @override
  ConsumerState<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends ConsumerState<AuthSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;
  var _submitted = false;
  var _isSubmitting = false;
  String? _formError;

  static const _googleProviderEnabled = false;
  static const _appleProviderEnabled = false;

  bool get _hasEnabledProviders =>
      _googleProviderEnabled || _appleProviderEnabled;

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.initialEmail?.trim();
    if (initialEmail != null && initialEmail.isNotEmpty) {
      _emailController.text = initialEmail;
    }
    _emailController.addListener(_handleFieldChanged);
    _passwordController.addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleFieldChanged);
    _passwordController.removeListener(_handleFieldChanged);
    _emailController.dispose();
    _passwordController.clear();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    setState(() {
      _formError = null;
    });
  }

  bool get _canSignIn =>
      _validateSignInEmail(_emailController.text) == null &&
      _passwordController.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _formError = null;
    });
    if (!_canSignIn || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    await ref
        .read(authBackendContractControllerProvider.notifier)
        .signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    final backendState = ref.read(authBackendContractControllerProvider);
    final signedInUser = backendState.user;
    if (backendState.status == AuthBackendContractStatus.signedIn &&
        signedInUser != null &&
        backendState.isSignedIn) {
      ref.read(authControllerProvider.notifier).applySignedInUser(signedInUser);
      setState(() => _isSubmitting = false);
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _formError =
          backendState.failure?.safeMessage ??
          backendState.infoMessage ??
          'Email or password is not correct.';
    });
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      AuthForgotPasswordScreen.route(
        initialEmail: _emailController.text.trim(),
      ),
    );
  }

  void _openCreateAccount() {
    Navigator.of(context).push(AuthSignUpScreen.route());
  }

  void _showProviderUnavailable(BuildContext context, String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$provider sign-in is not enabled in this build.'),
        ),
      );
  }

  String? get _emailError {
    if (!_submitted) return null;
    return _validateSignInEmail(_emailController.text);
  }

  String? get _passwordError {
    if (!_submitted) return null;
    if (_passwordController.text.isEmpty) {
      return 'Enter your password.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const backgroundTop = Color(0xFF050816);
    const backgroundMid = Color(0xFF0A1022);
    const backgroundBottom = Color(0xFF070A12);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundBottom,
        systemNavigationBarDividerColor: backgroundBottom,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const ValueKey('auth-sign-in-screen'),
        backgroundColor: backgroundBottom,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .42, 1],
              colors: [backgroundTop, backgroundMid, backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.viewInsetsOf(context);
                final compactHeight =
                    constraints.maxHeight < 760 || viewInsets.bottom > 0;
                final topGap = compactHeight ? AppSpacing.lg : AppSpacing.xl;
                final titleGap = compactHeight ? AppSpacing.xl : 34.0;
                final canSubmit = _canSignIn && !_isSubmitting;

                return SingleChildScrollView(
                  key: const ValueKey('auth-sign-in-scroll-view'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    topGap,
                    AppSpacing.xl,
                    AppSpacing.lg + viewInsets.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight:
                            constraints.maxHeight - topGap - AppSpacing.lg,
                      ),
                      child: IntrinsicHeight(
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthCompactBrandLockup(
                                keyPrefix: 'auth-sign-in',
                                emblemSize: compactHeight ? 54 : 62,
                              ),
                              SizedBox(height: titleGap),
                              const Text(
                                'Welcome back',
                                key: ValueKey('auth-sign-in-title'),
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: PackLoxTokens.textPrimary,
                                  fontSize: 30,
                                  height: 1.12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Sign in to continue protecting your collection.',
                                key: const ValueKey(
                                  'auth-sign-in-supporting-copy',
                                ),
                                style: TextStyle(
                                  color: PackLoxTokens.textSecondary.withValues(
                                    alpha: .94,
                                  ),
                                  fontSize: 15,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              AuthTextField(
                                key: const ValueKey('auth-sign-in-email-field'),
                                controller: _emailController,
                                label: 'Email address',
                                hint: 'you@example.com',
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                errorText: _emailError,
                                onSubmitted: (_) {
                                  if (canSubmit) {
                                    unawaited(_submit());
                                  } else {
                                    setState(() => _submitted = true);
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AuthTextField(
                                key: const ValueKey(
                                  'auth-sign-in-password-field',
                                ),
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Your password',
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                errorText: _passwordError,
                                suffixIcon: IconButton(
                                  key: const ValueKey(
                                    'auth-sign-in-password-visibility',
                                  ),
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  }),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                                onSubmitted: (_) {
                                  if (canSubmit) {
                                    unawaited(_submit());
                                  } else {
                                    setState(() => _submitted = true);
                                  }
                                },
                              ),
                              AuthMessage(errorMessage: _formError),
                              const SizedBox(height: AppSpacing.lg),
                              _GradientAuthButton(
                                key: const ValueKey('auth-sign-in-submit'),
                                label: _isSubmitting ? 'Signing In' : 'Sign In',
                                semanticLabel: _isSubmitting
                                    ? 'Signing In'
                                    : 'Sign In',
                                onPressed: canSubmit ? _submit : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  key: const ValueKey(
                                    'auth-forgot-password-link',
                                  ),
                                  onPressed: _openForgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        PackLoxTokens.textSecondary,
                                    minimumSize: const Size(48, 48),
                                    tapTargetSize: MaterialTapTargetSize.padded,
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _CreateAccountBridge(
                                onPressed: _openCreateAccount,
                              ),
                              if (_hasEnabledProviders) ...[
                                const SizedBox(height: AppSpacing.xl),
                                _AuthSignInSocialProviderBlock(
                                  googleEnabled: _googleProviderEnabled,
                                  appleEnabled: _appleProviderEnabled,
                                  onGoogle: () => _showProviderUnavailable(
                                    context,
                                    'Google',
                                  ),
                                  onApple: () => _showProviderUnavailable(
                                    context,
                                    'Apple',
                                  ),
                                ),
                              ],
                              const Spacer(),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateAccountBridge extends StatelessWidget {
  const _CreateAccountBridge({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'New to PackLox? Create Account',
      child: Wrap(
        key: const ValueKey('auth-sign-in-create-account-bridge'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'New to PackLox?',
            style: TextStyle(
              color: PackLoxTokens.textSecondary,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            key: const ValueKey('auth-open-sign-up'),
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: PackLoxTokens.textPrimary,
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.padded,
              textStyle: const TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}

class _AuthSignInSocialProviderBlock extends StatelessWidget {
  const _AuthSignInSocialProviderBlock({
    required this.googleEnabled,
    required this.appleEnabled,
    required this.onGoogle,
    required this.onApple,
  });

  final bool googleEnabled;
  final bool appleEnabled;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('auth-sign-in-provider-block'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'or continue with',
          key: ValueKey('auth-sign-in-provider-divider'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PackLoxTokens.textSecondary,
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        if (googleEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          PackLoxButton(
            key: const ValueKey('auth-sign-in-google'),
            label: 'Continue with Google',
            onPressed: onGoogle,
            variant: PackLoxButtonVariant.secondary,
            size: PackLoxButtonSize.fullWidth,
          ),
        ],
        if (appleEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          PackLoxButton(
            key: const ValueKey('auth-sign-in-apple'),
            label: 'Continue with Apple',
            onPressed: onApple,
            variant: PackLoxButtonVariant.secondary,
            size: PackLoxButtonSize.fullWidth,
          ),
        ],
      ],
    );
  }
}

class AuthSignUpScreen extends ConsumerStatefulWidget {
  const AuthSignUpScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: AuthRouteNames.createAccountEmail),
      builder: (_) => const AuthSignUpScreen(),
    );
  }

  @override
  ConsumerState<AuthSignUpScreen> createState() => _AuthSignUpScreenState();
}

class _AuthSignUpScreenState extends ConsumerState<AuthSignUpScreen> {
  final _emailController = TextEditingController();
  bool _submitted = false;
  var _isSubmitting = false;
  String? _formError;

  static const _googleProviderEnabled = false;
  static const _appleProviderEnabled = false;

  bool get _hasEnabledProviders =>
      _googleProviderEnabled || _appleProviderEnabled;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleEmailChanged);
  }

  void _handleEmailChanged() {
    setState(() {
      _formError = null;
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() {
      _submitted = true;
      _formError = null;
    });
    if (!_canContinue || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();
    await ref
        .read(authBackendContractControllerProvider.notifier)
        .startEmailSignup(email: email);
    if (!mounted) {
      return;
    }
    final backendState = ref.read(authBackendContractControllerProvider);
    if (backendState.status == AuthBackendContractStatus.verificationSent) {
      setState(() => _isSubmitting = false);
      Navigator.of(
        context,
      ).push(AuthVerifyEmailScreen.route(email: backendState.email ?? email));
      return;
    }

    setState(() {
      _isSubmitting = false;
      _formError =
          backendState.failure?.safeMessage ??
          backendState.infoMessage ??
          'We could not send a verification code. Check your connection and try again.';
    });
  }

  void _openSignIn() {
    Navigator.of(context).push(AuthSignInScreen.route());
  }

  String? get _emailError {
    final email = _emailController.text.trim();
    if (!_submitted && email.isEmpty) {
      return null;
    }
    return _validateCreateAccountEmail(email);
  }

  bool get _canContinue =>
      _validateCreateAccountEmail(_emailController.text.trim()) == null;

  void _showProviderUnavailable(BuildContext context, String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$provider sign-up is not enabled in this build.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundTop = Color(0xFF050816);
    const backgroundMid = Color(0xFF0A1022);
    const backgroundBottom = Color(0xFF070A12);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundBottom,
        systemNavigationBarDividerColor: backgroundBottom,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const ValueKey('auth-create-account-email-screen'),
        backgroundColor: backgroundBottom,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .42, 1],
              colors: [backgroundTop, backgroundMid, backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.viewInsetsOf(context);
                final compactHeight =
                    constraints.maxHeight < 760 || viewInsets.bottom > 0;
                final topGap = compactHeight ? AppSpacing.lg : AppSpacing.xl;
                final titleGap = compactHeight ? AppSpacing.xl : 34.0;

                return SingleChildScrollView(
                  key: const ValueKey('auth-create-account-scroll-view'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    topGap,
                    AppSpacing.xl,
                    AppSpacing.lg + viewInsets.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight:
                            constraints.maxHeight - topGap - AppSpacing.lg,
                      ),
                      child: IntrinsicHeight(
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthCompactBrandLockup(
                                emblemSize: compactHeight ? 54 : 62,
                              ),
                              SizedBox(height: titleGap),
                              Text(
                                'Create your PackLox account',
                                key: const ValueKey(
                                  'auth-create-account-title',
                                ),
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  color: PackLoxTokens.textPrimary,
                                  fontSize: 30,
                                  height: 1.12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Enter your email to start protecting and valuing your collection.',
                                key: const ValueKey(
                                  'auth-create-account-supporting-copy',
                                ),
                                style: TextStyle(
                                  color: PackLoxTokens.textSecondary.withValues(
                                    alpha: .94,
                                  ),
                                  fontSize: 15,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              AuthTextField(
                                key: const ValueKey(
                                  'auth-create-account-email-field',
                                ),
                                controller: _emailController,
                                label: 'Email address',
                                hint: 'you@example.com',
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                errorText: _emailError,
                                enabled: !_isSubmitting,
                                onSubmitted: (_) {
                                  if (_canContinue) {
                                    unawaited(_continue());
                                  } else {
                                    setState(() => _submitted = true);
                                  }
                                },
                              ),
                              AuthMessage(errorMessage: _formError),
                              const SizedBox(height: AppSpacing.lg),
                              _GradientAuthButton(
                                key: const ValueKey(
                                  'auth-create-account-continue',
                                ),
                                label: _isSubmitting
                                    ? 'Sending code'
                                    : 'Continue',
                                semanticLabel: _isSubmitting
                                    ? 'Sending verification code'
                                    : 'Continue',
                                onPressed: _canContinue && !_isSubmitting
                                    ? () => unawaited(_continue())
                                    : null,
                              ),
                              if (_hasEnabledProviders) ...[
                                const SizedBox(height: AppSpacing.xl),
                                _AuthSocialProviderBlock(
                                  googleEnabled: _googleProviderEnabled,
                                  appleEnabled: _appleProviderEnabled,
                                  onGoogle: () => _showProviderUnavailable(
                                    context,
                                    'Google',
                                  ),
                                  onApple: () => _showProviderUnavailable(
                                    context,
                                    'Apple',
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              _OutlineAuthButton(
                                key: const ValueKey(
                                  'auth-create-account-sign-in',
                                ),
                                label: 'Sign In',
                                semanticLabel: 'Sign In',
                                onPressed: _openSignIn,
                              ),
                              const Spacer(),
                              const SizedBox(height: AppSpacing.lg),
                              const Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                                child: _AuthLegalConsentCopy(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AuthVerifyEmailScreen extends ConsumerStatefulWidget {
  const AuthVerifyEmailScreen({super.key, this.email});

  final String? email;

  static Route<void> route({String? email}) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: AuthRouteNames.verifyEmail,
        arguments: {'email': email},
      ),
      builder: (_) => AuthVerifyEmailScreen(email: email),
    );
  }

  @override
  ConsumerState<AuthVerifyEmailScreen> createState() =>
      _AuthVerifyEmailScreenState();
}

class _AuthVerifyEmailScreenState extends ConsumerState<AuthVerifyEmailScreen> {
  static const _otpLength = 6;
  static const _maxAttempts = 5;
  static const _resendCooldownSeconds = 30;

  final _codeController = TextEditingController();
  Timer? _cooldownTimer;
  var _cooldownRemaining = _resendCooldownSeconds;
  var _attemptsRemaining = _maxAttempts;
  var _requiresResend = false;
  var _isVerifying = false;
  var _isResending = false;
  String? _fieldError;

  String get _maskedEmail => _maskEmailForVerification(widget.email);

  bool get _hasCompleteCode => _codeController.text.length == _otpLength;

  bool get _canVerify => _hasCompleteCode && !_requiresResend && !_isVerifying;

  bool get _canResend => _cooldownRemaining == 0 && !_isResending;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_handleCodeChanged);
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.removeListener(_handleCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _handleCodeChanged() {
    if (_fieldError != null && !_requiresResend) {
      _fieldError = null;
    }
    setState(() {});
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownRemaining = 0);
        return;
      }
      setState(() => _cooldownRemaining -= 1);
    });
  }

  Future<void> _verify() async {
    if (!_canVerify) {
      return;
    }
    setState(() {
      _isVerifying = true;
      _fieldError = null;
    });

    await ref
        .read(authBackendContractControllerProvider.notifier)
        .verifyEmailOtp(code: _codeController.text);
    if (!mounted) {
      return;
    }

    final backendState = ref.read(authBackendContractControllerProvider);
    if (backendState.status == AuthBackendContractStatus.otpVerified &&
        backendState.verification != null) {
      setState(() => _isVerifying = false);
      Navigator.of(context).push(AuthCreatePasswordScreen.route());
      return;
    }

    final failure = backendState.failure;
    setState(() {
      _isVerifying = false;
      if (failure?.code == AuthBackendFailureCode.otpAttemptLimitReached) {
        _attemptsRemaining = failure?.attemptsRemaining ?? 0;
        _requiresResend = true;
        _fieldError = failure?.safeMessage;
        return;
      }
      if (failure?.code == AuthBackendFailureCode.otpInvalid) {
        final backendAttempts = failure?.attemptsRemaining;
        _attemptsRemaining = backendAttempts ?? (_attemptsRemaining - 1);
        if (_attemptsRemaining <= 0) {
          _attemptsRemaining = 0;
          _requiresResend = true;
          _fieldError =
              AuthBackendFailureCode.otpAttemptLimitReached.safeMessage;
          return;
        }
      } else if (failure?.code == AuthBackendFailureCode.otpExpired) {
        _requiresResend = true;
      }
      _fieldError =
          failure?.safeMessage ??
          backendState.infoMessage ??
          'We could not verify that code. Try again.';
    });
  }

  Future<void> _resendCode() async {
    if (!_canResend) {
      return;
    }
    setState(() {
      _isResending = true;
      _fieldError = null;
    });

    await ref
        .read(authBackendContractControllerProvider.notifier)
        .resendVerificationCode();
    if (!mounted) {
      return;
    }

    final backendState = ref.read(authBackendContractControllerProvider);
    if (backendState.status == AuthBackendContractStatus.verificationSent &&
        backendState.failure == null) {
      _codeController.clear();
      final cooldown =
          backendState.cooldownRemaining?.inSeconds ?? _resendCooldownSeconds;
      setState(() {
        _isResending = false;
        _cooldownRemaining = cooldown > 0 ? cooldown : _resendCooldownSeconds;
        _attemptsRemaining = backendState.attemptsRemaining ?? _maxAttempts;
        _requiresResend = false;
        _fieldError = null;
      });
      _startCooldownTimer();
      return;
    }

    setState(() {
      _isResending = false;
      _fieldError =
          backendState.failure?.safeMessage ??
          backendState.infoMessage ??
          'We could not send a new code. Check your connection and try again.';
    });
  }

  void _changeEmail() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(AuthSignUpScreen.route());
  }

  @override
  Widget build(BuildContext context) {
    const backgroundTop = Color(0xFF050816);
    const backgroundMid = Color(0xFF0A1022);
    const backgroundBottom = Color(0xFF070A12);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundBottom,
        systemNavigationBarDividerColor: backgroundBottom,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const ValueKey('auth-verify-email-screen'),
        backgroundColor: backgroundBottom,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .42, 1],
              colors: [backgroundTop, backgroundMid, backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.viewInsetsOf(context);
                final compactHeight =
                    constraints.maxHeight < 760 || viewInsets.bottom > 0;
                final topGap = compactHeight ? AppSpacing.lg : AppSpacing.xl;
                final titleGap = compactHeight ? AppSpacing.xl : 34.0;

                return SingleChildScrollView(
                  key: const ValueKey('auth-verify-email-scroll-view'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    topGap,
                    AppSpacing.xl,
                    AppSpacing.lg + viewInsets.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight:
                            constraints.maxHeight - topGap - AppSpacing.lg,
                      ),
                      child: IntrinsicHeight(
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthCompactBrandLockup(
                                keyPrefix: 'auth-verify-email',
                                emblemSize: compactHeight ? 54 : 62,
                              ),
                              SizedBox(height: titleGap),
                              const Text(
                                'Verify your email',
                                key: ValueKey('auth-verify-email-title'),
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: PackLoxTokens.textPrimary,
                                  fontSize: 30,
                                  height: 1.12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Enter the code we sent to $_maskedEmail.',
                                key: const ValueKey(
                                  'auth-verify-email-supporting-copy',
                                ),
                                style: TextStyle(
                                  color: PackLoxTokens.textSecondary.withValues(
                                    alpha: .94,
                                  ),
                                  fontSize: 15,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              _OtpCodeField(
                                key: const ValueKey(
                                  'auth-verify-email-otp-field',
                                ),
                                controller: _codeController,
                                errorText: _fieldError,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _GradientAuthButton(
                                key: const ValueKey('auth-verify-email-verify'),
                                label: _isVerifying ? 'Verifying' : 'Verify',
                                semanticLabel: _isVerifying
                                    ? 'Verifying'
                                    : 'Verify',
                                onPressed: _canVerify
                                    ? () => unawaited(_verify())
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _CooldownAuthAction(
                                key: const ValueKey('auth-verify-email-resend'),
                                label: _isResending
                                    ? 'Sending code'
                                    : _canResend
                                    ? 'Resend code'
                                    : 'Resend code in ${_cooldownRemaining}s',
                                semanticLabel: _isResending
                                    ? 'Sending verification code'
                                    : _canResend
                                    ? 'Resend code'
                                    : 'Resend code available in $_cooldownRemaining seconds',
                                enabled: _canResend,
                                onPressed: () => unawaited(_resendCode()),
                              ),
                              _QuietAuthAction(
                                key: const ValueKey(
                                  'auth-verify-email-change-email',
                                ),
                                label: 'Change email',
                                semanticLabel: 'Change email',
                                onPressed: _changeEmail,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'This code expires in 10:00.',
                                key: const ValueKey('auth-verify-email-expiry'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: PackLoxTokens.textSecondary.withValues(
                                    alpha: .82,
                                  ),
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _requiresResend
                                    ? 'Request a new code to try again.'
                                    : '$_attemptsRemaining attempts remaining.',
                                key: const ValueKey(
                                  'auth-verify-email-attempts',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: PackLoxTokens.textSecondary.withValues(
                                    alpha: .72,
                                  ),
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpCodeField extends StatelessWidget {
  const _OtpCodeField({
    required this.controller,
    required this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Verification code, 6-digit code',
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: 6,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: PackLoxTokens.textPrimary,
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
        ),
        decoration: InputDecoration(
          labelText: 'Verification code',
          hintText: '6-digit code',
          counterText: '',
          errorText: errorText,
        ),
      ),
    );
  }
}

class _CooldownAuthAction extends StatelessWidget {
  const _CooldownAuthAction({
    required this.label,
    required this.semanticLabel,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: enabled
              ? const Color(0xFF9CCBFF)
              : PackLoxTokens.textSecondary.withValues(alpha: .70),
          disabledForegroundColor: PackLoxTokens.textSecondary.withValues(
            alpha: .70,
          ),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class AuthCreatePasswordScreen extends ConsumerStatefulWidget {
  const AuthCreatePasswordScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: AuthRouteNames.createPassword),
      builder: (_) => const AuthCreatePasswordScreen(),
    );
  }

  @override
  ConsumerState<AuthCreatePasswordScreen> createState() =>
      _AuthCreatePasswordScreenState();
}

class _AuthCreatePasswordScreenState
    extends ConsumerState<AuthCreatePasswordScreen> {
  static const _minimumPasswordLength = 12;

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _submitted = false;
  var _completed = false;
  var _isSubmitting = false;
  String? _formError;

  bool get _passwordMeetsLength =>
      _passwordController.text.length >= _minimumPasswordLength;

  bool get _confirmMatches =>
      _passwordController.text.isNotEmpty &&
      _confirmController.text == _passwordController.text;

  bool get _canFinish => _passwordMeetsLength && _confirmMatches;

  String? get _confirmError {
    if (_confirmController.text.isEmpty) {
      return null;
    }
    if (!_confirmMatches) {
      return 'Passwords do not match.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_handleFieldChanged);
    _confirmController.addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_handleFieldChanged);
    _confirmController.removeListener(_handleFieldChanged);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    setState(() {
      _completed = false;
      _formError = null;
    });
  }

  Future<void> _finishAccount() async {
    setState(() {
      _submitted = true;
      _formError = null;
    });
    if (!_canFinish || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    await ref
        .read(authBackendContractControllerProvider.notifier)
        .createPasswordAfterVerification(
          password: _passwordController.text,
          confirmPassword: _confirmController.text,
        );
    if (!mounted) {
      return;
    }

    final backendState = ref.read(authBackendContractControllerProvider);
    final signedInUser = backendState.user;
    if (backendState.status == AuthBackendContractStatus.signedIn &&
        signedInUser != null &&
        backendState.isSignedIn) {
      ref.read(authControllerProvider.notifier).applySignedInUser(signedInUser);
      setState(() {
        _isSubmitting = false;
        _completed = true;
      });
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _completed = false;
      _formError =
          backendState.failure?.safeMessage ??
          backendState.infoMessage ??
          'We could not finish account setup. Try again.';
    });
  }

  void _backToVerification() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundTop = Color(0xFF050816);
    const backgroundMid = Color(0xFF0A1022);
    const backgroundBottom = Color(0xFF070A12);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundBottom,
        systemNavigationBarDividerColor: backgroundBottom,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const ValueKey('auth-create-password-screen'),
        backgroundColor: backgroundBottom,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .42, 1],
              colors: [backgroundTop, backgroundMid, backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.viewInsetsOf(context);
                final compactHeight =
                    constraints.maxHeight < 760 || viewInsets.bottom > 0;
                final topGap = compactHeight ? AppSpacing.lg : AppSpacing.xl;
                final titleGap = compactHeight ? AppSpacing.xl : 34.0;

                return SingleChildScrollView(
                  key: const ValueKey('auth-create-password-scroll-view'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    topGap,
                    AppSpacing.xl,
                    AppSpacing.lg + viewInsets.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight:
                            constraints.maxHeight - topGap - AppSpacing.lg,
                      ),
                      child: IntrinsicHeight(
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthCompactBrandLockup(
                                keyPrefix: 'auth-create-password',
                                emblemSize: compactHeight ? 54 : 62,
                              ),
                              SizedBox(height: titleGap),
                              const Text(
                                'Create your password',
                                key: ValueKey('auth-create-password-title'),
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: PackLoxTokens.textPrimary,
                                  fontSize: 30,
                                  height: 1.12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Secure your PackLox account.',
                                key: const ValueKey(
                                  'auth-create-password-supporting-copy',
                                ),
                                style: TextStyle(
                                  color: PackLoxTokens.textSecondary.withValues(
                                    alpha: .94,
                                  ),
                                  fontSize: 15,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              AuthTextField(
                                key: const ValueKey(
                                  'auth-create-password-password-field',
                                ),
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Memorable passphrase',
                                obscureText: _obscurePassword,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                suffixIcon: IconButton(
                                  key: const ValueKey(
                                    'auth-create-password-password-visibility',
                                  ),
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                onSubmitted: (_) {
                                  if (_canFinish) {
                                    unawaited(_finishAccount());
                                  }
                                },
                                enabled: !_isSubmitting,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AuthTextField(
                                key: const ValueKey(
                                  'auth-create-password-confirm-field',
                                ),
                                controller: _confirmController,
                                label: 'Confirm password',
                                hint: 'Repeat your passphrase',
                                obscureText: _obscureConfirm,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                errorText: _confirmError,
                                suffixIcon: IconButton(
                                  key: const ValueKey(
                                    'auth-create-password-confirm-visibility',
                                  ),
                                  tooltip: _obscureConfirm
                                      ? 'Show confirm password'
                                      : 'Hide confirm password',
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                                onSubmitted: (_) {
                                  if (_canFinish) {
                                    unawaited(_finishAccount());
                                  }
                                },
                                enabled: !_isSubmitting,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _PasswordRequirementBlock(
                                key: const ValueKey(
                                  'auth-create-password-requirements',
                                ),
                                lengthMet: _passwordMeetsLength,
                                matchMet: _confirmMatches,
                              ),
                              AuthMessage(
                                errorMessage: _formError,
                                infoMessage: _completed
                                    ? 'Account ready.'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _GradientAuthButton(
                                key: const ValueKey(
                                  'auth-create-password-finish',
                                ),
                                label: _isSubmitting
                                    ? 'Finishing'
                                    : 'Finish Account',
                                semanticLabel: _isSubmitting
                                    ? 'Finishing Account'
                                    : 'Finish Account',
                                onPressed: _canFinish && !_isSubmitting
                                    ? () => unawaited(_finishAccount())
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _OutlineAuthButton(
                                key: const ValueKey(
                                  'auth-create-password-back',
                                ),
                                label: 'Back to verification',
                                semanticLabel: 'Back to verification',
                                onPressed: _backToVerification,
                              ),
                              if (_submitted && !_canFinish) ...[
                                const SizedBox(height: AppSpacing.md),
                                AuthMessage(
                                  errorMessage: _confirmController.text.isEmpty
                                      ? 'Confirm your password to finish.'
                                      : _confirmError,
                                ),
                              ],
                              const Spacer(),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRequirementBlock extends StatelessWidget {
  const _PasswordRequirementBlock({
    required this.lengthMet,
    required this.matchMet,
    super.key,
  });

  final bool lengthMet;
  final bool matchMet;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          'Password requirements. Use at least 12 characters. Use a memorable passphrase. Spaces and symbols are allowed.',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: PackLoxTokens.surfaceRaised.withValues(alpha: .78),
          border: Border.all(color: PackLoxTokens.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PasswordRequirementRow(
              key: const ValueKey('auth-create-password-length-rule'),
              met: lengthMet,
              label: 'Use at least 12 characters',
            ),
            const SizedBox(height: AppSpacing.sm),
            _PasswordRequirementRow(
              key: const ValueKey('auth-create-password-match-rule'),
              met: matchMet,
              label: 'Confirm password must match',
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Use a memorable passphrase. Spaces and symbols are allowed.',
              key: ValueKey('auth-create-password-helper-copy'),
              style: TextStyle(
                color: PackLoxTokens.textSecondary,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRequirementRow extends StatelessWidget {
  const _PasswordRequirementRow({
    required this.met,
    required this.label,
    super.key,
  });

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = met ? PackLoxTokens.success : PackLoxTokens.textSecondary;
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: color,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCompactBrandLockup extends StatelessWidget {
  const _AuthCompactBrandLockup({
    required this.emblemSize,
    this.keyPrefix = 'auth-create-account',
  });

  static const _brandV2EmblemPath =
      'assets/packlox/brand/packlox_brand_v2_emblem_authority_v0_7.png';

  final double emblemSize;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'PackLox Brand v2 identity',
      child: Row(
        key: ValueKey('$keyPrefix-brand-identity'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            key: ValueKey('$keyPrefix-brand-emblem'),
            dimension: emblemSize,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                _brandV2EmblemPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(painter: _BrandV2EmblemPainter());
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pack',
                      style: TextStyle(color: PackLoxTokens.textPrimary),
                    ),
                    TextSpan(
                      text: 'Lox',
                      style: TextStyle(color: Color(0xFF6FD3FF)),
                    ),
                  ],
                ),
                key: ValueKey('$keyPrefix-wordmark'),
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthSocialProviderBlock extends StatelessWidget {
  const _AuthSocialProviderBlock({
    required this.googleEnabled,
    required this.appleEnabled,
    required this.onGoogle,
    required this.onApple,
  });

  final bool googleEnabled;
  final bool appleEnabled;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('auth-create-account-provider-block'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'or continue with',
          key: ValueKey('auth-create-account-provider-divider'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PackLoxTokens.textSecondary,
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        if (googleEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          PackLoxButton(
            key: const ValueKey('auth-create-account-google'),
            label: 'Continue with Google',
            onPressed: onGoogle,
            variant: PackLoxButtonVariant.secondary,
            size: PackLoxButtonSize.fullWidth,
          ),
        ],
        if (appleEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          PackLoxButton(
            key: const ValueKey('auth-create-account-apple'),
            label: 'Continue with Apple',
            onPressed: onApple,
            variant: PackLoxButtonVariant.secondary,
            size: PackLoxButtonSize.fullWidth,
          ),
        ],
      ],
    );
  }
}

class AuthForgotPasswordScreen extends ConsumerStatefulWidget {
  const AuthForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  static Route<void> route({String? initialEmail}) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: AuthRouteNames.forgotPasswordEmail,
        arguments: {'initialEmail': initialEmail},
      ),
      builder: (_) => AuthForgotPasswordScreen(initialEmail: initialEmail),
    );
  }

  @override
  ConsumerState<AuthForgotPasswordScreen> createState() =>
      _AuthForgotPasswordScreenState();
}

class _AuthForgotPasswordScreenState
    extends ConsumerState<AuthForgotPasswordScreen> {
  static const _resendCooldownSeconds = 30;
  static const _maxRequestCount = 5;

  late final TextEditingController _emailController;
  Timer? _cooldownTimer;
  var _submitted = false;
  var _confirmed = false;
  var _requestCount = 0;
  var _cooldownRemaining = 0;
  var _rateLimited = false;
  var _isRequesting = false;
  String? _requestError;

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.initialEmail?.trim() ?? '';
    _emailController = TextEditingController(
      text: _validateForgotPasswordEmail(initialEmail) == null
          ? initialEmail
          : '',
    );
    _emailController.addListener(_handleEmailChanged);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.removeListener(_handleEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _handleEmailChanged() {
    if (_confirmed) {
      return;
    }
    setState(() {
      _submitted = false;
      _rateLimited = false;
      _requestError = null;
    });
  }

  bool get _canSend =>
      !_isRequesting &&
      _validateForgotPasswordEmail(_emailController.text) == null;

  String? get _emailError {
    if (!_submitted) return null;
    return _validateForgotPasswordEmail(_emailController.text);
  }

  void _submit() {
    setState(() {
      _submitted = true;
      _requestError = null;
    });
    if (!_canSend) {
      return;
    }
    unawaited(_sendResetRequest());
  }

  void _resend() {
    if (_cooldownRemaining > 0 || _rateLimited || _isRequesting) {
      return;
    }
    unawaited(_sendResetRequest());
  }

  Future<void> _sendResetRequest() async {
    if (_requestCount >= _maxRequestCount) {
      setState(() {
        _confirmed = true;
        _rateLimited = true;
        _requestError = null;
      });
      return;
    }

    _cooldownTimer?.cancel();
    setState(() {
      _isRequesting = true;
      _requestError = null;
    });

    final backendController = ref.read(
      authBackendContractControllerProvider.notifier,
    );
    await backendController.requestPasswordReset(
      email: _emailController.text.trim(),
    );
    if (!mounted) {
      return;
    }

    final backendState = ref.read(authBackendContractControllerProvider);
    if (backendState.status ==
        AuthBackendContractStatus.passwordResetConfirmation) {
      _acceptRequest(cooldown: backendState.cooldownRemaining);
      return;
    }

    setState(() {
      _isRequesting = false;
      _requestError =
          backendState.failure?.safeMessage ??
          backendState.infoMessage ??
          'We could not send reset instructions. Check your connection and try again.';
    });
  }

  void _acceptRequest({Duration? cooldown}) {
    final cooldownSeconds = cooldown?.inSeconds ?? _resendCooldownSeconds;
    setState(() {
      _submitted = false;
      _confirmed = true;
      _isRequesting = false;
      _requestError = null;
      _requestCount += 1;
      _rateLimited = _requestCount >= _maxRequestCount;
    });
    if (!_rateLimited) {
      _startCooldown(
        cooldownSeconds > 0 ? cooldownSeconds : _resendCooldownSeconds,
      );
    }
  }

  void _startCooldown(int seconds) {
    setState(() => _cooldownRemaining = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownRemaining = 0);
        return;
      }
      setState(() => _cooldownRemaining -= 1);
    });
  }

  void _backToSignIn() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundTop = Color(0xFF050816);
    const backgroundMid = Color(0xFF0A1022);
    const backgroundBottom = Color(0xFF070A12);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundBottom,
        systemNavigationBarDividerColor: backgroundBottom,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const ValueKey('auth-forgot-password-screen'),
        backgroundColor: backgroundBottom,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .42, 1],
              colors: [backgroundTop, backgroundMid, backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.viewInsetsOf(context);
                final compactHeight =
                    constraints.maxHeight < 760 || viewInsets.bottom > 0;
                final topGap = compactHeight ? AppSpacing.lg : AppSpacing.xl;
                final titleGap = compactHeight ? AppSpacing.xl : 34.0;

                return SingleChildScrollView(
                  key: const ValueKey('auth-forgot-password-scroll-view'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    topGap,
                    AppSpacing.xl,
                    AppSpacing.lg + viewInsets.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight:
                            constraints.maxHeight - topGap - AppSpacing.lg,
                      ),
                      child: IntrinsicHeight(
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthCompactBrandLockup(
                                keyPrefix: 'auth-forgot-password',
                                emblemSize: compactHeight ? 54 : 62,
                              ),
                              SizedBox(height: titleGap),
                              if (_confirmed)
                                _ForgotPasswordConfirmationContent(
                                  cooldownRemaining: _cooldownRemaining,
                                  rateLimited: _rateLimited,
                                  isLoading: _isRequesting,
                                  requestError: _requestError,
                                  onBackToSignIn: _backToSignIn,
                                  onResend: _resend,
                                )
                              else
                                _ForgotPasswordRequestContent(
                                  emailController: _emailController,
                                  emailError: _emailError,
                                  canSend: _canSend,
                                  isLoading: _isRequesting,
                                  requestError: _requestError,
                                  onSubmit: _submit,
                                  onBackToSignIn: _backToSignIn,
                                ),
                              const Spacer(),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordRequestContent extends StatelessWidget {
  const _ForgotPasswordRequestContent({
    required this.emailController,
    required this.emailError,
    required this.canSend,
    required this.isLoading,
    required this.requestError,
    required this.onSubmit,
    required this.onBackToSignIn,
  });

  final TextEditingController emailController;
  final String? emailError;
  final bool canSend;
  final bool isLoading;
  final String? requestError;
  final VoidCallback onSubmit;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reset your password',
          key: ValueKey('auth-forgot-password-title'),
          textAlign: TextAlign.left,
          style: TextStyle(
            color: PackLoxTokens.textPrimary,
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "Enter your email and we'll send reset instructions if the account exists.",
          key: const ValueKey('auth-forgot-password-supporting-copy'),
          style: TextStyle(
            color: PackLoxTokens.textSecondary.withValues(alpha: .94),
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AuthTextField(
          key: const ValueKey('auth-forgot-email-field'),
          controller: emailController,
          label: 'Email address',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          errorText: emailError,
          enabled: !isLoading,
          onSubmitted: (_) => onSubmit(),
        ),
        if (requestError != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ForgotPasswordNotice(
            key: const ValueKey('auth-forgot-request-error'),
            text: requestError!,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _GradientAuthButton(
          key: const ValueKey('auth-forgot-submit'),
          label: isLoading ? 'Sending...' : 'Send reset instructions',
          semanticLabel: 'Send reset instructions',
          onPressed: canSend && !isLoading ? onSubmit : null,
        ),
        const SizedBox(height: AppSpacing.md),
        _OutlineAuthButton(
          key: const ValueKey('auth-forgot-return-sign-in'),
          label: 'Back to Sign In',
          semanticLabel: 'Back to Sign In',
          onPressed: onBackToSignIn,
        ),
      ],
    );
  }
}

class _ForgotPasswordConfirmationContent extends StatelessWidget {
  const _ForgotPasswordConfirmationContent({
    required this.cooldownRemaining,
    required this.rateLimited,
    required this.isLoading,
    required this.requestError,
    required this.onBackToSignIn,
    required this.onResend,
  });

  final int cooldownRemaining;
  final bool rateLimited;
  final bool isLoading;
  final String? requestError;
  final VoidCallback onBackToSignIn;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('auth-forgot-confirmation'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Check your email',
          key: ValueKey('auth-forgot-confirmation-title'),
          textAlign: TextAlign.left,
          style: TextStyle(
            color: PackLoxTokens.textPrimary,
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'If an account exists for this email, reset instructions have been sent.',
          key: const ValueKey('auth-forgot-confirmation-copy'),
          style: TextStyle(
            color: PackLoxTokens.textSecondary.withValues(alpha: .94),
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _OutlineAuthButton(
          key: const ValueKey('auth-forgot-return-sign-in'),
          label: 'Back to Sign In',
          semanticLabel: 'Back to Sign In',
          onPressed: onBackToSignIn,
        ),
        if (requestError != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ForgotPasswordNotice(
            key: const ValueKey('auth-forgot-request-error'),
            text: requestError!,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (rateLimited)
          const _ForgotPasswordNotice(
            key: ValueKey('auth-forgot-rate-limit'),
            text:
                "We couldn't send more instructions right now. Please wait and try again.",
          )
        else if (isLoading)
          const _ForgotPasswordNotice(
            key: ValueKey('auth-forgot-resend-loading'),
            text: 'Sending reset instructions...',
          )
        else if (cooldownRemaining > 0)
          _ForgotPasswordNotice(
            key: const ValueKey('auth-forgot-resend-cooldown'),
            text: 'You can resend instructions in ${cooldownRemaining}s.',
          )
        else
          _QuietAuthAction(
            key: const ValueKey('auth-forgot-resend'),
            label: 'Resend instructions',
            semanticLabel: 'Resend instructions',
            onPressed: onResend,
          ),
        const SizedBox(height: AppSpacing.lg),
        const _ForgotPasswordNotice(
          key: ValueKey('auth-forgot-provider-guidance'),
          text:
              'If you use Google or Apple, return to Sign In and continue with that provider.',
        ),
      ],
    );
  }
}

class _ForgotPasswordNotice extends StatelessWidget {
  const _ForgotPasswordNotice({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: PackLoxTokens.surfaceRaised.withValues(alpha: .78),
          border: Border.all(color: PackLoxTokens.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: PackLoxTokens.textSecondary,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Scaffold(
      backgroundColor: PackLoxTokens.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              key: const ValueKey('auth-scroll-view'),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl + viewInsets.bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight:
                        constraints.maxHeight - AppSpacing.lg - AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PackLoxHeader(
                        key: const ValueKey('auth-packlox-header'),
                        firstName: title,
                        greetingText: 'PackLox',
                        fallbackName: title,
                        onNotifications: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: PackLoxTokens.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      child,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthIdentityMark extends StatelessWidget {
  const AuthIdentityMark({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: PackLoxTokens.surfaceRaised,
        border: Border.all(color: PackLoxTokens.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PackLoxTokens.blue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: PackLoxTokens.border),
            ),
            child: Icon(icon, color: PackLoxTokens.textPrimary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PackLoxTokens.textPrimary,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: PackLoxTokens.textSecondary,
                    fontSize: 12,
                    height: 1.4,
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

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.enabled = true,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.errorText,
    this.suffixIcon,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final String? errorText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        obscureText: obscureText,
        textInputAction: TextInputAction.next,
        onSubmitted: onSubmitted,
        inputFormatters: keyboardType == TextInputType.emailAddress
            ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class AuthMessage extends StatelessWidget {
  const AuthMessage({this.errorMessage, this.infoMessage, super.key});

  final String? errorMessage;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage ?? infoMessage;
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }
    final isError = errorMessage != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: ValueKey(isError ? 'auth-error-message' : 'auth-info-message'),
        margin: const EdgeInsets.only(top: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: (isError ? PackLoxTokens.error : PackLoxTokens.success)
              .withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isError ? PackLoxTokens.error : PackLoxTokens.success,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: PackLoxTokens.textPrimary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: PackLoxTokens.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthVerificationPanel extends StatelessWidget {
  const AuthVerificationPanel({
    required this.email,
    required this.isLoading,
    required this.onResend,
    required this.onReturnToSignIn,
    this.infoMessage,
    this.errorMessage,
    super.key,
  });

  final String email;
  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onReturnToSignIn;
  final String? infoMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthIdentityMark(
          icon: Icons.mark_email_read_outlined,
          title: 'Verification email sent',
          subtitle: email.isEmpty ? 'Check your inbox.' : email,
        ),
        AuthMessage(errorMessage: errorMessage, infoMessage: infoMessage),
        const SizedBox(height: AppSpacing.lg),
        PackLoxButton(
          key: const ValueKey('auth-resend-confirmation'),
          label: isLoading ? 'Sending' : 'Resend Confirmation',
          onPressed: isLoading ? null : onResend,
          loading: isLoading,
          leadingIcon: Icons.mark_email_unread_outlined,
          variant: PackLoxButtonVariant.secondary,
          size: PackLoxButtonSize.fullWidth,
        ),
        const SizedBox(height: AppSpacing.md),
        PackLoxButton(
          key: const ValueKey('auth-verification-return-sign-in'),
          label: 'Back to Sign In',
          onPressed: isLoading ? null : onReturnToSignIn,
          leadingIcon: Icons.login_rounded,
          size: PackLoxButtonSize.fullWidth,
        ),
      ],
    );
  }
}

class GuestAccessNote extends StatelessWidget {
  const GuestAccessNote({super.key});

  @override
  Widget build(BuildContext context) {
    return PackLoxEntryTile(
      key: const ValueKey('auth-guest-access-note'),
      icon: Icons.inventory_2_outlined,
      title: 'Guest mode stays available',
      supportingText:
          'Use scanning and Portfolio locally without an account. Sign in only for cloud sync.',
      onTap: null,
      showTrailing: false,
    );
  }
}

String? _validateCreateAccountEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) {
    return 'Enter your email address.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _validateSignInEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) {
    return 'Enter your email address.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _validateForgotPasswordEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) {
    return 'Enter your email address.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String _maskEmailForVerification(String? email) {
  final trimmed = email?.trim() ?? '';
  final atIndex = trimmed.indexOf('@');
  if (atIndex <= 0 || atIndex == trimmed.length - 1) {
    return 'h***@example.com';
  }

  final localPart = trimmed.substring(0, atIndex);
  final domain = trimmed.substring(atIndex + 1);
  return '${localPart[0]}***@$domain';
}
