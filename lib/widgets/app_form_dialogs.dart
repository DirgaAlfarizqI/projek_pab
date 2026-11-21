import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_models.dart';
import '../services/app_data_service.dart';
import 'image_picker_field.dart';

class AppFormDialogs {
  /// Form Tambah / Edit Lahan (Plot) dengan Kamera & Galeri Nyata (`image_picker`)
  static Future<PlotModel?> showPlotForm(
    BuildContext context, {
    PlotModel? existingPlot,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existingPlot?.name ?? '');
    final locationCtrl = TextEditingController(
      text: existingPlot?.location ?? '',
    );
    final areaCtrl = TextEditingController(
      text: existingPlot != null ? existingPlot.area.toString() : '',
    );
    final notesCtrl = TextEditingController(text: existingPlot?.notes ?? '');
    String? selectedPhotoPath = existingPlot?.photoPath;
    String selectedUnit =
        existingPlot?.areaUnit ??
        (AppDataService().currentUser?.preferredAreaUnit ?? 'hektare');

    return showModalBottomSheet<PlotModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentArea =
                AppFormatters.parsePositiveDouble(areaCtrl.text) ?? 0.0;
            final convertedHa = AppFormatters.toHectares(
              currentArea,
              selectedUnit,
            );
            final convertedM2 = AppFormatters.toSquareMeters(
              currentArea,
              selectedUnit,
            );

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              existingPlot == null
                                  ? 'Tambah Lahan Baru'
                                  : 'Edit Data Lahan',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lahan *',
                          hintText: 'Contoh: Lahan Sawah Utara',
                          prefixIcon: Icon(Icons.landscape_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama lahan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi Lahan *',
                          hintText: 'Contoh: Desa Sukamaju, Kec. Pare',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Lokasi lahan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: areaCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Luas Lahan *',
                                hintText: '1.5',
                                prefixIcon: Icon(Icons.square_foot_outlined),
                              ),
                              validator: (v) =>
                                  AppFormatters.parsePositiveDouble(v) == null
                                  ? 'Wajib > 0'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedUnit,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Satuan',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'hektare',
                                  child: Text(
                                    'Hektare (ha)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'm²',
                                  child: Text(
                                    'Meter² (m²)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => selectedUnit = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (currentArea > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${AppFormatters.number(convertedHa)} ha = ${AppFormatters.number(convertedM2)} m²',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Fitur Kamera & Galeri Nyata (ImagePickerField)
                      ImagePickerField(
                        label: 'Foto Lahan (Opsional)',
                        initialImagePath: selectedPhotoPath,
                        onImageChanged: (newPath) {
                          selectedPhotoPath = newPath;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                          hintText: 'Keterangan sumber air, akses jalan, dll.',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final areaVal = AppFormatters.parsePositiveDouble(
                              areaCtrl.text,
                            )!;
                            if (existingPlot == null) {
                              final created = await AppDataService().addPlot(
                                name: nameCtrl.text,
                                location: locationCtrl.text,
                                area: areaVal,
                                areaUnit: selectedUnit,
                                notes: notesCtrl.text,
                                photoPath: selectedPhotoPath,
                              );
                              if (ctx.mounted) Navigator.pop(ctx, created);
                            } else {
                              final updated = existingPlot.copyWith(
                                name: nameCtrl.text.trim(),
                                location: locationCtrl.text.trim(),
                                area: areaVal,
                                areaUnit: selectedUnit,
                                notes: notesCtrl.text.trim(),
                                photoPath: selectedPhotoPath,
                                isDemo: false,
                              );
                              await AppDataService().updatePlot(updated);
                              if (ctx.mounted) Navigator.pop(ctx, updated);
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            existingPlot == null
                                ? 'Simpan Lahan'
                                : 'Perbarui Lahan',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Form Buat / Edit Musim Tanam (Planting Cycle)
  /// Periode awal/default = 4 bulan setelah tanggal mulai, pengguna bebas mengubah durasi & tanggal
  static Future<PlantingCycleModel?> showPlantingCycleForm(
    BuildContext context, {
    PlantingCycleModel? existingCycle,
    String? preselectedPlotId,
  }) async {
    final service = AppDataService();
    if (service.plots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tambahkan minimal 1 Lahan terlebih dahulu sebelum membuat Musim Tanam.',
          ),
        ),
      );
      return null;
    }

    final formKey = GlobalKey<FormState>();
    String selectedPlotId =
        existingCycle?.plotId ?? preselectedPlotId ?? service.plots.first.id;
    final nameCtrl = TextEditingController(text: existingCycle?.name ?? '');
    final varietyCtrl = TextEditingController(
      text: existingCycle?.cornVariety ?? '',
    );
    final targetYieldCtrl = TextEditingController(
      text: existingCycle?.targetYieldTons != null
          ? existingCycle!.targetYieldTons.toString()
          : '',
    );
    final capitalCtrl = TextEditingController(
      text: existingCycle != null && existingCycle.initialCapital > 0
          ? existingCycle.initialCapital.round().toString()
          : '',
    );
    final notesCtrl = TextEditingController(text: existingCycle?.notes ?? '');

    DateTime plantingDate = existingCycle?.plantingDate ?? DateTime.now();
    DateTime estimatedHarvestDate =
        existingCycle?.estimatedHarvestDate ??
        DateTime(plantingDate.year, plantingDate.month + 4, plantingDate.day);
    DateTime? actualHarvestDate = existingCycle?.actualHarvestDate;
    String status = existingCycle?.status ?? 'Berlangsung';

    return showModalBottomSheet<PlantingCycleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final fourMonthsDefault = DateTime(
              plantingDate.year,
              plantingDate.month + 4,
              plantingDate.day,
            );
            final estDurationDays = estimatedHarvestDate
                .difference(plantingDate)
                .inDays;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              existingCycle == null
                                  ? 'Buat Musim Tanam Baru'
                                  : 'Edit Musim Tanam',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPlotId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Lahan *',
                          prefixIcon: Icon(Icons.terrain_outlined),
                        ),
                        items: service.plots
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
                          if (val != null) setState(() => selectedPlotId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama / Kode Musim Tanam *',
                          hintText: 'Contoh: MT 1 - 2026',
                          prefixIcon: Icon(Icons.event_note_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama musim tanam wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: varietyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Varietas Jagung *',
                          hintText: 'Contoh: BISI 18, NK 212, Pioneer P27',
                          prefixIcon: Icon(Icons.grass_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Varietas jagung wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: plantingDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setState(() {
                                    plantingDate = picked;
                                    if (existingCycle == null) {
                                      estimatedHarvestDate = DateTime(
                                        picked.year,
                                        picked.month + 4,
                                        picked.day,
                                      );
                                    }
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Mulai Tanam *',
                                ),
                                child: Text(
                                  AppFormatters.shortDate(plantingDate),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: estimatedHarvestDate,
                                  firstDate: plantingDate,
                                  lastDate: DateTime(2036),
                                );
                                if (picked != null) {
                                  setState(() => estimatedHarvestDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Perkiraan Panen *',
                                ),
                                child: Text(
                                  AppFormatters.shortDate(estimatedHarvestDate),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppTheme.darkGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Estimasi 4 bulan: ${AppFormatters.shortDate(fourMonthsDefault)} ($estDurationDays hari).',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  estimatedHarvestDate = fourMonthsDefault;
                                });
                              },
                              child: const Text(
                                'Set 4 Bln',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: status,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Status *',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Persiapan',
                                  child: Text('Persiapan'),
                                ),
                                DropdownMenuItem(
                                  value: 'Berlangsung',
                                  child: Text('Berlangsung'),
                                ),
                                DropdownMenuItem(
                                  value: 'Menunggu Panen',
                                  child: Text('Menunggu Panen'),
                                ),
                                DropdownMenuItem(
                                  value: 'Selesai',
                                  child: Text('Selesai'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => status = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      actualHarvestDate ?? DateTime.now(),
                                  firstDate: plantingDate,
                                  lastDate: DateTime(2036),
                                );
                                if (picked != null) {
                                  setState(() => actualHarvestDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Panen Aktual',
                                  suffixIcon: actualHarvestDate != null
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 16,
                                          ),
                                          onPressed: () => setState(
                                            () => actualHarvestDate = null,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Text(
                                  actualHarvestDate != null
                                      ? AppFormatters.shortDate(
                                          actualHarvestDate!,
                                        )
                                      : 'Belum Panen',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: targetYieldCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Target Panen (Ton)',
                                hintText: 'Opsional',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                if (AppFormatters.parsePositiveDouble(v) ==
                                    null) {
                                  return 'Harus > 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: capitalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Modal Awal (Rp)',
                                hintText: 'Opsional',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                if (AppFormatters.parsePositiveDouble(
                                      v,
                                      allowZero: true,
                                    ) ==
                                    null) {
                                  return 'Tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final targetTons =
                                AppFormatters.parsePositiveDouble(
                                  targetYieldCtrl.text,
                                );
                            final initCap =
                                AppFormatters.parsePositiveDouble(
                                  capitalCtrl.text,
                                  allowZero: true,
                                ) ??
                                0.0;

                            if (existingCycle == null) {
                              final created = await service.addPlantingCycle(
                                plotId: selectedPlotId,
                                name: nameCtrl.text,
                                cornVariety: varietyCtrl.text,
                                plantingDate: plantingDate,
                                estimatedHarvestDate: estimatedHarvestDate,
                                actualHarvestDate: actualHarvestDate,
                                status: status,
                                targetYieldTons: targetTons,
                                initialCapital: initCap,
                                notes: notesCtrl.text,
                              );
                              if (ctx.mounted) Navigator.pop(ctx, created);
                            } else {
                              final updated = existingCycle.copyWith(
                                plotId: selectedPlotId,
                                name: nameCtrl.text.trim(),
                                cornVariety: varietyCtrl.text.trim(),
                                plantingDate: plantingDate,
                                estimatedHarvestDate: estimatedHarvestDate,
                                actualHarvestDate: actualHarvestDate,
                                clearActualHarvestDate:
                                    actualHarvestDate == null,
                                status: status,
                                targetYieldTons: targetTons,
                                initialCapital: initCap,
                                notes: notesCtrl.text.trim(),
                                isDemo: false,
                              );
                              await service.updatePlantingCycle(updated);
                              if (ctx.mounted) Navigator.pop(ctx, updated);
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            existingCycle == null
                                ? 'Simpan Musim Tanam'
                                : 'Perbarui Musim Tanam',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Form Pencatatan Manual Benih dan Pupuk (CropInput)
  static Future<CropInputModel?> showCropInputForm(
    BuildContext context, {
    String? preselectedCycleId,
  }) async {
    final service = AppDataService();
    if (service.cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Buat Musim Tanam terlebih dahulu sebelum mencatat benih/pupuk.',
          ),
        ),
      );
      return null;
    }

    final formKey = GlobalKey<FormState>();
    String selectedCycleId = preselectedCycleId ?? service.cycles.first.id;
    String inputType = 'Pupuk';
    String unit = 'kg';
    DateTime selectedDate = DateTime.now();
    bool isFromPaidStock = false;
    String? selectedInventoryId;

    final productCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    return showModalBottomSheet<CropInputModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final qty = AppFormatters.parsePositiveDouble(qtyCtrl.text) ?? 0.0;
            final price =
                AppFormatters.parsePositiveDouble(
                  priceCtrl.text,
                  allowZero: true,
                ) ??
                0.0;
            final subtotal = qty * price;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Catat Benih / Pupuk',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCycleId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Musim Tanam & Lahan *',
                          prefixIcon: Icon(Icons.agriculture_outlined),
                        ),
                        items: service.cycles.map((c) {
                          final p = service.getPlotById(c.plotId);
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.name} (${p?.name ?? "Lahan"})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCycleId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: inputType,
                              isExpanded: true,
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
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => inputType = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setState(() => selectedDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal *',
                                ),
                                child: Text(
                                  AppFormatters.shortDate(selectedDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: productCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama $inputType *',
                          hintText: inputType == 'Benih'
                              ? 'Contoh: Benih Jagung BISI 18'
                              : 'Contoh: Pupuk Urea',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama produk wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: qtyCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Jumlah *',
                                hintText: '20',
                              ),
                              validator: (v) =>
                                  AppFormatters.parsePositiveDouble(v) == null
                                  ? 'Wajib > 0'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: unit,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Satuan *',
                              ),
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
                                  value: 'liter',
                                  child: Text('liter'),
                                ),
                                DropdownMenuItem(
                                  value: 'unit',
                                  child: Text('unit'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => unit = val);
                              },
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
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Harga per $unit (Rp) *',
                          hintText: '6000',
                          prefixIcon: const Icon(Icons.payments_outlined),
                        ),
                        validator: (v) =>
                            AppFormatters.parsePositiveDouble(
                                  v,
                                  allowZero: true,
                                ) ==
                                null
                            ? 'Masukkan harga valid'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'Total Biaya Otomatis:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              AppFormatters.currency(subtotal),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Diambil dari Stok yang Sudah Dibeli?',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isFromPaidStock
                              ? 'Biaya tidak dihitung ulang (anti biaya ganda).'
                              : 'Otomatis dicatat sebagai pengeluaran.',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        value: isFromPaidStock,
                        onChanged: (val) =>
                            setState(() => isFromPaidStock = val),
                      ),
                      if (isFromPaidStock && service.inventory.isNotEmpty) ...[
                        DropdownButtonFormField<String?>(
                          initialValue: selectedInventoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kurangi dari Stok (Opsional)',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tidak dihubungkan'),
                            ),
                            ...service.inventory.map(
                              (inv) => DropdownMenuItem<String?>(
                                value: inv.id,
                                child: Text(
                                  '${inv.itemName} (Sisa: ${AppFormatters.number(inv.remainingStock)} ${inv.unit})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => selectedInventoryId = val),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final cyc = service.getCycleById(selectedCycleId)!;
                            final created = await service.addCropInput(
                              plotId: cyc.plotId,
                              cycleId: cyc.id,
                              productName: productCtrl.text,
                              inputType: inputType,
                              quantity: AppFormatters.parsePositiveDouble(
                                qtyCtrl.text,
                              )!,
                              unit: unit,
                              unitPrice: AppFormatters.parsePositiveDouble(
                                priceCtrl.text,
                                allowZero: true,
                              )!,
                              date: selectedDate,
                              isFromPaidStock: isFromPaidStock,
                              recordAsExpense: !isFromPaidStock,
                              linkedInventoryId: selectedInventoryId,
                              notes: notesCtrl.text,
                            );
                            if (ctx.mounted) Navigator.pop(ctx, created);
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Form Pencatatan Seluruh Pengeluaran (Expense) dengan Bukti Transaksi & Integrasi Stok Pupuk
  static Future<ExpenseModel?> showExpenseForm(
    BuildContext context, {
    String? preselectedCycleId,
    ExpenseModel? existingExpense,
  }) async {
    final service = AppDataService();
    if (service.cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Buat Musim Tanam terlebih dahulu sebelum mencatat pengeluaran.',
          ),
        ),
      );
      return null;
    }

    final formKey = GlobalKey<FormState>();
    String selectedCycleId =
        existingExpense?.cycleId ??
        preselectedCycleId ??
        service.cycles.first.id;
    String category = existingExpense != null
        ? AppConstants.normalizeExpenseCategory(existingExpense.category)
        : 'Pupuk';
    String unit = existingExpense?.unit ?? 'kg';
    DateTime date = existingExpense?.date ?? DateTime.now();

    bool takeFromStock = existingExpense?.isFromFertilizerStock ?? false;
    final fertilizerStocks = service.inventory;
    String? selectedInventoryId =
        existingExpense?.linkedInventoryId ??
        (fertilizerStocks.isNotEmpty ? fertilizerStocks.first.id : null);

    final nameCtrl = TextEditingController(text: existingExpense?.name ?? '');
    final qtyCtrl = TextEditingController(
      text: existingExpense != null ? existingExpense.quantity.toString() : '1',
    );
    final priceCtrl = TextEditingController(
      text: existingExpense != null && !existingExpense.isFromFertilizerStock
          ? existingExpense.unitPrice.round().toString()
          : '',
    );
    final notesCtrl = TextEditingController(text: existingExpense?.notes ?? '');
    String? receiptPhotoPath = existingExpense?.receiptPhotoPath;

    return showModalBottomSheet<ExpenseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isFertilizer = category == 'Pupuk';
            final effectiveTakeFromStock = isFertilizer && takeFromStock;
            InventoryItemModel? selectedStockItem;
            if (selectedInventoryId != null) {
              try {
                selectedStockItem = fertilizerStocks.firstWhere(
                  (s) => s.id == selectedInventoryId,
                );
              } catch (_) {
                selectedStockItem = null;
              }
            }

            // Jika sedang mengedit pengeluaran yang sebelumnya sudah mengambil dari stok yang sama,
            // maka batas maksimum stok yang bisa diambil adalah sisa stok saat ini + jumlah yang sebelumnya diambil
            double maxAvailableStock = selectedStockItem?.remainingStock ?? 0.0;
            if (existingExpense != null &&
                existingExpense.isFromFertilizerStock &&
                existingExpense.linkedInventoryId == selectedStockItem?.id) {
              maxAvailableStock += existingExpense.stockTakenQuantity;
            }

            final qty = AppFormatters.parsePositiveDouble(qtyCtrl.text) ?? 0.0;
            final price = effectiveTakeFromStock
                ? 0.0
                : (AppFormatters.parsePositiveDouble(priceCtrl.text) ?? 0.0);
            final totalCost = effectiveTakeFromStock ? 0.0 : (qty * price);

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              existingExpense == null
                                  ? 'Catat Pengeluaran'
                                  : 'Edit Pengeluaran',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCycleId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Musim Tanam & Lahan *',
                          prefixIcon: Icon(Icons.agriculture_outlined),
                        ),
                        items: service.cycles.map((c) {
                          final p = service.getPlotById(c.plotId);
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.name} (${p?.name ?? "Lahan"})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCycleId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: category,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Kategori *',
                              ),
                              items: AppConstants.expenseCategories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    category = val;
                                    if (val != 'Pupuk') {
                                      takeFromStock = false;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) {
                                  setState(() => date = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal *',
                                ),
                                child: Text(AppFormatters.shortDate(date)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Opsi Sumber Pupuk: "Beli baru" atau "Ambil dari stok" (Revisi 6b)
                      if (isFertilizer) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sumber Pupuk',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          'Beli Baru',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      selected: !takeFromStock,
                                      onSelected: (_) =>
                                          setState(() => takeFromStock = false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          'Ambil dari Stok',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      selected: takeFromStock,
                                      onSelected: (_) {
                                        setState(() {
                                          takeFromStock = true;
                                          if (selectedInventoryId == null &&
                                              fertilizerStocks.isNotEmpty) {
                                            selectedInventoryId =
                                                fertilizerStocks.first.id;
                                          }
                                          if (selectedStockItem != null &&
                                              nameCtrl.text.trim().isEmpty) {
                                            nameCtrl.text =
                                                'Pemakaian ${selectedStockItem.itemName}';
                                            unit = selectedStockItem.unit;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (takeFromStock) ...[
                                const SizedBox(height: 10),
                                if (fertilizerStocks.isEmpty)
                                  const Text(
                                    'Belum ada stok pupuk tersedia di halaman Stok Pupuk. Silakan tambah stok pupuk terlebih dahulu atau pilih "Beli Baru".',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.dangerRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedInventoryId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Pilih Jenis Pupuk dari Stok *',
                                    ),
                                    items: fertilizerStocks.map((inv) {
                                      return DropdownMenuItem(
                                        value: inv.id,
                                        child: Text(
                                          '${inv.itemName} - tersedia ${AppFormatters.number(inv.remainingStock)} ${inv.unit}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        final chosen = fertilizerStocks
                                            .firstWhere((e) => e.id == val);
                                        setState(() {
                                          selectedInventoryId = val;
                                          unit = chosen.unit;
                                          nameCtrl.text =
                                              'Pemakaian ${chosen.itemName}';
                                        });
                                      }
                                    },
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Transaksi *',
                          hintText:
                              'Contoh: Pupuk Urea / Pestisida / Lain-lain',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama transaksi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: qtyCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: effectiveTakeFromStock
                                    ? 'Jumlah Diambil *'
                                    : 'Jumlah *',
                              ),
                              validator: (v) {
                                final parsed =
                                    AppFormatters.parsePositiveDouble(v);
                                if (parsed == null) return 'Wajib > 0';
                                if (effectiveTakeFromStock) {
                                  if (selectedStockItem == null) {
                                    return 'Pilih stok pupuk';
                                  }
                                  if (parsed > maxAvailableStock) {
                                    return 'Maks ${AppFormatters.number(maxAvailableStock)} ${selectedStockItem.unit}';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: unit,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Satuan *',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'kg',
                                  child: Text('kg'),
                                ),
                                DropdownMenuItem(
                                  value: 'paket',
                                  child: Text('paket'),
                                ),
                                DropdownMenuItem(
                                  value: 'hari',
                                  child: Text('hari'),
                                ),
                                DropdownMenuItem(
                                  value: 'liter',
                                  child: Text('liter'),
                                ),
                                DropdownMenuItem(
                                  value: 'hektare',
                                  child: Text('ha'),
                                ),
                                DropdownMenuItem(
                                  value: 'unit',
                                  child: Text('unit'),
                                ),
                              ],
                              onChanged: effectiveTakeFromStock
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setState(() => unit = val);
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      if (!effectiveTakeFromStock) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Harga Satuan (Rp) *',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          validator: (v) =>
                              AppFormatters.parsePositiveDouble(v) == null
                              ? 'Wajib > 0'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    effectiveTakeFromStock
                                        ? 'Biaya Pengeluaran Baru (Dari Stok):'
                                        : 'Total Biaya Otomatis:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  AppFormatters.currency(totalCost),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                            if (effectiveTakeFromStock &&
                                selectedStockItem != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Stok ${selectedStockItem.itemName} akan berkurang ${AppFormatters.number(qty)} ${selectedStockItem.unit}. Dicatat Rp0 agar tidak terhitung ganda dengan biaya pembelian stok.',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ImagePickerField(
                        label: 'Bukti Transaksi (Opsional)',
                        initialImagePath: receiptPhotoPath,
                        onImageChanged: (p) => receiptPhotoPath = p,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final cyc = service.getCycleById(selectedCycleId)!;
                            final parsedQty = AppFormatters.parsePositiveDouble(
                              qtyCtrl.text,
                            )!;
                            final parsedPrice = effectiveTakeFromStock
                                ? 0.0
                                : AppFormatters.parsePositiveDouble(
                                    priceCtrl.text,
                                  )!;

                            if (existingExpense == null) {
                              final created = await service.addExpense(
                                plotId: cyc.plotId,
                                cycleId: cyc.id,
                                name: nameCtrl.text,
                                category: category,
                                date: date,
                                quantity: parsedQty,
                                unit:
                                    effectiveTakeFromStock &&
                                        selectedStockItem != null
                                    ? selectedStockItem.unit
                                    : unit,
                                unitPrice: parsedPrice,
                                notes: notesCtrl.text,
                                receiptPhotoPath: receiptPhotoPath,
                                isFromFertilizerStock: effectiveTakeFromStock,
                                linkedInventoryId: effectiveTakeFromStock
                                    ? selectedInventoryId
                                    : null,
                                stockTakenQuantity: effectiveTakeFromStock
                                    ? parsedQty
                                    : 0.0,
                              );
                              if (ctx.mounted) Navigator.pop(ctx, created);
                            } else {
                              final updated = existingExpense.copyWith(
                                plotId: cyc.plotId,
                                cycleId: cyc.id,
                                name: nameCtrl.text.trim(),
                                category: category,
                                date: date,
                                quantity: parsedQty,
                                unit:
                                    effectiveTakeFromStock &&
                                        selectedStockItem != null
                                    ? selectedStockItem.unit
                                    : unit,
                                unitPrice: parsedPrice,
                                notes: notesCtrl.text.trim(),
                                receiptPhotoPath: receiptPhotoPath,
                                isFromFertilizerStock: effectiveTakeFromStock,
                                linkedInventoryId: effectiveTakeFromStock
                                    ? selectedInventoryId
                                    : null,
                                stockTakenQuantity: effectiveTakeFromStock
                                    ? parsedQty
                                    : 0.0,
                              );
                              await service.updateExpense(updated);
                              if (ctx.mounted) Navigator.pop(ctx, updated);
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            existingExpense == null
                                ? 'Simpan Pengeluaran'
                                : 'Perbarui Pengeluaran',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Form Tambah / Edit Aktivitas & Jadwal Tanggal Pertanian
  static Future<ActivityModel?> showActivityForm(
    BuildContext context, {
    String? preselectedCycleId,
    DateTime? preselectedDate,
    ActivityModel? existingActivity,
  }) async {
    final service = AppDataService();
    if (service.cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Buat Musim Tanam terlebih dahulu sebelum mencatat jadwal aktivitas.',
          ),
        ),
      );
      return null;
    }

    final formKey = GlobalKey<FormState>();
    String selectedCycleId =
        existingActivity?.cycleId ??
        preselectedCycleId ??
        service.cycles.first.id;

    const validTypes = [
      'Mulai Penanaman',
      'Pemupukan Pertama',
      'Pemupukan Kedua',
      'Penyemprotan',
      'Perawatan',
      'Perkiraan Panen',
      'Panen Aktual',
    ];
    String activityType =
        (existingActivity != null &&
            validTypes.contains(existingActivity.activityType))
        ? existingActivity.activityType
        : 'Pemupukan Pertama';

    DateTime date = existingActivity?.date ?? preselectedDate ?? DateTime.now();
    bool isCompleted = existingActivity?.isCompleted ?? false;
    bool recordCostAsExpense = existingActivity == null;

    final nameCtrl = TextEditingController(text: existingActivity?.name ?? '');
    final costCtrl = TextEditingController(
      text: existingActivity != null
          ? existingActivity.cost.round().toString()
          : '0',
    );
    final notesCtrl = TextEditingController(
      text: existingActivity?.notes ?? '',
    );

    return showModalBottomSheet<ActivityModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              existingActivity == null
                                  ? 'Tambah Aktivitas'
                                  : 'Edit Aktivitas',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCycleId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Musim Tanam & Lahan *',
                          prefixIcon: Icon(Icons.agriculture_outlined),
                        ),
                        items: service.cycles.map((c) {
                          final p = service.getPlotById(c.plotId);
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.name} (${p?.name ?? "Lahan"})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: existingActivity != null
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => selectedCycleId = val);
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: activityType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kegiatan *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Mulai Penanaman',
                            child: Text('Penanaman'),
                          ),
                          DropdownMenuItem(
                            value: 'Pemupukan Pertama',
                            child: Text('Pemupukan Pertama'),
                          ),
                          DropdownMenuItem(
                            value: 'Pemupukan Kedua',
                            child: Text('Pemupukan Kedua'),
                          ),
                          DropdownMenuItem(
                            value: 'Penyemprotan',
                            child: Text('Penyemprotan'),
                          ),
                          DropdownMenuItem(
                            value: 'Perawatan',
                            child: Text('Perawatan'),
                          ),
                          DropdownMenuItem(
                            value: 'Perkiraan Panen',
                            child: Text('Perkiraan Panen'),
                          ),
                          DropdownMenuItem(
                            value: 'Panen Aktual',
                            child: Text('Panen'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              activityType = val;
                              if (nameCtrl.text.trim().isEmpty) {
                                nameCtrl.text = val;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Aktivitas *',
                          hintText: 'Contoh: Pemupukan Kedua',
                          prefixIcon: Icon(Icons.event_note_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama aktivitas wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2036),
                                );
                                if (picked != null) {
                                  setState(() => date = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal *',
                                ),
                                child: Text(AppFormatters.shortDate(date)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: costCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Biaya (Rp)',
                                hintText: '0',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                if (AppFormatters.parsePositiveDouble(
                                      v,
                                      allowZero: true,
                                    ) ==
                                    null) {
                                  return 'Tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Tandai sudah selesai dilaksanakan',
                          style: TextStyle(fontSize: 13.5),
                        ),
                        value: isCompleted,
                        onChanged: (val) =>
                            setState(() => isCompleted = val ?? false),
                      ),
                      if (existingActivity == null)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Catat biaya kegiatan otomatis ke Pengeluaran',
                            style: TextStyle(fontSize: 13.5),
                          ),
                          value: recordCostAsExpense,
                          onChanged: (val) =>
                              setState(() => recordCostAsExpense = val ?? true),
                        ),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final cost =
                                AppFormatters.parsePositiveDouble(
                                  costCtrl.text,
                                  allowZero: true,
                                ) ??
                                0.0;

                            if (existingActivity == null) {
                              final cyc = service.getCycleById(
                                selectedCycleId,
                              )!;
                              final created = await service.addActivity(
                                plotId: cyc.plotId,
                                cycleId: cyc.id,
                                name: nameCtrl.text,
                                activityType: activityType,
                                date: date,
                                cost: cost,
                                isCompleted: isCompleted,
                                recordCostAsExpense: recordCostAsExpense,
                                notes: notesCtrl.text,
                              );
                              if (ctx.mounted) Navigator.pop(ctx, created);
                            } else {
                              final updated = existingActivity.copyWith(
                                name: nameCtrl.text.trim(),
                                activityType: activityType,
                                date: date,
                                cost: cost,
                                isCompleted: isCompleted,
                                notes: notesCtrl.text.trim(),
                              );
                              await service.updateActivity(updated);
                              if (ctx.mounted) Navigator.pop(ctx, updated);
                            }
                          },
                          icon: const Icon(Icons.event_available),
                          label: Text(
                            existingActivity == null
                                ? 'Simpan Aktivitas'
                                : 'Perbarui Aktivitas',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Form Input Hasil Panen Aktual (HarvestRecord)
  static Future<HarvestRecordModel?> showHarvestForm(
    BuildContext context, {
    String? preselectedCycleId,
    HarvestRecordModel? existingHarvest,
  }) async {
    final service = AppDataService();
    if (service.cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Buat Musim Tanam terlebih dahulu sebelum menginput hasil panen.',
          ),
        ),
      );
      return null;
    }

    final formKey = GlobalKey<FormState>();
    String selectedCycleId =
        existingHarvest?.cycleId ??
        preselectedCycleId ??
        service.cycles.first.id;
    DateTime harvestDate = existingHarvest?.harvestDate ?? DateTime.now();
    bool markCycleCompleted = true;

    final yieldTonsCtrl = TextEditingController(
      text: existingHarvest != null ? existingHarvest.yieldTons.toString() : '',
    );
    final pricePerKgCtrl = TextEditingController(
      text: existingHarvest != null
          ? existingHarvest.sellingPricePerKg.round().toString()
          : '',
    );
    final notesCtrl = TextEditingController(text: existingHarvest?.notes ?? '');

    return showModalBottomSheet<HarvestRecordModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final tons =
                AppFormatters.parsePositiveDouble(yieldTonsCtrl.text) ?? 0.0;
            final kg = AppFormatters.tonsToKg(tons);
            final pricePerKg =
                AppFormatters.parsePositiveDouble(pricePerKgCtrl.text) ?? 0.0;
            final grossRevenue = kg * pricePerKg;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              existingHarvest == null
                                  ? 'Input Hasil Panen'
                                  : 'Edit Hasil Panen',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCycleId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Musim Tanam & Lahan *',
                          prefixIcon: Icon(Icons.agriculture_outlined),
                        ),
                        items: service.cycles.map((c) {
                          final p = service.getPlotById(c.plotId);
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.name} (${p?.name ?? "Lahan"})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: existingHarvest != null
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => selectedCycleId = val);
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: harvestDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2036),
                          );
                          if (picked != null) {
                            setState(() => harvestDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Panen *',
                            prefixIcon: Icon(Icons.event_available_outlined),
                          ),
                          child: Text(AppFormatters.shortDate(harvestDate)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: yieldTonsCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Panen (Ton) *',
                                hintText: '7',
                              ),
                              validator: (v) =>
                                  AppFormatters.parsePositiveDouble(v) == null
                                  ? 'Wajib > 0'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: pricePerKgCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Harga / Kg (Rp) *',
                                hintText: '4000',
                              ),
                              validator: (v) =>
                                  AppFormatters.parsePositiveDouble(v) == null
                                  ? 'Wajib > 0'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text('Konversi (1 ton = 1.000 kg):'),
                                ),
                                Text(
                                  '${AppFormatters.number(kg)} kg',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Total Pendapatan:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  AppFormatters.currency(grossRevenue),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: AppTheme.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (existingHarvest == null)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Ubah status musim tanam menjadi "Selesai"',
                            style: TextStyle(fontSize: 13.5),
                          ),
                          value: markCycleCompleted,
                          onChanged: (val) =>
                              setState(() => markCycleCompleted = val ?? true),
                        ),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final tonsVal = AppFormatters.parsePositiveDouble(
                              yieldTonsCtrl.text,
                            )!;
                            final priceVal = AppFormatters.parsePositiveDouble(
                              pricePerKgCtrl.text,
                            )!;

                            if (existingHarvest == null) {
                              final cyc = service.getCycleById(
                                selectedCycleId,
                              )!;
                              final created = await service.addHarvestRecord(
                                plotId: cyc.plotId,
                                cycleId: cyc.id,
                                harvestDate: harvestDate,
                                yieldTons: tonsVal,
                                sellingPricePerKg: priceVal,
                                markCycleCompleted: markCycleCompleted,
                                notes: notesCtrl.text,
                              );
                              if (ctx.mounted) Navigator.pop(ctx, created);
                            } else {
                              final updated = existingHarvest.copyWith(
                                harvestDate: harvestDate,
                                yieldTons: tonsVal,
                                sellingPricePerKg: priceVal,
                                notes: notesCtrl.text.trim(),
                              );
                              await service.updateHarvestRecord(updated);
                              if (ctx.mounted) Navigator.pop(ctx, updated);
                            }
                          },
                          icon: const Icon(Icons.agriculture),
                          label: Text(
                            existingHarvest == null
                                ? 'Simpan Hasil Panen'
                                : 'Perbarui Data Panen',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
