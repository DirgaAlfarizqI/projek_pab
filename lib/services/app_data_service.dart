import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_models.dart';

class CycleFinancialSummary {
  final PlantingCycleModel cycle;
  final PlotModel? plot;
  final double initialCapital;
  final double operationalExpenses;
  final double totalExpenses;
  final double totalHarvestTons;
  final double totalHarvestKg;
  final double averageSellingPricePerKg;
  final double totalRevenue;
  final double netProfitOrLoss;
  final String financialStatus; // 'UNTUNG', 'RUGI', 'IMPAS'
  final double profitPercentage;
  final double productionCostPerKg;
  final double breakEvenPricePerKg;
  final double productivityKgPerHa;
  final double productivityTonsPerHa;
  final double totalSeedKg;
  final double totalFertilizerKg;
  final Map<String, double> expensesByCategory;

  CycleFinancialSummary({
    required this.cycle,
    required this.plot,
    required this.initialCapital,
    required this.operationalExpenses,
    required this.totalExpenses,
    required this.totalHarvestTons,
    required this.totalHarvestKg,
    required this.averageSellingPricePerKg,
    required this.totalRevenue,
    required this.netProfitOrLoss,
    required this.financialStatus,
    required this.profitPercentage,
    required this.productionCostPerKg,
    required this.breakEvenPricePerKg,
    required this.productivityKgPerHa,
    required this.productivityTonsPerHa,
    required this.totalSeedKg,
    required this.totalFertilizerKg,
    required this.expensesByCategory,
  });
}

class AppDataService extends ChangeNotifier {
  static final AppDataService _instance = AppDataService._internal();
  factory AppDataService() => _instance;
  AppDataService._internal();

  final Uuid _uuid = const Uuid();
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _hasSeenOnboarding = false;
  bool _firebaseReady = false;

  UserModel? _currentUser;

  // Seluruh tabel entitas yang diisolasi berdasarkan userId
  List<FarmModel> _farms = [];
  List<PlotModel> _plots = [];
  List<PlantingCycleModel> _cycles = [];
  List<CropInputModel> _cropInputs = [];
  List<ExpenseModel> _expenses = [];
  List<InventoryItemModel> _inventory = [];
  List<InventoryTransactionModel> _inventoryTransactions = [];
  List<ActivityModel> _activities = [];
  List<HarvestRecordModel> _harvests = [];
  List<PredictionModel> _predictions = [];
  List<AppNotificationModel> _notifications = [];

  bool get isInitialized => _isInitialized;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isLoggedIn => _currentUser != null;
  bool get isFirebaseConnected => _firebaseReady;
  UserModel? get currentUser => _currentUser;

  // Getter terisolasi hanya untuk pengguna aktif
  List<FarmModel> get farms => _currentUser == null
      ? []
      : _farms.where((e) => e.userId == _currentUser!.id).toList();

  List<PlotModel> get plots =>
      _currentUser == null
            ? []
            : _plots.where((e) => e.userId == _currentUser!.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<PlantingCycleModel> get cycles =>
      _currentUser == null
            ? []
            : _cycles.where((e) => e.userId == _currentUser!.id).toList()
        ..sort((a, b) => b.plantingDate.compareTo(a.plantingDate));

  List<PlantingCycleModel> get activeCycles =>
      cycles.where((c) => c.isActive).toList();

  List<CropInputModel> get cropInputs =>
      _currentUser == null
            ? []
            : _cropInputs.where((e) => e.userId == _currentUser!.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<ExpenseModel> get expenses =>
      _currentUser == null
            ? []
            : _expenses.where((e) => e.userId == _currentUser!.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<InventoryItemModel> get inventory =>
      _currentUser == null
            ? []
            : _inventory.where((e) => e.userId == _currentUser!.id).toList()
        ..sort((a, b) => a.itemName.compareTo(b.itemName));

  List<InventoryTransactionModel> get inventoryTransactions =>
      _currentUser == null
            ? []
            : _inventoryTransactions
                  .where((e) => e.userId == _currentUser!.id)
                  .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<ActivityModel> get activities =>
      _currentUser == null
            ? []
            : _activities.where((e) => e.userId == _currentUser!.id).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<HarvestRecordModel> get harvests =>
      _currentUser == null
            ? []
            : _harvests.where((e) => e.userId == _currentUser!.id).toList()
        ..sort((a, b) => b.harvestDate.compareTo(a.harvestDate));

  List<PredictionModel> get predictions =>
      _currentUser == null
            ? []
            : _predictions.where((e) => e.userId == _currentUser!.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Membangun daftar pengingat otomatis berdasarkan tanggal manual pengguna dan batas stok minimum
  List<AppNotificationModel> get generatedNotifications {
    if (_currentUser == null || !_currentUser!.notificationsEnabled) return [];
    final uid = _currentUser!.id;
    final List<AppNotificationModel> result = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Cek jadwal aktivitas yang terlambat atau akan datang (<= 7 hari ke depan)
    for (final act in activities) {
      if (act.isCompleted) continue;
      final actDay = DateTime(act.date.year, act.date.month, act.date.day);
      final diffDays = actDay.difference(today).inDays;
      final plotName = getPlotById(act.plotId)?.name ?? 'Lahan';

      if (diffDays < 0) {
        result.add(
          AppNotificationModel(
            id: 'notif_act_overdue_${act.id}',
            userId: uid,
            title: 'Terlambat ${diffDays.abs()} Hari: ${act.name}',
            message:
                'Kegiatan ${act.activityType} pada $plotName terjadwal tanggal ${_formatDayMonth(act.date)}.',
            type: 'jadwal_terlambat',
            relatedId: act.id,
            date: act.date,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else if (diffDays <= 7) {
        final labelWaktu = diffDays == 0 ? 'Hari Ini' : '$diffDays Hari Lagi';
        result.add(
          AppNotificationModel(
            id: 'notif_act_upcoming_${act.id}',
            userId: uid,
            title: 'Jadwal $labelWaktu: ${act.name}',
            message:
                'Kegiatan ${act.activityType} pada $plotName tanggal ${_formatDayMonth(act.date)}.',
            type: 'jadwal_akan_datang',
            relatedId: act.id,
            date: act.date,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    // 2. Cek stok habis atau di bawah batas minimum yang ditentukan pengguna
    for (final item in inventory) {
      if (item.isOutOfStock) {
        result.add(
          AppNotificationModel(
            id: 'notif_inv_empty_${item.id}',
            userId: uid,
            title: 'Stok Habis: ${item.itemName}',
            message:
                'Persediaan ${item.itemName} (${item.itemType}) saat ini 0 ${item.unit}.',
            type: 'stok_menipis',
            relatedId: item.id,
            date: item.updatedAt,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else if (item.isLowStock) {
        result.add(
          AppNotificationModel(
            id: 'notif_inv_low_${item.id}',
            userId: uid,
            title: 'Stok Menipis: ${item.itemName}',
            message:
                'Sisa stok ${item.remainingStock} ${item.unit} (batas minimum pengguna: ${item.minimumStockAlert} ${item.unit}).',
            type: 'stok_menipis',
            relatedId: item.id,
            date: item.updatedAt,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    return result;
  }

  String _formatDayMonth(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = _prefs?.getBool('has_seen_onboarding') ?? false;

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      // Berjalan mulus dengan persistence lokal terisolasi jika google-services.json belum dikonfigurasi
      _firebaseReady = false;
    }

    await _loadAllFromDisk();
    await _sanitizeLegacyDemoPrefix();

    final savedUserId = _prefs?.getString('active_user_id');
    if (savedUserId != null) {
      final usersMap = _getRegisteredUsersMap();
      if (usersMap.containsKey(savedUserId)) {
        _currentUser = UserModel.fromMap(usersMap[savedUserId]!);
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    await _prefs?.setBool('has_seen_onboarding', true);
    notifyListeners();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('tanijagung_salt_$password');
    return sha256.convert(bytes).toString();
  }

  Map<String, Map<String, dynamic>> _getRegisteredUsersMap() {
    final raw = _prefs?.getString('table_users');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveRegisteredUsersMap(
    Map<String, Map<String, dynamic>> map,
  ) async {
    await _prefs?.setString('table_users', jsonEncode(map));
  }

  /// Registrasi pengguna baru (nama, email, password)
  /// Data pengguna baru mulai bersih (kosong), pengguna bisa memuat data contoh berlabel [DATA CONTOH] jika diinginkan
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String farmBusinessName = 'Usaha Tani Jagung Mandiri',
    bool loadLabeledDemoData = false,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty) return 'Nama lengkap wajib diisi.';
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return 'Format email tidak valid.';
    }
    if (password.length < 6) {
      return 'Password minimal terdiri dari 6 karakter.';
    }

    final usersMap = _getRegisteredUsersMap();
    for (final entry in usersMap.values) {
      if ((entry['email'] as String?)?.toLowerCase() == cleanEmail) {
        return 'Email sudah terdaftar. Silakan login menggunakan akun Anda.';
      }
    }

    String uid = 'usr_${_uuid.v4()}';
    if (_firebaseReady) {
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (cred.user != null) {
          uid = cred.user!.uid;
        }
      } catch (_) {
        // Tetap lanjutkan penyimpanan akun lokal
      }
    }

    final now = DateTime.now();
    final newUser = UserModel(
      id: uid,
      name: name.trim(),
      email: cleanEmail,
      farmBusinessName: farmBusinessName.trim().isEmpty
          ? 'Usaha Tani Jagung Mandiri'
          : farmBusinessName.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final userRecord = newUser.toMap();
    userRecord['password_hash'] = _hashPassword(password);
    usersMap[uid] = userRecord;
    await _saveRegisteredUsersMap(usersMap);

    // Buat entitas farm induk default untuk user ini
    final defaultFarm = FarmModel(
      id: 'farm_${_uuid.v4()}',
      userId: uid,
      name: newUser.farmBusinessName,
      region: 'Indonesia',
      description: 'Unit usaha pertanian jagung milik ${newUser.name}',
      isDemo: false,
      createdAt: now,
      updatedAt: now,
    );
    _farms.add(defaultFarm);

    _currentUser = newUser;
    await _prefs?.setString('active_user_id', uid);

    if (loadLabeledDemoData) {
      await seedLabeledDemoDataForCurrentUser();
    } else {
      await _persistAllToDisk();
    }

    _syncToFirestoreIfAvailable('users', uid, newUser.toMap());
    notifyListeners();
    return null;
  }

  /// Login pengguna dengan isolasi data per akun
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final usersMap = _getRegisteredUsersMap();
    final hashed = _hashPassword(password);

    for (final entry in usersMap.values) {
      if ((entry['email'] as String?)?.toLowerCase() == cleanEmail) {
        if (entry['password_hash'] == hashed) {
          _currentUser = UserModel.fromMap(entry);
          await _prefs?.setString('active_user_id', _currentUser!.id);
          notifyListeners();
          return null;
        } else {
          return 'Password yang Anda masukkan salah.';
        }
      }
    }

    if (_firebaseReady) {
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (cred.user != null) {
          final now = DateTime.now();
          final u = UserModel(
            id: cred.user!.uid,
            name: cred.user!.displayName ?? cleanEmail.split('@').first,
            email: cleanEmail,
            createdAt: now,
            updatedAt: now,
          );
          final rec = u.toMap();
          rec['password_hash'] = hashed;
          usersMap[u.id] = rec;
          await _saveRegisteredUsersMap(usersMap);
          _currentUser = u;
          await _prefs?.setString('active_user_id', u.id);
          notifyListeners();
          return null;
        }
      } catch (_) {}
    }

    return 'Akun dengan email tersebut belum terdaftar.';
  }

  Future<void> logout() async {
    if (_firebaseReady) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    await _prefs?.remove('active_user_id');
    notifyListeners();
  }

  Future<void> updateUserProfile(UserModel updated) async {
    if (_currentUser == null) return;
    _currentUser = updated.copyWith(updatedAt: DateTime.now());
    final usersMap = _getRegisteredUsersMap();
    final existing = usersMap[_currentUser!.id] ?? {};
    final newMap = _currentUser!.toMap();
    if (existing.containsKey('password_hash')) {
      newMap['password_hash'] = existing['password_hash'];
    }
    usersMap[_currentUser!.id] = newMap;
    await _saveRegisteredUsersMap(usersMap);
    _syncToFirestoreIfAvailable(
      'users',
      _currentUser!.id,
      _currentUser!.toMap(),
    );
    notifyListeners();
  }

  // ==================== HELPER RELASI & PENCARIAN ====================

  PlotModel? getPlotById(String plotId) {
    try {
      return plots.firstWhere((p) => p.id == plotId);
    } catch (_) {
      return null;
    }
  }

  PlantingCycleModel? getCycleById(String cycleId) {
    try {
      return cycles.firstWhere((c) => c.id == cycleId);
    } catch (_) {
      return null;
    }
  }

  List<PlantingCycleModel> getCyclesForPlot(String plotId) =>
      cycles.where((c) => c.plotId == plotId).toList();

  List<CropInputModel> getCropInputsForCycle(String cycleId) =>
      cropInputs.where((i) => i.cycleId == cycleId).toList();

  List<ExpenseModel> getExpensesForCycle(String cycleId) =>
      expenses.where((e) => e.cycleId == cycleId).toList();

  List<ActivityModel> getActivitiesForCycle(String cycleId) =>
      activities.where((a) => a.cycleId == cycleId).toList();

  List<HarvestRecordModel> getHarvestsForCycle(String cycleId) =>
      harvests.where((h) => h.cycleId == cycleId).toList();

  // ==================== OPERASI CRUD LAHAN (PLOTS) ====================

  Future<PlotModel> addPlot({
    required String name,
    required String location,
    required double area,
    required String areaUnit,
    String notes = '',
    String? photoPath,
    bool isDemo = false,
  }) async {
    final uid = _currentUser!.id;
    final now = DateTime.now();
    String farmId = farms.isNotEmpty ? farms.first.id : 'farm_$uid';
    if (farms.isEmpty) {
      final f = FarmModel(
        id: farmId,
        userId: uid,
        name: _currentUser!.farmBusinessName,
        region: location,
        isDemo: isDemo,
        createdAt: now,
        updatedAt: now,
      );
      _farms.add(f);
    }

    final plot = PlotModel(
      id: 'plot_${_uuid.v4()}',
      userId: uid,
      farmId: farmId,
      name: name.trim(),
      location: location.trim(),
      area: area,
      areaUnit: areaUnit,
      notes: notes.trim(),
      photoPath: photoPath,
      isDemo: isDemo,
      createdAt: now,
      updatedAt: now,
    );
    _plots.add(plot);
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('plots', plot.id, plot.toMap());
    notifyListeners();
    return plot;
  }

  Future<void> updatePlot(PlotModel updated) async {
    final idx = _plots.indexWhere(
      (p) => p.id == updated.id && p.userId == _currentUser?.id,
    );
    if (idx == -1) return;
    _plots[idx] = updated.copyWith(updatedAt: DateTime.now());
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('plots', updated.id, _plots[idx].toMap());
    notifyListeners();
  }

  Future<void> deletePlot(String plotId) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    final relatedCycleIds = _cycles
        .where((c) => c.userId == uid && c.plotId == plotId)
        .map((c) => c.id)
        .toSet();

    _plots.removeWhere((p) => p.id == plotId && p.userId == uid);
    _cycles.removeWhere((c) => c.plotId == plotId && c.userId == uid);
    _cropInputs.removeWhere(
      (i) =>
          i.userId == uid &&
          (i.plotId == plotId || relatedCycleIds.contains(i.cycleId)),
    );
    _expenses.removeWhere(
      (e) =>
          e.userId == uid &&
          (e.plotId == plotId || relatedCycleIds.contains(e.cycleId)),
    );
    _activities.removeWhere(
      (a) =>
          a.userId == uid &&
          (a.plotId == plotId || relatedCycleIds.contains(a.cycleId)),
    );
    _harvests.removeWhere(
      (h) =>
          h.userId == uid &&
          (h.plotId == plotId || relatedCycleIds.contains(h.cycleId)),
    );
    _predictions.removeWhere(
      (p) =>
          p.userId == uid &&
          (p.plotId == plotId || relatedCycleIds.contains(p.cycleId)),
    );

    await _persistAllToDisk();
    notifyListeners();
  }

  // ==================== OPERASI CRUD MUSIM TANAM (PLANTING CYCLES) ====================

  Future<PlantingCycleModel> addPlantingCycle({
    required String plotId,
    required String name,
    required String cornVariety,
    required DateTime plantingDate,
    required DateTime estimatedHarvestDate,
    DateTime? actualHarvestDate,
    required String status,
    double? targetYieldTons,
    double initialCapital = 0.0,
    String notes = '',
    bool isDemo = false,
  }) async {
    final uid = _currentUser!.id;
    final now = DateTime.now();
    final cycle = PlantingCycleModel(
      id: 'cyc_${_uuid.v4()}',
      userId: uid,
      plotId: plotId,
      name: name.trim(),
      cornVariety: cornVariety.trim(),
      plantingDate: plantingDate,
      estimatedHarvestDate: estimatedHarvestDate,
      actualHarvestDate: actualHarvestDate,
      status: status,
      targetYieldTons: targetYieldTons,
      initialCapital: initialCapital,
      notes: notes.trim(),
      isDemo: isDemo,
      createdAt: now,
      updatedAt: now,
    );
    _cycles.add(cycle);

    // Otomatis catat tanggal mulai tanam & tanggal perkiraan panen ke kalender aktivitas pengguna
    _activities.add(
      ActivityModel(
        id: 'act_${_uuid.v4()}',
        userId: uid,
        plotId: plotId,
        cycleId: cycle.id,
        name: 'Mulai Penanaman (${cycle.cornVariety})',
        activityType: 'Mulai Penanaman',
        date: plantingDate,
        cost: 0,
        isCompleted: !plantingDate.isAfter(now),
        notes: 'Tanggal mulai penanaman musim ${cycle.name}',
        isDemo: isDemo,
        createdAt: now,
        updatedAt: now,
      ),
    );

    _activities.add(
      ActivityModel(
        id: 'act_${_uuid.v4()}',
        userId: uid,
        plotId: plotId,
        cycleId: cycle.id,
        name: 'Target Perkiraan Panen (${cycle.name})',
        activityType: 'Perkiraan Panen',
        date: estimatedHarvestDate,
        cost: 0,
        isCompleted: actualHarvestDate != null || status == 'Selesai',
        notes: 'Perkiraan tanggal panen berdasarkan jadwal musim tanam',
        isDemo: isDemo,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('planting_cycles', cycle.id, cycle.toMap());
    notifyListeners();
    return cycle;
  }

  Future<void> updatePlantingCycle(PlantingCycleModel updated) async {
    final idx = _cycles.indexWhere(
      (c) => c.id == updated.id && c.userId == _currentUser?.id,
    );
    if (idx == -1) return;
    _cycles[idx] = updated.copyWith(updatedAt: DateTime.now());
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable(
      'planting_cycles',
      updated.id,
      _cycles[idx].toMap(),
    );
    notifyListeners();
  }

  Future<void> deletePlantingCycle(String cycleId) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    _cycles.removeWhere((c) => c.id == cycleId && c.userId == uid);
    _cropInputs.removeWhere((i) => i.cycleId == cycleId && i.userId == uid);
    _expenses.removeWhere((e) => e.cycleId == cycleId && e.userId == uid);
    _activities.removeWhere((a) => a.cycleId == cycleId && a.userId == uid);
    _harvests.removeWhere((h) => h.cycleId == cycleId && h.userId == uid);
    _predictions.removeWhere((p) => p.cycleId == cycleId && p.userId == uid);
    await _persistAllToDisk();
    notifyListeners();
  }

  // ==================== PENCATATAN BENIH & PUPUK (CROP INPUTS) ====================

  /// Mencatat penggunaan atau pembelian benih/pupuk secara manual.
  /// - Jika `isFromPaidStock == true`, penggunaan diambil dari stok yang sudah dibeli sebelumnya,
  ///   sehingga stok dikurangi dan TIDAK dibuatkan biaya baru (menghindari penghitungan ganda).
  /// - Jika `isFromPaidStock == false` dan `recordAsExpense == true`, otomatis tercatat di pengeluaran musim tanam.
  Future<CropInputModel> addCropInput({
    required String plotId,
    required String cycleId,
    required String productName,
    required String inputType,
    required double quantity,
    required String unit,
    required double unitPrice,
    required DateTime date,
    bool isFromPaidStock = false,
    bool recordAsExpense = true,
    String? linkedInventoryId,
    String notes = '',
    bool isDemo = false,
  }) async {
    final uid = _currentUser!.id;
    final now = DateTime.now();
    final inputId = 'inp_${_uuid.v4()}';
    String? expenseId;

    // Jika bukan dari stok yang sudah dibayar, dan dicatat sebagai pengeluaran baru
    if (!isFromPaidStock && recordAsExpense && (quantity * unitPrice) > 0) {
      expenseId = 'exp_${_uuid.v4()}';
      String expenseCat = 'Biaya lainnya';
      if (inputType.toLowerCase().contains('benih')) {
        expenseCat = 'Benih';
      } else if (inputType.toLowerCase().contains('pupuk')) {
        expenseCat = 'Pupuk';
      } else if (inputType.toLowerCase().contains('pestisida')) {
        expenseCat = 'Pestisida';
      }

      final exp = ExpenseModel(
        id: expenseId,
        userId: uid,
        plotId: plotId,
        cycleId: cycleId,
        name: '$inputType: ${productName.trim()}',
        category: expenseCat,
        date: date,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        notes: notes.trim().isEmpty
            ? 'Tercatat otomatis dari input penggunaan $inputType'
            : notes.trim(),
        sourceReferenceId: inputId,
        isDemo: isDemo,
        createdAt: now,
        updatedAt: now,
      );
      _expenses.add(exp);
      _syncToFirestoreIfAvailable('expenses', exp.id, exp.toMap());
    }

    // Jika diambil dari stok gudang yang dipilih, kurangi stok keluar
    if (linkedInventoryId != null) {
      final invIdx = _inventory.indexWhere(
        (inv) => inv.id == linkedInventoryId && inv.userId == uid,
      );
      if (invIdx != -1) {
        final currentInv = _inventory[invIdx];
        _inventory[invIdx] = currentInv.copyWith(
          stockOut: currentInv.stockOut + quantity,
          lastTransactionDate: date,
          updatedAt: now,
        );
        _inventoryTransactions.add(
          InventoryTransactionModel(
            id: 'invtx_${_uuid.v4()}',
            userId: uid,
            inventoryId: currentInv.id,
            itemName: currentInv.itemName,
            transactionType: 'Keluar',
            quantity: quantity,
            unit: currentInv.unit,
            unitPrice: unitPrice,
            date: date,
            cycleId: cycleId,
            notes: 'Digunakan pada musim tanam (${notes.trim()})',
            isDemo: isDemo,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    final item = CropInputModel(
      id: inputId,
      userId: uid,
      plotId: plotId,
      cycleId: cycleId,
      productName: productName.trim(),
      inputType: inputType,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      date: date,
      isFromPaidStock: isFromPaidStock,
      linkedExpenseId: expenseId,
      linkedInventoryId: linkedInventoryId,
      notes: notes.trim(),
      isDemo: isDemo,
      createdAt: now,
      updatedAt: now,
    );

    _cropInputs.add(item);
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('crop_inputs', item.id, item.toMap());
    notifyListeners();
    return item;
  }

  Future<void> deleteCropInput(String inputId) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    final idx = _cropInputs.indexWhere(
      (i) => i.id == inputId && i.userId == uid,
    );
    if (idx == -1) return;
    final target = _cropInputs[idx];
    if (target.linkedExpenseId != null) {
      _expenses.removeWhere(
        (e) => e.id == target.linkedExpenseId && e.userId == uid,
      );
    }
    _cropInputs.removeAt(idx);
    await _persistAllToDisk();
    notifyListeners();
  }

  // ==================== PENCATATAN PENGELUARAN (EXPENSES) ====================

  Future<ExpenseModel> addExpense({
    required String plotId,
    required String cycleId,
    required String name,
    required String category,
    required DateTime date,
    required double quantity,
    required String unit,
    required double unitPrice,
    String notes = '',
    String? receiptPhotoPath,
    bool isDemo = false,
  }) async {
    final uid = _currentUser!.id;
    final now = DateTime.now();
    final exp = ExpenseModel(
      id: 'exp_${_uuid.v4()}',
      userId: uid,
      plotId: plotId,
      cycleId: cycleId,
      name: name.trim(),
      category: category,
      date: date,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      notes: notes.trim(),
      receiptPhotoPath: receiptPhotoPath,
      isDemo: isDemo,
      createdAt: now,
      updatedAt: now,
    );
    _expenses.add(exp);
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('expenses', exp.id, exp.toMap());
    notifyListeners();
    return exp;
  }

  Future<void> updateExpense(ExpenseModel updated) async {
    final idx = _expenses.indexWhere(
      (e) => e.id == updated.id && e.userId == _currentUser?.id,
    );
    if (idx == -1) return;
    _expenses[idx] = updated;
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('expenses', updated.id, updated.toMap());
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    _expenses.removeWhere((e) => e.id == expenseId && e.userId == uid);
    await _persistAllToDisk();
    notifyListeners();
  }

  // ==================== AKTIVITAS & KALENDER TANGGAL ====================

  Future<ActivityModel> addActivity({
    required String plotId,
    required String cycleId,
    required String name,
    required String activityType,
    required DateTime date,
    double cost = 0.0,
    bool isCompleted = false,
    bool recordCostAsExpense = true,
    String notes = '',
    bool isDemo = false,
  }) async {
    final uid = _currentUser!.id;
    final now = DateTime.now();
    final actId = 'act_${_uuid.v4()}';
    String? linkedExpId;

    if (cost > 0 && recordCostAsExpense) {
      linkedExpId = 'exp_${_uuid.v4()}';
      String category = 'Tenaga kerja';
      if (activityType.toLowerCase().contains('pestisida')) {
        category = 'Pestisida';
      } else if (activityType.toLowerCase().contains('pengolahan')) {
        category = 'Sewa alat atau mesin';
      }

      final exp = ExpenseModel(
        id: linkedExpId,
        userId: uid,
        plotId: plotId,
        cycleId: cycleId,
        name: 'Biaya Aktivitas: ${name.trim()}',
        category: category,
        date: date,
        quantity: 1,
        unit: 'kegiatan',
        unitPrice: cost,
        notes: notes.trim(),
        sourceReferenceId: actId,
        isDemo: isDemo,
        createdAt: now,
        updatedAt: now,
      );
      _expenses.add(exp);
      _syncToFirestoreIfAvailable('expenses', exp.id, exp.toMap());
    }

    final act = ActivityModel(
      id: actId,
      userId: uid,
      plotId: plotId,
      cycleId: cycleId,
      name: name.trim(),
      activityType: activityType,
      date: date,
      cost: cost,
      isCompleted: isCompleted,
      linkedExpenseId: linkedExpId,
      notes: notes.trim(),
      isDemo: isDemo,
      createdAt: now,
      updatedAt: now,
    );
    _activities.add(act);
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('activities', act.id, act.toMap());
    notifyListeners();
    return act;
  }

  Future<void> updateActivity(ActivityModel updated) async {
    final idx = _activities.indexWhere(
      (a) => a.id == updated.id && a.userId == _currentUser?.id,
    );
    if (idx == -1) return;
    _activities[idx] = updated.copyWith(updatedAt: DateTime.now());
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable(
      'activities',
      updated.id,
      _activities[idx].toMap(),
    );
    notifyListeners();
  }

  Future<void> toggleActivityCompleted(
    String activityId,
    bool completed,
  ) async {
    final idx = _activities.indexWhere(
      (a) => a.id == activityId && a.userId == _currentUser?.id,
    );
    if (idx == -1) return;
    _activities[idx] = _activities[idx].copyWith(
      isCompleted: completed,
      updatedAt: DateTime.now(),
    );
    await _persistAllToDisk();
    notifyListeners();
  }

  Future<void> deleteActivity(String activityId) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    final idx = _activities.indexWhere(
      (a) => a.id == activityId && a.userId == uid,
    );
    if (idx == -1) return;
    final act = _activities[idx];
    if (act.linkedExpenseId != null) {
      _expenses.removeWhere(
        (e) => e.id == act.linkedExpenseId && e.userId == uid,
      );
    }
    _activities.removeAt(idx);
    await _persistAllToDisk();
    notifyListeners();
  }

  // ==================== INPUT HASIL PANEN AKTUAL (HARVEST RECORDS) ====================

  Future<HarvestRecordModel> addHarvestRecord({
    required String plotId,
    required String cycleId,
    required DateTime harvestDate,
    required double yieldTons,
    required double sellingPricePerKg,
    bool markCycleCompleted = true,
    String notes = '',
    bool isDemo = false,
  }) async {
    final uid = _currentUser!.id;
    final now = DateTime.now();
    final record = HarvestRecordModel(
      id: 'hrv_${_uuid.v4()}',
      userId: uid,
      plotId: plotId,
      cycleId: cycleId,
      harvestDate: harvestDate,
      yieldTons: yieldTons,
      sellingPricePerKg: sellingPricePerKg,
      notes: notes.trim(),
      isDemo: isDemo,
      createdAt: now,
      updatedAt: now,
    );
    _harvests.add(record);

    // Update tanggal panen aktual & status pada musim tanam terkait
    final cycIdx = _cycles.indexWhere(
      (c) => c.id == cycleId && c.userId == uid,
    );
    if (cycIdx != -1) {
      final currentCycle = _cycles[cycIdx];
      _cycles[cycIdx] = currentCycle.copyWith(
        actualHarvestDate: harvestDate,
        status: markCycleCompleted ? 'Selesai' : currentCycle.status,
        updatedAt: now,
      );
    }

    // Catat ke timeline aktivitas sebagai Panen Aktual
    _activities.add(
      ActivityModel(
        id: 'act_${_uuid.v4()}',
        userId: uid,
        plotId: plotId,
        cycleId: cycleId,
        name: 'Panen Aktual (${yieldTons.toStringAsFixed(2)} Ton)',
        activityType: 'Panen Aktual',
        date: harvestDate,
        cost: 0,
        isCompleted: true,
        notes:
            'Panen ${yieldTons * 1000} kg dengan harga jual Rp${sellingPricePerKg.round()}/kg',
        isDemo: isDemo,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('harvest_records', record.id, record.toMap());
    notifyListeners();
    return record;
  }

  Future<void> updateHarvestRecord(HarvestRecordModel updated) async {
    final idx = _harvests.indexWhere(
      (h) => h.id == updated.id && h.userId == _currentUser?.id,
    );
    if (idx == -1) return;
    _harvests[idx] = updated.copyWith(updatedAt: DateTime.now());
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('harvest_records', updated.id, updated.toMap());
    notifyListeners();
  }

  Future<void> deleteHarvestRecord(String harvestId) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    _harvests.removeWhere((h) => h.id == harvestId && h.userId == uid);
    await _persistAllToDisk();
    notifyListeners();
  }

  // ==================== STOK BENIH DAN PUPUK (INVENTORY) ====================

  Future<InventoryItemModel> addInventoryItem({
    required String itemName,
    required String itemType,
    required double initialStock,
    required String unit,
    required double purchasePrice,
    required double minimumStockAlert,
    required DateTime transactionDate,
    bool recordInitialPurchaseAsExpense = false,
    String? cycleIdForExpense,
    bool isDemo = false,
  }) async {
    final uid = _currentUser!.id;
    final now = DateTime.now();
    final inv = InventoryItemModel(
      id: 'inv_${_uuid.v4()}',
      userId: uid,
      itemName: itemName.trim(),
      itemType: itemType,
      initialStock: initialStock,
      stockIn: 0.0,
      stockOut: 0.0,
      unit: unit,
      lastPurchasePrice: purchasePrice,
      minimumStockAlert: minimumStockAlert,
      lastTransactionDate: transactionDate,
      isDemo: isDemo,
      createdAt: now,
      updatedAt: now,
    );
    _inventory.add(inv);

    _inventoryTransactions.add(
      InventoryTransactionModel(
        id: 'invtx_${_uuid.v4()}',
        userId: uid,
        inventoryId: inv.id,
        itemName: inv.itemName,
        transactionType: 'Stok Awal',
        quantity: initialStock,
        unit: unit,
        unitPrice: purchasePrice,
        date: transactionDate,
        cycleId: cycleIdForExpense,
        notes: 'Pencatatan persediaan awal',
        isDemo: isDemo,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (recordInitialPurchaseAsExpense &&
        cycleIdForExpense != null &&
        initialStock * purchasePrice > 0) {
      final cyc = getCycleById(cycleIdForExpense);
      if (cyc != null) {
        await addExpense(
          plotId: cyc.plotId,
          cycleId: cyc.id,
          name: 'Pembelian Stok ${inv.itemName}',
          category: itemType == 'Benih'
              ? 'Benih'
              : (itemType == 'Pupuk' ? 'Pupuk' : 'Biaya lainnya'),
          date: transactionDate,
          quantity: initialStock,
          unit: unit,
          unitPrice: purchasePrice,
          notes: 'Pembelian persediaan awal gudang',
          isDemo: isDemo,
        );
      }
    }

    await _persistAllToDisk();
    _syncToFirestoreIfAvailable('inventory', inv.id, inv.toMap());
    notifyListeners();
    return inv;
  }

  /// Transaksi tambah stok masuk atau pengurangan stok keluar
  /// Rumus: Stok akhir = Stok awal + Stok masuk - Stok keluar
  Future<void> recordInventoryTransaction({
    required String inventoryId,
    required String transactionType, // 'Masuk' atau 'Keluar'
    required double quantity,
    required double unitPrice,
    required DateTime date,
    String? cycleId,
    bool recordPurchaseAsExpense = false,
    String notes = '',
  }) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    final idx = _inventory.indexWhere(
      (i) => i.id == inventoryId && i.userId == uid,
    );
    if (idx == -1) return;
    final item = _inventory[idx];
    final now = DateTime.now();

    if (transactionType == 'Masuk') {
      _inventory[idx] = item.copyWith(
        stockIn: item.stockIn + quantity,
        lastPurchasePrice: unitPrice > 0 ? unitPrice : item.lastPurchasePrice,
        lastTransactionDate: date,
        updatedAt: now,
      );

      if (recordPurchaseAsExpense &&
          cycleId != null &&
          quantity * unitPrice > 0) {
        final cyc = getCycleById(cycleId);
        if (cyc != null) {
          await addExpense(
            plotId: cyc.plotId,
            cycleId: cyc.id,
            name: 'Pembelian Stok: ${item.itemName}',
            category: item.itemType == 'Benih'
                ? 'Benih'
                : (item.itemType == 'Pupuk' ? 'Pupuk' : 'Biaya lainnya'),
            date: date,
            quantity: quantity,
            unit: item.unit,
            unitPrice: unitPrice,
            notes: notes.isEmpty ? 'Stok masuk gudang' : notes,
          );
        }
      }
    } else {
      _inventory[idx] = item.copyWith(
        stockOut: item.stockOut + quantity,
        lastTransactionDate: date,
        updatedAt: now,
      );

      // Jika digunakan pada musim tanam tertentu, catat pada riwayat penggunaan benih/pupuk TANPA menghitung biaya ganda
      if (cycleId != null) {
        final cyc = getCycleById(cycleId);
        if (cyc != null) {
          _cropInputs.add(
            CropInputModel(
              id: 'inp_${_uuid.v4()}',
              userId: uid,
              plotId: cyc.plotId,
              cycleId: cyc.id,
              productName: item.itemName,
              inputType: item.itemType == 'Benih' ? 'Benih' : 'Pupuk',
              quantity: quantity,
              unit: item.unit,
              unitPrice: unitPrice > 0 ? unitPrice : item.lastPurchasePrice,
              date: date,
              isFromPaidStock:
                  true, // Tidak dihitung dua kali sebagai pengeluaran
              linkedInventoryId: item.id,
              notes: notes.isEmpty ? 'Penggunaan dari stok gudang' : notes,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
    }

    _inventoryTransactions.add(
      InventoryTransactionModel(
        id: 'invtx_${_uuid.v4()}',
        userId: uid,
        inventoryId: item.id,
        itemName: item.itemName,
        transactionType: transactionType,
        quantity: quantity,
        unit: item.unit,
        unitPrice: unitPrice > 0 ? unitPrice : item.lastPurchasePrice,
        date: date,
        cycleId: cycleId,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _persistAllToDisk();
    notifyListeners();
  }

  Future<void> deleteInventoryItem(String inventoryId) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    _inventory.removeWhere((i) => i.id == inventoryId && i.userId == uid);
    _inventoryTransactions.removeWhere(
      (t) => t.inventoryId == inventoryId && t.userId == uid,
    );
    await _persistAllToDisk();
    notifyListeners();
  }

  // ==================== RIWAYAT PREDIKSI ML ====================

  Future<PredictionModel> savePrediction(PredictionModel prediction) async {
    _predictions.add(prediction);
    await _persistAllToDisk();
    _syncToFirestoreIfAvailable(
      'predictions',
      prediction.id,
      prediction.toMap(),
    );
    notifyListeners();
    return prediction;
  }

  // ==================== PERHITUNGAN OTOMATIS KEUANGAN & PRODUKTIVITAS ====================

  /// Menghitung seluruh metrik keuangan dan produktivitas untuk 1 musim tanam secara akurat
  CycleFinancialSummary calculateCycleSummary(String cycleId) {
    final cycle = getCycleById(cycleId)!;
    final plot = getPlotById(cycle.plotId);
    final cycleExpenses = getExpensesForCycle(cycleId);
    final cycleInputs = getCropInputsForCycle(cycleId);
    final cycleHarvests = getHarvestsForCycle(cycleId);

    // 1. Pengeluaran operasional dari tabel expenses
    double operationalExpenses = 0.0;
    final Map<String, double> byCategory = {
      'Benih': 0.0,
      'Pupuk': 0.0,
      'Pestisida': 0.0,
      'Pengolahan lahan': 0.0,
      'Tenaga kerja': 0.0,
      'Sewa alat': 0.0,
      'Transportasi': 0.0,
      'Biaya panen': 0.0,
      'Lain-lain': 0.0,
    };

    for (final exp in cycleExpenses) {
      operationalExpenses += exp.totalCost;
      final normalizedCat = byCategory.containsKey(exp.category)
          ? exp.category
          : (exp.category == 'Sewa alat atau mesin'
                ? 'Sewa alat'
                : 'Lain-lain');
      byCategory[normalizedCat] =
          (byCategory[normalizedCat] ?? 0.0) + exp.totalCost;
    }

    // Cek apabila ada input benih/pupuk yang belum punya linkedExpenseId dan BUKAN dari stok yang sudah dibayar
    for (final inp in cycleInputs) {
      if (!inp.isFromPaidStock && inp.linkedExpenseId == null) {
        operationalExpenses += inp.subtotal;
        final cat = inp.inputType == 'Benih'
            ? 'Benih'
            : (inp.inputType == 'Pupuk' ? 'Pupuk' : 'Lain-lain');
        byCategory[cat] = (byCategory[cat] ?? 0.0) + inp.subtotal;
      }
    }

    final totalExpenses = operationalExpenses;

    // 2. Hasil panen aktual & pendapatan kotor
    double totalHarvestTons = 0.0;
    double totalHarvestKg = 0.0;
    double totalRevenue = 0.0;

    for (final h in cycleHarvests) {
      totalHarvestTons += h.yieldTons;
      totalHarvestKg += h.yieldKg;
      totalRevenue += h.grossRevenue;
    }

    final double avgSellingPrice = totalHarvestKg > 0
        ? (totalRevenue / totalHarvestKg)
        : 0.0;

    // 3. Laba / Rugi = Total Pendapatan - Total Pengeluaran
    final double netProfitOrLoss = totalRevenue - totalExpenses;
    String status = 'IMPAS';
    if (netProfitOrLoss > 0.001) {
      status = 'UNTUNG';
    } else if (netProfitOrLoss < -0.001) {
      status = 'RUGI';
    }

    // 4. Persentase keuntungan terhadap total biaya
    final double profitPercentage = totalExpenses > 0
        ? (netProfitOrLoss / totalExpenses) * 100.0
        : 0.0;

    // 5. Biaya produksi per kg & Harga impas (Break-even price) per kg
    final double productionCostPerKg = totalHarvestKg > 0
        ? (totalExpenses / totalHarvestKg)
        : 0.0;
    final double breakEvenPricePerKg = productionCostPerKg;

    // 6. Produktivitas (kg/ha) = Total hasil panen (kg) / Luas lahan (ha)
    final double areaHa = plot?.areaInHectares ?? 0.0;
    final double productivityKgPerHa = areaHa > 0
        ? (totalHarvestKg / areaHa)
        : 0.0;
    final double productivityTonsPerHa = areaHa > 0
        ? (totalHarvestTons / areaHa)
        : 0.0;

    // 7. Total penggunaan Benih (kg) dan Pupuk (kg)
    double totalSeedKg = 0.0;
    double totalFertilizerKg = 0.0;
    for (final inp in cycleInputs) {
      if (inp.inputType.toLowerCase() == 'benih') {
        totalSeedKg += inp.quantityInKg;
      } else if (inp.inputType.toLowerCase() == 'pupuk') {
        totalFertilizerKg += inp.quantityInKg;
      }
    }

    return CycleFinancialSummary(
      cycle: cycle,
      plot: plot,
      initialCapital: cycle.initialCapital,
      operationalExpenses: operationalExpenses,
      totalExpenses: totalExpenses,
      totalHarvestTons: totalHarvestTons,
      totalHarvestKg: totalHarvestKg,
      averageSellingPricePerKg: avgSellingPrice,
      totalRevenue: totalRevenue,
      netProfitOrLoss: netProfitOrLoss,
      financialStatus: status,
      profitPercentage: profitPercentage,
      productionCostPerKg: productionCostPerKg,
      breakEvenPricePerKg: breakEvenPricePerKg,
      productivityKgPerHa: productivityKgPerHa,
      productivityTonsPerHa: productivityTonsPerHa,
      totalSeedKg: totalSeedKg,
      totalFertilizerKg: totalFertilizerKg,
      expensesByCategory: byCategory,
    );
  }

  /// Ringkasan agregat seluruh lahan & musim tanam untuk Beranda
  double get totalManagedAreaHectares {
    double sum = 0.0;
    for (final p in plots) {
      sum += p.areaInHectares;
    }
    return sum;
  }

  double get totalActiveCyclesExpenses {
    final activeIds = activeCycles.map((c) => c.id).toSet();
    double sum = 0.0;
    for (final cid in activeIds) {
      sum += calculateCycleSummary(cid).totalExpenses;
    }
    return sum;
  }

  double get totalAllCyclesExpenses {
    double sum = 0.0;
    for (final c in cycles) {
      sum += calculateCycleSummary(c.id).totalExpenses;
    }
    return sum;
  }

  double get totalRecordedRevenue {
    double sum = 0.0;
    for (final h in harvests) {
      sum += h.grossRevenue;
    }
    return sum;
  }

  double get totalOverallProfitOrLoss =>
      totalRecordedRevenue - totalAllCyclesExpenses;

  double get totalTargetYieldActiveCyclesTons {
    double sum = 0.0;
    for (final c in activeCycles) {
      if (c.targetYieldTons != null) {
        sum += c.targetYieldTons!;
      }
    }
    return sum;
  }

  /// Rata-rata historis produktivitas (ton/ha) dari musim tanam yang sudah dipanen
  double? get historicalAverageYieldTonsPerHa {
    double totalKg = 0.0;
    double totalHa = 0.0;
    for (final c in cycles) {
      final summary = calculateCycleSummary(c.id);
      if (summary.totalHarvestKg > 0 &&
          summary.plot != null &&
          summary.plot!.areaInHectares > 0) {
        totalKg += summary.totalHarvestKg;
        totalHa += summary.plot!.areaInHectares;
      }
    }
    if (totalHa <= 0) return null;
    return (totalKg / 1000.0) / totalHa;
  }

  // ==================== DATA CONTOH BERLABEL JELAS ([DATA CONTOH]) ====================
  /// Aturan 6: Jangan membuat data contoh seolah-olah merupakan data nyata pengguna.
  /// Data demo hanya dimuat jika pengguna memilih tombol "Muat Data Contoh [DEMO]" dan seluruhnya diberi label [DATA CONTOH].
  bool get hasDemoData =>
      plots.any((p) => p.isDemo) || cycles.any((c) => c.isDemo);

  Future<void> clearDemoDataForCurrentUser() async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    _plots.removeWhere((e) => e.userId == uid && e.isDemo);
    _cycles.removeWhere((e) => e.userId == uid && e.isDemo);
    _cropInputs.removeWhere((e) => e.userId == uid && e.isDemo);
    _expenses.removeWhere((e) => e.userId == uid && e.isDemo);
    _inventory.removeWhere((e) => e.userId == uid && e.isDemo);
    _inventoryTransactions.removeWhere((e) => e.userId == uid && e.isDemo);
    _activities.removeWhere((e) => e.userId == uid && e.isDemo);
    _harvests.removeWhere((e) => e.userId == uid && e.isDemo);
    await _persistAllToDisk();
    notifyListeners();
  }

  String _stripDemoTag(String text) {
    return text
        .replaceAll('[DATA CONTOH] ', '')
        .replaceAll('[DATA CONTOH]', '')
        .trim();
  }

  Future<void> _sanitizeLegacyDemoPrefix() async {
    bool changed = false;
    for (int i = 0; i < _plots.length; i++) {
      if (_plots[i].name.contains('[DATA CONTOH]')) {
        _plots[i] = _plots[i].copyWith(name: _stripDemoTag(_plots[i].name));
        changed = true;
      }
    }
    for (int i = 0; i < _cycles.length; i++) {
      if (_cycles[i].name.contains('[DATA CONTOH]')) {
        _cycles[i] = _cycles[i].copyWith(name: _stripDemoTag(_cycles[i].name));
        changed = true;
      }
    }
    for (int i = 0; i < _cropInputs.length; i++) {
      if (_cropInputs[i].productName.contains('[DATA CONTOH]')) {
        final old = _cropInputs[i];
        _cropInputs[i] = CropInputModel(
          id: old.id,
          userId: old.userId,
          plotId: old.plotId,
          cycleId: old.cycleId,
          productName: _stripDemoTag(old.productName),
          inputType: old.inputType,
          quantity: old.quantity,
          unit: old.unit,
          unitPrice: old.unitPrice,
          date: old.date,
          isFromPaidStock: old.isFromPaidStock,
          linkedExpenseId: old.linkedExpenseId,
          linkedInventoryId: old.linkedInventoryId,
          notes: old.notes,
          isDemo: old.isDemo,
          createdAt: old.createdAt,
          updatedAt: old.updatedAt,
        );
        changed = true;
      }
    }
    for (int i = 0; i < _expenses.length; i++) {
      if (_expenses[i].name.contains('[DATA CONTOH]')) {
        final old = _expenses[i];
        _expenses[i] = ExpenseModel(
          id: old.id,
          userId: old.userId,
          plotId: old.plotId,
          cycleId: old.cycleId,
          name: _stripDemoTag(old.name),
          category: old.category,
          date: old.date,
          quantity: old.quantity,
          unit: old.unit,
          unitPrice: old.unitPrice,
          notes: old.notes,
          receiptPhotoPath: old.receiptPhotoPath,
          sourceReferenceId: old.sourceReferenceId,
          isDemo: old.isDemo,
          createdAt: old.createdAt,
          updatedAt: old.updatedAt,
        );
        changed = true;
      }
    }
    for (int i = 0; i < _activities.length; i++) {
      if (_activities[i].name.contains('[DATA CONTOH]')) {
        _activities[i] = _activities[i].copyWith(
          name: _stripDemoTag(_activities[i].name),
        );
        changed = true;
      }
    }
    for (int i = 0; i < _inventory.length; i++) {
      if (_inventory[i].itemName.contains('[DATA CONTOH]')) {
        _inventory[i] = _inventory[i].copyWith(
          itemName: _stripDemoTag(_inventory[i].itemName),
        );
        changed = true;
      }
    }
    if (changed) {
      await _persistAllToDisk();
    }
  }

  Future<void> seedLabeledDemoDataForCurrentUser() async {
    if (_currentUser == null) return;
    await clearDemoDataForCurrentUser();
    final now = DateTime.now();

    // Lahan 1 (Data Contoh)
    final plot1 = await addPlot(
      name: 'Lahan Blok Timur A',
      location: 'Desa Sumberagung, Kec. Plosoklaten, Kediri',
      area: 1.5,
      areaUnit: 'hektare',
      notes: 'Simulasi lahan jagung irigasi teknis (1,5 Ha).',
      isDemo: true,
    );

    // Lahan 2 (Data Contoh)
    final plot2 = await addPlot(
      name: 'Lahan Blok Barat B',
      location: 'Desa Kawedusan, Kediri',
      area: 8000,
      areaUnit: 'm²',
      notes: 'Lahan 8.000 m² (0,8 Ha).',
      isDemo: true,
    );

    // Musim Tanam 1 (Sudah Selesai - untuk perbandingan historis)
    final startCycle1 = now.subtract(const Duration(days: 150));
    final estHarvest1 = DateTime(
      startCycle1.year,
      startCycle1.month + 4,
      startCycle1.day,
    );
    final actualHarvest1 = startCycle1.add(const Duration(days: 116));

    final cycle1 = await addPlantingCycle(
      plotId: plot1.id,
      name: 'Musim Tanam I - Kemarau Awal',
      cornVariety: 'BISI 18',
      plantingDate: startCycle1,
      estimatedHarvestDate: estHarvest1,
      actualHarvestDate: actualHarvest1,
      status: 'Selesai',
      targetYieldTons: 10.5,
      initialCapital: 15000000,
      notes: 'Musim tanam yang telah selesai dipanen.',
      isDemo: true,
    );

    await addCropInput(
      plotId: plot1.id,
      cycleId: cycle1.id,
      productName: 'Benih Jagung Hibrida BISI 18',
      inputType: 'Benih',
      quantity: 25,
      unit: 'kg',
      unitPrice: 95000,
      date: startCycle1,
      recordAsExpense: true,
      notes: 'Penggunaan benih',
      isDemo: true,
    );

    await addCropInput(
      plotId: plot1.id,
      cycleId: cycle1.id,
      productName: 'Pupuk Urea',
      inputType: 'Pupuk',
      quantity: 450,
      unit: 'kg',
      unitPrice: 6500,
      date: startCycle1.add(const Duration(days: 15)),
      recordAsExpense: true,
      notes: 'Pemupukan tahap 1',
      isDemo: true,
    );

    await addCropInput(
      plotId: plot1.id,
      cycleId: cycle1.id,
      productName: 'Pupuk NPK Phonska',
      inputType: 'Pupuk',
      quantity: 400,
      unit: 'kg',
      unitPrice: 7200,
      date: startCycle1.add(const Duration(days: 40)),
      recordAsExpense: true,
      notes: 'Pemupukan tahap 2',
      isDemo: true,
    );

    await addExpense(
      plotId: plot1.id,
      cycleId: cycle1.id,
      name: 'Sewa Traktor Bajak Lahan',
      category: 'Sewa alat',
      date: startCycle1.subtract(const Duration(days: 4)),
      quantity: 1.5,
      unit: 'hektare',
      unitPrice: 1200000,
      notes: 'Biaya pengolahan tanah',
      isDemo: true,
    );

    await addExpense(
      plotId: plot1.id,
      cycleId: cycle1.id,
      name: 'Upah Tenaga Tanam & Panen',
      category: 'Tenaga kerja',
      date: actualHarvest1,
      quantity: 1,
      unit: 'paket',
      unitPrice: 3600000,
      notes: 'Biaya tenaga kerja',
      isDemo: true,
    );

    await addHarvestRecord(
      plotId: plot1.id,
      cycleId: cycle1.id,
      harvestDate: actualHarvest1,
      yieldTons: 10.8,
      sellingPricePerKg: 4800,
      markCycleCompleted: true,
      notes: 'Hasil panen kering pipil',
      isDemo: true,
    );

    // Musim Tanam 2 (Sedang Berlangsung - Aktif)
    final startCycle2 = now.subtract(const Duration(days: 35));
    final estHarvest2 = DateTime(
      startCycle2.year,
      startCycle2.month + 4,
      startCycle2.day,
    );

    final cycle2 = await addPlantingCycle(
      plotId: plot1.id,
      name: 'Musim Tanam II - Berlangsung',
      cornVariety: 'NK 212',
      plantingDate: startCycle2,
      estimatedHarvestDate: estHarvest2,
      status: 'Berlangsung',
      targetYieldTons: 11.2,
      initialCapital: 16000000,
      notes: 'Musim tanam aktif.',
      isDemo: true,
    );

    await addCropInput(
      plotId: plot1.id,
      cycleId: cycle2.id,
      productName: 'Benih NK 212',
      inputType: 'Benih',
      quantity: 26,
      unit: 'kg',
      unitPrice: 105000,
      date: startCycle2,
      recordAsExpense: true,
      notes: 'Penanaman benih',
      isDemo: true,
    );

    await addCropInput(
      plotId: plot1.id,
      cycleId: cycle2.id,
      productName: 'Pupuk Urea Tahap 1',
      inputType: 'Pupuk',
      quantity: 300,
      unit: 'kg',
      unitPrice: 6800,
      date: startCycle2.add(const Duration(days: 14)),
      recordAsExpense: true,
      notes: 'Pemupukan pertama',
      isDemo: true,
    );

    await addActivity(
      plotId: plot1.id,
      cycleId: cycle2.id,
      name: 'Pemupukan Pertama Susulan',
      activityType: 'Pemupukan Pertama',
      date: startCycle2.add(const Duration(days: 14)),
      cost: 450000,
      isCompleted: true,
      recordCostAsExpense: true,
      notes: 'Kegiatan pemupukan pertama selesai',
      isDemo: true,
    );

    await addActivity(
      plotId: plot1.id,
      cycleId: cycle2.id,
      name: 'Pemupukan Kedua (NPK + Urea)',
      activityType: 'Pemupukan Kedua',
      date: now.add(const Duration(days: 4)),
      cost: 500000,
      isCompleted: false,
      recordCostAsExpense: false,
      notes: 'Jadwal pemupukan kedua 4 hari lagi',
      isDemo: true,
    );

    // Musim Tanam 3 pada Lahan 2 (Untuk perbandingan antar lahan)
    final startCycle3 = now.subtract(const Duration(days: 140));
    final estHarvest3 = DateTime(
      startCycle3.year,
      startCycle3.month + 4,
      startCycle3.day,
    );
    final actualHarvest3 = startCycle3.add(const Duration(days: 118));

    final cycle3 = await addPlantingCycle(
      plotId: plot2.id,
      name: 'Musim Tanam Blok B',
      cornVariety: 'Pioneer P27',
      plantingDate: startCycle3,
      estimatedHarvestDate: estHarvest3,
      actualHarvestDate: actualHarvest3,
      status: 'Selesai',
      targetYieldTons: 5.5,
      initialCapital: 8000000,
      notes: 'Musim tanam pada lahan kedua (0,8 Ha).',
      isDemo: true,
    );

    await addCropInput(
      plotId: plot2.id,
      cycleId: cycle3.id,
      productName: 'Benih Pioneer P27',
      inputType: 'Benih',
      quantity: 14,
      unit: 'kg',
      unitPrice: 98000,
      date: startCycle3,
      recordAsExpense: true,
      isDemo: true,
    );

    await addCropInput(
      plotId: plot2.id,
      cycleId: cycle3.id,
      productName: 'Pupuk NPK & Urea Blok B',
      inputType: 'Pupuk',
      quantity: 420,
      unit: 'kg',
      unitPrice: 7000,
      date: startCycle3.add(const Duration(days: 20)),
      recordAsExpense: true,
      isDemo: true,
    );

    await addExpense(
      plotId: plot2.id,
      cycleId: cycle3.id,
      name: 'Biaya Operasional & Tenaga Blok B',
      category: 'Tenaga kerja',
      date: actualHarvest3,
      quantity: 1,
      unit: 'paket',
      unitPrice: 2400000,
      isDemo: true,
    );

    await addHarvestRecord(
      plotId: plot2.id,
      cycleId: cycle3.id,
      harvestDate: actualHarvest3,
      yieldTons: 5.6,
      sellingPricePerKg: 4750,
      markCycleCompleted: true,
      notes: 'Panen Lahan Blok B (5,6 ton pada 0,8 Ha)',
      isDemo: true,
    );

    // Contoh Stok Gudang
    await addInventoryItem(
      itemName: 'Pupuk NPK Phonska Gudang',
      itemType: 'Pupuk',
      initialStock: 150,
      unit: 'kg',
      purchasePrice: 7200,
      minimumStockAlert: 200,
      transactionDate: now.subtract(const Duration(days: 10)),
      isDemo: true,
    );

    await addInventoryItem(
      itemName: 'Benih Jagung NK 212 Cadangan',
      itemType: 'Benih',
      initialStock: 15,
      unit: 'kg',
      purchasePrice: 105000,
      minimumStockAlert: 5,
      transactionDate: now.subtract(const Duration(days: 10)),
      isDemo: true,
    );
  }

  // ==================== PERSISTENSI LOKAL & FIRESTORE ====================

  Future<void> _loadAllFromDisk() async {
    _farms = _decodeList('table_farms', FarmModel.fromMap);
    _plots = _decodeList('table_plots', PlotModel.fromMap);
    _cycles = _decodeList('table_planting_cycles', PlantingCycleModel.fromMap);
    _cropInputs = _decodeList('table_crop_inputs', CropInputModel.fromMap);
    _expenses = _decodeList('table_expenses', ExpenseModel.fromMap);
    _inventory = _decodeList('table_inventory', InventoryItemModel.fromMap);
    _inventoryTransactions = _decodeList(
      'table_inventory_transactions',
      InventoryTransactionModel.fromMap,
    );
    _activities = _decodeList('table_activities', ActivityModel.fromMap);
    _harvests = _decodeList(
      'table_harvest_records',
      HarvestRecordModel.fromMap,
    );
    _predictions = _decodeList('table_predictions', PredictionModel.fromMap);
    _notifications = _decodeList(
      'table_notifications',
      AppNotificationModel.fromMap,
    );
  }

  List<T> _decodeList<T>(String key, T Function(Map<String, dynamic>) fromMap) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistAllToDisk() async {
    await _prefs?.setString(
      'table_farms',
      jsonEncode(_farms.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_plots',
      jsonEncode(_plots.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_planting_cycles',
      jsonEncode(_cycles.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_crop_inputs',
      jsonEncode(_cropInputs.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_expenses',
      jsonEncode(_expenses.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_inventory',
      jsonEncode(_inventory.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_inventory_transactions',
      jsonEncode(_inventoryTransactions.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_activities',
      jsonEncode(_activities.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_harvest_records',
      jsonEncode(_harvests.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_predictions',
      jsonEncode(_predictions.map((e) => e.toMap()).toList()),
    );
    await _prefs?.setString(
      'table_notifications',
      jsonEncode(_notifications.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> _syncToFirestoreIfAvailable(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (!_firebaseReady) return;
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }
}
