import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_models.dart';
import '../services/app_data_service.dart';
import '../services/local_notification_service.dart';

/// HALAMAN PENGINGAT JADWAL BUATAN PENGGUNA (Revisi 4: Profil > Notifikasi)
/// - Pengingat Penyiraman, Pemupukan, Penyemprotan, Perawatan Lahan, atau Lainnya
/// - Pilihan Lahan (opsional), Tanggal, Jam, Pengulangan (Sekali, Harian, Mingguan, Interval Hari), Catatan, dan Toggle Aktif/Nonaktif
/// - Mengirim notifikasi lokal terjadwal (flutter_local_notifications) yang tetap berbunyi meski aplikasi ditutup & setelah perangkat restart
/// - Tersinkron dengan "Aktivitas Terdekat" di Beranda
class ScheduledRemindersScreen extends StatefulWidget {
  const ScheduledRemindersScreen({super.key});

  @override
  State<ScheduledRemindersScreen> createState() =>
      _ScheduledRemindersScreenState();
}

class _ScheduledRemindersScreenState extends State<ScheduledRemindersScreen> {
  @override
  void initState() {
    super.initState();
    LocalNotificationService().requestPermissions();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final reminders = service.scheduledReminders;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pengingat Jadwal'),
            actions: [
              IconButton(
                tooltip: 'Izin Notifikasi & Alarm',
                onPressed: () async {
                  final ok = await LocalNotificationService()
                      .requestPermissions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Izin notifikasi dan alarm terjadwal telah aktif.'
                              : 'Silakan aktifkan izin notifikasi di Pengaturan Android Anda.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active_outlined),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showReminderForm(context),
            icon: const Icon(Icons.add_alarm_rounded),
            label: const Text('Tambah Pengingat'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 92),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.alarm_on_rounded,
                      color: AppTheme.darkGreen,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Atur jadwal pengingat penyiraman dan pemupukan. Notifikasi akan tetap berbunyi otomatis pada waktu yang ditentukan meskipun aplikasi ditutup.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Daftar Pengingat Mendatang (${reminders.length})',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (reminders.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.notifications_paused_outlined,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Belum Ada Pengingat Terjadwal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ketuk tombol "Tambah Pengingat" untuk membuat jadwal penyiraman atau pemupukan lahan jagung Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...reminders.map((rem) {
                  final plot = rem.plotId != null
                      ? service.getPlotById(rem.plotId!)
                      : null;
                  final nextOcc = rem.nextOccurrence;
                  final repeatText = rem.repeatType == 'Interval Hari'
                      ? 'Setiap ${rem.intervalDays} Hari'
                      : rem.repeatType;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: rem.isEnabled
                                        ? AppTheme.lightGreen
                                        : AppTheme.borderColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    rem.activityType == 'Penyiraman'
                                        ? Icons.water_drop_outlined
                                        : Icons.compost_outlined,
                                    color: rem.isEnabled
                                        ? AppTheme.darkGreen
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rem.activityType,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: rem.isEnabled
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${plot?.name ?? "Semua Lahan"} • $repeatText',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: rem.isEnabled,
                                  onChanged: (val) => service
                                      .toggleScheduledReminder(rem.id, val),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Jadwal Berikutnya: ${AppFormatters.date(nextOcc)} • ${_formatTime(nextOcc)}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.darkGreen,
                                        ),
                                      ),
                                      if (rem.notes.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Catatan: ${rem.notes}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit Pengingat',
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: AppTheme.textSecondary,
                                      ),
                                      onPressed: () => _showReminderForm(
                                        context,
                                        existingReminder: rem,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Hapus Pengingat',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: AppTheme.dangerRed,
                                      ),
                                      onPressed: () => service
                                          .deleteScheduledReminder(rem.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showReminderForm(
    BuildContext context, {
    ScheduledReminderModel? existingReminder,
  }) {
    final service = AppDataService();
    final formKey = GlobalKey<FormState>();

    String activityType = existingReminder?.activityType ?? 'Penyiraman';
    if (!AppConstants.reminderActivityTypes.contains(activityType)) {
      activityType = 'Penyiraman';
    }
    String? selectedPlotId = existingReminder?.plotId;
    DateTime selectedDate =
        existingReminder?.scheduledDateTime ??
        DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay(
      hour: selectedDate.hour,
      minute: selectedDate.minute,
    );
    String repeatType = existingReminder?.repeatType ?? 'Sekali';
    if (!AppConstants.reminderRepeatTypes.contains(repeatType)) {
      repeatType = 'Sekali';
    }
    final intervalCtrl = TextEditingController(
      text: (existingReminder?.intervalDays ?? 3).toString(),
    );
    final notesCtrl = TextEditingController(
      text: existingReminder?.notes ?? '',
    );
    bool isEnabled = existingReminder?.isEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            existingReminder == null
                                ? 'Tambah Pengingat Jadwal'
                                : 'Edit Pengingat Jadwal',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
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
                    DropdownButtonFormField<String>(
                      initialValue: activityType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kegiatan *',
                        prefixIcon: Icon(Icons.notifications_active_outlined),
                      ),
                      items: AppConstants.reminderActivityTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => activityType = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedPlotId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilihan Lahan (Opsional)',
                        prefixIcon: Icon(Icons.landscape_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Lahan / Umum'),
                        ),
                        ...service.plots.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedPlotId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2036),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal Mulai *',
                              ),
                              child: Text(
                                AppFormatters.shortDate(selectedDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setState(() => selectedTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Jam Pengingat *',
                              ),
                              child: Text(
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} WIB',
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
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: repeatType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Pengulangan *',
                            ),
                            items: AppConstants.reminderRepeatTypes
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => repeatType = v);
                            },
                          ),
                        ),
                        if (repeatType == 'Interval Hari') ...[
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: intervalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tiap (Hari) *',
                              ),
                              validator: (v) {
                                final val = int.tryParse(v ?? '');
                                if (val == null || val < 1) {
                                  return 'Min 1 hari';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Pengingat (Opsional)',
                        hintText: 'Contoh: Siram pagi & cek kelembapan tanah',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Aktifkan Pengingat Ini',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      value: isEnabled,
                      onChanged: (val) => setState(() => isEnabled = val),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final combinedDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          final intervalVal =
                              int.tryParse(intervalCtrl.text.trim()) ?? 1;

                          await LocalNotificationService().requestPermissions();

                          if (existingReminder == null) {
                            await service.addScheduledReminder(
                              activityType: activityType,
                              plotId: selectedPlotId,
                              scheduledDateTime: combinedDateTime,
                              repeatType: repeatType,
                              intervalDays: intervalVal,
                              notes: notesCtrl.text,
                              isEnabled: isEnabled,
                            );
                          } else {
                            await service.updateScheduledReminder(
                              existingReminder.copyWith(
                                activityType: activityType,
                                plotId: selectedPlotId,
                                clearPlotId: selectedPlotId == null,
                                scheduledDateTime: combinedDateTime,
                                repeatType: repeatType,
                                intervalDays: intervalVal,
                                notes: notesCtrl.text.trim(),
                                isEnabled: isEnabled,
                              ),
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.alarm_add_rounded),
                        label: Text(
                          existingReminder == null
                              ? 'Simpan Pengingat'
                              : 'Perbarui Pengingat',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
