import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_data_service.dart';
import '../widgets/tanijagung_widgets.dart';

/// Backward compatibility alias agar referensi lama tetap aman
class CornLogoWidget extends StatelessWidget {
  final double size;
  final bool lightMode;
  const CornLogoWidget({super.key, this.size = 64, this.lightMode = false});

  @override
  Widget build(BuildContext context) {
    return CornBrandLogo(size: size, lightText: lightMode);
  }
}

/// 1. SPLASH SCREEN / WELCOME SCREEN "TaniJagung" (Animasi Intro Otomatis 3.5 Detik)
/// Urutan Animasi:
/// 1. Langit & latar muncul dengan fade-in halus.
/// 2. Matahari naik perlahan dari bawah ke posisinya sambil fade-in.
/// 3. Lapisan bukit hijau menggeser naik satu per satu (parallax ringan dari belakang ke depan).
/// 4. Karakter petani dalam lingkaran muncul dengan efek pop/scale (Curves.elasticOut).
/// 5. Jagung-jagung kecil tumbuh dari bawah lalu bergoyang pelan seperti tertiup angin.
/// 6. Judul "TaniJagung" muncul dengan animasi fade-up ("Tani" lalu "Jagung" menyusul).
/// 7. Indikator loading tipis/halus di bagian bawah, tanpa tombol atau interaksi apa pun.
class SplashScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  const SplashScreen({super.key, this.onCompleted});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _swayCtrl;
  Timer? _finishTimer;
  bool _hasCompleted = false;

  late final Animation<double> _skyFade;
  late final Animation<double> _sunProgress;
  late final Animation<double> _farHillProgress;
  late final Animation<double> _midHillProgress;
  late final Animation<double> _frontHillProgress;
  late final Animation<double> _farmerScale;
  late final Animation<double> _cornGrowProgress;
  late final Animation<double> _taniTextProgress;
  late final Animation<double> _jagungTextProgress;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _swayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _skyFade = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );

    _sunProgress = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.10, 0.38, curve: Curves.easeOutCubic),
    );

    _farHillProgress = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.18, 0.45, curve: Curves.easeOutCubic),
    );

    _midHillProgress = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.26, 0.54, curve: Curves.easeOutCubic),
    );

    _frontHillProgress = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.34, 0.62, curve: Curves.easeOutCubic),
    );

    _farmerScale = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.45, 0.78, curve: Curves.elasticOut),
    );

    _cornGrowProgress = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.54, 0.82, curve: Curves.easeOutBack),
    );

    _taniTextProgress = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.66, 0.88, curve: Curves.easeOutCubic),
    );

    _jagungTextProgress = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.75, 0.96, curve: Curves.easeOutCubic),
    );

    _loaderFade = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
    );

    _introCtrl.forward();

    _introCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishTimer = Timer(const Duration(milliseconds: 500), _triggerFinish);
      }
    });
  }

  Future<void> _triggerFinish() async {
    if (_hasCompleted || !mounted) return;
    _hasCompleted = true;
    await AppDataService().completeOnboarding();
    if (!mounted) return;
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _introCtrl.dispose();
    _swayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_introCtrl, _swayCtrl]),
          builder: (context, _) {
            final swayAngle = math.sin(_swayCtrl.value * math.pi * 2) * 0.08;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  // Bagian Ilustrasi Ladang, Langit, Matahari, Bukit Parallax, Jagung Bergoyang & Karakter Petani
                  Expanded(
                    flex: 6,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _AnimatedWelcomeScenePainter(
                                skyFade: _skyFade.value,
                                sunProgress: _sunProgress.value,
                                farHillProgress: _farHillProgress.value,
                                midHillProgress: _midHillProgress.value,
                                frontHillProgress: _frontHillProgress.value,
                                cornGrowProgress: _cornGrowProgress.value.clamp(
                                  0.0,
                                  1.2,
                                ),
                                swayAngle: swayAngle,
                              ),
                            ),
                            Align(
                              alignment: const Alignment(0, 0.55),
                              child: Transform.scale(
                                scale: _farmerScale.value.clamp(0.0, 1.3),
                                child: const FarmerAvatarIllustration(
                                  size: 136,
                                  withTablet: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Judul "TaniJagung" dengan animasi Fade-Up ("Tani" lalu "Jagung" menyusul)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: _taniTextProgress.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (1 - _taniTextProgress.value) * 20),
                          child: const Text(
                            'Tani',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryDarkGreen,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _jagungTextProgress.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            (1 - _jagungTextProgress.value) * 20,
                          ),
                          child: const Text(
                            'Jagung',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryGreen,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),

                  // Indikator Loading Tipis/Halus di Bagian Bawah (Tanpa Tombol)
                  Opacity(
                    opacity: _loaderFade.value.clamp(0.0, 1.0),
                    child: SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _introCtrl.value,
                          minHeight: 4,
                          backgroundColor: AppTheme.lightGreen,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedWelcomeScenePainter extends CustomPainter {
  final double skyFade;
  final double sunProgress;
  final double farHillProgress;
  final double midHillProgress;
  final double frontHillProgress;
  final double cornGrowProgress;
  final double swayAngle;

  _AnimatedWelcomeScenePainter({
    required this.skyFade,
    required this.sunProgress,
    required this.farHillProgress,
    required this.midHillProgress,
    required this.frontHillProgress,
    required this.cornGrowProgress,
    required this.swayAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Langit cerah gradasi biru-krem dengan fade-in
    if (skyFade > 0) {
      final skyPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF81D4FA).withValues(alpha: skyFade),
            const Color(0xFFE1F5FE).withValues(alpha: skyFade),
            const Color(0xFFFFF9C4).withValues(alpha: skyFade),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.68));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);
    }

    // 2. Matahari naik perlahan dari bawah ke posisinya sambil fade-in
    if (sunProgress > 0) {
      final sunY = h * (0.55 - (0.31 * sunProgress));
      canvas.drawCircle(
        Offset(w * 0.78, sunY),
        h * 0.12,
        Paint()
          ..color = const Color(0xFFFFF59D)
              .withValues(alpha: (0.88 * sunProgress).clamp(0.0, 1.0)),
      );
    }

    // 3a. Bukit hijau jauh (Parallax lapisan belakang)
    if (farHillProgress > 0) {
      final dy = (1 - farHillProgress) * h * 0.35;
      canvas.save();
      canvas.translate(0, dy);
      final farHill = Path()
        ..moveTo(0, h * 0.60)
        ..quadraticBezierTo(w * 0.28, h * 0.42, w * 0.62, h * 0.55)
        ..quadraticBezierTo(w * 0.85, h * 0.45, w, h * 0.53)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(farHill, Paint()..color = const Color(0xFF66BB6A));
      canvas.restore();
    }

    // 3b. Bukit tengah + alur tanaman (Parallax lapisan tengah)
    if (midHillProgress > 0) {
      final dy = (1 - midHillProgress) * h * 0.38;
      canvas.save();
      canvas.translate(0, dy);
      final midHill = Path()
        ..moveTo(0, h * 0.68)
        ..quadraticBezierTo(w * 0.45, h * 0.53, w, h * 0.66)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(midHill, Paint()..color = const Color(0xFF2E7D32));

      final rowPaint = Paint()
        ..color = const Color(0xFF81C784).withValues(alpha: 0.55)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      for (int i = 1; i <= 7; i++) {
        final startX = w * (0.12 * i);
        final path = Path()
          ..moveTo(w * 0.5 + (startX - w * 0.5) * 0.25, h * 0.58)
          ..lineTo(startX, h);
        canvas.drawPath(path, rowPaint);
      }
      canvas.restore();
    }

    // 3c. Bukit depan bawah (Parallax lapisan depan)
    if (frontHillProgress > 0) {
      final dy = (1 - frontHillProgress) * h * 0.40;
      canvas.save();
      canvas.translate(0, dy);
      final frontGrass = Path()
        ..moveTo(0, h * 0.82)
        ..quadraticBezierTo(w * 0.3, h * 0.73, w * 0.65, h * 0.83)
        ..quadraticBezierTo(w * 0.85, h * 0.77, w, h * 0.79)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(frontGrass, Paint()..color = AppTheme.primaryDarkGreen);
      canvas.restore();
    }

    // 5. Jagung-jagung kecil tumbuh dari bawah lalu bergoyang pelan
    if (cornGrowProgress > 0) {
      final smallCobPaint = Paint()..color = AppTheme.cornYellow;
      final leafPaint = Paint()..color = const Color(0xFF81C784);
      for (int i = 0; i < 5; i++) {
        final cx = w * (0.14 + i * 0.18);
        final baseCy = h * (0.76 + (i.isEven ? 0.04 : -0.02));
        final scale = cornGrowProgress.clamp(0.0, 1.15);

        canvas.save();
        canvas.translate(cx, baseCy + 10);
        canvas.rotate(swayAngle * (i.isEven ? 1 : -1));
        canvas.scale(scale, scale);

        // Daun kecil penyangga jagung
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(-4, -5), width: 6, height: 12),
          leafPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(4, -5), width: 6, height: 12),
          leafPaint,
        );

        // Tongkol jagung kuning kecil
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(0, -10), width: 8, height: 18),
            const Radius.circular(4),
          ),
          smallCobPaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedWelcomeScenePainter oldDelegate) {
    return oldDelegate.skyFade != skyFade ||
        oldDelegate.sunProgress != sunProgress ||
        oldDelegate.farHillProgress != farHillProgress ||
        oldDelegate.midHillProgress != midHillProgress ||
        oldDelegate.frontHillProgress != frontHillProgress ||
        oldDelegate.cornGrowProgress != cornGrowProgress ||
        oldDelegate.swayAngle != swayAngle;
  }
}

/// 2. ONBOARDING SCREEN (Tetap mengarah ke SplashScreen animasi otomatis agar alur lama tetap kompatibel)
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

/// 3. LOGIN DAN REGISTER SCREEN
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _loadDemoData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController(
    text: 'Usaha Tani Jagung Mandiri',
  );
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final service = AppDataService();
    String? err;
    if (_isLogin) {
      err = await service.login(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    } else {
      err = await service.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        farmBusinessName: _businessCtrl.text,
        loadLabeledDemoData: _loadDemoData,
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CornBrandLogo(size: 82, showText: true),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin
                          ? 'Masuk untuk melanjutkan'
                          : 'Daftar akun petani baru',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dangerRed),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.dangerRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!_isLogin) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nama Lengkap Petani',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Budi Santoso',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama lengkap wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nama Usaha Tani (Opsional)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _businessCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Usaha Tani Jagung Mandiri',
                          prefixIcon: Icon(Icons.agriculture_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan email (misal: budi@email.com)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@') || !v.contains('.'))
                          ? 'Masukkan alamat email yang valid'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Masukkan password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password minimal 6 karakter'
                          : null,
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _loadDemoData,
                        onChanged: (val) =>
                            setState(() => _loadDemoData = val ?? false),
                        title: const Text(
                          'Muat Data Contoh',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Memudahkan melihat simulasi fitur (dapat dihapus kapan saja).',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ] else ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Gunakan email & password yang didaftarkan pada perangkat ini atau daftar akun baru.',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDarkGreen,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: Text(
                          _isSubmitting
                              ? 'Memproses...'
                              : (_isLogin ? 'Masuk' : 'Daftar Akun'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isLogin ? 'Daftar Akun' : 'Sudah Punya Akun? Masuk',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const BottomCornLeavesDecoration(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
