import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../services/app_data_service.dart';
import '../widgets/tanijagung_widgets.dart';
import 'profit_simulation_screen.dart';
import 'reports_screen.dart';

/// HALAMAN ANALISIS (Master Prompt Final — Simple But Modern)
/// REVISI WAJIB DITERAPKAN:
/// - TIDAK ADA menu, card, grafik, atau shortcut Produktivitas di halaman Analisis.
/// - Fokus penuh pada keuangan dan hasil usaha pertanian:
///   1. Total pendapatan
///   2. Total pengeluaran
///   3. Keuntungan atau kerugian (Untung / Rugi / Impas)
///   4. Grafik pendapatan dan pengeluaran
///   5. Perbandingan hasil panen antar musim tanam
///   6. Biaya produksi & Harga impas
///   7. Ringkasan keuangan per lahan
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String? _selectedCycleId;
  int _financeSubTab = 0; // 0 = Ringkasan, 1 = Detail & Lahan

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final cycles = service.cycles;
        if (cycles.isNotEmpty &&
            (_selectedCycleId == null ||
                !cycles.any((c) => c.id == _selectedCycleId))) {
          _selectedCycleId = cycles.first.id;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analisis Keuangan'),
            actions: [
              IconButton(
                tooltip: 'Simulasi Keuntungan',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfitSimulationScreen(
                        initialCycleId: _selectedCycleId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calculate_outlined),
              ),
              IconButton(
                tooltip: 'Riwayat & Laporan PDF',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
            ],
          ),
          body: cycles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada data musim tanam untuk dianalisis.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : _FinanceAnalysisContent(
                  selectedCycleId: _selectedCycleId!,
                  cycles: cycles,
                  onSelectCycle: (id) => setState(() => _selectedCycleId = id),
                  subTab: _financeSubTab,
                  onSubTabChanged: (idx) =>
                      setState(() => _financeSubTab = idx),
                ),
        );
      },
    );
  }
}

class _FinanceAnalysisContent extends StatelessWidget {
  final String selectedCycleId;
  final List<dynamic> cycles;
  final ValueChanged<String> onSelectCycle;
  final int subTab;
  final ValueChanged<int> onSubTabChanged;

  const _FinanceAnalysisContent({
    required this.selectedCycleId,
    required this.cycles,
    required this.onSelectCycle,
    required this.subTab,
    required this.onSubTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final service = AppDataService();
    final summary = service.calculateCycleSummary(selectedCycleId);

    final revenue = summary.totalRevenue;
    final expenses = summary.totalExpenses;
    final profit = summary.netProfitOrLoss;
    final pct = summary.profitPercentage;

    // Data kronologis untuk perbandingan hasil panen antar musim tanam
    final chronologicalCycles = [...service.cycles]
      ..sort((a, b) => a.plantingDate.compareTo(b.plantingDate));
    final allSummaries = chronologicalCycles
        .map((c) => service.calculateCycleSummary(c.id))
        .toList();

    final maxYieldTons = allSummaries.isEmpty
        ? 10.0
        : allSummaries
              .map((s) => s.totalHarvestTons)
              .fold<double>(5.0, (a, b) => a > b ? a : b);

    // Ringkasan keuangan per lahan
    final plots = service.plots;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // 1. Pilihan Musim Tanam
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCycleId,
                isExpanded: true,
                items: cycles
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c.id as String,
                        child: Text(
                          '${c.name} (${c.cornVariety})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onSelectCycle(v);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Pill Switcher: Ringkasan | Detail
        PillSegmentedSwitch(
          leftLabel: 'Ringkasan',
          rightLabel: 'Detail',
          selectedIndex: subTab,
          onChanged: onSubTabChanged,
        ),
        const SizedBox(height: 16),

        if (subTab == 0) ...[
          // Total Pendapatan & Total Pengeluaran
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pendapatan',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.currency(revenue),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pengeluaran',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.currency(expenses),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Banner Keuntungan / Kerugian
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: profit >= 0
                    ? [AppTheme.darkGreen, AppTheme.primaryGreen]
                    : [AppTheme.dangerRed, const Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.financialStatus == 'UNTUNG'
                            ? 'Keuntungan (Untung)'
                            : (summary.financialStatus == 'RUGI'
                                  ? 'Kerugian (Rugi)'
                                  : 'Impas'),
                        style: const TextStyle(
                          color: Color(0xFFD9ECE0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.currency(profit),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${profit >= 0 ? "+" : "-"}${AppFormatters.number(pct.abs())}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Biaya Produksi & Harga Impas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _KVRow(
                    'Biaya Produksi Total',
                    AppFormatters.currency(summary.totalExpenses),
                  ),
                  const Divider(height: 16),
                  _KVRow(
                    'Harga Impas per Kg',
                    summary.totalHarvestKg > 0
                        ? '${AppFormatters.currency(summary.breakEvenPricePerKg)} / kg'
                        : 'Menunggu data panen',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Grafik Pendapatan dan Pengeluaran (Donut Chart)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grafik Pendapatan & Pengeluaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 30,
                            sectionsSpace: 3,
                            sections: [
                              PieChartSectionData(
                                value: revenue > 0 ? revenue : 1,
                                color: AppTheme.primaryGreen,
                                radius: 22,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: expenses > 0 ? expenses : 1,
                                color: AppTheme.cornYellow,
                                radius: 22,
                                showTitle: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LegendDot(
                              color: AppTheme.primaryGreen,
                              label: 'Pendapatan',
                              value: AppFormatters.currency(revenue),
                            ),
                            const SizedBox(height: 10),
                            _LegendDot(
                              color: AppTheme.cornYellow,
                              label: 'Pengeluaran',
                              value: AppFormatters.currency(expenses),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Perbandingan Hasil Panen Antar Musim Tanam (Ton)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perbandingan Hasil Panen Antar Musim (Ton)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 170,
                    child: BarChart(
                      BarChartData(
                        maxY: maxYieldTons * 1.25,
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx < 0 || idx >= allSummaries.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '${AppFormatters.number(allSummaries[idx].totalHarvestTons)} T',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx < 0 || idx >= allSummaries.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'MT ${idx + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(allSummaries.length, (i) {
                          final isSelected =
                              allSummaries[i].cycle.id == selectedCycleId;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: allSummaries[i].totalHarvestTons,
                                width: 28,
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : AppTheme.cornYellow,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // TAB 1: DETAIL KEUANGAN & RINGKASAN KEUANGAN PER LAHAN
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Keuangan Musim Tanam',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _KVRow(
                    'Modal Awal',
                    AppFormatters.currency(summary.initialCapital),
                  ),
                  _KVRow(
                    'Total Pengeluaran',
                    AppFormatters.currency(summary.totalExpenses),
                    bold: true,
                  ),
                  _KVRow(
                    'Hasil Panen Aktual',
                    '${AppFormatters.number(summary.totalHarvestTons)} Ton (${AppFormatters.number(summary.totalHarvestKg)} kg)',
                  ),
                  _KVRow(
                    'Harga Jual Rata-rata',
                    '${AppFormatters.currency(summary.averageSellingPricePerKg)} / kg',
                  ),
                  _KVRow(
                    'Total Pendapatan',
                    AppFormatters.currency(summary.totalRevenue),
                    bold: true,
                  ),
                  const Divider(height: 20),
                  _KVRow(
                    'Keuntungan / Kerugian',
                    '${summary.financialStatus} (${AppFormatters.currency(summary.netProfitOrLoss)})',
                    bold: true,
                  ),
                  _KVRow(
                    'Biaya Produksi per Kg',
                    '${AppFormatters.currency(summary.productionCostPerKg)} / kg',
                  ),
                  _KVRow(
                    'Harga Impas per Kg',
                    '${AppFormatters.currency(summary.breakEvenPricePerKg)} / kg',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ringkasan Keuangan per Lahan
          const Text(
            'Ringkasan Keuangan per Lahan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...plots.map((plot) {
            final plotCycles = service.getCyclesForPlot(plot.id);
            double plotExpenses = 0;
            double plotRevenue = 0;
            double plotTons = 0;
            for (final c in plotCycles) {
              final s = service.calculateCycleSummary(c.id);
              plotExpenses += s.totalExpenses;
              plotRevenue += s.totalRevenue;
              plotTons += s.totalHarvestTons;
            }
            final plotProfit = plotRevenue - plotExpenses;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plot.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${plotCycles.length} Musim • ${AppFormatters.number(plotTons)} Ton',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _KVRow(
                        'Total Pendapatan Lahan',
                        AppFormatters.currency(plotRevenue),
                      ),
                      _KVRow(
                        'Total Pengeluaran Lahan',
                        AppFormatters.currency(plotExpenses),
                      ),
                      _KVRow(
                        'Laba / Rugi Lahan',
                        AppFormatters.currency(plotProfit),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfitSimulationScreen(initialCycleId: selectedCycleId),
                ),
              );
            },
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Simulasi Keuntungan'),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _KVRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
