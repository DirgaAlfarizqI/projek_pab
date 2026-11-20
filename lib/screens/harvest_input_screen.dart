import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../services/app_data_service.dart';
import '../widgets/app_form_dialogs.dart';
import '../widgets/tanijagung_widgets.dart';

/// HALAMAN K: INPUT HASIL PANEN
/// Form khusus untuk memasukkan hasil panen:
/// - Pilih lahan
/// - Pilih musim tanam
/// - Tanggal panen
/// - Jumlah hasil panen dalam ton
/// - Harga jual per kg
/// - Catatan
/// Rumus: 1 ton = 1.000 kg, Pendapatan = Hasil panen (kg) × Harga jual per kg
/// Contoh: Hasil panen 7 ton, Harga jual Rp4.000/kg -> Pendapatan Rp28.000.000
class HarvestInputScreen extends StatefulWidget {
  final String? initialCycleId;
  const HarvestInputScreen({super.key, this.initialCycleId});

  @override
  State<HarvestInputScreen> createState() => _HarvestInputScreenState();
}

class _HarvestInputScreenState extends State<HarvestInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlotId;
  String? _selectedCycleId;
  DateTime _harvestDate = DateTime.now();
  final _yieldTonsCtrl = TextEditingController(text: '7');
  final _pricePerKgCtrl = TextEditingController(text: '4000');
  final _notesCtrl = TextEditingController();
  bool _markCompleted = true;

  @override
  void initState() {
    super.initState();
    final service = AppDataService();
    if (widget.initialCycleId != null) {
      final c = service.getCycleById(widget.initialCycleId!);
      if (c != null) {
        _selectedCycleId = c.id;
        _selectedPlotId = c.plotId;
      }
    } else if (service.plots.isNotEmpty) {
      _selectedPlotId = service.plots.first.id;
      final plotCycles = service.getCyclesForPlot(_selectedPlotId!);
      if (plotCycles.isNotEmpty) {
        _selectedCycleId = plotCycles.first.id;
      } else if (service.cycles.isNotEmpty) {
        _selectedCycleId = service.cycles.first.id;
        _selectedPlotId = service.cycles.first.plotId;
      }
    }
  }

  Future<void> _saveHarvest() async {
    if (!_formKey.currentState!.validate()) return;
    final service = AppDataService();
    if (_selectedCycleId == null || _selectedPlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lahan dan musim tanam terlebih dahulu.'),
        ),
      );
      return;
    }

    final tons = AppFormatters.parsePositiveDouble(_yieldTonsCtrl.text)!;
    final price = AppFormatters.parsePositiveDouble(_pricePerKgCtrl.text)!;

    await service.addHarvestRecord(
      plotId: _selectedPlotId!,
      cycleId: _selectedCycleId!,
      harvestDate: _harvestDate,
      yieldTons: tons,
      sellingPricePerKg: price,
      markCycleCompleted: _markCompleted,
      notes: _notesCtrl.text.trim(),
    );

    if (mounted) {
      _notesCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hasil panen berhasil disimpan & pendapatan otomatis diperbarui.',
          ),
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
        final plots = service.plots;
        final cyclesForPlot = _selectedPlotId != null
            ? service.getCyclesForPlot(_selectedPlotId!)
            : service.cycles;

        if (_selectedCycleId != null &&
            !cyclesForPlot.any((c) => c.id == _selectedCycleId)) {
          _selectedCycleId = cyclesForPlot.isNotEmpty
              ? cyclesForPlot.first.id
              : null;
        }

        final tons =
            AppFormatters.parsePositiveDouble(_yieldTonsCtrl.text) ?? 0.0;
        final kg = AppFormatters.tonsToKg(tons);
        final pricePerKg =
            AppFormatters.parsePositiveDouble(_pricePerKgCtrl.text) ?? 0.0;
        final revenue = kg * pricePerKg;

        final harvestHistory = _selectedCycleId != null
            ? service.getHarvestsForCycle(_selectedCycleId!)
            : service.harvests;

        return Scaffold(
          appBar: AppBar(title: const Text('Input Hasil Panen')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Lahan',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPlotId,
                          items: plots
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    '${p.name} (${AppFormatters.number(p.area)} ${p.areaUnit})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPlotId = val;
                              final cList = val != null
                                  ? service.getCyclesForPlot(val)
                                  : service.cycles;
                              _selectedCycleId = cList.isNotEmpty
                                  ? cList.first.id
                                  : null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Pilih Musim Tanam',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCycleId,
                          items: cyclesForPlot
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    '${c.name} (${c.cornVariety})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCycleId = val),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tanggal Panen',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _harvestDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2036),
                            );
                            if (picked != null) {
                              setState(() => _harvestDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                            ),
                            child: Text(AppFormatters.date(_harvestDate)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hasil Panen (Ton)',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _yieldTonsCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      suffixText: 'Ton',
                                      hintText: '7.0',
                                    ),
                                    validator: (v) =>
                                        AppFormatters.parsePositiveDouble(v) ==
                                            null
                                        ? 'Wajib > 0'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Harga Jual (Rp/Kg)',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _pricePerKgCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      prefixText: 'Rp ',
                                      hintText: '4000',
                                    ),
                                    validator: (v) =>
                                        AppFormatters.parsePositiveDouble(v) ==
                                            null
                                        ? 'Wajib > 0'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Kotak Konversi Otomatis 1 Ton = 1.000 Kg & Pendapatan
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.softMintGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Konversi Otomatis (1 ton = 1.000 kg):',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${AppFormatters.number(kg)} kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              const Text(
                                'Pendapatan Otomatis (Hasil Panen kg × Harga Jual/kg)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppFormatters.currency(revenue),
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryDarkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Catatan (opsional)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _notesCtrl,
                          decoration: const InputDecoration(
                            hintText:
                                'Contoh: Panen tahap 1 jagung pipil kering',
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _markCompleted,
                          onChanged: (v) =>
                              setState(() => _markCompleted = v ?? true),
                          title: const Text(
                            'Tandai musim tanam selesai dipanen',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Hilangkan centang jika panen dilakukan bertahap.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveHarvest,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Simpan Hasil Panen'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Riwayat Transaksi Panen (${harvestHistory.length})',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (harvestHistory.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Belum ada transaksi panen pada musim tanam ini.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...harvestHistory.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.cornYellowLight,
                          child: const Icon(
                            Icons.agriculture_rounded,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        title: Text(
                          '${AppFormatters.number(h.yieldTons)} Ton (${AppFormatters.number(h.yieldKg)} kg) • ${AppFormatters.currency(h.grossRevenue)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          'Tanggal: ${AppFormatters.date(h.harvestDate)} • Harga Jual: ${AppFormatters.currency(h.sellingPricePerKg)}/kg\n${h.notes}',
                        ),
                        isThreeLine: h.notes.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => AppFormDialogs.showHarvestForm(
                                context,
                                existingHarvest: h,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.dangerRed,
                              ),
                              onPressed: () =>
                                  service.deleteHarvestRecord(h.id),
                            ),
                          ],
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
