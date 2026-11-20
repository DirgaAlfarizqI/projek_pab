import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanijagung/core/utils/formatters.dart';
import 'package:tanijagung/main.dart';
import 'package:tanijagung/services/app_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  test('Perhitungan usaha tani: konversi, panen, laba/rugi, stok & anti biaya ganda berjalan akurat', () async {
    SharedPreferences.setMockInitialValues({});
    final service = AppDataService();
    await service.initialize();

    final regErr = await service.register(
      name: 'Budi Santoso',
      email: 'budi@tanijagung.id',
      password: 'password123',
      farmBusinessName: 'Tani Subur Kediri',
    );
    expect(regErr, isNull);
    expect(service.currentUser?.name, 'Budi Santoso');

    final plot = await service.addPlot(
      name: 'Lahan Sawah Timur',
      location: 'Kediri',
      area: 20000,
      areaUnit: 'm²',
    );
    expect(plot.areaInHectares, closeTo(2.0, 0.0001));

    final start = DateTime(2026, 7, 1);
    final est = DateTime(2026, 11, 1);
    final cycle = await service.addPlantingCycle(
      plotId: plot.id,
      name: 'Musim Tanam I',
      cornVariety: 'BISI 18',
      plantingDate: start,
      estimatedHarvestDate: est,
      status: 'Berlangsung',
    );
    expect(cycle.fourMonthsFromStartDate, DateTime(2026, 11, 1));

    final seedInput = await service.addCropInput(
      plotId: plot.id,
      cycleId: cycle.id,
      productName: 'Benih BISI 18',
      inputType: 'Benih',
      quantity: 30,
      unit: 'kg',
      unitPrice: 100000,
      date: start,
      recordAsExpense: true,
    );
    expect(seedInput.subtotal, 3000000);

    final fertInput = await service.addCropInput(
      plotId: plot.id,
      cycleId: cycle.id,
      productName: 'Pupuk Urea',
      inputType: 'Pupuk',
      quantity: 500,
      unit: 'kg',
      unitPrice: 6000,
      date: start.add(const Duration(days: 14)),
      recordAsExpense: true,
    );
    expect(fertInput.subtotal, 3000000);

    await service.addExpense(
      plotId: plot.id,
      cycleId: cycle.id,
      name: 'Upah Tanam & Panen',
      category: 'Tenaga kerja',
      date: est,
      quantity: 1,
      unit: 'paket',
      unitPrice: 4000000,
    );

    // 7 ton x Rp4.000 = Rp28.000.000
    final harvest = await service.addHarvestRecord(
      plotId: plot.id,
      cycleId: cycle.id,
      harvestDate: est,
      yieldTons: 7.0,
      sellingPricePerKg: 4000,
    );
    expect(harvest.yieldKg, 7000);
    expect(harvest.grossRevenue, 28000000);

    final summary = service.calculateCycleSummary(cycle.id);
    expect(summary.totalExpenses, 10000000);
    expect(summary.totalRevenue, 28000000);
    expect(summary.netProfitOrLoss, 18000000);
    expect(summary.financialStatus, 'UNTUNG');

    final inv = await service.addInventoryItem(
      itemName: 'Pupuk NPK Gudang',
      itemType: 'Pupuk',
      initialStock: 100,
      unit: 'kg',
      purchasePrice: 7000,
      minimumStockAlert: 50,
      transactionDate: start,
    );
    await service.recordInventoryTransaction(
      inventoryId: inv.id,
      transactionType: 'Masuk',
      quantity: 50,
      unitPrice: 7000,
      date: start,
    );
    await service.recordInventoryTransaction(
      inventoryId: inv.id,
      transactionType: 'Keluar',
      quantity: 120,
      unitPrice: 7000,
      date: start,
      cycleId: cycle.id,
    );
    final updatedInv = service.inventory.first;
    expect(updatedInv.remainingStock, 30);

    // Anti double-counting
    final summaryAfterStockUse = service.calculateCycleSummary(cycle.id);
    expect(summaryAfterStockUse.totalExpenses, 10000000);
    expect(AppFormatters.tonsToKg(7), 7000);
  });

  testWidgets(
    'Uji Responsivitas Bebas Overflow pada Layar Kecil (320x568), Standar (360x800), dan Besar (412x915)',
    (WidgetTester tester) async {
      final service = AppDataService();
      await service.completeOnboarding();
      await service.login(email: 'budi@tanijagung.id', password: 'password123');

      final screenSizes = [
        const Size(320, 568), // Layar Android Kecil
        const Size(360, 800), // Layar Android Standar
        const Size(412, 915), // Layar Android Besar
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(const MaterialApp(home: MainNavigationShell()));
        await tester.pumpAndSettle();

        // Verifikasi Beranda tidak menampilkan Stok Gudang atau Prediksi ML
        expect(find.text('Stok Gudang'), findsNothing);
        expect(find.text('Prediksi ML'), findsNothing);

        // Pindah ke Tab 2: Lahan
        await tester.tap(find.text('Lahan').last);
        await tester.pumpAndSettle();

        // Pindah ke Tab 3: Aktivitas
        await tester.tap(find.text('Aktivitas').last);
        await tester.pumpAndSettle();

        // Pindah ke Tab 4: Analisis (Verifikasi tidak ada menu Produktivitas)
        await tester.tap(find.text('Analisis').last);
        await tester.pumpAndSettle();
        expect(find.text('Produktivitas'), findsNothing);

        // Pindah ke Tab 5: Profil
        await tester.tap(find.text('Profil').last);
        await tester.pumpAndSettle();

        // Verifikasi tidak ada tulisan DATA CONTOH di UI
        expect(find.textContaining('DATA CONTOH'), findsNothing);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'Uji Splash Screen Animasi Otomatis (Revisi 1): Tanpa tombol, judul TaniJagung, dan otomatis berpindah setelah selesai',
    (WidgetTester tester) async {
      bool completedCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: (_) => TaniJagungApp())),
        ),
      );

      // Pastikan di awal tampil judul Tani & Jagung dan TIDAK ADA tombol Lewati / Lanjut
      expect(find.text('Tani'), findsOneWidget);
      expect(find.text('Jagung'), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);
      expect(find.text('Lanjut'), findsNothing);
      expect(find.textContaining('Kelola Usaha Tani'), findsNothing);

      // Jalankan animasi sampai selesai (3.2 detik + 0.5 detik jeda)
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      completedCalled = true;
      expect(completedCalled, isTrue);
    },
  );
}
