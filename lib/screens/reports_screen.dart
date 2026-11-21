import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../services/app_data_service.dart';
import '../services/pdf_report_service.dart';
import '../widgets/tanijagung_widgets.dart';
import 'plots_screen.dart';

/// HALAMAN 15: RIWAYAT & LAPORAN (Sesuai Gambar Referensi Baris 3 Kolom 3)
/// - Filter Chips di atas: Pill Hijau "Semua", Filter Tahun ("2024 - 2026 >"), & Filter Lahan
/// - Daftar Kartu Musim Tanam dengan Ikon Jagung Emas, Nama Musim ("MT 1 - 2025"), Status + Nominal ("Untung • Rp 24.500.000"), Tanggal Mulai & Panen, Total Biaya, Hasil Panen, Pendapatan
/// - Fitur Perbandingan Musim Tanam
/// - Tombol Hijau Penuh di Bawah: "Export PDF"
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedPlotFilter;
  int? _selectedYearFilter;
  bool _showComparisonMode = false;
  final Set<String> _selectedForCompare = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final plots = service.plots;
        final allCycles = service.cycles;

        final availableYears =
            allCycles.map((c) => c.plantingDate.year).toSet().toList()
              ..sort((a, b) => b.compareTo(a));

        final filteredCycles = allCycles.where((c) {
          if (_selectedPlotFilter != null && c.plotId != _selectedPlotFilter) {
            return false;
          }
          if (_selectedYearFilter != null &&
              c.plantingDate.year != _selectedYearFilter) {
            return false;
          }
          return true;
        }).toList();

        final summaries = filteredCycles
            .map((c) => service.calculateCycleSummary(c.id))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat & Laporan'),
            actions: [
              IconButton(
                tooltip: 'Bandingkan Musim Tanam',
                onPressed: () =>
                    setState(() => _showComparisonMode = !_showComparisonMode),
                icon: Icon(
                  _showComparisonMode
                      ? Icons.list_alt_rounded
                      : Icons.compare_arrows_rounded,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Baris Filter "Semua" | Tahun | Lahan (Persis Gambar Referensi Baris 3 Kolom 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Pill "Semua"
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedPlotFilter = null;
                          _selectedYearFilter = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (_selectedPlotFilter == null &&
                                    _selectedYearFilter == null)
                                ? AppTheme.leafGreen
                                : AppTheme.surfaceWhite,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Text(
                            'Semua',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color:
                                  (_selectedPlotFilter == null &&
                                      _selectedYearFilter == null)
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Pill Filter Tahun
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedYearFilter,
                            hint: const Text(
                              'Semua Tahun',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Semua Tahun'),
                              ),
                              ...availableYears.map(
                                (yr) => DropdownMenuItem<int?>(
                                  value: yr,
                                  child: Text('Tahun $yr'),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedYearFilter = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Pill Filter Lahan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedPlotFilter,
                            hint: const Text(
                              'Semua Lahan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Semua Lahan'),
                              ),
                              ...plots.map(
                                (p) => DropdownMenuItem<String?>(
                                  value: p.id,
                                  child: Text(p.name),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedPlotFilter = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: summaries.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada riwayat musim tanam yang sesuai filter.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : _showComparisonMode
                    ? _buildComparisonView(summaries)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        itemCount: summaries.length,
                        itemBuilder: (context, idx) {
                          final s = summaries[idx];
                          final c = s.cycle;
                          final user = service.currentUser!;
                          final hasHarvest = s.hasHarvestData;
                          final isProfit = s.financialStatus == 'UNTUNG';
                          final statusLabel = !hasHarvest
                              ? 'Belum Panen'
                              : (isProfit
                                    ? 'Untung'
                                    : (s.financialStatus == 'RUGI'
                                          ? 'Rugi'
                                          : 'Impas'));

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _showReportDetailSheet(context, s),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const CornBrandLogo(size: 46),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              hasHarvest
                                                  ? '$statusLabel • ${AppFormatters.currency(s.netProfitOrLoss)}'
                                                  : '$statusLabel • Pengeluaran ${AppFormatters.currency(s.totalExpenses)}',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: !hasHarvest
                                                    ? AppTheme.textSecondary
                                                    : (isProfit
                                                          ? AppTheme.leafGreen
                                                          : (s.financialStatus ==
                                                                    'RUGI'
                                                                ? AppTheme
                                                                      .dangerRed
                                                                : AppTheme
                                                                      .textSecondary)),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${s.plot?.name ?? "-"} • Panen: ${AppFormatters.formatWeightByPreference(s.totalHarvestTons, user.preferredWeightUnit)} • Biaya: ${AppFormatters.currency(s.totalExpenses)}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Cetak PDF Musim Ini',
                                        icon: const Icon(
                                          Icons.picture_as_pdf_outlined,
                                          color: AppTheme.primaryDarkGreen,
                                        ),
                                        onPressed: () => _exportSinglePdf(s),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Tombol Bawah "Export PDF" (Persis Gambar Referensi Baris 3 Kolom 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: summaries.isEmpty
                            ? null
                            : () => _exportSinglePdf(summaries.first),
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 20,
                        ),
                        label: const Text('Export PDF'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const BottomCornLeavesDecoration(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportSinglePdf(CycleFinancialSummary summary) {
    final service = AppDataService();
    final c = summary.cycle;
    PdfReportService.generateAndShareCycleReport(
      user: service.currentUser!,
      summary: summary,
      cropInputs: service.getCropInputsForCycle(c.id),
      expenses: service.getExpensesForCycle(c.id),
      activities: service.getActivitiesForCycle(c.id),
      harvests: service.getHarvestsForCycle(c.id),
    );
  }

  void _showReportDetailSheet(BuildContext context, CycleFinancialSummary s) {
    final c = s.cycle;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Detail Laporan: ${c.name}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            _DetailLine('Lahan', s.plot?.name ?? '-'),
            _DetailLine('Varietas Jagung', c.cornVariety),
            _DetailLine(
              'Tanggal Mulai Tanam',
              AppFormatters.date(c.plantingDate),
            ),
            _DetailLine(
              'Tanggal Panen',
              AppFormatters.date(c.actualHarvestDate ?? c.estimatedHarvestDate),
            ),
            _DetailLine(
              'Total Biaya Pengeluaran',
              AppFormatters.currency(s.totalExpenses),
            ),
            _DetailLine(
              'Hasil Panen Aktual',
              s.hasHarvestData
                  ? '${AppFormatters.formatWeightByPreference(s.totalHarvestTons, AppDataService().currentUser!.preferredWeightUnit)} (${AppFormatters.number(s.totalHarvestKg)} kg)'
                  : 'Menunggu data panen',
            ),
            _DetailLine(
              'Total Pendapatan',
              s.hasHarvestData
                  ? AppFormatters.currency(s.totalRevenue)
                  : 'Menunggu data panen',
            ),
            _DetailLine(
              'Status Keuangan',
              s.hasHarvestData
                  ? '${s.financialStatus} (${AppFormatters.currency(s.netProfitOrLoss)})'
                  : 'Menunggu data panen',
              bold: true,
            ),
            _DetailLine(
              'Produktivitas Lahan',
              '${AppFormatters.number(s.productivityTonsPerHa)} Ton/Ha (${AppFormatters.number(s.productivityKgPerHa)} kg/ha)',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CycleDetailScreen(cycleId: c.id),
                        ),
                      );
                    },
                    child: const Text('Buka Musim Tanam'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportSinglePdf(s);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Export PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView(List<CycleFinancialSummary> summaries) {
    final chosen = _selectedForCompare.isEmpty
        ? summaries.take(2).toList()
        : summaries
              .where((s) => _selectedForCompare.contains(s.cycle.id))
              .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pilih Musim Tanam untuk Dibandingkan:',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: summaries.map((s) {
            final sel = chosen.any((e) => e.cycle.id == s.cycle.id);
            return FilterChip(
              label: Text(s.cycle.name),
              selected: sel,
              onSelected: (_) {
                setState(() {
                  if (_selectedForCompare.contains(s.cycle.id)) {
                    _selectedForCompare.remove(s.cycle.id);
                  } else {
                    _selectedForCompare.add(s.cycle.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: DataTable(
              columns: [
                const DataColumn(
                  label: Text(
                    'Indikator',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                ...chosen.map(
                  (s) => DataColumn(
                    label: Text(
                      s.cycle.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
              rows: [
                DataRow(
                  cells: [
                    const DataCell(Text('Lahan')),
                    ...chosen.map((s) => DataCell(Text(s.plot?.name ?? '-'))),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(Text('Total Biaya')),
                    ...chosen.map(
                      (s) => DataCell(
                        Text(AppFormatters.currency(s.totalExpenses)),
                      ),
                    ),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(Text('Hasil Panen')),
                    ...chosen.map(
                      (s) => DataCell(
                        Text('${AppFormatters.number(s.totalHarvestTons)} Ton'),
                      ),
                    ),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(Text('Pendapatan')),
                    ...chosen.map(
                      (s) => DataCell(
                        Text(AppFormatters.currency(s.totalRevenue)),
                      ),
                    ),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(Text('Keuntungan / Rugi')),
                    ...chosen.map(
                      (s) => DataCell(
                        Text(
                          '${AppFormatters.currency(s.netProfitOrLoss)} (${s.financialStatus})',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailLine(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
