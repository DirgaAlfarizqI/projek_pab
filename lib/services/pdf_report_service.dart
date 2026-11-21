import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/formatters.dart';
import '../models/app_models.dart';
import 'app_data_service.dart';

class PdfReportService {
  static Future<void> generateAndShareCycleReport({
    required UserModel user,
    required CycleFinancialSummary summary,
    required List<CropInputModel> cropInputs,
    required List<ExpenseModel> expenses,
    required List<ActivityModel> activities,
    required List<HarvestRecordModel> harvests,
  }) async {
    final pdf = pw.Document();
    final cycle = summary.cycle;
    final plot = summary.plot;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header Laporan
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1B4D2E'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN MUSIM TANAM - TANIJAGUNG',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Usaha Tani: ${user.farmBusinessName} | Pemilik: ${user.name}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Status: ${summary.financialStatus}',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#F59E0B'),
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Dicetak: ${AppFormatters.shortDate(DateTime.now())}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // 1. Identitas Lahan & Musim Tanam
          pw.Text(
            '1. IDENTITAS LAHAN & MUSIM TANAM',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Parameter', 'Keterangan'],
            data: [
              ['Nama Musim Tanam', cycle.name],
              [
                'Identitas Lahan',
                plot != null ? '${plot.name} (${plot.location})' : '-',
              ],
              [
                'Luas Lahan',
                plot != null
                    ? '${AppFormatters.number(plot.area)} ${plot.areaUnit} (${AppFormatters.number(plot.areaInHectares)} ha)'
                    : '-',
              ],
              ['Varietas Jagung', cycle.cornVariety],
              [
                'Tanggal Mulai Tanam',
                AppFormatters.shortDate(cycle.plantingDate),
              ],
              [
                'Tanggal Perkiraan Panen',
                AppFormatters.shortDate(cycle.estimatedHarvestDate),
              ],
              [
                'Tanggal Panen Aktual',
                cycle.actualHarvestDate != null
                    ? AppFormatters.shortDate(cycle.actualHarvestDate!)
                    : 'Belum Diisi',
              ],
              ['Status Siklus', cycle.status],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#2E7D32'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),

          // 2. Ringkasan Keuangan & Produktivitas
          pw.Text(
            '2. RINGKASAN KEUANGAN & PRODUKTIVITAS',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Komponen Analisis', 'Nilai'],
            data: [
              [
                'Total Penggunaan Benih',
                '${AppFormatters.number(summary.totalSeedKg)} kg',
              ],
              [
                'Total Penggunaan Pupuk',
                '${AppFormatters.number(summary.totalFertilizerKg)} kg',
              ],
              [
                'Total Biaya Operasional / Pengeluaran',
                AppFormatters.currency(summary.totalExpenses),
              ],
              [
                'Hasil Panen Aktual',
                summary.hasHarvestData
                    ? '${AppFormatters.formatWeightByPreference(summary.totalHarvestTons, user.preferredWeightUnit)} (${AppFormatters.number(summary.totalHarvestKg)} kg)'
                    : 'Menunggu data panen',
              ],
              [
                'Rata-rata Harga Jual per Kg',
                summary.hasHarvestData
                    ? '${AppFormatters.currency(summary.averageSellingPricePerKg)} / kg'
                    : 'Menunggu data panen',
              ],
              [
                'Total Pendapatan Kotor',
                summary.hasHarvestData
                    ? AppFormatters.currency(summary.totalRevenue)
                    : 'Menunggu data panen',
              ],
              [
                'Status Keuangan (${summary.financialStatus})',
                summary.hasHarvestData
                    ? AppFormatters.currency(summary.netProfitOrLoss)
                    : 'Menunggu data panen',
              ],
              if (summary.hasHarvestData)
                [
                  'Persentase Keuntungan terhadap Biaya',
                  '${AppFormatters.number(summary.profitPercentage)}%',
                ],
              [
                'Biaya Produksi / Harga Impas per Kg',
                summary.hasHarvestData
                    ? '${AppFormatters.currency(summary.breakEvenPricePerKg)} / kg'
                    : 'Menunggu data panen',
              ],
              [
                'Produktivitas per Hektare',
                '${AppFormatters.number(summary.productivityKgPerHa)} kg/ha (${AppFormatters.number(summary.productivityTonsPerHa)} ton/ha)',
              ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#1B4D2E'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),

          // 3. Riwayat Pengeluaran
          pw.Text(
            '3. RINCIAN PENGELUARAN (${expenses.length} Transaksi)',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (expenses.isEmpty)
            pw.Text(
              'Belum ada data pengeluaran.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Tanggal',
                'Nama Pengeluaran',
                'Kategori',
                'Kuantitas',
                'Total Biaya',
              ],
              data: expenses
                  .map(
                    (e) => [
                      AppFormatters.shortDate(e.date),
                      e.name,
                      e.category,
                      '${AppFormatters.number(e.quantity)} ${e.unit} x ${AppFormatters.currency(e.unitPrice)}',
                      AppFormatters.currency(e.totalCost),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#2E7D32'),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 16),

          // 4. Tanggal Kegiatan Penting
          pw.Text(
            '4. JADWAL & TANGGAL KEGIATAN PENTING (${activities.length} Kegiatan)',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (activities.isEmpty)
            pw.Text(
              'Belum ada data kegiatan.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Jenis Kegiatan', 'Nama Kegiatan', 'Status'],
              data: activities
                  .map(
                    (a) => [
                      AppFormatters.shortDate(a.date),
                      a.activityType,
                      a.name,
                      a.isCompleted ? 'Selesai' : 'Terjadwal',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1B4D2E'),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_${cycle.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
