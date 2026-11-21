import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_models.dart';
import '../services/app_data_service.dart';
import '../widgets/app_form_dialogs.dart';
import '../widgets/tanijagung_widgets.dart';

/// HALAMAN 9: DAFTAR PENGELUARAN (Sesuai Gambar Referensi Baris 2 Kolom 3)
/// - Menampilkan daftar transaksi dengan ikon karung/kantong sesuai kategori
/// - Filter Kategori (9 kategori: Benih, Pupuk, Pestisida, Pengolahan lahan, Tenaga kerja, Sewa alat, Transportasi, Biaya panen, Lain-lain)
/// - Tombol "+ Tambah Pengeluaran"
/// - Footer Total Pengeluaran seluruh transaksi
class ExpensesScreen extends StatefulWidget {
  final String? initialCycleId;
  const ExpensesScreen({super.key, this.initialCycleId});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? _selectedCycleId;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _selectedCycleId = widget.initialCycleId;
  }

  Color _categoryBgColor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('pupuk')) return const Color(0xFFE3F2FD);
    if (c.contains('benih')) return AppTheme.cornYellowLight;
    if (c.contains('tenaga') || c.contains('panen')) {
      return const Color(0xFFFFF3E0);
    }
    return AppTheme.lightLeafGreen;
  }

  Color _categoryIconColor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('pupuk')) return AppTheme.infoBlue;
    if (c.contains('benih')) return const Color(0xFFD97706);
    if (c.contains('tenaga') || c.contains('panen')) {
      return const Color(0xFFE65100);
    }
    return AppTheme.primaryDarkGreen;
  }

  IconData _categoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('benih')) return Icons.grain_rounded;
    if (c.contains('pupuk')) return Icons.inventory_2_rounded;
    if (c.contains('pestisida')) return Icons.sanitizer_outlined;
    if (c.contains('alat') || c.contains('pengolahan')) {
      return Icons.agriculture_rounded;
    }
    if (c.contains('transport')) return Icons.local_shipping_outlined;
    return Icons.shopping_bag_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final cycles = service.cycles;
        List<ExpenseModel> list = service.expenses;

        if (_selectedCycleId != null) {
          list = list.where((e) => e.cycleId == _selectedCycleId).toList();
        }
        if (_selectedCategory != 'Semua') {
          list = list.where((e) => e.category == _selectedCategory).toList();
        }

        double totalExpenses = 0.0;
        for (final e in list) {
          totalExpenses += e.totalCost;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Pengeluaran')),
          body: Column(
            children: [
              // Filter Musim Tanam & Kategori
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Column(
                  children: [
                    if (cycles.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedCycleId,
                              isExpanded: true,
                              hint: const Text('Semua Musim Tanam'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(
                                    'Semua Musim Tanam',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                ...cycles.map(
                                  (c) => DropdownMenuItem<String?>(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedCycleId = v),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Semua', ...AppConstants.expenseCategories]
                            .map((cat) {
                              final selected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: selected,
                                  selectedColor: AppTheme.primaryDarkGreen,
                                  labelStyle: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = cat),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Daftar Карtu Pengeluaran (Sesuai Gambar Referensi)
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Belum ada data pengeluaran tercatat.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        itemCount: list.length,
                        itemBuilder: (context, idx) {
                          final exp = list[idx];
                          final plot = service.getPlotById(exp.plotId);
                          final cycle = service.getCycleById(exp.cycleId);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: _categoryBgColor(exp.category),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        _categoryIcon(exp.category),
                                        color: _categoryIconColor(exp.category),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exp.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            exp.isFromFertilizerStock
                                                ? 'Rp0 (Diambil dari Stok Pupuk: ${AppFormatters.number(exp.stockTakenQuantity)} ${exp.unit})'
                                                : AppFormatters.currency(
                                                    exp.totalCost,
                                                  ),
                                            style: TextStyle(
                                              fontSize:
                                                  exp.isFromFertilizerStock
                                                  ? 13.5
                                                  : 16,
                                              fontWeight: FontWeight.w900,
                                              color: exp.isFromFertilizerStock
                                                  ? AppTheme.darkGreen
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${AppFormatters.date(exp.date)} • ${exp.category} • ${plot?.name ?? "-"} (${cycle?.name ?? "-"})',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit Pengeluaran',
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppTheme.textSecondary,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              AppFormDialogs.showExpenseForm(
                                                context,
                                                existingExpense: exp,
                                              ),
                                        ),
                                        IconButton(
                                          tooltip: 'Hapus Pengeluaran',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.dangerRed,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              service.deleteExpense(exp.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bagian Bawah: Tombol "+ Tambah Pengeluaran" & Total Pengeluaran (Persis Gambar Referensi)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.softMintGreen,
                          foregroundColor: AppTheme.primaryDarkGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () => AppFormDialogs.showExpenseForm(
                          context,
                          preselectedCycleId: _selectedCycleId,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Tambah Pengeluaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pengeluaran',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          AppFormatters.currency(totalExpenses),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
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
}
