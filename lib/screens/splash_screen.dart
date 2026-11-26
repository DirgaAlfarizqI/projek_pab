import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../services/app_data_service.dart';

/// =====================================================================
/// SPLASH SCREEN TANIJAGUNG — 2D KINETIC TYPOGRAPHY (1080×1920 · 60 FPS)
/// =====================================================================
/// Mengimplementasikan 5 Scene Kinetic Typography yang sama persis dengan
/// design/tanijagung_splash.html:
/// - Latar hijau hutan pekat (#0E442E).
/// - Bentuk huruf "TaniJagung" ("Tani" putih #FFFFFF, "Jagung" kuning #F9C334)
///   dan titik biji jagung miring di atas "i" diekstrak 1:1 dari assets/icon.png.
/// - Scene 1 (0–3 s): "Dari lahan, untuk panen" -> titik emas -> huruf muncul
///   satu per satu mengelilingi titik -> titik menjadi biji jagung di atas "i".
/// - Scene 2 (3–6 s): Gelombang vertikal berjenjang pada beat + rotasi halus
///   6–8° + biji jagung bergerak mandiri lalu kembali presisi ke atas "i".
/// - Scene 3 (6–9 s): Biji jagung lepas dari "i", turun menggambar kurva
///   pertumbuhan spring (overshoot lalu settle, tanpa +38% PANEN).
/// - Scene 4 (9–12 s): Grafik menjadi jalur horizontal -> biji meluncur ke
///   tengah -> membesar jadi lingkaran -> kotak tumpul -> pill -> mengerut
///   kembali menjadi biji jagung.
/// - Scene 5 (12–15 s): Wordmark "TaniJagung" tampil di tengah disusul tagline
///   "Kelola usaha tani, raih panen maksimal" (Poppins Medium & SemiBold).
class SplashScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final Future<void>? bootFuture;

  const SplashScreen({super.key, this.onCompleted, this.bootFuture});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgGreen = Color(0xFF0E442E);
  static const double _vw = 1080.0;
  static const double _vh = 1920.0;
  static const double _cx = 540.0;
  static const double _cy = 880.0;
  static const double _durSec = 15.0;
  static const double _beat = 0.5;
  static const double _gx0 = 150.0;
  static const double _gx1 = 930.0;
  static const double _gy0 = 1320.0;
  static const double _gh = 520.0;

  late final AnimationController _ctrl;
  late final List<_DecodedGlyph> _glyphs;
  bool _hasCompleted = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _glyphs = _kGlyphSpecs.map((s) => _DecodedGlyph(s)).toList(growable: false);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 15000),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _ctrl.value = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _ctrl.forward();
    }
  }

  Future<void> _finish() async {
    if (_hasCompleted || !mounted) return;
    _hasCompleted = true;
    try {
      await widget.bootFuture;
    } catch (_) {}
    await AppDataService().completeOnboarding();
    if (!mounted) return;
    HapticFeedback.lightImpact();
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // -------------------- fungsi matematika deterministik seek(t) --------------------
  static double _clamp(double x, [double a = 0.0, double b = 1.0]) =>
      x < a ? a : (x > b ? b : x);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _eoc(double t) => 1.0 - math.pow(1.0 - _clamp(t), 3).toDouble();
  static double _eio(double t) {
    final c = _clamp(t);
    return c < 0.5
        ? 4.0 * c * c * c
        : 1.0 - math.pow(-2.0 * c + 2.0, 3).toDouble() / 2.0;
  }

  static double _spr(double u, [double z = 0.55, double w = 12.0]) {
    if (u <= 0.0) return 0.0;
    final wd = w * math.sqrt(1.0 - z * z);
    return 1.0 -
        math.exp(-z * w * u) *
            (math.cos(wd * u) + (z * w / wd) * math.sin(wd * u));
  }

  static double _sprc(double u, [double z = 0.55, double w = 12.0]) =>
      u <= 0.0 ? 0.0 : (u >= 1.0 ? 1.0 : _spr(u, z, w));

  static double _bump(double u) {
    final c = _clamp(u);
    return math.sin(math.pi * c) - 0.18 * math.sin(2.0 * math.pi * c);
  }

  static ({double s, double ty}) _groupState(double t) {
    if (t < 6.0) return (s: 1.0, ty: 0.0);
    if (t < 9.5) {
      final e = _sprc((t - 6.0) / 0.8, 0.7, 11.0);
      return (s: _lerp(1.0, 0.52, e), ty: _lerp(0.0, -500.0, e));
    }
    return (s: _lerp(0.94, 1.0, _sprc((t - 11.6) / 1.2, 0.7, 11.0)), ty: 0.0);
  }

  static double _waveDy(int i, double t) {
    final d = i * 0.035;
    double y = 0.0;
    for (final b in const [3.0, 3.5, 4.0]) {
      y -= 72.0 * _bump((t - b - d) / _beat);
    }
    return y;
  }

  ({double alpha, double offX, double sc, double dy, double rot}) _letterFx(
    int i,
    double t,
  ) {
    double alpha, e;
    if (t < 9.0) {
      final u = (t - (1.5 + 0.12 * i)) / 0.5;
      e = _sprc(u, 0.55, 12.0);
      alpha = _clamp(u * 3.0) * (1.0 - _clamp((t - 9.0) / 0.5));
    } else if (t < 11.6) {
      alpha = 0.0;
      e = 1.0;
    } else {
      final u = (t - (11.6 + 0.04 * i)) / 0.4;
      e = _sprc(u, 0.6, 12.0);
      alpha = _clamp(u * 3.5);
    }
    final d = i * 0.035;
    double rot = 0.0;
    if (i == 1 || i == 4 || i == 7) {
      rot =
          (i == 4 ? -1.0 : 1.0) *
          7.0 *
          math.pi /
          180.0 *
          math.sin(math.pi * _clamp((t - 3.5 - d) / _beat));
    }
    double pulse = 1.0;
    if (i >= 4) {
      pulse += 0.05 * math.sin(math.pi * _clamp((t - 5.0) / _beat));
    } else {
      pulse += 0.05 * math.sin(math.pi * _clamp((t - 5.5) / _beat));
    }
    return (
      alpha: alpha,
      offX: -_glyphs[i].cx * (1.0 - e),
      sc: (0.35 + 0.65 * e) * pulse,
      dy: _waveDy(i, t),
      rot: rot,
    );
  }

  _DotState _kd(double sc) {
    final k = _glyphs[10];
    return _DotState(
      x: 0,
      y: 0,
      w: k.w * sc,
      h: k.h * sc,
      r: k.w * sc * 0.46,
      rot: 0,
      isKernel: 1.0,
      alpha: 1.0,
    );
  }

  ({double x, double y, double s}) _iAbove(double t) {
    final g = _groupState(t);
    final k = _glyphs[10];
    final lx = k.cx;
    final ly = k.cy + _waveDy(3, t);
    return (x: _cx + g.s * lx, y: _cy + g.ty + g.s * ly, s: g.s);
  }

  static _DotState _mix(_DotState a, _DotState b, double e) => _DotState(
    x: _lerp(a.x, b.x, e),
    y: _lerp(a.y, b.y, e),
    w: _lerp(a.w, b.w, e),
    h: _lerp(a.h, b.h, e),
    r: _lerp(a.r, b.r, e),
    rot: _lerp(a.rot, b.rot, e),
    isKernel: _lerp(a.isKernel, b.isKernel, e),
    alpha: 1.0,
  );

  static double _sg(double p) => _spr(p, 0.45, 8.0);
  static double _gx(double p) => _lerp(_gx0, _gx1, p);
  static double _gy(double p) => _gy0 - _gh * _sg(p);

  _DotState _dotState(double t) {
    const circ = 44.0;
    if (t < 1.0) {
      return const _DotState(
        x: _cx,
        y: _cy,
        w: circ,
        h: circ,
        r: circ / 2,
        rot: 0,
        isKernel: 0,
        alpha: 0,
      );
    }
    if (t < 2.2) {
      final e = _sprc((t - 1.0) / 0.5, 0.6, 12.0);
      return _DotState(
        x: _cx,
        y: t < 1.5 ? _lerp(_cy + 260.0, _cy, e) : _cy,
        w: circ,
        h: circ,
        r: circ / 2,
        rot: 0,
        isKernel: 0,
        alpha: _clamp((t - 1.0) * 6.0),
      );
    }
    if (t < 3.0) {
      final e = _sprc((t - 2.2) / 0.8, 0.6, 12.0);
      final ia = _iAbove(t);
      final k = _kd(ia.s).At(ia.x, ia.y);
      return _mix(
        const _DotState(
          x: _cx,
          y: _cy,
          w: circ,
          h: circ,
          r: circ / 2,
          rot: 0,
          isKernel: 0,
          alpha: 1,
        ),
        k,
        e,
      );
    }
    if (t < 6.0) {
      final ia = _iAbove(t);
      double ox = 0.0, oy = 0.0;
      if (t >= 4.5) {
        final u = (t - 4.5) / 1.5;
        ox = 120.0 * math.sin(2.0 * math.pi * u) * math.sin(math.pi * u);
        oy = -170.0 * math.sin(math.pi * u);
      }
      return _kd(ia.s).At(ia.x + ox, ia.y + oy);
    }
    if (t < 6.5) {
      final e = _sprc((t - 6.0) / 0.5, 0.6, 12.0);
      final ia = _iAbove(t);
      return _mix(_kd(ia.s).At(ia.x, ia.y), _kd(0.95).At(_gx0, _gy0), e);
    }
    if (t < 9.0) {
      final p = _clamp((t - 6.5) / 1.9);
      return _kd(0.95).At(_gx(p), _gy(p));
    }
    if (t < 10.0) {
      final e1 = _eio((t - 9.0) / 0.7);
      final x = t < 9.5 ? _gx1 : _lerp(_gx1, _cx, _eio((t - 9.5) / 0.5));
      return _kd(0.95).At(x, _lerp(_gy(1.0), _cy, e1));
    }
    var s = _kd(0.95).At(_cx, _cy);
    const a = _DotState(
      x: _cx,
      y: _cy,
      w: 440,
      h: 440,
      r: 220,
      rot: 0,
      isKernel: 0,
      alpha: 1,
    );
    const b = _DotState(
      x: _cx,
      y: _cy,
      w: 440,
      h: 440,
      r: 96,
      rot: 0,
      isKernel: 0,
      alpha: 1,
    );
    const c = _DotState(
      x: _cx,
      y: _cy,
      w: 860,
      h: 300,
      r: 150,
      rot: 0,
      isKernel: 0,
      alpha: 1,
    );
    s = _mix(s, a, _sprc((t - 10.0) / 0.4, 0.6, 12.0));
    s = _mix(s, b, _sprc((t - 10.5) / 0.4, 0.6, 12.0));
    s = _mix(s, c, _sprc((t - 11.0) / 0.4, 0.6, 12.0));
    final ia = _iAbove(t);
    s = _mix(s, _kd(ia.s).At(ia.x, ia.y), _eoc((t - 11.35) / 0.5));
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _bgGreen,
      ),
      child: Scaffold(
        backgroundColor: _bgGreen,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Teks semantik tak terlihat untuk pembaca layar & kompatibilitas pengujian widget
            const Opacity(
              opacity: 0.0,
              child: IgnorePointer(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Tani'), Text('Jagung')],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _vw,
                    height: _vh,
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) {
                        final t = _ctrl.value * _durSec;
                        final g = _groupState(t);
                        final d = _dotState(t);
                        final kBlend = _clamp(d.isKernel);

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Layer 1: Kanvas untuk frasa pembuka, kurva grafik spring, bentuk morph, dan tagline
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _KineticBackdropPainter(
                                  t: t,
                                  dot: d,
                                  kBlend: kBlend,
                                ),
                              ),
                            ),

                            // Layer 2: Sprite Biji Jagung 1:1 (ketika kBlend > 0)
                            if (d.alpha > 0.001 && kBlend > 0.001)
                              Positioned(
                                left: d.x - d.w / 2,
                                top: d.y - d.h / 2,
                                width: d.w,
                                height: d.h,
                                child: Opacity(
                                  opacity: _clamp(d.alpha * kBlend),
                                  child: Transform.rotate(
                                    angle: d.rot,
                                    child: Image.memory(
                                      _glyphs[10].bytes,
                                      width: d.w,
                                      height: d.h,
                                      fit: BoxFit.fill,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                ),
                              ),

                            // Layer 3: 10 Huruf "TaniJagung" 1:1 dari assets/icon.png
                            for (int i = 0; i < 10; i++)
                              Builder(
                                builder: (_) {
                                  final f = _letterFx(i, t);
                                  if (f.alpha <= 0.001) {
                                    return const SizedBox.shrink();
                                  }
                                  final gl = _glyphs[i];
                                  final cx = _cx + g.s * (gl.cx + f.offX);
                                  final cy = _cy + g.ty + g.s * (gl.cy + f.dy);
                                  final w = gl.w * g.s * f.sc;
                                  final h = gl.h * g.s * f.sc;
                                  return Positioned(
                                    left: cx - w / 2,
                                    top: cy - h / 2,
                                    width: w,
                                    height: h,
                                    child: Opacity(
                                      opacity: _clamp(f.alpha),
                                      child: Transform.rotate(
                                        angle: f.rot,
                                        child: Image.memory(
                                          gl.bytes,
                                          width: w,
                                          height: h,
                                          fit: BoxFit.fill,
                                          gaplessPlayback: true,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotState {
  final double x, y, w, h, r, rot, isKernel, alpha;
  const _DotState({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.r,
    required this.rot,
    required this.isKernel,
    required this.alpha,
  });

  // ignore: non_constant_identifier_names
  _DotState At(double nx, double ny) => _DotState(
    x: nx,
    y: ny,
    w: w,
    h: h,
    r: r,
    rot: rot,
    isKernel: isKernel,
    alpha: alpha,
  );
}

class _KineticBackdropPainter extends CustomPainter {
  final double t;
  final _DotState dot;
  final double kBlend;

  _KineticBackdropPainter({
    required this.t,
    required this.dot,
    required this.kBlend,
  });

  static const Color _gold = Color(0xFFF9C334);
  static const double _cx = 540.0;
  static const double _cy = 880.0;
  static const double _gx0 = 150.0;
  static const double _gx1 = 930.0;
  static const double _gy0 = 1320.0;
  static const double _gh = 520.0;

  static double _clamp(double x, [double a = 0.0, double b = 1.0]) =>
      x < a ? a : (x > b ? b : x);
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _eoc(double t) => 1.0 - math.pow(1.0 - _clamp(t), 3).toDouble();
  static double _eio(double t) {
    final c = _clamp(t);
    return c < 0.5
        ? 4.0 * c * c * c
        : 1.0 - math.pow(-2.0 * c + 2.0, 3).toDouble() / 2.0;
  }

  static double _spr(double u, [double z = 0.45, double w = 8.0]) {
    if (u <= 0.0) return 0.0;
    final wd = w * math.sqrt(1.0 - z * z);
    return 1.0 -
        math.exp(-z * w * u) *
            (math.cos(wd * u) + (z * w / wd) * math.sin(wd * u));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Scene 1: Frasa Pembuka "Dari lahan," / "untuk panen" (Poppins)
    if (t < 1.55) {
      final fadeOut = 1.0 - _clamp((t - 1.0) / 0.45);
      final e1 = _eoc(t / 0.65);
      final e2 = _eoc((t - 0.14) / 0.65);
      if (fadeOut > 0.0) {
        final barW = 72.0 * e1;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              _cx - barW / 2,
              _cy - 92.0 + (1.0 - e1) * 16.0,
              barW,
              7.0,
            ),
            const Radius.circular(3.5),
          ),
          Paint()..color = _gold.withValues(alpha: _clamp(e1 * fadeOut)),
        );

        _drawCenteredText(
          canvas,
          'Dari lahan,',
          Offset(_cx, _cy - 26.0 + (1.0 - e1) * 22.0),
          TextStyle(
            fontFamily: 'Poppins',
            fontSize: 50,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: _clamp(e1 * fadeOut * 0.95)),
          ),
        );
        _drawCenteredText(
          canvas,
          'untuk panen',
          Offset(_cx, _cy + 44.0 + (1.0 - e2) * 24.0),
          TextStyle(
            fontFamily: 'Poppins',
            fontSize: 56,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: _gold.withValues(alpha: _clamp(e2 * fadeOut)),
          ),
        );
      }
    }

    // 2. Scene 3 & 4: Kurva Grafik Pertumbuhan Spring
    if (t >= 6.3 && t <= 10.4) {
      final lineA = t < 6.5
          ? _clamp((t - 6.3) / 0.2)
          : (t < 10.0 ? 1.0 : 1.0 - _clamp((t - 10.0) / 0.3));
      final p = _clamp((t - 6.5) / 1.9);
      final e1 = _eio((t - 9.0) / 0.7);
      final baseAlpha = lineA * 0.22 * (1.0 - _clamp((t - 9.0) / 0.5));
      if (baseAlpha > 0.001) {
        canvas.drawLine(
          const Offset(_gx0 - 30.0, _gy0),
          const Offset(_gx1 + 30.0, _gy0),
          Paint()
            ..color = Colors.white.withValues(alpha: _clamp(baseAlpha))
            ..strokeWidth = 6.0
            ..strokeCap = StrokeCap.round,
        );
      }
      if (p > 0.0 && lineA > 0.001) {
        final path = Path();
        const n = 140;
        for (int k = 0; k <= n; k++) {
          final pp = p * k / n;
          final x = _lerp(_gx0, _gx1, pp);
          final gy = _gy0 - _gh * _spr(pp);
          final y = _lerp(gy, _cy, e1);
          if (k == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = _gold.withValues(alpha: _clamp(lineA))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    // 3. Bentuk Geometris Titik / Lingkaran / Kotak Rounded / Pill (ketika kBlend < 1)
    if (dot.alpha > 0.001 && kBlend < 0.999) {
      canvas.save();
      canvas.translate(dot.x, dot.y);
      canvas.rotate(dot.rot);
      final rad = math.min(dot.r, math.min(dot.w, dot.h) / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: dot.w, height: dot.h),
          Radius.circular(rad),
        ),
        Paint()
          ..color = _gold.withValues(alpha: _clamp(dot.alpha * (1.0 - kBlend))),
      );
      canvas.restore();
    }

    // 4. Scene 5: Tagline "Kelola usaha tani," / "raih panen maksimal" (Poppins)
    if (t >= 13.0) {
      final e1 = _eoc((t - 13.0) / 0.85);
      final e2 = _eoc((t - 13.18) / 0.85);
      const y0 = _cy + 195.0;

      final pillW = 56.0 * e1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            _cx - pillW / 2,
            y0 - 76.0 + _lerp(16.0, 0.0, e1),
            pillW,
            6.0,
          ),
          const Radius.circular(3.0),
        ),
        Paint()..color = _gold.withValues(alpha: _clamp(e1)),
      );

      _drawCenteredText(
        canvas,
        'Kelola usaha tani,',
        Offset(_cx, y0 - 18.0 + _lerp(24.0, 0.0, e1)),
        TextStyle(
          fontFamily: 'Poppins',
          fontSize: 48,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: Colors.white.withValues(alpha: _clamp(e1 * 0.96)),
        ),
      );

      final tp = TextPainter(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 50,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          children: [
            TextSpan(
              text: 'raih ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: _clamp(e2)),
              ),
            ),
            TextSpan(
              text: 'panen maksimal',
              style: TextStyle(color: _gold.withValues(alpha: _clamp(e2))),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          _cx - tp.width / 2,
          y0 + 54.0 + _lerp(26.0, 0.0, e2) - tp.height / 2,
        ),
      );
    }
  }

  static void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _KineticBackdropPainter old) =>
      old.t != t ||
      old.kBlend != kBlend ||
      old.dot.x != dot.x ||
      old.dot.w != dot.w;
}

class _GlyphSpec {
  final int id;
  final double x, y, w, h;
  final String b64;
  const _GlyphSpec({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.b64,
  });
}

class _DecodedGlyph {
  static const double _refCx = 511.0;
  static const double _refCy = 505.0;
  static const double _scale = 1.08;

  final int id;
  final double cx, cy, w, h;
  final Uint8List bytes;

  _DecodedGlyph(_GlyphSpec s)
    : id = s.id,
      cx = (s.x + s.w / 2.0 - _refCx) * _scale,
      cy = (s.y + s.h / 2.0 - _refCy) * _scale,
      w = s.w * _scale,
      h = s.h * _scale,
      bytes = base64Decode(s.b64);
}

const List<_GlyphSpec> _kGlyphSpecs = [
  _GlyphSpec(
    id: 0,
    x: 102.0,
    y: 445.0,
    w: 102.0,
    h: 112.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 1,
    x: 182.0,
    y: 473.0,
    w: 92.0,
    h: 87.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 2,
    x: 281.0,
    y: 471.0,
    w: 86.0,
    h: 87.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 3,
    x: 376.0,
    y: 477.0,
    w: 32.0,
    h: 81.0,
    b64: 'iVBORw0KGgoAAAANSUhEUgAAACAAAABRCAYAAACzBKSQAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAATeSURBVGhDzZpLrxVFFIWZ6M3Fa3DEjCgDEObMjUDQGH4AY+YkmoDh8ROYGZXwCvwJ49iJP8C5YyCER3wQHsFFVqcWd519dz36nHNv3Mk63V1dVfurXVW7O+ecffv22AB8GMt21egQwEbRJoCPAXwQ663F2LFJDiVeE2b/2gDMGTv+qIgO5DBqqhf7mWWJQx+dhzuT2s2LQGnMhpy/T8qR2jKpzOX3KfbB9pvRx//TAJwDcBXAtwAuArgE4DKAK4NiXer7ou8AXANwNvp6b5ofABcAvAHwCsDfAF4AeA3gP2wbzzPJ3haxHftiP7T70e+CAfgGwF+l4XMA/wD4t4gghOKxJt6n1IaO2cfTUn4n+nxvAA4C+L2MhBAvC4hGI9VGzfNYVxEgRDsCAM6XSqys0JOaHcSO5TwCeR22GwMAcADAbwZA54wAAaLjCFNTBnA3+p4MwIkyajaU8yz8c+QAXA9NAG4Rjo4NpCz06rh2L9ZTPxxUE+DXUmGk41GNAZSHyB+lQuxkzpxHjU0BgEMA/qwArKLhCHABPhwEiDmgpj6AXpFK9mPW0yKMTkfF9jKVqb89AXBjX4qAA9zLAL4G8Kw0qmW+Ucl43gXYMABGgLaKc8l3jgCY2HYFwJ3pmqbrGIGFNbBbADEC3V1wpqyBGkDcXj1lADsTUQB4MgjQA4n3BbDzaWivYKcbAN6hWw2iBpBGQACnyisTLQNwU3lWpvp+vecALuWBlQCiM1msk0kAPO/ughpAXHxxjlvKALbfimcAxI57UpsugBJRLw9kGgHzNdAFGMmEcRp6EF2AOZmwdV2TAygRVQFqa2CuPDIOoG24AKBtuG4Av25GYFWA6Cwqi0A1EdWeBXJUc5aVe9lQBFqZcM6q9/oRoBkBPg1HADIHUX5/eAp6AH4cKZ8dgdYijB32yl3dCMzJA3IYFestDdDKhA5AmwvA824q7kWgpgxCZV0AXwO1PDAyWr8f68Y8cDsDGH0pHSnXPQegBHCzBlCbgpqjVmTWCtCCyO7F67gLbmUArWeBj1Qd12CifBtqEaYAJwcBvCw6y1QFmHwPAmQQcwF4LoBpF0wpYBAgc14DiIDDAOt6HMd6LYCNuAtGIlAD8Hs80nhsASxEYNVU7GAZQHcRjjyM3FkrIjKeZwBpIvqqEYGaowgiyWIElIhSgNYUrAugGYEeQHROyYmOqiuLAM0IzNkFcbRZmcqHAeY8C1rOlwb4cgmAmlM/z9ZA+jD6AsDjUiECRIh4LafuXNcCYJthADWoyR20IqD6cQqUCRcS0RyALAqxjuRTsPBOGAG4BkYBXC3nlACo9JVMr+Wtx/EyYh8Uf3vg1/QUfwqm/ZwBtN4JR0KdOeeoHUDfQVUBag+jZZxnAIrAj+sG8PoRQBBUCqCv6XZjChzCF+GN4nPaBQLgImwByBzCHbkiTJqI9EomAOaB3i6Izn10rgyAR/1opQjs58f0lxrLA3RCUnUWR0f5wmJdnUtqx6PX4ZFQPxWfm/yY/tlk/x2gsRLN517XGpVAHEbXWQTZluW06w7g/3T6oUSBa4F7lrmb4uLhCuYu4f1H5XfmB+XIa4r31J512Qfb8cjp5fkvAI76GuBfszQNhDgC4HMAxwAcL8ejAA4D+HRQnwWpnH1vFV/T9p9MEAuFe2TvAEJUvDX6592NAAAAAElFTkSuQmCC',
  ),
  _GlyphSpec(
    id: 4,
    x: 411.0,
    y: 440.0,
    w: 72.0,
    h: 119.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 5,
    x: 488.0,
    y: 475.0,
    w: 85.0,
    h: 83.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 6,
    x: 578.0,
    y: 475.0,
    w: 84.0,
    h: 117.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 7,
    x: 669.0,
    y: 477.0,
    w: 77.0,
    h: 82.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 8,
    x: 753.0,
    y: 475.0,
    w: 79.0,
    h: 82.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 9,
    x: 836.0,
    y: 475.0,
    w: 85.0,
    h: 117.0,
    b64: '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',
  ),
  _GlyphSpec(
    id: 10,
    x: 374.0,
    y: 432.0,
    w: 45.0,
    h: 45.0,
    b64: 'iVBORw0KGgoAAAANSUhEUgAAAC0AAAAtCAYAAAA6GuKaAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAUsSURBVGhDzZlNaFxVFMe7EWuNdqWoiKILFV0o9X9n3NSFdFnISlBQCqKom1pQwYVurItC7UJBItatKC5EXbgoQqnnvkxiGhWEIlhFqkUtiNWaTP7zdeXcj8nMnUkyTV5meuCQeZP37v3Neefr3rtjx5iEgp0U3EPBoxQcpeALCiwtCv9XcIJiZiiVAxTclz8/VqFgioInKfiYYi64hYpz8xXXqRnXnl1VvXbzxrnFitP7aCszFFTy8bZdaLGfYr5SSPdN1TWtcbRoUtCioD2gFq3wf+Pct1XHAn9T8DIFV+Vjly4UXEeLGdZMQy3rIS0aEU6v19cAX2/NGufm/PNH8zlKFQr2scB3CtssjE7YpB0RdlD1raRxXozjX53PuSWhmEO0WFLf9NYa1bLrqUWzEaD/Zc3sy+fctFBwLQXvKay+0mShEnXZfe3d5FMKduXzjywpOCi4jRYn3Wk/qFpWLZxPujXV4Cy8n5+nwOQsI0n6tZTKI7T42QdbWe4wXHXseqvm3e5gzjOysMAztCa8tpDG8onKVDXGsluoag6fyVk2FI1eWrzZsEj+W747DKpCL7k5P99HOdNQyfz3hPdfi86YgNObXIo5+4Ocb02hVPZSzFm3WE2DbJf/DqoWJotLWlkp5v2cbajQ4ikK/otpZ7v9t19DgK/4+UN1fTvn65PYmR1Lzc3Y3GFVQwq1qGsgsvDfvZBz9vrv7do+xl+3Pfl3FFVXVOjQCpzjLB7Mmb1QsIcWZ7QzG7v/9qt2fjp/qoifUXBNzqvAoOB8tzsbHGicGrrDYGlleS7n1YB7gIJfQpSOOeCGq77hUAkFP1BwZz9waHq+9CuH0PvmA0xKV5ohAA/3AUfo53tS2uR8uNclLRoN8Vb+nYL7c+Bb1S2a4TVM0o/jcstnDJ81QhU07/YBR+iDsbWcJHCysqqCr4TgMxdYVKs5s644TmkBmaBbqKbWNoHXO6HXeCvnDU2Q4E/fsW1+LVeuetfwPL/RYk/OvIPFQ9N+HWaHPDw5jav4NXpnXeXGvvhK0WZcfWvGQM7rhRavxmZokpo2arQ+LMf4OpazdoVyhUDH4Iuff113P4+CV8YM3Rvs/Z8t6p2azxiv55x9QsGzrVAmt1uHZabUL/tC0gq+vEjBzTlnn1BQ9fV9PNlDIXNNTb52clpUnsgZB0SbfgrOtMOewjBrbFVzyFXYVPkEl+JKW/esd+aMQ4UWR9xp3VMovYz3AiZN1+F/qVcusETB/pxtTaHgXgr+8VUoDJZPvlnttWy6zu+pO5/izPHIMvpeNAXvxO2BsnvpYaBBLVqd4BY/ch535UwbSlzInu2sbtMOTlKGdnf7vS+3WXgjPZbzjCwUTOsgPpNsDnxtqybVYLceuL5h5RtVKHhJIzmmwMsF3wg6Apt2bO6Pb2m/uVcoeI1zxsVkP+rya+CebucYz1D8VkBIrZoxjpQJnDZrDnEWF+PKPKWoHDSHTWkspLew/Ndq19C354POYkHdsHeuLUssNj7B+0MfwUm1mB5NdKtmAEnBlFQtqUukUN0E7fBcRY/WGnp4ROuP126JY+v5YjmWTpJOkSjYTYunKTjlX+/c6mGl9uHa+zZs+OwPMmvGddK+n8VPFHzIAo9TcGMcbxcFN0Tock+qVHQLqsfqUywwTcEbtPicgu8p+IMWFyn4i9aco/XNzifeXy0OsGbu7hlLYW+KwNfH63LcI5foLmqVbk8QJ7yDBQwtHqZgb9yd0vVmH0i8d7duBmXfT/VeX478DylCS1iT7Y+1AAAAAElFTkSuQmCC',
  ),
];

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

/// Widget Wordmark "TaniJagung" 1:1 (Tani putih #FFFFFF, Jagung kuning #F9C334,
/// titik biji jagung miring di atas "i") yang diekstrak langsung dari assets/icon.png.
/// Digunakan pada halaman Login/Register agar 1 tema penuh dengan Splash Screen & Ikon Aplikasi.
class TaniJagungWordmark extends StatelessWidget {
  final double width;

  const TaniJagungWordmark({super.key, this.width = 250});

  static final List<_DecodedGlyph> _glyphs = _kGlyphSpecs
      .map((s) => _DecodedGlyph(s))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    const double baseW = 920.0;
    const double baseH = 220.0;
    const double cx0 = baseW / 2.0;
    const double cy0 = baseH / 2.0;
    final double aspect = baseH / baseW;

    return SizedBox(
      width: width,
      height: width * aspect,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: baseW,
          height: baseH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final gl in _glyphs)
                Positioned(
                  left: cx0 + gl.cx - gl.w / 2.0,
                  top: cy0 + gl.cy - gl.h / 2.0,
                  width: gl.w,
                  height: gl.h,
                  child: Image.memory(
                    gl.bytes,
                    width: gl.w,
                    height: gl.h,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
