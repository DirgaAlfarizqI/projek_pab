import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_models.dart';
import '../services/app_data_service.dart';
import '../widgets/tanijagung_widgets.dart';

/// HALAMAN 16: STOK BENIH DAN PUPUK (Sesuai Gambar Referensi Baris 3 Kolom 4)
/// - Pill Switcher: "Benih" | "Pupuk"
/// - Kartu Produk dengan Ikon Karung Hijau, Nama Produk, "Stok Tersedia 20 kg", Badge Kuning/Oranye "⚠ Stok menipis" (jika di bawah batas minimum)
/// - Detail Rumus: Stok Akhir = Stok Awal + Stok Masuk - Stok Keluar
/// - Tombol Hijau Penuh "+ Tambah Stok" & Riwayat Transaksi
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _selectedTab =
      1; // Default tampilkan Pupuk (atau Benih = 0) seperti referensi

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final allItems = service.inventory;
        final filteredItems = allItems.where((item) {
          if (_selectedTab == 0) {
            return item.itemType.toLowerCase() == 'benih';
          }
          return item.itemType.toLowerCase() != 'benih';
        }).toList();

        final transactions = service.inventoryTransactions;

        return Scaffold(
          appBar: AppBar(title: const Text('Stok Benih & Pupuk')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Pill Switcher: Benih | Pupuk (Persis Gambar Referensi Baris 3 Kolom 4)
              PillSegmentedSwitch(
                leftLabel: 'Benih',
                rightLabel: 'Pupuk',
                selectedIndex: _selectedTab,
                onChanged: (idx) => setState(() => _selectedTab = idx),
              ),
              const SizedBox(height: 18),

              if (filteredItems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Belum Ada Stok ${_selectedTab == 0 ? "Benih" : "Pupuk"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tambahkan stok awal dan batas minimum peringatan untuk memantau sisa persediaan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredItems.map((item) {
                  final isLow = item.isLowStock || item.isOutOfStock;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ikon Karung Hijau (Persis Gambar Referensi)
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightLeafGreen,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    size: 34,
                                    color: AppTheme.primaryDarkGreen,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.itemName,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: AppTheme.dangerRed,
                                            ),
                                            onPressed: () => service
                                                .deleteInventoryItem(item.id),
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'Stok Tersedia',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${AppFormatters.number(item.remainingStock)} ${item.unit}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (isLow) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cornYellowLight,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.warning_amber_rounded,
                                                size: 16,
                                                color: Color(0xFFD97706),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                item.isOutOfStock
                                                    ? 'Stok habis'
                                                    : 'Stok menipis (Min: ${AppFormatters.number(item.minimumStockAlert)} ${item.unit})',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFB45309),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 22),
                            // Rumus Stok: Stok Akhir = Stok Awal + Stok Masuk - Stok Keluar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Awal: ${AppFormatters.number(item.initialStock)} ${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  '+ Masuk: ${AppFormatters.number(item.stockIn)} ${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.leafGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '- Keluar: ${AppFormatters.number(item.stockOut)} ${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.dangerRed,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showStockTransactionDialog(
                                          context,
                                          item,
                                          'Masuk',
                                        ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Stok Masuk'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: item.remainingStock <= 0
                                        ? null
                                        : () => _showStockTransactionDialog(
                                            context,
                                            item,
                                            'Keluar',
                                          ),
                                    icon: const Icon(Icons.remove, size: 18),
                                    label: const Text('Pakai Stok'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 6),
              // Tombol Hijau Penuh "+ Tambah Stok" (Persis Gambar Referensi Baris 3 Kolom 4)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddInventoryDialog(
                    context,
                    defaultType: _selectedTab == 0 ? 'Benih' : 'Pupuk',
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text('Tambah Stok'),
                ),
              ),

              if (transactions.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Riwayat Transaksi Stok',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...transactions.take(6).map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          tx.transactionType == 'Keluar'
                              ? Icons.call_made_rounded
                              : Icons.call_received_rounded,
                          color: tx.transactionType == 'Keluar'
                              ? AppTheme.dangerRed
                              : AppTheme.leafGreen,
                        ),
                        title: Text(
                          '${tx.transactionType}: ${tx.itemName} (${AppFormatters.number(tx.quantity)} ${tx.unit})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${AppFormatters.date(tx.date)} • Harga: ${AppFormatters.currency(tx.unitPrice)}/${tx.unit}',
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              const BottomCornLeavesDecoration(),
            ],
          ),
        );
      },
    );
  }

  void _showAddInventoryDialog(
    BuildContext context, {
    required String defaultType,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final initStockCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final minStockCtrl = TextEditingController(text: '25');
    String itemType = defaultType;
    String unit = 'kg';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Produk Stok Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk *',
                      hintText: 'Contoh: Pupuk Urea / Benih Pioneer',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: itemType,
                          decoration: const InputDecoration(
                            labelText: 'Jenis *',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Benih',
                              child: Text('Benih'),
                            ),
                            DropdownMenuItem(
                              value: 'Pupuk',
                              child: Text('Pupuk'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => itemType = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: unit,
                          decoration: const InputDecoration(
                            labelText: 'Satuan *',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(
                              value: 'gram',
                              child: Text('gram'),
                            ),
                            DropdownMenuItem(
                              value: 'karung',
                              child: Text('karung'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => unit = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: initStockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Stok Awal *',
                          ),
                          validator: (v) =>
                              AppFormatters.parsePositiveDouble(
                                    v,
                                    allowZero: true,
                                  ) ==
                                  null
                              ? 'Tidak valid'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: minStockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Batas Min. Stok *',
                          ),
                          validator: (v) =>
                              AppFormatters.parsePositiveDouble(
                                    v,
                                    allowZero: true,
                                  ) ==
                                  null
                              ? 'Tidak valid'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Harga Pembelian per Satuan (Rp) *',
                    ),
                    validator: (v) =>
                        AppFormatters.parsePositiveDouble(v, allowZero: true) ==
                            null
                        ? 'Masukkan harga valid'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await AppDataService().addInventoryItem(
                          itemName: nameCtrl.text,
                          itemType: itemType,
                          initialStock: AppFormatters.parsePositiveDouble(
                            initStockCtrl.text,
                            allowZero: true,
                          )!,
                          unit: unit,
                          purchasePrice: AppFormatters.parsePositiveDouble(
                            priceCtrl.text,
                            allowZero: true,
                          )!,
                          minimumStockAlert: AppFormatters.parsePositiveDouble(
                            minStockCtrl.text,
                            allowZero: true,
                          )!,
                          transactionDate: DateTime.now(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Simpan Stok'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStockTransactionDialog(
    BuildContext context,
    InventoryItemModel item,
    String type,
  ) {
    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: item.lastPurchasePrice.round().toString(),
    );
    final notesCtrl = TextEditingController();
    final service = AppDataService();
    String? selectedCycleId = service.cycles.isNotEmpty
        ? service.cycles.first.id
        : null;
    bool recordExpense = type == 'Masuk';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stok $type: ${item.itemName}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Sisa stok tersedia: ${AppFormatters.number(item.remainingStock)} ${item.unit}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Jumlah (${item.unit}) *',
                    ),
                    validator: (v) {
                      final val = AppFormatters.parsePositiveDouble(v);
                      if (val == null) return 'Wajib > 0';
                      if (type == 'Keluar' && val > item.remainingStock) {
                        return 'Melebihi sisa stok (${item.remainingStock})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Harga per ${item.unit} (Rp) *',
                    ),
                    validator: (v) =>
                        AppFormatters.parsePositiveDouble(v, allowZero: true) ==
                            null
                        ? 'Tidak valid'
                        : null,
                  ),
                  if (service.cycles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedCycleId,
                      decoration: const InputDecoration(
                        labelText: 'Hubungkan ke Musim Tanam',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tidak dihubungkan'),
                        ),
                        ...service.cycles.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedCycleId = v),
                    ),
                  ],
                  if (type == 'Masuk' && selectedCycleId != null)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Catat pembelian ini sebagai Pengeluaran',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: recordExpense,
                      onChanged: (v) =>
                          setState(() => recordExpense = v ?? false),
                    ),
                  if (type == 'Keluar' && selectedCycleId != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Penggunaan stok ini tidak akan dihitung ulang sebagai pengeluaran baru (bebas biaya ganda).',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryDarkGreen,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Catatan'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await service.recordInventoryTransaction(
                          inventoryId: item.id,
                          transactionType: type,
                          quantity: AppFormatters.parsePositiveDouble(
                            qtyCtrl.text,
                          )!,
                          unitPrice: AppFormatters.parsePositiveDouble(
                            priceCtrl.text,
                            allowZero: true,
                          )!,
                          date: DateTime.now(),
                          cycleId: selectedCycleId,
                          recordPurchaseAsExpense:
                              type == 'Masuk' && recordExpense,
                          notes: notesCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Simpan Transaksi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
