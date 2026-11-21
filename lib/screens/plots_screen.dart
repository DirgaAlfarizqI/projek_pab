import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../services/app_data_service.dart';
import '../services/pdf_report_service.dart';
import '../widgets/app_form_dialogs.dart';
import '../widgets/tanijagung_widgets.dart';
import '../widgets/ui_kit.dart';
import 'expenses_screen.dart';
import 'harvest_input_screen.dart';
import 'seed_fertilizer_screen.dart';

/// HALAMAN 5: LAHAN & TANAMAN (Sesuai Gambar Referensi Kolom 5 Baris 1)
/// - Judul "Lahan & Tanaman"
/// - Tombol Hijau Penuh "+ Tambah Lahan"
/// - Kartu Lahan dengan Nama Lahan, Lokasi, Luas (Ha / m²), Musim Tanam Aktif, Thumbnail Ilustrasi Ladang Jagung di kanan, dan Tombol "Lihat Detail ->"
class PlotsScreen extends StatelessWidget {
  const PlotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final plots = service.plots;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lahan & Tanaman'),
            actions: [
              IconButton(
                tooltip: 'Buat Musim Tanam',
                onPressed: () => AppFormDialogs.showPlantingCycleForm(context),
                icon: const Icon(Icons.event_available_outlined),
              ),
            ],
          ),
          body: ResponsiveCenter(
            maxWidth: 760,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Tombol Hijau Penuh "+ Tambah Lahan"
                StaggeredEntrance(
                  index: 0,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => AppFormDialogs.showPlotForm(context),
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const Text('Tambah Lahan'),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                if (plots.isEmpty)
                  SoftCard(
                    radius: AppRadius.xl,
                    child: Column(
                      children: [
                        CornEmptyState(
                          title: 'Belum Ada Data Lahan',
                          message: 'Tambahkan lahan pertanian jagung Anda beserta luas (m² atau hektare) untuk mulai mencatat musim tanam.',
                          actionLabel: 'Muat Data Contoh',
                          actionIcon: Icons.auto_awesome_outlined,
                          onAction: () =>
                              service.seedLabeledDemoDataForCurrentUser(),
                        ),
                      ],
                    ),
                  )
                else
                  AdaptiveTwoColumn(
                    children: List.generate(plots.length, (idx) {
                      final plot = plots[idx];
                      final plotCycles = service.getCyclesForPlot(plot.id);
                      final activeCycle =
                          plotCycles.where((c) => c.isActive).isNotEmpty
                          ? plotCycles.firstWhere((c) => c.isActive)
                          : (plotCycles.isNotEmpty ? plotCycles.first : null);

                      return StaggeredEntrance(
                        index: idx + 1,
                        child: SoftCard(
                          radius: AppRadius.xl,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plot.name,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.headingFont,
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          plot.location,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${AppFormatters.formatAreaByPreference(plot.areaInHectares, service.currentUser!.preferredAreaUnit)} (${AppFormatters.number(plot.area)} ${plot.areaUnit})',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.headingFont,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.primaryDarkGreen,
                                          ),
                                        ),
                                        if (activeCycle != null) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.softMintGreen,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${activeCycle.name} • ${activeCycle.cornVariety}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    AppTheme.primaryDarkGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 100,
                                    child: _PlotPhotoOrBanner(
                                      photoPath: plot.photoPath,
                                      height: 80,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.softMintGreen,
                                    foregroundColor: AppTheme.primaryDarkGreen,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlotDetailScreen(plotId: plot.id),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                          fontFamily: AppTheme.headingFont,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                const SizedBox(height: 12),
                const BottomCornLeavesDecoration(),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// HALAMAN 6: DETAIL LAHAN (Sesuai Gambar Referensi Kolom 6 Baris 1)
/// - Banner Foto / Ilustrasi Ladang Jagung Besar di Atas
/// - Nama Lahan ("Lahan 1 - Sawah Utara")
/// - Baris Info Ikon: Luas Lahan (1,0 Ha), Lokasi (Jl. Pertanian No. 1), Varietas (Bisi 18)
/// - Riwayat Musim Tanam (Kartu dengan badge "Aktif >" yang membuka halaman Musim Tanam)
/// - Catatan ("Lahan subur dan produktif.")
/// - Tombol "Edit Data" & "+ Buat Musim Tanam"
class PlotDetailScreen extends StatelessWidget {
  final String plotId;
  const PlotDetailScreen({super.key, required this.plotId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final plot = service.getPlotById(plotId);
        if (plot == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Lahan')),
            body: const Center(child: Text('Data lahan tidak ditemukan.')),
          );
        }

        final plotCycles = service.getCyclesForPlot(plot.id);
        final latestVariety = plotCycles.isNotEmpty
            ? plotCycles.first.cornVariety
            : 'Belum ditentukan';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Lahan'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'edit') {
                    await AppFormDialogs.showPlotForm(
                      context,
                      existingPlot: plot,
                    );
                  } else if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Lahan?'),
                        content: Text(
                          'Hapus "${plot.name}" beserta seluruh riwayat musim tanamnya?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dangerRed,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await service.deletePlot(plot.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Data Lahan')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Hapus Lahan',
                      style: TextStyle(color: AppTheme.dangerRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Banner Foto Lahan atau Ilustrasi Ladang Jagung di Atas
              _PlotPhotoOrBanner(
                photoPath: plot.photoPath,
                height: 175,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 16),

              Text(
                plot.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Kartu Informasi Luas, Lokasi, dan Varietas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailInfoRow(
                        icon: Icons.crop_free_rounded,
                        label: 'Luas Lahan',
                        value:
                            '${AppFormatters.formatAreaByPreference(plot.areaInHectares, service.currentUser!.preferredAreaUnit)} (${AppFormatters.number(plot.area)} ${plot.areaUnit})',
                      ),
                      const Divider(height: 20),
                      _DetailInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Lokasi',
                        value: plot.location,
                      ),
                      const Divider(height: 20),
                      _DetailInfoRow(
                        icon: Icons.eco_outlined,
                        label: 'Varietas',
                        value: latestVariety,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bagian Riwayat Musim Tanam
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Riwayat Musim Tanam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => AppFormDialogs.showPlantingCycleForm(
                      context,
                      preselectedPlotId: plot.id,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Buat Musim'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (plotCycles.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Belum ada riwayat musim tanam pada lahan ini.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...plotCycles.map((c) {
                  final isAct = c.isActive;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CycleDetailScreen(cycleId: c.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.lightLeafGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_outlined,
                                  color: AppTheme.primaryDarkGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${AppFormatters.date(c.plantingDate)} – ${AppFormatters.date(c.actualHarvestDate ?? c.estimatedHarvestDate)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isAct
                                      ? AppTheme.softMintGreen
                                      : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isAct ? 'Aktif' : c.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isAct
                                            ? AppTheme.primaryDarkGreen
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: isAct
                                          ? AppTheme.primaryDarkGreen
                                          : AppTheme.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 14),
              const Text(
                'Catatan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    plot.notes.isNotEmpty
                        ? plot.notes
                        : 'Lahan subur dan produktif.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Tombol Edit Data Hijau Penuh (Persis Gambar Referensi)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      AppFormDialogs.showPlotForm(context, existingPlot: plot),
                  child: const Text('Edit Data'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryDarkGreen),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// HALAMAN 6B: MUSIM TANAM & TIMELINE (Sesuai Gambar Referensi Baris 2 Kolom 1)
/// - Banner Hijau Tua di Atas: Nama Musim ("MT 1 - 2025"), Periode Tanggal ("1 Jan - 30 Apr 2025"), Status ("Aktif"), dan Ikon Jagung Emas
/// - Timeline Vertikal dengan lingkaran checklist hijau:
///   * Penanaman
///   * Pemupukan I
///   * Pemupukan II
///   * Kegiatan lainnya
///   * Panen (Target / Aktual)
/// - Akses cepat ke Input Benih & Pupuk, Pengeluaran, Input Hasil Panen, Ekspor PDF
/// - Tombol Bawah "Tambah Musim Tanam"
class CycleDetailScreen extends StatelessWidget {
  final String cycleId;
  const CycleDetailScreen({super.key, required this.cycleId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final cycle = service.getCycleById(cycleId);
        if (cycle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Musim Tanam')),
            body: const Center(
              child: Text('Data musim tanam tidak ditemukan.'),
            ),
          );
        }

        final summary = service.calculateCycleSummary(cycle.id);
        final activities = service.getActivitiesForCycle(cycle.id)
          ..sort((a, b) => a.date.compareTo(b.date));
        final inputs = service.getCropInputsForCycle(cycle.id);
        final expenses = service.getExpensesForCycle(cycle.id);
        final harvests = service.getHarvestsForCycle(cycle.id);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Musim Tanam'),
            actions: [
              IconButton(
                tooltip: 'Edit Musim Tanam',
                onPressed: () => AppFormDialogs.showPlantingCycleForm(
                  context,
                  existingCycle: cycle,
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Ekspor Laporan PDF',
                onPressed: () {
                  PdfReportService.generateAndShareCycleReport(
                    user: service.currentUser!,
                    summary: summary,
                    cropInputs: inputs,
                    expenses: expenses,
                    activities: activities,
                    harvests: harvests,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Kartu Header Hijau Tua Musim Tanam (Persis Gambar Referensi Baris 2 Kolom 1)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryDarkGreen, AppTheme.leafGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cycle.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${AppFormatters.date(cycle.plantingDate)} – ${AppFormatters.date(cycle.actualHarvestDate ?? cycle.estimatedHarvestDate)}',
                            style: const TextStyle(
                              color: Color(0xFFE8F5E9),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Status : ${cycle.isActive ? "Aktif (${cycle.status})" : cycle.status} • Varietas: ${cycle.cornVariety}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cycle.actualDurationInDays != null
                                ? 'Durasi aktual: ${cycle.actualDurationInDays} hari'
                                : 'Umur tanaman: ${cycle.ageInDays} hari • Sisa ${cycle.daysRemainingToEstimatedHarvest} hari menuju perkiraan panen',
                            style: const TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const CornBrandLogo(size: 56),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Timeline Vertikal Kegiatan Musim Tanam (Persis Gambar Referensi)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Timeline Kegiatan',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => AppFormDialogs.showActivityForm(
                      context,
                      preselectedCycleId: cycle.id,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Tambah Jadwal'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      if (activities.isEmpty)
                        const Text(
                          'Belum ada jadwal kegiatan tercatat.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        )
                      else
                        ...List.generate(activities.length, (idx) {
                          final act = activities[idx];
                          final isLast = idx == activities.length - 1;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        service.toggleActivityCompleted(
                                          act.id,
                                          !act.isCompleted,
                                        ),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: act.isCompleted
                                            ? AppTheme.primaryDarkGreen
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.primaryDarkGreen,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        act.isCompleted
                                            ? Icons.check_rounded
                                            : Icons.circle,
                                        size: act.isCompleted ? 17 : 8,
                                        color: act.isCompleted
                                            ? Colors.white
                                            : AppTheme.primaryDarkGreen,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2.2,
                                      height: 44,
                                      color: AppTheme.primaryDarkGreen
                                          .withValues(alpha: 0.35),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              act.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${AppFormatters.date(act.date)} • ${act.activityType}',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: AppTheme.textSecondary,
                                        ),
                                        onPressed: () =>
                                            service.deleteActivity(act.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pintasan Operasional Musim Tanam Ini
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SeedFertilizerScreen(initialCycleId: cycle.id),
                        ),
                      ),
                      icon: const Icon(Icons.grain_rounded, size: 18),
                      label: const Text('Benih & Pupuk'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExpensesScreen(initialCycleId: cycle.id),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Pengeluaran'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HarvestInputScreen(initialCycleId: cycle.id),
                    ),
                  ),
                  icon: const Icon(Icons.scale_outlined, size: 18),
                  label: const Text('Input Hasil Panen'),
                ),
              ),
              const SizedBox(height: 18),

              // Tombol Bawah "Tambah Musim Tanam" (Persis Gambar Referensi)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => AppFormDialogs.showPlantingCycleForm(
                    context,
                    preselectedPlotId: cycle.plotId,
                  ),
                  child: const Text('Tambah Musim Tanam'),
                ),
              ),
              const SizedBox(height: 10),
              const BottomCornLeavesDecoration(),
            ],
          ),
        );
      },
    );
  }
}

class _PlotPhotoOrBanner extends StatelessWidget {
  final String? photoPath;
  final double height;
  final BorderRadius borderRadius;

  const _PlotPhotoOrBanner({
    required this.photoPath,
    required this.height,
    required this.borderRadius,
  });

  bool _canShowFile(String? path) {
    if (kIsWeb || path == null || path.trim().isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_canShowFile(photoPath)) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.file(
          File(photoPath!),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => CornFieldIllustrationBanner(
            height: height,
            borderRadius: borderRadius,
          ),
        ),
      );
    }
    return CornFieldIllustrationBanner(
      height: height,
      borderRadius: borderRadius,
    );
  }
}
