import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../services/app_data_service.dart';
import '../widgets/tanijagung_widgets.dart';

/// HALAMAN 7: INPUT BENIH DAN PUPUK (Sesuai Gambar Referensi Baris 2 Kolom 2)
/// Dua Tab: "Benih" dan "Pupuk"
/// - Tab Benih: Nama benih, Jumlah benih, Satuan, Harga per satuan, Tanggal pembelian, Total harga otomatis, Keterangan, Tombol Simpan
/// - Tab Pupuk: Nama pupuk, Jumlah pupuk dibeli (kg), Harga pupuk per kg, Jumlah pupuk digunakan (kg), Tanggal pembelian, Tanggal penggunaan, Total harga otomatis (Contoh: 20 kg x Rp6.000 = Rp120.000)
class SeedFertilizerScreen extends StatefulWidget {
  final String? initialCycleId;
  final int initialTabIndex;

  const SeedFertilizerScreen({
    super.key,
    this.initialCycleId,
    this.initialTabIndex = 0,
  });

  @override
  State<SeedFertilizerScreen> createState() => _SeedFertilizerScreenState();
}

class _SeedFertilizerScreenState extends State<SeedFertilizerScreen> {
  late int _selectedTab; // 0 = Benih, 1 = Pupuk
  String? _selectedCycleId;

  // Controllers Tab Benih
  final _seedNameCtrl = TextEditingController();
  final _seedQtyCtrl = TextEditingController(text: '5');
  String _seedUnit = 'kg';
  final _seedPriceCtrl = TextEditingController(text: '24000');
  DateTime _seedBuyDate = DateTime.now();
  final _seedNotesCtrl = TextEditingController();
  bool _seedFromPaidStock = false;

  // Controllers Tab Pupuk
  final _fertNameCtrl = TextEditingController();
  final _fertBoughtKgCtrl = TextEditingController(text: '20');
  final _fertUsedKgCtrl = TextEditingController(text: '20');
  final _fertPricePerKgCtrl = TextEditingController(text: '6000');
  DateTime _fertBuyDate = DateTime.now();
  DateTime _fertUseDate = DateTime.now();
  final _fertNotesCtrl = TextEditingController();
  bool _fertFromPaidStock = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    final cycles = AppDataService().cycles;
    if (cycles.isNotEmpty) {
      _selectedCycleId = widget.initialCycleId ?? cycles.first.id;
    }
  }

  Future<void> _saveSeed() async {
    final service = AppDataService();
    if (_selectedCycleId == null || service.cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Buat Musim Tanam terlebih dahulu sebelum menyimpan benih.',
          ),
        ),
      );
      return;
    }

    final name = _seedNameCtrl.text.trim();
    final qty = AppFormatters.parsePositiveDouble(_seedQtyCtrl.text);
    final price = AppFormatters.parsePositiveDouble(
      _seedPriceCtrl.text,
      allowZero: true,
    );

    if (name.isEmpty || qty == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi nama benih, jumlah (> 0), dan harga satuan.'),
        ),
      );
      return;
    }

    final cyc = service.getCycleById(_selectedCycleId!)!;
    await service.addCropInput(
      plotId: cyc.plotId,
      cycleId: cyc.id,
      productName: name,
      inputType: 'Benih',
      quantity: qty,
      unit: _seedUnit,
      unitPrice: price,
      date: _seedBuyDate,
      isFromPaidStock: _seedFromPaidStock,
      recordAsExpense: !_seedFromPaidStock,
      notes: _seedNotesCtrl.text.trim(),
    );

    if (mounted) {
      _seedNameCtrl.clear();
      _seedNotesCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data benih berhasil disimpan dan dihitung otomatis.'),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _saveFertilizer() async {
    final service = AppDataService();
    if (_selectedCycleId == null || service.cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Buat Musim Tanam terlebih dahulu sebelum menyimpan pupuk.',
          ),
        ),
      );
      return;
    }

    final name = _fertNameCtrl.text.trim();
    final boughtKg = AppFormatters.parsePositiveDouble(
      _fertBoughtKgCtrl.text,
      allowZero: true,
    );
    final usedKg = AppFormatters.parsePositiveDouble(_fertUsedKgCtrl.text);
    final pricePerKg = AppFormatters.parsePositiveDouble(
      _fertPricePerKgCtrl.text,
      allowZero: true,
    );

    if (name.isEmpty ||
        boughtKg == null ||
        usedKg == null ||
        pricePerKg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lengkapi nama pupuk, jumlah dibeli (kg), jumlah digunakan (kg), dan harga per kg.',
          ),
        ),
      );
      return;
    }

    final cyc = service.getCycleById(_selectedCycleId!)!;
    final detailNote =
        'Dibeli: ${AppFormatters.number(boughtKg)} kg (${AppFormatters.shortDate(_fertBuyDate)}) • Digunakan: ${AppFormatters.number(usedKg)} kg (${AppFormatters.shortDate(_fertUseDate)})${_fertNotesCtrl.text.trim().isNotEmpty ? " • ${_fertNotesCtrl.text.trim()}" : ""}';

    // Jika jumlah dibeli > jumlah digunakan dan bukan dari stok lama, sisa otomatis dicatat ke stok gudang tanpa biaya ganda
    await service.addCropInput(
      plotId: cyc.plotId,
      cycleId: cyc.id,
      productName: name,
      inputType: 'Pupuk',
      quantity: usedKg,
      unit: 'kg',
      unitPrice: pricePerKg,
      date: _fertUseDate,
      isFromPaidStock: _fertFromPaidStock,
      recordAsExpense: !_fertFromPaidStock,
      notes: detailNote,
    );

    if (mounted) {
      _fertNameCtrl.clear();
      _fertNotesCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pupuk berhasil disimpan dan dihitung otomatis.'),
        ),
      );
      setState(() {});
    }
  }

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

        final seedQty =
            AppFormatters.parsePositiveDouble(_seedQtyCtrl.text) ?? 0.0;
        final seedPrice =
            AppFormatters.parsePositiveDouble(
              _seedPriceCtrl.text,
              allowZero: true,
            ) ??
            0.0;
        final seedTotal = seedQty * seedPrice;

        final fertUsedKg =
            AppFormatters.parsePositiveDouble(_fertUsedKgCtrl.text) ?? 0.0;
        final fertPrice =
            AppFormatters.parsePositiveDouble(
              _fertPricePerKgCtrl.text,
              allowZero: true,
            ) ??
            0.0;
        final fertTotal = fertUsedKg * fertPrice;

        final filteredHistory = service.cropInputs.where((i) {
          if (_selectedCycleId != null && i.cycleId != _selectedCycleId) {
            return false;
          }
          return _selectedTab == 0
              ? i.inputType == 'Benih'
              : i.inputType == 'Pupuk';
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Benih & Pupuk')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Pill Switcher: Benih | Pupuk (Persis Gambar Referensi)
              PillSegmentedSwitch(
                leftLabel: 'Benih',
                rightLabel: 'Pupuk',
                selectedIndex: _selectedTab,
                onChanged: (idx) => setState(() => _selectedTab = idx),
              ),
              const SizedBox(height: 16),

              // Pilihan Musim Tanam & Lahan
              if (cycles.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCycleId,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: cycles.map((c) {
                          final p = service.getPlotById(c.plotId);
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.name} • ${p?.name ?? "Lahan"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCycleId = val),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // FORM TAB 0: BENIH
              if (_selectedTab == 0)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Nama Benih'),
                        TextFormField(
                          controller: _seedNameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Jagung Pioneer / BISI 18',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Jumlah & Satuan'),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _seedQtyCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: 5',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _seedUnit,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'kg',
                                    child: Text('kg'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'gram',
                                    child: Text('gram'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'kantong',
                                    child: Text('kantong'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _seedUnit = v);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel('Harga per $_seedUnit'),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _seedPriceCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  prefixText: 'Rp ',
                                  hintText: '24000',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.softMintGreen,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  AppFormatters.currency(seedTotal),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                    color: AppTheme.primaryDarkGreen,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Tanggal Beli / Tanam'),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _seedBuyDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() => _seedBuyDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                            ),
                            child: Text(AppFormatters.shortDate(_seedBuyDate)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Keterangan (opsional)'),
                        TextFormField(
                          controller: _seedNotesCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Benih unggul hibrida',
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _seedFromPaidStock,
                          onChanged: (v) =>
                              setState(() => _seedFromPaidStock = v ?? false),
                          title: const Text(
                            'Diambil dari stok gudang yang sudah dibayar',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Mencegah penghitungan biaya dua kali pada pengeluaran.',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveSeed,
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // FORM TAB 1: PUPUK
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Nama Pupuk'),
                        TextFormField(
                          controller: _fertNameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Pupuk Urea / NPK Phonska',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Jumlah Dibeli (kg)'),
                                  TextFormField(
                                    controller: _fertBoughtKgCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      suffixText: 'kg',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Jumlah Digunakan (kg)'),
                                  TextFormField(
                                    controller: _fertUsedKgCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      suffixText: 'kg',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(
                          'Harga per Kg & Total Harga Otomatis',
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _fertPricePerKgCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  prefixText: 'Rp ',
                                  suffixText: '/kg',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.softMintGreen,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  AppFormatters.currency(fertTotal),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                    color: AppTheme.primaryDarkGreen,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Tanggal Beli'),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _fertBuyDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setState(() => _fertBuyDate = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(),
                                      child: Text(
                                        AppFormatters.shortDate(_fertBuyDate),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Tanggal Pakai'),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _fertUseDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setState(() => _fertUseDate = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(),
                                      child: Text(
                                        AppFormatters.shortDate(_fertUseDate),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Keterangan (opsional)'),
                        TextFormField(
                          controller: _fertNotesCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Pemupukan tahap 1 umur 15 HST',
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _fertFromPaidStock,
                          onChanged: (v) =>
                              setState(() => _fertFromPaidStock = v ?? false),
                          title: const Text(
                            'Menggunakan pupuk dari stok yang sudah dibeli',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Tidak dihitung ulang sebagai biaya pengeluaran baru.',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveFertilizer,
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              Text(
                'Riwayat Pencatatan ${_selectedTab == 0 ? "Benih" : "Pupuk"} (${filteredHistory.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (filteredHistory.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Belum ada data tercatat pada musim tanam ini.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...filteredHistory.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _selectedTab == 0
                              ? AppTheme.cornYellowLight
                              : AppTheme.lightLeafGreen,
                          child: Icon(
                            _selectedTab == 0
                                ? Icons.grain_rounded
                                : Icons.inventory_2_outlined,
                            color: AppTheme.primaryDarkGreen,
                          ),
                        ),
                        title: Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${AppFormatters.number(item.quantity)} ${item.unit} × ${AppFormatters.currency(item.unitPrice)} = ${AppFormatters.currency(item.subtotal)}\n${AppFormatters.shortDate(item.date)} ${item.notes.isNotEmpty ? "• ${item.notes}" : ""}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.dangerRed,
                          ),
                          onPressed: () => service.deleteCropInput(item.id),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const BottomCornLeavesDecoration(),
            ],
          ),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
