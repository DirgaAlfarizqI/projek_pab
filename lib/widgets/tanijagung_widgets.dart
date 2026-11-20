import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// 1. Logo Jagung TaniJagung (Sesuai Gambar Referensi: Tongkol Jagung Emas + Daun Hijau Melengkung)
class CornBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSlogan;
  final bool lightText;

  const CornBrandLogo({
    super.key,
    this.size = 76,
    this.showText = false,
    this.showSlogan = false,
    this.lightText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _CornLogoPainter()),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(
                  text: 'Tani',
                  style: TextStyle(
                    color: lightText ? Colors.white : AppTheme.primaryDarkGreen,
                  ),
                ),
                const TextSpan(
                  text: 'Jagung',
                  style: TextStyle(color: AppTheme.cornYellow),
                ),
              ],
            ),
          ),
        ],
        if (showSlogan) ...[
          const SizedBox(height: 6),
          Text(
            'Kelola Usaha Tani, Raih Hasil Maksimal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: lightText
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _CornLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Lingkaran cahaya krem lembut di belakang
    final glowPaint = Paint()
      ..color = AppTheme.cornYellowLight.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.44, glowPaint);

    // Tongkol jagung emas di tengah
    final cobRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.44),
        width: w * 0.34,
        height: h * 0.58,
      ),
      Radius.circular(w * 0.17),
    );
    final cobPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(cobRect.outerRect);
    canvas.drawRRect(cobRect, cobPaint);

    // Biji-biji jagung (grid)
    final kernelPaint = Paint()
      ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 2; c++) {
        final kx = w * (0.43 + c * 0.14);
        final ky = h * (0.26 + r * 0.095);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(kx, ky),
              width: w * 0.09,
              height: h * 0.065,
            ),
            const Radius.circular(4),
          ),
          kernelPaint,
        );
      }
    }

    // Daun kiri melengkung
    final leftLeafPath = Path()
      ..moveTo(w * 0.5, h * 0.82)
      ..quadraticBezierTo(w * 0.12, h * 0.72, w * 0.16, h * 0.30)
      ..quadraticBezierTo(w * 0.36, h * 0.44, w * 0.5, h * 0.74)
      ..close();
    final leftLeafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.leafGreen, AppTheme.primaryDarkGreen],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(leftLeafPath, leftLeafPaint);

    // Daun kanan melengkung
    final rightLeafPath = Path()
      ..moveTo(w * 0.5, h * 0.82)
      ..quadraticBezierTo(w * 0.88, h * 0.72, w * 0.84, h * 0.30)
      ..quadraticBezierTo(w * 0.64, h * 0.44, w * 0.5, h * 0.74)
      ..close();
    final rightLeafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF43A047), AppTheme.primaryDarkGreen],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(rightLeafPath, rightLeafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Banner Ilustrasi Ladang Jagung (Digunakan pada Splash, Detail Lahan, Lahan Card, dan Footer Dekoratif)
class CornFieldIllustrationBanner extends StatelessWidget {
  final double height;
  final BorderRadius? borderRadius;
  final Widget? child;
  final bool showBigCornCob;

  const CornFieldIllustrationBanner({
    super.key,
    this.height = 160,
    this.borderRadius,
    this.child,
    this.showBigCornCob = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _CornFieldScenicPainter(showBigCornCob: showBigCornCob),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class _CornFieldScenicPainter extends CustomPainter {
  final bool showBigCornCob;
  _CornFieldScenicPainter({this.showBigCornCob = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Langit cerah gradasi biru-krem hangat
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF81D4FA), Color(0xFFE1F5FE), Color(0xFFFFF9C4)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Matahari lembut di kanan atas
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.25),
      h * 0.14,
      Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.8),
    );

    // Bukit hijau jauh
    final farHill = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.28, h * 0.42, w * 0.62, h * 0.56)
      ..quadraticBezierTo(w * 0.85, h * 0.45, w, h * 0.54)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(farHill, Paint()..color = const Color(0xFF66BB6A));

    // Bukit ladang jagung tengah
    final midHill = Path()
      ..moveTo(0, h * 0.68)
      ..quadraticBezierTo(w * 0.45, h * 0.54, w, h * 0.66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midHill, Paint()..color = const Color(0xFF2E7D32));

    // Barisan alur tanaman jagung perspektif
    final rowPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 7; i++) {
      final startX = w * (0.12 * i);
      final path = Path()
        ..moveTo(w * 0.5 + (startX - w * 0.5) * 0.25, h * 0.58)
        ..lineTo(startX, h);
      canvas.drawPath(path, rowPaint);
    }

    // Rumput/daun jagung bagian depan bawah
    final frontGrass = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.3, h * 0.74, w * 0.65, h * 0.84)
      ..quadraticBezierTo(w * 0.85, h * 0.78, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontGrass, Paint()..color = AppTheme.primaryDarkGreen);

    // Beberapa siluet tongkol jagung kuning di ladang
    final smallCobPaint = Paint()..color = AppTheme.cornYellow;
    for (int i = 0; i < 5; i++) {
      final cx = w * (0.15 + i * 0.18);
      final cy = h * (0.76 + (i.isEven ? 0.04 : -0.02));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: 7, height: 16),
          const Radius.circular(4),
        ),
        smallCobPaint,
      );
    }

    // Jika showBigCornCob (seperti pada Splash Screen kanan bawah)
    if (showBigCornCob) {
      final bigCobCenter = Offset(w * 0.77, h * 0.66);
      final bigCobRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: bigCobCenter,
          width: w * 0.22,
          height: h * 0.46,
        ),
        const Radius.circular(28),
      );
      canvas.drawRRect(
        bigCobRect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFE082), Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bigCobRect.outerRect),
      );
      // Daun pembungkus tongkol besar
      final huskPath = Path()
        ..moveTo(w * 0.77, h * 0.92)
        ..quadraticBezierTo(w * 0.58, h * 0.82, w * 0.62, h * 0.52)
        ..quadraticBezierTo(w * 0.70, h * 0.70, w * 0.77, h * 0.86)
        ..close();
      canvas.drawPath(huskPath, Paint()..color = const Color(0xFF43A047));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Ilustrasi Petani Modern (Untuk Onboarding & Avatar Profil sesuai Gambar Referensi)
class FarmerAvatarIllustration extends StatelessWidget {
  final double size;
  final bool withTablet;
  final String? customImagePath;
  final bool showEditBadge;

  const FarmerAvatarIllustration({
    super.key,
    this.size = 64,
    this.withTablet = false,
    this.customImagePath,
    this.showEditBadge = false,
  });

  bool _hasValidFile(String? path) {
    if (kIsWeb || path == null || path.trim().isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomPhoto = _hasValidFile(customImagePath);

    final avatarCircle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: AppTheme.cornYellow, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: hasCustomPhoto
          ? ClipOval(
              child: Image.file(
                File(customImagePath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildDefaultFarmerStack(),
              ),
            )
          : _buildDefaultFarmerStack(),
    );

    if (!showEditBadge) return avatarCircle;

    final badgeSize = (size * 0.34).clamp(22.0, 30.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarCircle,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: AppTheme.primaryDarkGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: badgeSize * 0.54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultFarmerStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Bahu / Kemeja Hijau Petani
        Positioned(
          bottom: size * 0.04,
          child: Container(
            width: size * 0.68,
            height: size * 0.34,
            decoration: BoxDecoration(
              color: AppTheme.leafGreen,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(size * 0.25),
              ),
            ),
          ),
        ),
        // Wajah Petani
        Positioned(
          top: size * 0.26,
          child: Container(
            width: size * 0.34,
            height: size * 0.36,
            decoration: const BoxDecoration(
              color: Color(0xFFE0AC69),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Topi Caping / Topi Jerami Kuning Petani
        Positioned(
          top: size * 0.14,
          child: Container(
            width: size * 0.62,
            height: size * 0.14,
            decoration: BoxDecoration(
              color: AppTheme.cornYellow,
              borderRadius: BorderRadius.circular(size * 0.1),
            ),
          ),
        ),
        Positioned(
          top: size * 0.06,
          child: Container(
            width: size * 0.36,
            height: size * 0.14,
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(size * 0.12),
              ),
            ),
          ),
        ),
        if (withTablet)
          Positioned(
            bottom: size * 0.10,
            right: size * 0.14,
            child: Container(
              width: size * 0.26,
              height: size * 0.20,
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

/// 4. Segmented Tab Switcher Pill (Hijau Tua vs Putih/Abu seperti pada halaman Benih/Pupuk, Prediksi/Analisis, Ringkasan/Detail)
class PillSegmentedSwitch extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const PillSegmentedSwitch({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8DF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selectedIndex == 0
                      ? AppTheme.primaryDarkGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  leftLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selectedIndex == 0
                        ? Colors.white
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selectedIndex == 1
                      ? AppTheme.primaryDarkGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  rightLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selectedIndex == 1
                        ? Colors.white
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. Spacer Bersih Bawah Halaman (Menggantikan dekorasi daun agar mematuhi prinsip Simple But Modern & tanpa dekorasi pengganggu)
class BottomCornLeavesDecoration extends StatelessWidget {
  const BottomCornLeavesDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 8);
  }
}
