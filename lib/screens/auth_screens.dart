import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_data_service.dart';
import '../widgets/tanijagung_widgets.dart';
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
