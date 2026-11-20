import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../services/app_data_service.dart';
import '../widgets/tanijagung_widgets.dart';

/// HALAMAN 14: SIMULASI KEUNTUNGAN (Sesuai Gambar Referensi Baris 3 Kolom 2)
/// - Input Hasil Panen (Ton)
/// - Input Harga Jual (Rp/Kg)
/// - Input Total Biaya (Rp)
/// - Kotak Hijau Muda: Keuntungan Rp24.500.000 (+ Pendapatan Otomatis & Harga Impas)
/// - Tombol "Hitung Ulang"
/// - Tidak mengubah data keuangan aktual
class ProfitSimulationScreen extends StatefulWidget {
  final String? initialCycleId;
  const ProfitSimulationScreen({super.key, this.initialCycleId});

  @override
  State<ProfitSimulationScreen> createState() => _ProfitSimulationScreenState();
}

class _ProfitSimulationScreenState extends State<ProfitSimulationScreen> {
  String? _selectedCycleId;
  final _yieldTonsCtrl = TextEditingController(text: '7.0');
  final _pricePerKgCtrl = TextEditingController(text: '4000');
  final _totalCostCtrl = TextEditingController(text: '3500000');

  @override
  void initState() {
    super.initState();
    final service = AppDataService();
    if (service.cycles.isNotEmpty) {
      _selectedCycleId = widget.initialCycleId ?? service.cycles.first.id;
      _loadFromCycle(_selectedCycleId!);
    }
  }

  void _loadFromCycle(String cycleId) {
    final summary = AppDataService().calculateCycleSummary(cycleId);
    final tons = summary.totalHarvestTons > 0
        ? summary.totalHarvestTons
        : (summary.cycle.targetYieldTons ?? 7.0);
    final price = summary.averageSellingPricePerKg > 0
        ? summary.averageSellingPricePerKg
        : 4000.0;
    final cost = summary.totalExpenses > 0 ? summary.totalExpenses : 3500000.0;

    _yieldTonsCtrl.text = tons.toStringAsFixed(1);
    _pricePerKgCtrl.text = price.round().toString();
    _totalCostCtrl.text = cost.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final service = AppDataService();
    final cycles = service.cycles;

    final tons =
        AppFormatters.parsePositiveDouble(
          _yieldTonsCtrl.text,
          allowZero: true,
        ) ??
        0.0;
    final kg = tons * 1000.0;
    final pricePerKg =
        AppFormatters.parsePositiveDouble(
          _pricePerKgCtrl.text,
          allowZero: true,
        ) ??
        0.0;
    final totalCost =
        AppFormatters.parsePositiveDouble(
          _totalCostCtrl.text,
          allowZero: true,
        ) ??
        0.0;

    final simRevenue = kg * pricePerKg;
    final simProfit = simRevenue - totalCost;
    final breakEvenPricePerKg = kg > 0 ? (totalCost / kg) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulasi Keuntungan'),
        actions: [
          IconButton(
            tooltip: 'Reset ke Data Musim Tanam',
            onPressed: () {
              if (_selectedCycleId != null) {
                setState(() => _loadFromCycle(_selectedCycleId!));
              } else {
                setState(() {
                  _yieldTonsCtrl.text = '7.0';
                  _pricePerKgCtrl.text = '4000';
                  _totalCostCtrl.text = '3500000';
                });
              }
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (cycles.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCycleId,
                    isExpanded: true,
                    items: cycles
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              'Acuan Awal: ${c.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCycleId = val;
                          _loadFromCycle(val);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hasil Panen (Ton)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _yieldTonsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      suffixIcon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      helperText:
                          'Setara ${AppFormatters.number(kg)} kg (1 ton = 1.000 kg)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Harga Jual (Rp/Kg)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pricePerKgCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(prefixText: 'Rp '),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Total Biaya (Rp)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _totalCostCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(prefixText: 'Rp '),
                  ),
                  const SizedBox(height: 22),

                  // Kotak Hijau Muda Hasil Simulasi (Persis Gambar Referensi)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: simProfit >= 0
                          ? AppTheme.softMintGreen
                          : AppTheme.dangerLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          simProfit > 0
                              ? 'Keuntungan (Simulasi)'
                              : (simProfit < 0
                                    ? 'Kerugian (Simulasi)'
                                    : 'Impas (Simulasi)'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: simProfit >= 0
                                ? AppTheme.textPrimary
                                : AppTheme.dangerRed,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.currency(simProfit),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: simProfit >= 0
                                ? AppTheme.primaryDarkGreen
                                : AppTheme.dangerRed,
                          ),
                        ),
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Hasil Pendapatan Otomatis:',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(simRevenue),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Harga Impas (Break-Even / Kg):',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '${AppFormatters.currency(breakEvenPricePerKg)} / kg',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Simulasi keuntungan berhasil dihitung ulang (data keuangan aktual tidak berubah).',
                            ),
                          ),
                        );
                      },
                      child: const Text('Hitung Ulang'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '* Catatan: Hasil perhitungan di halaman ini adalah simulasi dan tidak mengubah catatan keuangan aktual usaha tani Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          const BottomCornLeavesDecoration(),
        ],
      ),
    );
  }
}
