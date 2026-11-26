import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_models.dart';
import '../services/app_data_service.dart';
import '../widgets/app_form_dialogs.dart';
import '../widgets/tanijagung_widgets.dart';
import '../widgets/ui_kit.dart';
import 'expenses_screen.dart';
import 'harvest_input_screen.dart';
import 'inventory_screen.dart';
import 'plots_screen.dart';
import 'profit_simulation_screen.dart';
import 'reports_screen.dart';
import 'scheduled_reminders_screen.dart';
import 'seed_fertilizer_screen.dart';

/// =====================================================================
/// BERANDA (Tahap 3 Redesain — Modern, Hidup, Premium)
/// =====================================================================
/// - Staggered entrance (jeda 60 ms per kartu)
/// - Count-up animasi angka uang tebal (Plus Jakarta Sans tabular)
/// - Badge status berdenyut halus (PulseBadge: Belum Panen / Untung / Rugi)
/// - Input Modal Awal dapat diubah langsung dari kartu hero
/// - Pull-to-refresh bertema tunas/daun (SproutRefreshWrapper)
/// - Lonceng pengingat bergoyang saat ada pengingat aktif (AnimatedBellIcon)
/// - Responsif untuk ponsel & tablet (ResponsiveCenter)
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
        final colors = context.appColors;

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
        final IconData statusBadgeIcon;

        if (!hasHarvest) {
          statusBadgeText = 'Belum Panen';
          statusBadgeBgColor = AppTheme.cornYellow;
          statusBadgeTextColor = AppTheme.textPrimary;
          statusBadgeIcon = Icons.hourglass_top_rounded;
        } else if (overallProfitLoss >= 0) {
          statusBadgeText = 'Untung';
          statusBadgeBgColor = const Color(0xFF4ADE80);
          statusBadgeTextColor = AppTheme.darkGreen;
          statusBadgeIcon = Icons.trending_up_rounded;
        } else {
          statusBadgeText = 'Rugi';
          statusBadgeBgColor = AppTheme.dangerRed;
          statusBadgeTextColor = Colors.white;
          statusBadgeIcon = Icons.trending_down_rounded;
        }

        // Gabungkan aktivitas kalender yang belum selesai & pengingat jadwal aktif
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
        final hasActiveAlerts =
            notifications.isNotEmpty ||
            service.scheduledReminders.any((r) => r.isEnabled);

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: SproutRefreshWrapper(
              onRefresh: () async => service.initialize(),
              child: ResponsiveCenter(
                maxWidth: 760,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    AppSpacing.xl,
                  ),
                  children: [
                    // 1. Header Sapaan Pengguna + Lonceng Bergoyang
                    StaggeredEntrance(
                      index: 0,
                      child: Row(
                        children: [
                          PressableScale(
                            onTap: () => onNavigateTab(4),
                            child: FarmerAvatarIllustration(
                              size: 48,
                              customImagePath: user.profilePhotoPath,
                              userName: user.name,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, ${user.name}',
                                  style: TextStyle(
                                    fontFamily: AppTheme.headingFont,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.farmBusinessName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: AppShadows.soft,
                            ),
                            child: IconButton(
                              tooltip: 'Notifikasi & Pengingat',
                              onPressed: () => _showNotificationsSheet(
                                context,
                                notifications,
                              ),
                              icon: Badge(
                                isLabelVisible: notifications.isNotEmpty,
                                backgroundColor: AppTheme.dangerRed,
                                label: Text('${notifications.length}'),
                                child: AnimatedBellIcon(
                                  animate: hasActiveAlerts,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. Hero Card Keuangan Modern (Gradient Halus, Shadow Berlapis, Count-Up, PulseBadge, Input Modal Awal)
                    StaggeredEntrance(
                      index: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: AppShadows.hero,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Ornamen lingkaran cahaya lembut di sudut kanan atas
                            Positioned(
                              top: -40,
                              right: -30,
                              child: IgnorePointer(
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    onTap: () => onNavigateTab(3),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            PulseBadge(
                                              label: statusBadgeText,
                                              background: statusBadgeBgColor,
                                              foreground: statusBadgeTextColor,
                                              icon: statusBadgeIcon,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Angka utama menghitung naik (Count-Up) dengan font Plus Jakarta Sans tebal
                                        AnimatedCountUp(
                                          value: hasHarvest
                                              ? overallProfitLoss
                                              : totalAllExpenses,
                                          formatter: AppFormatters.currency,
                                          style: AppTextStyles.money(
                                            size: 30,
                                            color: Colors.white,
                                            weight: FontWeight.w800,
                                          ),
                                        ),
                                        if (!hasHarvest) ...[
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Menunggu data panen untuk menghitung untung/rugi',
                                            style: TextStyle(
                                              color: Color(0xFFD9ECE0),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Divider(
                                      color: Colors.white24,
                                      height: 1,
                                    ),
                                  ),

                                  // Baris Modal Awal (Bisa Diedit Langsung dari Kartu)
                                  PressableScale(
                                    onTap: () => _showEditInitialCapitalSheet(
                                      context,
                                      service,
                                      initialCapital,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.11,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons
                                                .account_balance_wallet_outlined,
                                            size: 17,
                                            color: AppTheme.cornYellow,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Modal Awal: ${AppFormatters.currency(initialCapital)}',
                                              style: const TextStyle(
                                                fontFamily:
                                                    AppTheme.headingFont,
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.18,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.xs,
                                                  ),
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
                                                    fontFamily:
                                                        AppTheme.headingFont,
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
                                  const SizedBox(height: 14),

                                  // Total Pendapatan & Total Pengeluaran
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Pendapatan',
                                              style: TextStyle(
                                                color: Color(0xFFD9ECE0),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (hasHarvest)
                                              AnimatedCountUp(
                                                value: totalRevenue,
                                                formatter:
                                                    AppFormatters.currency,
                                                style: AppTextStyles.money(
                                                  size: 15.5,
                                                  color: Colors.white,
                                                  weight: FontWeight.w700,
                                                ),
                                              )
                                            else
                                              const Text(
                                                'Belum Panen',
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.headingFont,
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 34,
                                        color: Colors.white24,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Pengeluaran',
                                              style: TextStyle(
                                                color: Color(0xFFD9ECE0),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            AnimatedCountUp(
                                              value: totalAllExpenses,
                                              formatter: AppFormatters.currency,
                                              style: AppTextStyles.money(
                                                size: 15.5,
                                                color: Colors.white,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Baris Ringkasan Musim Tanam Aktif & Jumlah Lahan
                    StaggeredEntrance(
                      index: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: SoftCard(
                              radius: AppRadius.xl,
                              padding: const EdgeInsets.all(AppSpacing.md),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colors.accentTint,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 17,
                                          color: AppTheme.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Musim Aktif',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: colors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    primaryCycle != null
                                        ? primaryCycle.name
                                        : 'Belum Ada',
                                    style: TextStyle(
                                      fontFamily: AppTheme.headingFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    primaryCycle != null
                                        ? primaryCycle.cornVariety
                                        : 'Buat musim tanam',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SoftCard(
                              radius: AppRadius.xl,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              onTap: () => onNavigateTab(1),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colors.accentTint,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.landscape_rounded,
                                          size: 17,
                                          color: AppTheme.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Jumlah Lahan',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: colors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${plots.length} Lahan',
                                    style: TextStyle(
                                      fontFamily: AppTheme.headingFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Total ${AppFormatters.formatAreaByPreference(service.totalManagedAreaHectares, user.preferredAreaUnit)}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Akses Cepat (Horizontal Scroll Navigation untuk Semua Fitur Operasional)
                    StaggeredEntrance(
                      index: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: SectionHeader(title: 'Akses Cepat'),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Geser',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.swipe_rounded,
                                    size: 15,
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.none,
                            child: Row(
                              children: [
                                _QuickActionBtn(
                                  icon: Icons.add_location_alt_outlined,
                                  label: 'Tambah Lahan',
                                  subtitle: 'Input lahan baru',
                                  onTap: () =>
                                      AppFormDialogs.showPlotForm(context),
                                ),
                                const SizedBox(width: 12),
                                _QuickActionBtn(
                                  icon: Icons.grain_rounded,
                                  label: 'Benih & Pupuk',
                                  subtitle: 'Catat pemakaian',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SeedFertilizerScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _QuickActionBtn(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Stok Pupuk',
                                  subtitle: 'Cek sisa stok',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const InventoryScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _QuickActionBtn(
                                  icon: Icons.receipt_long_outlined,
                                  label: 'Pengeluaran',
                                  subtitle: 'Biaya usaha tani',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ExpensesScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _QuickActionBtn(
                                  icon: Icons.scale_outlined,
                                  label: 'Input Panen',
                                  subtitle: 'Hasil & jual panen',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HarvestInputScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _QuickActionBtn(
                                  icon: Icons.calculate_outlined,
                                  label: 'Simulasi Untung',
                                  subtitle: 'Hitung laba/impas',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ProfitSimulationScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _QuickActionBtn(
                                  icon: Icons.picture_as_pdf_outlined,
                                  label: 'Laporan PDF',
                                  subtitle: 'Riwayat & ekspor',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 5. Aktivitas Terdekat (Tersinkron dengan Kalender Aktivitas & Pengingat Jadwal)
                    StaggeredEntrance(
                      index: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Aktivitas Terdekat',
                            actionLabel: 'Lihat Kalender',
                            onAction: () => onNavigateTab(2),
                          ),
                          const SizedBox(height: 6),
                          SoftCard(
                            radius: AppRadius.xl,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            onTap: () {
                              if (nearestSchedule != null &&
                                  nearestSchedule.isReminder) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ScheduledRemindersScreen(),
                                  ),
                                );
                              } else {
                                onNavigateTab(2);
                              }
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: colors.accentTint,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  child: Icon(
                                    nearestSchedule?.isReminder == true
                                        ? Icons.alarm_rounded
                                        : Icons.event_note_rounded,
                                    color: AppTheme.darkGreen,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nearestSchedule != null
                                            ? nearestSchedule.title
                                            : 'Belum ada jadwal terdekat',
                                        style: TextStyle(
                                          fontFamily: AppTheme.headingFont,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        nearestSchedule != null
                                            ? nearestSchedule.subtitle
                                            : 'Ketuk untuk menambah jadwal atau pengingat kegiatan',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: colors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (service.hasDemoData) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cornYellowLight,
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atur Modal Awal Usaha Tani',
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 18),
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
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final val =
                          AppFormatters.parsePositiveDouble(
                            ctrl.text,
                            allowZero: true,
                          ) ??
                          0.0;
                      await service.updateInitialCapital(val);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        showSuccessToast(
                          context,
                          'Modal awal diperbarui menjadi ${AppFormatters.currency(val)}',
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Simpan Modal'),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pengingat Kegiatan',
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
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
              const CornEmptyState(
                illustrationSize: 88,
                title: 'Tidak Ada Pengingat Mendesak',
                message: 'Semua jadwal kegiatan dan stok pupuk Anda dalam kondisi terkendali.',
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
                          fontFamily: AppTheme.headingFont,
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
  final String? subtitle;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 132,
      child: SoftCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.accentTint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppTheme.darkGreen, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
