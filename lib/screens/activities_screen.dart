import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_models.dart';
import '../services/app_data_service.dart';
import '../widgets/app_form_dialogs.dart';
import '../widgets/tanijagung_widgets.dart';
import 'expenses_screen.dart';
import 'seed_fertilizer_screen.dart';

/// HALAMAN 10: AKTIVITAS DAN KALENDER (Sesuai Gambar Referensi Baris 2 Kolom 4)
/// - Kalender Bulanan bersih & elegan dengan lingkaran hijau pada tanggal terpilih
/// - Bagian "Kegiatan Hari Ini" / kegiatan pada tanggal terpilih + daftar timeline kegiatan
/// - Tombol Hijau Penuh "+ Tambah Aktivitas"
/// - Jadwal murni berdasarkan tanggal input manual pengguna (tanpa cuaca/BMKG)
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String? _selectedCycleFilter;
  bool _showTimelineView = false;

  List<ActivityModel> _getEventsForDay(
    DateTime day,
    List<ActivityModel> source,
  ) {
    return source.where((a) => isSameDay(a.date, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppDataService(),
      builder: (context, _) {
        final service = AppDataService();
        final cycles = service.cycles;
        final allActivities = _selectedCycleFilter == null
            ? service.activities
            : service.getActivitiesForCycle(_selectedCycleFilter!);

        final selectedDateEvents = _selectedDay != null
            ? _getEventsForDay(_selectedDay!, allActivities)
            : <ActivityModel>[];

        final displayEvents = selectedDateEvents.isNotEmpty
            ? selectedDateEvents
            : allActivities;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Aktivitas'),
            actions: [
              IconButton(
                tooltip: 'Input Benih & Pupuk',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SeedFertilizerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.grain_rounded),
              ),
              IconButton(
                tooltip: 'Daftar Pengeluaran',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Filter Musim Tanam + Toggle Kalender / Timeline
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedCycleFilter,
                            isExpanded: true,
                            hint: const Text(
                              'Semua Musim Tanam',
                              style: TextStyle(fontSize: 13),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Semua Musim Tanam',
                                  style: TextStyle(
                                    fontSize: 13,
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedCycleFilter = v),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: _showTimelineView
                        ? 'Tampilkan Kalender'
                        : 'Tampilkan Timeline',
                    onPressed: () =>
                        setState(() => _showTimelineView = !_showTimelineView),
                    icon: Icon(
                      _showTimelineView
                          ? Icons.calendar_month_rounded
                          : Icons.timeline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // KALENDER BULANAN (Persis Gambar Referensi Baris 2 Kolom 4)
              if (!_showTimelineView) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                    child: TableCalendar<ActivityModel>(
                      locale: 'id_ID',
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2036),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      eventLoader: (day) =>
                          _getEventsForDay(day, allActivities),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                        weekendStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      calendarStyle: const CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: AppTheme.leafGreen,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppTheme.cornYellow,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: AppTheme.primaryDarkGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Bagian "Kegiatan Hari Ini" / Daftar Kegiatan Berdasarkan Tanggal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedDateEvents.isNotEmpty
                          ? 'Kegiatan ${AppFormatters.date(_selectedDay!)}'
                          : 'Kegiatan Hari Ini & Terjadwal',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selectedDateEvents.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selectedDay = null),
                      child: const Text('Lihat Semua'),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (displayEvents.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Belum ada kegiatan pertanian tercatat. Tekan tombol "+ Tambah Aktivitas" untuk mencatat jadwal penanaman, pemupukan pertama/kedua, penyemprotan, perawatan, atau panen.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...displayEvents.map((act) {
                  final plot = service.getPlotById(act.plotId);
                  final cycle = service.getCycleById(act.cycleId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        onTap: () => service.toggleActivityCompleted(
                          act.id,
                          !act.isCompleted,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: act.isCompleted
                                ? AppTheme.primaryDarkGreen
                                : AppTheme.lightLeafGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            act.isCompleted
                                ? Icons.check_rounded
                                : Icons.eco_rounded,
                            color: act.isCompleted
                                ? Colors.white
                                : AppTheme.primaryDarkGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          act.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            decoration: act.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${AppFormatters.date(act.date)} • ${act.activityType} • ${plot?.name ?? "-"} (${cycle?.name ?? "-"})',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit Aktivitas',
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () => AppFormDialogs.showActivityForm(
                                context,
                                existingActivity: act,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Hapus Aktivitas',
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppTheme.dangerRed,
                              ),
                              onPressed: () => service.deleteActivity(act.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // Tombol Hijau Penuh "+ Tambah Aktivitas" (Persis Gambar Referensi)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => AppFormDialogs.showActivityForm(
                    context,
                    preselectedCycleId: _selectedCycleFilter,
                    preselectedDate: _selectedDay ?? DateTime.now(),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text('Tambah Aktivitas'),
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
