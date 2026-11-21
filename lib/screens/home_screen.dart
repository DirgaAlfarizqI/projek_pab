import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_models.dart';
import '../services/app_data_service.dart';
import '../widgets/app_form_dialogs.dart';
import '../widgets/tanijagung_widgets.dart';
import 'expenses_screen.dart';
import 'harvest_input_screen.dart';
import 'plots_screen.dart';
import 'scheduled_reminders_screen.dart';

/// BERANDA (Master Prompt Final — Simple But Modern)
/// Menampilkan:
/// - Sapaan pengguna
/// - Kartu Dashboard Keuangan Reaktif (Modal Awal dapat diedit langsung, Total Pendapatan, Total Pengeluaran, Status Belum Panen / Untung / Rugi)
/// - Informasi musim tanam aktif & jumlah lahan (mengikuti satuan pilihan pengguna)
/// - Akses cepat: Tambah Lahan, Catat Pengeluaran, Input Hasil Panen
/// - Aktivitas & Pengingat Jadwal terdekat
class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final user = service.currentUser!;
        final plots = service.plots;
        final activeCycles = service.activeCycles;
        final allCycles = service.cycles;

        final primaryCycle = activeCycles.isNotEmpty
            ? activeCycles.first
            : (allCycles.isNotEmpty ? allCycles.first : null);

        final initialCapital = service.effectiveInitialCapital;
        final totalAllExpenses = service.totalAllCyclesExpenses;
        final totalRevenue = service.totalRecordedRevenue;
        final hasHarvest = service.hasAnyHarvestData;
        final overallProfitLoss = service.totalOverallProfitOrLoss;

        // Logika Status Revisi 2c:
        // Status "Rugi" TIDAK boleh muncul hanya karena ada pengeluaran sebelum data panen dimasukkan.
        final String statusBadgeText;
        final Color statusBadgeBgColor;
        final Color statusBadgeTextColor;

        if (!hasHarvest) {
          statusBadgeText = 'Belum Panen';
          statusBadgeBgColor = AppTheme.cornYellow;
          statusBadgeTextColor = AppTheme.textPrimary;
        } else if (overallProfitLoss >= 0) {
          statusBadgeText = 'Untung';
          statusBadgeBgColor = const Color(0xFF4ADE80);
          statusBadgeTextColor = AppTheme.darkGreen;
        } else {
          statusBadgeText = 'Rugi';
          statusBadgeBgColor = AppTheme.dangerRed;
          statusBadgeTextColor = Colors.white;
        }

        // Gabungkan aktivitas kalender yang belum selesai & pengingat jadwal aktif untuk "Aktivitas Terdekat"
        final upcomingItems = <_UpcomingScheduleItem>[];

        for (final act in service.activities.where((a) => !a.isCompleted)) {
          upcomingItems.add(
            _UpcomingScheduleItem(
              title: act.name,
              subtitle: '${AppFormatters.date(act.date)} • ${act.activityType}',
              dateTime: act.date,
              isReminder: false,
            ),
          );
        }

        for (final ScheduledReminderModel rem
            in service.scheduledReminders.where((r) => r.isEnabled)) {
          final nextDt = rem.nextOccurrence;
          final plot = rem.plotId != null
              ? service.getPlotById(rem.plotId!)
              : null;
          final timeStr =
              '${nextDt.hour.toString().padLeft(2, '0')}:${nextDt.minute.toString().padLeft(2, '0')}';
          upcomingItems.add(
            _UpcomingScheduleItem(
              title:
                  '${rem.activityType}${plot != null ? " (${plot.name})" : ""}',
              subtitle:
                  '${AppFormatters.date(nextDt)} • $timeStr • Pengingat ${rem.repeatType}',
              dateTime: nextDt,
              isReminder: true,
            ),
          );
        }

        upcomingItems.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final nearestSchedule = upcomingItems.isNotEmpty
            ? upcomingItems.first
            : null;

        final notifications = service.generatedNotifications;

        return Scaffold(
          backgroundColor: AppTheme.creamBackground,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => service.initialize(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // 1. Header Sapaan Pengguna
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => onNavigateTab(4),
                        child: FarmerAvatarIllustration(
                          size: 46,
                          customImagePath: user.profilePhotoPath,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user.name}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.farmBusinessName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notifikasi & Pengingat',
                        onPressed: () =>
                            _showNotificationsSheet(context, notifications),
                        icon: Badge(
                          isLabelVisible: notifications.isNotEmpty,
                          label: Text('${notifications.length}'),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Hero Card Keuangan Modern (Reaktif + Input Modal Awal + Logika Belum Panen / Untung / Rugi)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onNavigateTab(3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      hasHarvest
                                          ? (overallProfitLoss >= 0
                                                ? 'Keuntungan Bersih'
                                                : 'Kerugian Bersih')
                                          : 'Total Pengeluaran',
                                      style: const TextStyle(
                                        color: Color(0xFFD9ECE0),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBadgeBgColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusBadgeText,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: statusBadgeTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasHarvest
                                    ? AppFormatters.currency(overallProfitLoss)
                                    : AppFormatters.currency(totalAllExpenses),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (!hasHarvest) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Menunggu data panen untuk menghitung untung/rugi',
                                  style: TextStyle(
                                    color: Color(0xFFD9ECE0),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white24, height: 1),
                        ),
                        // Baris Modal Awal (Bisa Diedit Langsung dari Kartu)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _showEditInitialCapitalSheet(
                            context,
                            service,
                            initialCapital,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 16,
                                  color: AppTheme.cornYellow,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Modal Awal: ${AppFormatters.currency(initialCapital)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ubah',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Pendapatan',
                                    style: TextStyle(
                                      color: Color(0xFFD9ECE0),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    hasHarvest
                                        ? AppFormatters.currency(totalRevenue)
                                        : 'Belum Panen',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.white24,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Pengeluaran',
                                    style: TextStyle(
                                      color: Color(0xFFD9ECE0),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    AppFormatters.currency(totalAllExpenses),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Baris Ringkasan Musim Tanam Aktif & Jumlah Lahan
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (primaryCycle != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CycleDetailScreen(
                                      cycleId: primaryCycle.id,
                                    ),
                                  ),
                                );
                              } else {
                                AppFormDialogs.showPlantingCycleForm(context);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightGreen,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 16,
                                          color: AppTheme.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Musim Aktif',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    primaryCycle != null
                                        ? primaryCycle.name
                                        : 'Belum Ada',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    primaryCycle != null
                                        ? primaryCycle.cornVariety
                                        : 'Buat musim tanam',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => onNavigateTab(1),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightGreen,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.landscape_rounded,
                                          size: 16,
                                          color: AppTheme.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Jumlah Lahan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${plots.length} Lahan',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total ${AppFormatters.formatAreaByPreference(service.totalManagedAreaHectares, user.preferredAreaUnit)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 4. Akses Cepat (3 Aksi Utama Sesuai Spesifikasi: Tambah Lahan, Catat Pengeluaran, Input Panen)
                  const Text(
                    'Akses Cepat',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionBtn(
                          icon: Icons.add_location_alt_outlined,
                          label: 'Tambah Lahan',
                          onTap: () => AppFormDialogs.showPlotForm(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionBtn(
                          icon: Icons.receipt_long_outlined,
                          label: 'Pengeluaran',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpensesScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionBtn(
                          icon: Icons.scale_outlined,
                          label: 'Input Panen',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HarvestInputScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 5. Aktivitas Terdekat (Tersinkron dengan Kalender Aktivitas & Pengingat Jadwal)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Aktivitas Terdekat',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateTab(2),
                        child: const Text('Lihat Kalender'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (nearestSchedule != null &&
                            nearestSchedule.isReminder) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScheduledRemindersScreen(),
                            ),
                          );
                        } else {
                          onNavigateTab(2);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.lightGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                nearestSchedule?.isReminder == true
                                    ? Icons.alarm_rounded
                                    : Icons.event_note_rounded,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nearestSchedule != null
                                        ? nearestSchedule.title
                                        : 'Belum ada jadwal terdekat',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nearestSchedule != null
                                        ? nearestSchedule.subtitle
                                        : 'Ketuk untuk menambah jadwal atau pengingat kegiatan',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (service.hasDemoData) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cornYellowLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cornYellow),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppTheme.darkGreen,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Menampilkan data simulasi.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                service.clearDemoDataForCurrentUser(),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditInitialCapitalSheet(
    BuildContext context,
    AppDataService service,
    double currentCapital,
  ) {
    final ctrl = TextEditingController(
      text: currentCapital > 0 ? currentCapital.toStringAsFixed(0) : '',
    );

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atur Modal Awal Usaha Tani',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Masukkan modal awal musim tanam atau usaha tani Anda. Nilai ini akan langsung diperbarui pada Beranda dan Analisis Keuangan.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Nominal Modal Awal (Rp)',
                prefixText: 'Rp ',
                hintText: 'Contoh: 10000000',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final val =
                          AppFormatters.parsePositiveDouble(
                            ctrl.text,
                            allowZero: true,
                          ) ??
                          0.0;
                      await service.updateInitialCapital(val);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Simpan Modal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(
    BuildContext context,
    List<dynamic> notifications,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pengingat Kegiatan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScheduledRemindersScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.alarm_add_rounded, size: 18),
                  label: const Text('Kelola Jadwal'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Tidak ada pengingat saat ini.')),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, idx) {
                    final n = notifications[idx];
                    final isDanger =
                        n.type == 'jadwal_terlambat' ||
                        n.type == 'stok_menipis';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isDanger
                            ? AppTheme.dangerLight
                            : AppTheme.lightGreen,
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: isDanger
                              ? AppTheme.dangerRed
                              : AppTheme.darkGreen,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        n.message,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingScheduleItem {
  final String title;
  final String subtitle;
  final DateTime dateTime;
  final bool isReminder;

  const _UpcomingScheduleItem({
    required this.title,
    required this.subtitle,
    required this.dateTime,
    required this.isReminder,
  });
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.darkGreen, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
