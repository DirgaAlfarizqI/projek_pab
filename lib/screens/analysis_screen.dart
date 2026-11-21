import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../services/app_data_service.dart';
import '../widgets/app_form_dialogs.dart';
import '../widgets/tanijagung_widgets.dart';
import '../widgets/ui_kit.dart';
import 'profit_simulation_screen.dart';
import 'reports_screen.dart';

/// =====================================================================
/// HALAMAN ANALISIS KEUANGAN (Tahap 4 Redesain — Modern, Hidup, Premium)
/// =====================================================================
/// - TIDAK ADA menu, card, grafik, atau shortcut Produktivitas.
/// - Selama belum ada data panen, tampilkan kartu netral "Menunggu data panen"
///   dan sembunyikan persentase -100%.
/// - Grafik Donut & Batang menggambar dari 0 saat halaman muncul + tooltip
///   interaktif animatif dengan haptic feedback saat disentuh.
/// - Empty state ilustrasi ladang jagung beranimasi lembut.
/// - Responsif ponsel & tablet (ResponsiveCenter + AdaptiveTwoColumn).
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
        final colors = context.appColors;

        if (cycles.isNotEmpty &&
            (_selectedCycleId == null ||
                !cycles.any((c) => c.id == _selectedCycleId))) {
          _selectedCycleId = cycles.first.id;
        }

        return Scaffold(
          backgroundColor: colors.background,
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
          body: ResponsiveCenter(
            maxWidth: 760,
            child: cycles.isEmpty
                ? Center(
                    child: CornEmptyState(
                      title: 'Belum Ada Musim Tanam untuk Dianalisis',
                      message: 'Mulai catat lahan dan musim tanam jagung Anda untuk melihat grafik pendapatan, pengeluaran, serta perhitungan harga impas.',
                      actionLabel: 'Buat Musim Tanam',
                      actionIcon: Icons.event_available_rounded,
                      onAction: () =>
                          AppFormDialogs.showPlantingCycleForm(context),
                    ),
                  )
                : _FinanceAnalysisContent(
                    selectedCycleId: _selectedCycleId!,
                    cycles: cycles,
                    onSelectCycle: (id) =>
                        setState(() => _selectedCycleId = id),
                    subTab: _financeSubTab,
                    onSubTabChanged: (idx) =>
                        setState(() => _financeSubTab = idx),
                  ),
          ),
        );
      },
    );
  }
}

class _FinanceAnalysisContent extends StatefulWidget {
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
  State<_FinanceAnalysisContent> createState() =>
      _FinanceAnalysisContentState();
}

class _FinanceAnalysisContentState extends State<_FinanceAnalysisContent> {
  int _touchedPieIndex = -1;
  int _touchedBarIndex = -1;

  @override
  Widget build(BuildContext context) {
    final service = AppDataService();
    final user = service.currentUser!;
    final colors = context.appColors;
    final summary = service.calculateCycleSummary(widget.selectedCycleId);

    final hasHarvest = summary.hasHarvestData;
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

    final plots = service.plots;
    final chartAnimDur = AppMotion.of(
      context,
      const Duration(milliseconds: 560),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        // 1. Pilihan Musim Tanam
        StaggeredEntrance(
          index: 0,
          child: SoftCard(
            radius: AppRadius.lg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.selectedCycleId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: widget.cycles
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c.id as String,
                        child: Text(
                          '${c.name} (${c.cornVariety})',
                          style: TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    HapticFeedback.selectionClick();
                    widget.onSelectCycle(v);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Pill Switcher: Ringkasan | Detail
        StaggeredEntrance(
          index: 1,
          child: PillSegmentedSwitch(
            leftLabel: 'Ringkasan',
            rightLabel: 'Detail',
            selectedIndex: widget.subTab,
            onChanged: (idx) {
              HapticFeedback.selectionClick();
              widget.onSubTabChanged(idx);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (widget.subTab == 0) ...[
          // 3. Total Pendapatan & Total Pengeluaran (Count-Up)
          StaggeredEntrance(
            index: 2,
            child: Row(
              children: [
                Expanded(
                  child: SoftCard(
                    radius: AppRadius.xl,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Total Pendapatan',
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
                        const SizedBox(height: 8),
                        if (hasHarvest)
                          AnimatedCountUp(
                            value: revenue,
                            formatter: AppFormatters.currency,
                            style: AppTextStyles.money(
                              size: 18,
                              color: colors.textPrimary,
                            ),
                          )
                        else
                          Text(
                            'Belum Panen',
                            style: TextStyle(
                              fontFamily: AppTheme.headingFont,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SoftCard(
                    radius: AppRadius.xl,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.cornYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Total Pengeluaran',
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
                        const SizedBox(height: 8),
                        AnimatedCountUp(
                          value: expenses,
                          formatter: AppFormatters.currency,
                          style: AppTextStyles.money(
                            size: 18,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Banner Status Keuangan (Revisi 2c: Kartu netral "Menunggu data panen" & sembunyikan -100% selama belum panen)
          StaggeredEntrance(
            index: 3,
            child: !hasHarvest
                ? Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.cornYellowLight,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: AppShadows.soft,
                      border: Border.all(
                        color: AppTheme.cornYellow,
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppTheme.cornYellow.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            color: AppTheme.darkGreen,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Menunggu data panen',
                                style: TextStyle(
                                  fontFamily: AppTheme.headingFont,
                                  color: AppTheme.textPrimary,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Pengeluaran: ${AppFormatters.currency(expenses)} • Untung/rugi dihitung setelah panen diisi.',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: profit >= 0
                          ? AppTheme.heroGradient
                          : AppTheme.lossGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: profit >= 0
                          ? AppShadows.hero
                          : AppShadows.medium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profit >= 0
                                    ? 'Keuntungan (Untung)'
                                    : 'Kerugian (Rugi)',
                                style: const TextStyle(
                                  color: Color(0xFFD9ECE0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedCountUp(
                                value: profit,
                                formatter: AppFormatters.currency,
                                style: AppTextStyles.money(
                                  size: 25,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PulseBadge(
                          label:
                              '${profit >= 0 ? "+" : "-"}${AppFormatters.number(pct.abs())}%',
                          background: Colors.white.withValues(alpha: 0.20),
                          foreground: Colors.white,
                          icon: profit >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),

          // 5. Biaya Produksi & Harga Impas
          StaggeredEntrance(
            index: 4,
            child: SoftCard(
              radius: AppRadius.xl,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _KVRow(
                    'Biaya Produksi Total',
                    AppFormatters.currency(summary.totalExpenses),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
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

          // 6. Grafik Donut & Batang (Adaptif 2 Kolom di Tablet, Menggambar dari 0 + Tooltip Interaktif)
          StaggeredEntrance(
            index: 5,
            child: AdaptiveTwoColumn(
              children: [
                // Grafik Pendapatan dan Pengeluaran (Donut Chart)
                SoftCard(
                  radius: AppRadius.xl,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grafik Pendapatan & Pengeluaran',
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        key: ValueKey('pie_${widget.selectedCycleId}'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: chartAnimDur,
                        curve: AppMotion.standard,
                        builder: (context, animT, _) {
                          final revVal =
                              (revenue > 0 ? revenue : 1.0) *
                              (animT < 0.05 ? 0.05 : animT);
                          final expVal =
                              (expenses > 0 ? expenses : 1.0) *
                              (animT < 0.05 ? 0.05 : animT);
                          return Row(
                            children: [
                              SizedBox(
                                width: 118,
                                height: 118,
                                child: PieChart(
                                  PieChartData(
                                    centerSpaceRadius: 32,
                                    sectionsSpace: 3,
                                    pieTouchData: PieTouchData(
                                      touchCallback: (event, resp) {
                                        if (!event
                                                .isInterestedForInteractions ||
                                            resp == null ||
                                            resp.touchedSection == null) {
                                          if (_touchedPieIndex != -1) {
                                            setState(
                                              () => _touchedPieIndex = -1,
                                            );
                                          }
                                          return;
                                        }
                                        final newIdx = resp
                                            .touchedSection!
                                            .touchedSectionIndex;
                                        if (newIdx != _touchedPieIndex) {
                                          HapticFeedback.selectionClick();
                                          setState(
                                            () => _touchedPieIndex = newIdx,
                                          );
                                        }
                                      },
                                    ),
                                    sections: [
                                      PieChartSectionData(
                                        value: revVal,
                                        color: AppTheme.primaryGreen,
                                        radius: _touchedPieIndex == 0 ? 28 : 23,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: expVal,
                                        color: AppTheme.cornYellow,
                                        radius: _touchedPieIndex == 1 ? 28 : 23,
                                        showTitle: false,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _LegendDot(
                                      color: AppTheme.primaryGreen,
                                      label: 'Pendapatan',
                                      value: hasHarvest
                                          ? AppFormatters.currency(revenue)
                                          : 'Menunggu data panen',
                                      highlighted: _touchedPieIndex == 0,
                                    ),
                                    const SizedBox(height: 10),
                                    _LegendDot(
                                      color: AppTheme.cornYellow,
                                      label: 'Pengeluaran',
                                      value: AppFormatters.currency(expenses),
                                      highlighted: _touchedPieIndex == 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Perbandingan Hasil Panen Antar Musim Tanam (Bar Chart Menggambar dari 0 + Tooltip)
                SoftCard(
                  radius: AppRadius.xl,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perbandingan Hasil Panen Antar Musim (${user.preferredWeightUnit.toUpperCase()})',
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TweenAnimationBuilder<double>(
                        key: ValueKey('bar_${widget.selectedCycleId}'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: chartAnimDur,
                        curve: AppMotion.standard,
                        builder: (context, animT, _) {
                          return SizedBox(
                            height: 175,
                            child: BarChart(
                              BarChartData(
                                maxY: maxYieldTons * 1.25,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchCallback: (event, resp) {
                                    if (!event.isInterestedForInteractions ||
                                        resp == null ||
                                        resp.spot == null) {
                                      if (_touchedBarIndex != -1) {
                                        setState(() => _touchedBarIndex = -1);
                                      }
                                      return;
                                    }
                                    final idx = resp.spot!.touchedBarGroupIndex;
                                    if (idx != _touchedBarIndex) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _touchedBarIndex = idx);
                                    }
                                  },
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => AppTheme.darkGreen,
                                    tooltipBorderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                          if (groupIndex < 0 ||
                                              groupIndex >=
                                                  allSummaries.length) {
                                            return null;
                                          }
                                          final s = allSummaries[groupIndex];
                                          return BarTooltipItem(
                                            '${s.cycle.name}\n${AppFormatters.formatWeightByPreference(s.totalHarvestTons, user.preferredWeightUnit)}',
                                            const TextStyle(
                                              fontFamily: AppTheme.headingFont,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11.5,
                                            ),
                                          );
                                        },
                                  ),
                                ),
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
                                        if (idx < 0 ||
                                            idx >= allSummaries.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          AppFormatters.formatWeightByPreference(
                                            allSummaries[idx].totalHarvestTons,
                                            user.preferredWeightUnit,
                                          ),
                                          style: TextStyle(
                                            fontFamily: AppTheme.headingFont,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: colors.textPrimary,
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
                                        if (idx < 0 ||
                                            idx >= allSummaries.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            'MT ${idx + 1}',
                                            style: TextStyle(
                                              fontFamily: AppTheme.headingFont,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: List.generate(allSummaries.length, (
                                  i,
                                ) {
                                  final isSelected =
                                      allSummaries[i].cycle.id ==
                                      widget.selectedCycleId;
                                  final isTouched = i == _touchedBarIndex;
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY:
                                            allSummaries[i].totalHarvestTons *
                                            animT,
                                        width: isTouched ? 32 : 28,
                                        color: isSelected
                                            ? AppTheme.primaryGreen
                                            : AppTheme.cornYellow,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(10),
                                            ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // TAB 1: DETAIL KEUANGAN, KOMPOSISI KATEGORI PENGELUARAN & RINGKASAN KEUANGAN PER LAHAN
          StaggeredEntrance(
            index: 2,
            child: SoftCard(
              radius: AppRadius.xl,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rincian Keuangan Musim Tanam',
                    style: TextStyle(
                      fontFamily: AppTheme.headingFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
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
                    hasHarvest
                        ? AppFormatters.formatWeightByPreference(
                            summary.totalHarvestTons,
                            user.preferredWeightUnit,
                          )
                        : 'Menunggu data panen',
                  ),
                  _KVRow(
                    'Harga Jual Rata-rata',
                    hasHarvest
                        ? '${AppFormatters.currency(summary.averageSellingPricePerKg)} / kg'
                        : 'Menunggu data panen',
                  ),
                  _KVRow(
                    'Total Pendapatan',
                    hasHarvest
                        ? AppFormatters.currency(summary.totalRevenue)
                        : 'Menunggu data panen',
                    bold: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _KVRow(
                    'Keuntungan / Kerugian',
                    hasHarvest
                        ? '${profit >= 0 ? "Untung" : "Rugi"} (${AppFormatters.currency(summary.netProfitOrLoss)})'
                        : 'Menunggu data panen',
                    bold: true,
                  ),
                  _KVRow(
                    'Biaya Produksi per Kg',
                    hasHarvest
                        ? '${AppFormatters.currency(summary.productionCostPerKg)} / kg'
                        : 'Menunggu data panen',
                  ),
                  _KVRow(
                    'Harga Impas per Kg',
                    hasHarvest
                        ? '${AppFormatters.currency(summary.breakEvenPricePerKg)} / kg'
                        : 'Menunggu data panen',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rincian Pengeluaran per Kategori (Pupuk, Benih, Pestisida, Pengolahan lahan, Lain-lain)
          StaggeredEntrance(
            index: 3,
            child: SoftCard(
              radius: AppRadius.xl,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rincian Pengeluaran per Kategori',
                    style: TextStyle(
                      fontFamily: AppTheme.headingFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...AppConstants.expenseCategories.map((cat) {
                    final amount = summary.expensesByCategory[cat] ?? 0.0;
                    final ratio = expenses > 0
                        ? (amount / expenses).clamp(0.0, 1.0)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          _KVRow(
                            cat,
                            AppFormatters.currency(amount),
                            bold: amount > 0,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: ratio),
                              duration: chartAnimDur,
                              curve: AppMotion.standard,
                              builder: (context, v, _) =>
                                  LinearProgressIndicator(
                                    value: v,
                                    minHeight: 6,
                                    backgroundColor: colors.accentTint,
                                    color: amount > 0
                                        ? AppTheme.primaryGreen
                                        : colors.border,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Ringkasan Keuangan per Lahan (Adaptif 2 Kolom di Tablet)
          StaggeredEntrance(
            index: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Ringkasan Keuangan per Lahan'),
                const SizedBox(height: 10),
                AdaptiveTwoColumn(
                  children: plots.map((plot) {
                    final plotCycles = service.getCyclesForPlot(plot.id);
                    double plotExpenses = 0;
                    double plotRevenue = 0;
                    double plotTons = 0;
                    bool plotHasHarvest = false;
                    for (final c in plotCycles) {
                      final s = service.calculateCycleSummary(c.id);
                      plotExpenses += s.totalExpenses;
                      plotRevenue += s.totalRevenue;
                      plotTons += s.totalHarvestTons;
                      if (s.hasHarvestData) {
                        plotHasHarvest = true;
                      }
                    }
                    final plotProfit = plotRevenue - plotExpenses;

                    return SoftCard(
                      radius: AppRadius.xl,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${plot.name} (${AppFormatters.formatAreaByPreference(plot.areaInHectares, user.preferredAreaUnit)})',
                                  style: TextStyle(
                                    fontFamily: AppTheme.headingFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${plotCycles.length} Musim • ${AppFormatters.formatWeightByPreference(plotTons, user.preferredWeightUnit)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          _KVRow(
                            'Total Pendapatan Lahan',
                            plotHasHarvest
                                ? AppFormatters.currency(plotRevenue)
                                : 'Menunggu data panen',
                          ),
                          _KVRow(
                            'Total Pengeluaran Lahan',
                            AppFormatters.currency(plotExpenses),
                          ),
                          _KVRow(
                            'Status / Hasil Lahan',
                            plotHasHarvest
                                ? '${plotProfit >= 0 ? "Untung" : "Rugi"} (${AppFormatters.currency(plotProfit)})'
                                : 'Menunggu data panen',
                            bold: true,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),
        StaggeredEntrance(
          index: 6,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfitSimulationScreen(
                      initialCycleId: widget.selectedCycleId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Simulasi Keuntungan'),
            ),
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
  final bool highlighted;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedContainer(
      duration: AppMotion.fast,
      padding: EdgeInsets.symmetric(
        horizontal: highlighted ? 8 : 0,
        vertical: highlighted ? 4 : 0,
      ),
      decoration: BoxDecoration(
        color: highlighted ? colors.accentTint : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
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
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: bold ? AppTheme.headingFont : AppTheme.bodyFont,
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
