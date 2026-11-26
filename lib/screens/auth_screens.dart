import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../services/app_data_service.dart';
import '../widgets/tanijagung_widgets.dart';
import '../widgets/ui_kit.dart';
import 'splash_screen.dart';

export 'splash_screen.dart';

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

/// 2. ONBOARDING SCREEN (Tetap mengarah ke SplashScreen animasi otomatis agar alur lama tetap kompatibel)
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

/// =====================================================================
/// 3. HALAMAN MASUK & DAFTAR (1 Tema Terpadu dengan Ikon & Splash Screen)
/// =====================================================================
/// - Header hijau hutan pekat (#0E442E) dengan Wordmark "TaniJagung" 1:1
///   ("Tani" putih #FFFFFF, "Jagung" kuning #F9C334, titik biji jagung di atas "i")
///   TANPA ikon/ilustrasi jagung terpisah.
/// - Garis aksen pill kuning emas (#F9C334) & tagline Poppins.
/// - Kartu form modern membulat 28 px dengan animasi masuk bertahap.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color _brandGreen = Color(0xFF0E442E);
  static const Color _brandGold = Color(0xFFF9C334);

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _brandGreen,
      ),
      child: Scaffold(
        backgroundColor: _brandGreen,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Header Identitas Brand 1:1 (Sama Persis dengan Ikon & Splash Screen)
                    StaggeredEntrance(
                      index: 0,
                      child: Column(
                        children: [
                          const TaniJagungWordmark(width: 248),
                          const SizedBox(height: 10),
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _brandGold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                                height: 1.45,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Kelola usaha tani, ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                                const TextSpan(
                                  text: 'raih panen maksimal',
                                  style: TextStyle(
                                    color: _brandGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // 2. Kartu Form Masuk / Daftar Modern
                    StaggeredEntrance(
                      index: 1,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _brandGold,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _isLogin
                                          ? 'Masuk ke Akun Anda'
                                          : 'Daftar Akun Petani Baru',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.headingFont,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  _isLogin
                                      ? 'Silakan masuk untuk mengelola lahan & panen jagung Anda'
                                      : 'Lengkapi data di bawah untuk mulai mencatat usaha tani',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (_errorMessage != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.dangerRed,
                                    ),
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
                                const _AuthFieldLabel('Nama Lengkap Petani'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Contoh: Budi Santoso',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Nama lengkap wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                const _AuthFieldLabel(
                                  'Nama Usaha Tani (Opsional)',
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _businessCtrl,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Contoh: Usaha Tani Jagung Mandiri',
                                    prefixIcon: Icon(
                                      Icons.agriculture_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              const _AuthFieldLabel('Email'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'Masukkan email (budi@email.com)',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) =>
                                    (v == null ||
                                        !v.contains('@') ||
                                        !v.contains('.'))
                                    ? 'Masukkan alamat email yang valid'
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              const _AuthFieldLabel('Password'),
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
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                                  onChanged: (val) => setState(
                                    () => _loadDemoData = val ?? false,
                                  ),
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                        color: _brandGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                    ),
                                  ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'atau',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.8),
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
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _brandGreen,
                                    side: BorderSide(
                                      color: _brandGreen.withValues(
                                        alpha: 0.28,
                                      ),
                                      width: 1.4,
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _errorMessage = null;
                                    });
                                  },
                                  child: Text(
                                    _isLogin
                                        ? 'Daftar Akun'
                                        : 'Sudah Punya Akun? Masuk',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _AuthFieldLabel extends StatelessWidget {
  final String text;
  const _AuthFieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTheme.headingFont,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
