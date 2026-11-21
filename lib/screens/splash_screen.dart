import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../services/app_data_service.dart';

/// =====================================================================
/// SPLASH SCREEN TANIJAGUNG (Tahap 2 Redesain) — ± 2,3 detik
/// =====================================================================
/// Urutan animasi (satu AnimationController, tanpa Timer, 60 fps):
/// 1. Logo tongkol jagung muncul dari kecil: scale + bounce (easeOutBack).
/// 2. Biji jagung berkilau satu per satu (sparkle bergelombang).
/// 3. "Tani" lalu "Jagung" fade-in + slide-up (stagger), disusul tagline.
/// 4. Indikator loading berupa titik-titik yang mengalir.
/// 5. Transisi keluar (circular reveal + fade) ditangani oleh AppRootFlow.
/// Data aplikasi dimuat di latar SELAMA animasi ([bootFuture]), sehingga
/// splash tidak menunda lebih lama dari yang diperlukan.
/// Menghormati "Kurangi animasi": langsung tampil statis & selesai cepat.
class SplashScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final Future<void>? bootFuture;

  const SplashScreen({super.key, this.onCompleted, this.bootFuture});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _dots;
  bool _hasCompleted = false;
  bool _started = false;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _sparkle;
  late final Animation<double> _taniText;
  late final Animation<double> _jagungText;
  late final Animation<double> _tagline;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoScale = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.36, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
    );
    _sparkle = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.24, 0.72, curve: Curves.linear),
    );
    _taniText = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.42, 0.66, curve: Curves.easeOutCubic),
    );
    _jagungText = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.50, 0.74, curve: Curves.easeOutCubic),
    );
    _tagline = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.62, 0.88, curve: Curves.easeOutCubic),
    );
    _loaderFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.55, 0.80, curve: Curves.easeOut),
    );

    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _intro.value = 1.0; // tampil statis, langsung lanjut
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _intro.forward();
      _dots.repeat();
    }
  }

  Future<void> _finish() async {
    if (_hasCompleted || !mounted) return;
    _hasCompleted = true;
    // Tunggu data selesai dimuat (biasanya sudah selesai selama animasi)
    try {
      await widget.bootFuture;
    } catch (_) {}
    await AppDataService().completeOnboarding();
    if (!mounted) return;
    _dots.stop();
    HapticFeedback.lightImpact();
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _intro.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppTheme.primaryGreen,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.darkGreen,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _dots]),
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, c) {
                    final logoSize = math.min(
                      150.0,
                      math.min(c.maxWidth, c.maxHeight) * 0.36,
                    );
                    return Stack(
                      children: [
                        // Ornamen cahaya lembut di latar
                        Positioned(
                          top: -c.maxWidth * 0.3,
                          right: -c.maxWidth * 0.25,
                          child: _GlowOrb(
                            size: c.maxWidth * 0.8,
                            opacity: 0.10 * _logoFade.value,
                          ),
                        ),
                        Positioned(
                          bottom: -c.maxWidth * 0.35,
                          left: -c.maxWidth * 0.3,
                          child: _GlowOrb(
                            size: c.maxWidth * 0.9,
                            opacity: 0.08 * _logoFade.value,
                            color: AppTheme.cornYellow,
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1–2. Logo tongkol jagung + sparkle biji
                                Opacity(
                                  opacity: _logoFade.value.clamp(0.0, 1.0),
                                  child: Transform.scale(
                                    scale: 0.3 + 0.7 * _logoScale.value,
                                    child: SizedBox(
                                      width: logoSize,
                                      height: logoSize,
                                      child: CustomPaint(
                                        painter: _CornLogoPainter(
                                          sparkle: _sparkle.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // 3. Nama aplikasi (stagger "Tani" → "Jagung")
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _FadeUp(
                                        t: _taniText.value,
                                        child: const Text(
                                          'Tani',
                                          style: TextStyle(
                                            fontFamily: AppTheme.headingFont,
                                            fontSize: 40,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -1.0,
                                          ),
                                        ),
                                      ),
                                      _FadeUp(
                                        t: _jagungText.value,
                                        child: const Text(
                                          'Jagung',
                                          style: TextStyle(
                                            fontFamily: AppTheme.headingFont,
                                            fontSize: 40,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.cornYellow,
                                            letterSpacing: -1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _FadeUp(
                                  t: _tagline.value,
                                  distance: 12,
                                  child: Text(
                                    'Kelola usaha tani, raih panen maksimal',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(
                                        alpha: 0.82,
                                      ),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 4. Loading titik mengalir
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: AppSpacing.xl,
                          child: Opacity(
                            opacity: _loaderFade.value.clamp(0.0, 1.0),
                            child: _FlowingDots(t: _dots.value),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeUp extends StatelessWidget {
  final double t;
  final double distance;
  final Widget child;

  const _FadeUp({required this.t, required this.child, this.distance = 20});

  @override
  Widget build(BuildContext context) {
    final v = t.clamp(0.0, 1.0);
    return Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset(0, (1 - v) * distance),
        child: child,
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final double opacity;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.opacity,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lima titik yang "mengalir" (gelombang skala & opasitas berurutan).
class _FlowingDots extends StatelessWidget {
  final double t;
  const _FlowingDots({required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final phase = (t - i * 0.14) % 1.0;
        final wave = math.max(0.0, math.sin(phase * math.pi));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 7 + wave * 3,
          height: 7 + wave * 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              Colors.white.withValues(alpha: 0.35),
              AppTheme.cornYellow,
              wave,
            ),
          ),
        );
      }),
    );
  }
}

/// Logo tongkol jagung vektor dengan biji yang berkilau satu per satu.
class _CornLogoPainter extends CustomPainter {
  final double sparkle; // 0..1

  _CornLogoPainter({required this.sparkle});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final center = Offset(w / 2, h / 2);

    // Lingkaran latar (glass) + cincin halus
    canvas.drawCircle(
      center,
      w * 0.5,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      center,
      w * 0.5 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.22),
    );

    // Daun kelobot kiri & kanan
    final leafL = Path()
      ..moveTo(w * 0.5, h * 0.86)
      ..quadraticBezierTo(w * 0.2, h * 0.74, w * 0.22, h * 0.36)
      ..quadraticBezierTo(w * 0.36, h * 0.6, w * 0.5, h * 0.7)
      ..close();
    final leafR = Path()
      ..moveTo(w * 0.5, h * 0.86)
      ..quadraticBezierTo(w * 0.8, h * 0.74, w * 0.78, h * 0.36)
      ..quadraticBezierTo(w * 0.64, h * 0.6, w * 0.5, h * 0.7)
      ..close();
    canvas.drawPath(leafL, Paint()..color = const Color(0xFF5DBB7E));
    canvas.drawPath(leafR, Paint()..color = const Color(0xFF3E9A60));

    // Tongkol
    final cob = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.46),
      width: w * 0.3,
      height: h * 0.56,
    );
    final cobRRect = RRect.fromRectAndRadius(cob, Radius.circular(w * 0.15));
    canvas.drawRRect(
      cobRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFCE38A), AppTheme.cornYellow, AppTheme.cornGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(cob),
    );

    // Biji jagung + sparkle bergelombang dari atas ke bawah
    const rows = 7, cols = 3;
    final total = rows * cols;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        final cx = cob.left + cob.width * (0.25 + c * 0.25);
        final cy = cob.top + cob.height * (0.12 + r * 0.127);
        final kr = w * 0.026;

        // Jendela waktu sparkle tiap biji
        final start = idx / total * 0.75;
        final local = ((sparkle - start) / 0.25).clamp(0.0, 1.0);
        final glow = math.sin(local * math.pi); // 0 → 1 → 0

        canvas.drawCircle(
          Offset(cx, cy),
          kr,
          Paint()
            ..color = Color.lerp(
              AppTheme.cornGold.withValues(alpha: 0.55),
              Colors.white,
              glow * 0.85,
            )!,
        );

        if (glow > 0.15) {
          _drawStar(
            canvas,
            Offset(cx + kr * 0.6, cy - kr * 0.6),
            kr * 1.6 * glow,
            Colors.white.withValues(alpha: glow),
          );
        }
      }
    }

    // Kilau diagonal pada tongkol
    canvas.save();
    canvas.clipRRect(cobRRect);
    final shineX = cob.left - cob.width + (cob.width * 3) * sparkle;
    canvas.drawRect(
      Rect.fromLTWH(shineX, cob.top, cob.width * 0.35, cob.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(shineX, cob.top, cob.width * 0.35, 1)),
    );
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = math.max(1.0, r * 0.18)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), p);
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), p);
  }

  @override
  bool shouldRepaint(covariant _CornLogoPainter old) => old.sparkle != sparkle;
}

/// Clipper "circular reveal": membuat lubang lingkaran yang membesar di
/// tengah layar sehingga halaman berikutnya terlihat dari balik splash.
class CircularRevealHoleClipper extends CustomClipper<Path> {
  final double progress; // 0..1

  CircularRevealHoleClipper(this.progress);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: maxRadius * progress));
  }

  @override
  bool shouldReclip(covariant CircularRevealHoleClipper old) =>
      old.progress != progress;
}
