import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/theme/app_theme.dart';
import '../models/app_models.dart';
import '../services/app_data_service.dart';
import '../widgets/tanijagung_widgets.dart';
import '../widgets/ui_kit.dart';
import 'expenses_screen.dart';
import 'harvest_input_screen.dart';
import 'inventory_screen.dart';
import 'profit_simulation_screen.dart';
import 'reports_screen.dart';
import 'scheduled_reminders_screen.dart';
import 'seed_fertilizer_screen.dart';

/// HALAMAN 17: PROFIL & PENGATURAN
/// - Header Profil: Avatar Ilustrasi Petani bertopi jerami di sebelah kiri + Nama Pengguna & Email di sebelah kanan
/// - Kartu Daftar Menu:
///   1. Pengaturan Akun > (Tanpa URL Backend FastAPI)
///   2. Notifikasi > (Halaman Pengingat Jadwal Buatan Pengguna)
///   3. Satuan > (Pengaturan Satuan Luas Lahan & Berat Hasil Panen dengan penjelasan lengkap)
///   4. Tentang Aplikasi >
/// - Akses Modul Lengkap Usaha Tani (Input Benih & Pupuk, Stok Pupuk, Pengeluaran, Panen, Simulasi, Laporan PDF)
/// - Tombol Logout Merah Salmon Penuh ("Logout")
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final user = service.currentUser!;
        final activeRemindersCount = service.scheduledReminders
            .where((r) => r.isEnabled)
            .length;

        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: ResponsiveCenter(
            maxWidth: 760,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header Avatar Petani (Bisa Diketuk untuk Ganti Foto Profil) + Nama & Email
                StaggeredEntrance(
                  index: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showProfilePhotoOptions(context, user),
                          child: FarmerAvatarIllustration(
                            size: 84,
                            customImagePath: user.profilePhotoPath,
                            showEditBadge: true,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontFamily: AppTheme.headingFont,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.farmBusinessName,
                                style: const TextStyle(
                                  fontFamily: AppTheme.headingFont,
                                  fontSize: 12.5,
                                  color: AppTheme.primaryDarkGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4 Menu Utama Pengaturan
                StaggeredEntrance(
                  index: 1,
                  child: SoftCard(
                    radius: AppRadius.xl,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        _ProfileMenuTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Pengaturan Akun',
                          subtitle: 'Nama pengguna, usaha tani & nomor telepon',
                          onTap: () => _showAccountSettingsSheet(context),
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifikasi',
                          subtitle:
                              'Pengingat jadwal kegiatan ($activeRemindersCount jadwal aktif)',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ScheduledRemindersScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon: Icons.straighten_rounded,
                          title: 'Satuan',
                          subtitle:
                              'Luas: ${user.preferredAreaUnit} • Panen: ${user.preferredWeightUnit} • Mata Uang: Rp',
                          onTap: () => _showUnitSettingsSheet(context),
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Tentang Aplikasi',
                          subtitle: 'TaniJagung v1.0.0 • Kelola Usaha Tani, Raih Hasil Maksimal',
                          onTap: () => _showAboutAppDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pintasan Seluruh Halaman Fungsional TaniJagung
                StaggeredEntrance(
                  index: 2,
                  child: SoftCard(
                    radius: AppRadius.xl,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        _ProfileMenuTile(
                          icon: Icons.grain_rounded,
                          title: 'Input Benih & Pupuk',
                          subtitle:
                              'Pencatatan pembelian & pemakaian benih/pupuk',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SeedFertilizerScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon: Icons.inventory_2_outlined,
                          title: 'Stok Pupuk',
                          subtitle: 'Stok tersedia per jenis pupuk & peringatan batas minimum',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InventoryScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'Daftar Pengeluaran',
                          subtitle: '5 kategori biaya operasional & integrasi stok pupuk',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpensesScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon: Icons.scale_outlined,
                          title: 'Input Hasil Panen',
                          subtitle: 'Konversi otomatis ton ke kg & pendapatan',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HarvestInputScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon: Icons.calculate_outlined,
                          title: 'Simulasi Keuntungan',
                          subtitle:
                              'Simulasi pendapatan, laba/rugi & harga impas',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfitSimulationScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        _ProfileMenuTile(
                          icon: Icons.picture_as_pdf_outlined,
                          title: 'Riwayat & Laporan PDF',
                          subtitle:
                              'Filter tahun, lahan, perbandingan & Export PDF',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Logout Merah Salmon Penuh
                StaggeredEntrance(
                  index: 3,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.salmonLogout,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () => service.logout(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const BottomCornLeavesDecoration(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndSaveProfilePhoto(
    BuildContext context,
    UserModel user,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }

      String savedPath = picked.path;
      if (!kIsWeb) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final profileDir = Directory('${appDir.path}/tanijagung_profiles');
          if (!await profileDir.exists()) {
            await profileDir.create(recursive: true);
          }
          final ext = picked.path.contains('.')
              ? picked.path.split('.').last
              : 'jpg';
          final fileName =
              'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final copied = await File(picked.path)
              .copy('${profileDir.path}/$fileName');
          savedPath = copied.path;
        } catch (_) {
          savedPath = picked.path;
        }
      }

      await AppDataService().updateUserProfile(
        user.copyWith(profilePhotoPath: savedPath),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui.')),
        );
      }
    } on PlatformException catch (e) {
      String msg = 'Gagal mengakses kamera atau galeri.';
      final code = e.code.toLowerCase();
      if (code.contains('denied') || code.contains('permission')) {
        msg = 'Izin kamera/galeri ditolak. Silakan aktifkan izin di Pengaturan perangkat Anda.';
      } else if (code.contains('camera_access') ||
          code.contains('no_available_camera')) {
        msg = 'Kamera tidak tersedia pada perangkat ini.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        msg = e.message!;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat memilih foto profil.'),
          ),
        );
      }
    }
  }

  void _showProfilePhotoOptions(BuildContext context, UserModel user) {
    final hasCustomPhoto =
        user.profilePhotoPath != null &&
        user.profilePhotoPath!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ganti Foto Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppTheme.darkGreen,
                  ),
                ),
                title: const Text(
                  'Ambil dari Kamera',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSaveProfilePhoto(context, user, ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppTheme.darkGreen,
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSaveProfilePhoto(context, user, ImageSource.gallery);
                },
              ),
              if (hasCustomPhoto)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.dangerLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.dangerRed,
                    ),
                  ),
                  title: const Text(
                    'Hapus Foto / Kembali ke Default',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.dangerRed,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await AppDataService().updateUserProfile(
                      user.copyWith(clearProfilePhoto: true),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Foto profil dikembalikan ke avatar default.',
                          ),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// REVISI 3: Hapus field "URL Backend Prediksi FastAPI" dari Pengaturan Akun.
  /// Hanya menyisakan Nama Pengguna, Nama Usaha Tani Jagung, Nomor Telepon, tombol "Muat Data Contoh", dan "Simpan Akun".
  void _showAccountSettingsSheet(BuildContext context) {
    final service = AppDataService();
    final user = service.currentUser!;
    final nameCtrl = TextEditingController(text: user.name);
    final businessCtrl = TextEditingController(text: user.farmBusinessName);
    final phoneCtrl = TextEditingController(text: user.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengaturan Akun',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Pengguna'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: businessCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Usaha Tani Jagung',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await service.seedLabeledDemoDataForCurrentUser();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Muat Data Contoh'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await service.updateUserProfile(
                          user.copyWith(
                            name: nameCtrl.text.trim(),
                            farmBusinessName: businessCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                          ),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Simpan Akun'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// REVISI 5: Pengaturan Satuan dengan penjelasan singkat & terhubung ke tampilan Beranda, Lahan, Analisis, dan Laporan.
  void _showUnitSettingsSheet(BuildContext context) {
    final service = AppDataService();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final user = service.currentUser!;
          return Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengaturan Satuan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Atur satuan tampilan utama untuk luas lahan (Hektare / m²) dan berat hasil panen (Ton / Kilogram / Kuintal). Pilihan Anda otomatis diterapkan pada halaman Beranda, Lahan, Analisis Keuangan, dan Laporan.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: user.preferredAreaUnit,
                  decoration: const InputDecoration(
                    labelText: 'Satuan Luas Lahan',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'hektare',
                      child: Text('Hektare (Ha)'),
                    ),
                    DropdownMenuItem(
                      value: 'm²',
                      child: Text('Meter Persegi (m²)'),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v != null) {
                      await service.updateUserProfile(
                        user.copyWith(preferredAreaUnit: v),
                      );
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: user.preferredWeightUnit,
                  decoration: const InputDecoration(
                    labelText: 'Satuan Berat Hasil Panen',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ton', child: Text('Ton')),
                    DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                    DropdownMenuItem(
                      value: 'kuintal',
                      child: Text('Kuintal (kw)'),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v != null) {
                      await service.updateUserProfile(
                        user.copyWith(preferredWeightUnit: v),
                      );
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Selesai'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            CornBrandLogo(size: 38),
            SizedBox(width: 10),
            Text('TaniJagung'),
          ],
        ),
        content: const Text(
          'TaniJagung v1.0.0\n\n'
          'Slogan: Kelola Usaha Tani, Raih Hasil Maksimal.\n\n'
          'Aplikasi manajemen lahan pertanian jagung, pencatatan musim tanam, penggunaan benih & pupuk, stok pupuk terintegrasi dengan pengeluaran, pengingat jadwal kegiatan lokal, analisis keuangan usaha tani, simulasi keuntungan, serta ekspor laporan PDF.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryDarkGreen, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
