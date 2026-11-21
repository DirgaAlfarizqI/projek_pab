// Entitas database terstruktur untuk TaniJagung
import '../core/constants/app_constants.dart';

// Mengakomodasi:
// - users
// - farms
// - plots
// - planting_cycles
// - crop_inputs
// - expenses
// - inventory
// - inventory_transactions
// - activities
// - harvest_records
// - predictions
// - notifications

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String farmBusinessName;
  final String preferredAreaUnit; // 'hektare' atau 'm²'
  final String preferredWeightUnit; // 'ton' atau 'kg'
  final bool notificationsEnabled;
  final String currencyCode; // 'IDR'
  final String? profilePhotoPath;
  final double initialCapital; // Modal Awal Usaha Tani di Dashboard Beranda
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.farmBusinessName = 'Usaha Tani Jagung Mandiri',
    this.preferredAreaUnit = 'hektare',
    this.preferredWeightUnit = 'ton',
    this.notificationsEnabled = true,
    this.currencyCode = 'IDR',
    this.profilePhotoPath,
    this.initialCapital = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? farmBusinessName,
    String? preferredAreaUnit,
    String? preferredWeightUnit,
    bool? notificationsEnabled,
    String? currencyCode,
    String? profilePhotoPath,
    bool clearProfilePhoto = false,
    double? initialCapital,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      farmBusinessName: farmBusinessName ?? this.farmBusinessName,
      preferredAreaUnit: preferredAreaUnit ?? this.preferredAreaUnit,
      preferredWeightUnit: preferredWeightUnit ?? this.preferredWeightUnit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      currencyCode: currencyCode ?? this.currencyCode,
      profilePhotoPath: clearProfilePhoto
          ? null
          : (profilePhotoPath ?? this.profilePhotoPath),
      initialCapital: initialCapital ?? this.initialCapital,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'farmBusinessName': farmBusinessName,
    'preferredAreaUnit': preferredAreaUnit,
    'preferredWeightUnit': preferredWeightUnit,
    'notificationsEnabled': notificationsEnabled,
    'currencyCode': currencyCode,
    'profilePhotoPath': profilePhotoPath,
    'initialCapital': initialCapital,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    farmBusinessName: map['farmBusinessName'] ?? 'Usaha Tani Jagung Mandiri',
    preferredAreaUnit: map['preferredAreaUnit'] ?? 'hektare',
    preferredWeightUnit: map['preferredWeightUnit'] ?? 'ton',
    notificationsEnabled: map['notificationsEnabled'] ?? true,
    currencyCode: map['currencyCode'] ?? 'IDR',
    profilePhotoPath: map['profilePhotoPath'],
    initialCapital: (map['initialCapital'] as num?)?.toDouble() ?? 0.0,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// Entitas `farms` (Unit Usaha Pertanian / Induk Lahan)
class FarmModel {
  final String id;
  final String userId;
  final String name;
  final String region;
  final String description;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.region,
    this.description = '',
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'region': region,
    'description': description,
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory FarmModel.fromMap(Map<String, dynamic> map) => FarmModel(
    id: map['id'] ?? '',
    userId: map['user_id'] ?? '',
    name: map['name'] ?? '',
    region: map['region'] ?? '',
    description: map['description'] ?? '',
    isDemo: map['is_demo'] ?? false,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// Entitas `plots` (Lahan / Petak Lahan yang dikelola pengguna)
class PlotModel {
  final String id;
  final String userId;
  final String farmId;
  final String name;
  final String location;
  final double area;
  final String areaUnit; // 'hektare' atau 'm²'
  final String notes;
  final String? photoPath;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlotModel({
    required this.id,
    required this.userId,
    required this.farmId,
    required this.name,
    required this.location,
    required this.area,
    required this.areaUnit,
    this.notes = '',
    this.photoPath,
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Luas lahan terkonversi ke hektare (ha)
  double get areaInHectares {
    if (areaUnit.toLowerCase() == 'm²' || areaUnit.toLowerCase() == 'm2') {
      return area / 10000.0;
    }
    return area;
  }

  /// Luas lahan terkonversi ke m²
  double get areaInSquareMeters {
    if (areaUnit.toLowerCase() == 'hektare' || areaUnit.toLowerCase() == 'ha') {
      return area * 10000.0;
    }
    return area;
  }

  PlotModel copyWith({
    String? name,
    String? location,
    double? area,
    String? areaUnit,
    String? notes,
    String? photoPath,
    bool? isDemo,
    DateTime? updatedAt,
  }) {
    return PlotModel(
      id: id,
      userId: userId,
      farmId: farmId,
      name: name ?? this.name,
      location: location ?? this.location,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'farm_id': farmId,
    'name': name,
    'location': location,
    'area': area,
    'area_unit': areaUnit,
    'notes': notes,
    'photo_path': photoPath,
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory PlotModel.fromMap(Map<String, dynamic> map) => PlotModel(
    id: map['id'] ?? '',
    userId: map['user_id'] ?? '',
    farmId: map['farm_id'] ?? '',
    name: map['name'] ?? '',
    location: map['location'] ?? '',
    area: (map['area'] as num?)?.toDouble() ?? 0.0,
    areaUnit: map['area_unit'] ?? 'hektare',
    notes: map['notes'] ?? '',
    photoPath: map['photo_path'],
    isDemo: map['is_demo'] ?? false,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// Entitas `planting_cycles` (Musim Tanam)
/// Status: 'Persiapan', 'Berlangsung', 'Menunggu Panen', 'Selesai'
class PlantingCycleModel {
  final String id;
  final String userId;
  final String plotId;
  final String name;
  final String cornVariety;
  final DateTime plantingDate;
  final DateTime estimatedHarvestDate;
  final DateTime? actualHarvestDate;
  final String status; // Persiapan, Berlangsung, Menunggu Panen, Selesai
  final double? targetYieldTons; // Target/estimasi manual pengguna (opsional)
  final double
  initialCapital; // Modal awal musim tanam (diinput manual pengguna)
  final String notes;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantingCycleModel({
    required this.id,
    required this.userId,
    required this.plotId,
    required this.name,
    required this.cornVariety,
    required this.plantingDate,
    required this.estimatedHarvestDate,
    this.actualHarvestDate,
    required this.status,
    this.targetYieldTons,
    this.initialCapital = 0.0,
    this.notes = '',
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status != 'Selesai';

  /// Tanggal default 4 bulan setelah tanggal mulai penanaman
  DateTime get fourMonthsFromStartDate {
    return DateTime(
      plantingDate.year,
      plantingDate.month + 4,
      plantingDate.day,
    );
  }

  /// Umur musim tanam dalam hari berdasarkan tanggal mulai
  int get ageInDays {
    final endReference = actualHarvestDate ?? DateTime.now();
    final diff = endReference.difference(plantingDate).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Sisa hari menuju perkiraan tanggal panen
  int get daysRemainingToEstimatedHarvest {
    if (actualHarvestDate != null || status == 'Selesai') return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final est = DateTime(
      estimatedHarvestDate.year,
      estimatedHarvestDate.month,
      estimatedHarvestDate.day,
    );
    return est.difference(today).inDays;
  }

  /// Lama musim tanam aktual setelah tanggal panen diisi (dalam hari)
  int? get actualDurationInDays {
    if (actualHarvestDate == null) return null;
    final diff = actualHarvestDate!.difference(plantingDate).inDays;
    return diff < 0 ? 0 : diff;
  }

  PlantingCycleModel copyWith({
    String? plotId,
    String? name,
    String? cornVariety,
    DateTime? plantingDate,
    DateTime? estimatedHarvestDate,
    DateTime? actualHarvestDate,
    bool clearActualHarvestDate = false,
    String? status,
    double? targetYieldTons,
    double? initialCapital,
    String? notes,
    bool? isDemo,
    DateTime? updatedAt,
  }) {
    return PlantingCycleModel(
      id: id,
      userId: userId,
      plotId: plotId ?? this.plotId,
      name: name ?? this.name,
      cornVariety: cornVariety ?? this.cornVariety,
      plantingDate: plantingDate ?? this.plantingDate,
      estimatedHarvestDate: estimatedHarvestDate ?? this.estimatedHarvestDate,
      actualHarvestDate: clearActualHarvestDate
          ? null
          : (actualHarvestDate ?? this.actualHarvestDate),
      status: status ?? this.status,
      targetYieldTons: targetYieldTons ?? this.targetYieldTons,
      initialCapital: initialCapital ?? this.initialCapital,
      notes: notes ?? this.notes,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'plot_id': plotId,
    'name': name,
    'corn_variety': cornVariety,
    'planting_date': plantingDate.toIso8601String(),
    'estimated_harvest_date': estimatedHarvestDate.toIso8601String(),
    'actual_harvest_date': actualHarvestDate?.toIso8601String(),
    'status': status,
    'target_yield_tons': targetYieldTons,
    'initial_capital': initialCapital,
    'notes': notes,
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory PlantingCycleModel.fromMap(Map<String, dynamic> map) =>
      PlantingCycleModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        plotId: map['plot_id'] ?? '',
        name: map['name'] ?? '',
        cornVariety: map['corn_variety'] ?? '',
        plantingDate:
            DateTime.tryParse(map['planting_date'] ?? '') ?? DateTime.now(),
        estimatedHarvestDate:
            DateTime.tryParse(map['estimated_harvest_date'] ?? '') ??
            DateTime.now().add(const Duration(days: 120)),
        actualHarvestDate: map['actual_harvest_date'] != null
            ? DateTime.tryParse(map['actual_harvest_date'])
            : null,
        status: map['status'] ?? 'Berlangsung',
        targetYieldTons: (map['target_yield_tons'] as num?)?.toDouble(),
        initialCapital: (map['initial_capital'] as num?)?.toDouble() ?? 0.0,
        notes: map['notes'] ?? '',
        isDemo: map['is_demo'] ?? false,
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      );
}

/// Entitas `crop_inputs` (Pencatatan Penggunaan Benih, Pupuk, dan Bahan Pertanian Lainnya)
class CropInputModel {
  final String id;
  final String userId;
  final String plotId;
  final String cycleId;
  final String productName;
  final String inputType; // 'Benih', 'Pupuk', 'Bahan Pertanian Lainnya'
  final double quantity;
  final String unit; // 'kg', 'gram', 'liter', 'unit'
  final double unitPrice;
  final DateTime date;
  final bool isFromPaidStock; // Jika true, sudah dibeli di stok/pengeluaran sehingga tidak dihitung ganda sebagai biaya baru
  final String?
  linkedExpenseId; // ID pengeluaran terkait jika dicatat sebagai biaya baru
  final String? linkedInventoryId;
  final String notes;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  CropInputModel({
    required this.id,
    required this.userId,
    required this.plotId,
    required this.cycleId,
    required this.productName,
    required this.inputType,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.date,
    this.isFromPaidStock = false,
    this.linkedExpenseId,
    this.linkedInventoryId,
    this.notes = '',
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Subtotal otomatis: Jumlah × Harga per satuan
  double get subtotal => quantity * unitPrice;

  /// Konversi jumlah ke kilogram (kg) untuk agregasi benih/pupuk
  double get quantityInKg {
    final u = unit.toLowerCase();
    if (u == 'gram') return quantity / 1000.0;
    return quantity;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'plot_id': plotId,
    'cycle_id': cycleId,
    'product_name': productName,
    'input_type': inputType,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'subtotal': subtotal,
    'date': date.toIso8601String(),
    'is_from_paid_stock': isFromPaidStock,
    'linked_expense_id': linkedExpenseId,
    'linked_inventory_id': linkedInventoryId,
    'notes': notes,
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CropInputModel.fromMap(Map<String, dynamic> map) => CropInputModel(
    id: map['id'] ?? '',
    userId: map['user_id'] ?? '',
    plotId: map['plot_id'] ?? '',
    cycleId: map['cycle_id'] ?? '',
    productName: map['product_name'] ?? '',
    inputType: map['input_type'] ?? 'Pupuk',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
    unit: map['unit'] ?? 'kg',
    unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    isFromPaidStock: map['is_from_paid_stock'] ?? false,
    linkedExpenseId: map['linked_expense_id'],
    linkedInventoryId: map['linked_inventory_id'],
    notes: map['notes'] ?? '',
    isDemo: map['is_demo'] ?? false,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// Entitas `expenses` (Seluruh Pengeluaran Usaha Tani)
/// Kategori: 'Benih', 'Pupuk', 'Pestisida', 'Tenaga kerja', 'Sewa alat atau mesin', 'Biaya lainnya'
class ExpenseModel {
  final String id;
  final String userId;
  final String plotId;
  final String cycleId;
  final String name;
  final String category;
  final DateTime date;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String notes;
  final String? receiptPhotoPath;
  final String? sourceReferenceId; // Mencegah penghitungan ganda dari crop_input atau activity
  final bool isFromFertilizerStock;
  final String? linkedInventoryId;
  final double stockTakenQuantity;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.plotId,
    required this.cycleId,
    required this.name,
    required String category,
    required this.date,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.notes = '',
    this.receiptPhotoPath,
    this.sourceReferenceId,
    this.isFromFertilizerStock = false,
    this.linkedInventoryId,
    this.stockTakenQuantity = 0.0,
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  }) : category = AppConstants.normalizeExpenseCategory(category);

  double get totalCost => isFromFertilizerStock ? 0.0 : (quantity * unitPrice);

  ExpenseModel copyWith({
    String? plotId,
    String? cycleId,
    String? name,
    String? category,
    DateTime? date,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? notes,
    String? receiptPhotoPath,
    String? sourceReferenceId,
    bool? isFromFertilizerStock,
    String? linkedInventoryId,
    double? stockTakenQuantity,
    bool? isDemo,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id,
      userId: userId,
      plotId: plotId ?? this.plotId,
      cycleId: cycleId ?? this.cycleId,
      name: name ?? this.name,
      category: category != null
          ? AppConstants.normalizeExpenseCategory(category)
          : this.category,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
      receiptPhotoPath: receiptPhotoPath ?? this.receiptPhotoPath,
      sourceReferenceId: sourceReferenceId ?? this.sourceReferenceId,
      isFromFertilizerStock:
          isFromFertilizerStock ?? this.isFromFertilizerStock,
      linkedInventoryId: linkedInventoryId ?? this.linkedInventoryId,
      stockTakenQuantity: stockTakenQuantity ?? this.stockTakenQuantity,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'plot_id': plotId,
    'cycle_id': cycleId,
    'name': name,
    'category': category,
    'date': date.toIso8601String(),
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'total_cost': totalCost,
    'notes': notes,
    'receipt_photo_path': receiptPhotoPath,
    'source_reference_id': sourceReferenceId,
    'is_from_fertilizer_stock': isFromFertilizerStock,
    'linked_inventory_id': linkedInventoryId,
    'stock_taken_quantity': stockTakenQuantity,
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
    id: map['id'] ?? '',
    userId: map['user_id'] ?? '',
    plotId: map['plot_id'] ?? '',
    cycleId: map['cycle_id'] ?? '',
    name: map['name'] ?? '',
    category: AppConstants.normalizeExpenseCategory(
      map['category'] ?? 'Lain-lain',
    ),
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
    unit: map['unit'] ?? 'unit',
    unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
    notes: map['notes'] ?? '',
    receiptPhotoPath: map['receipt_photo_path'],
    sourceReferenceId: map['source_reference_id'],
    isFromFertilizerStock: map['is_from_fertilizer_stock'] ?? false,
    linkedInventoryId: map['linked_inventory_id'],
    stockTakenQuantity:
        (map['stock_taken_quantity'] as num?)?.toDouble() ?? 0.0,
    isDemo: map['is_demo'] ?? false,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// Entitas `inventory` (Stok Benih dan Pupuk)
/// Rumus: Stok akhir = Stok awal + Stok masuk - Stok keluar
class InventoryItemModel {
  final String id;
  final String userId;
  final String itemName;
  final String itemType; // 'Benih', 'Pupuk', 'Pestisida', 'Bahan Lainnya'
  final double initialStock;
  final double stockIn;
  final double stockOut;
  final String unit; // 'kg', 'gram', 'liter', 'unit'
  final double lastPurchasePrice;
  final double minimumStockAlert; // Ditentukan sendiri oleh pengguna
  final DateTime lastTransactionDate;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItemModel({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.itemType,
    required this.initialStock,
    this.stockIn = 0.0,
    this.stockOut = 0.0,
    required this.unit,
    required this.lastPurchasePrice,
    required this.minimumStockAlert,
    required this.lastTransactionDate,
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Rumus wajib: Stok akhir = Stok awal + Stok masuk - Stok keluar
  double get remainingStock {
    final val = initialStock + stockIn - stockOut;
    return val < 0 ? 0.0 : val;
  }

  bool get isOutOfStock => remainingStock <= 0;
  bool get isLowStock => remainingStock <= minimumStockAlert;

  InventoryItemModel copyWith({
    String? itemName,
    String? itemType,
    double? initialStock,
    double? stockIn,
    double? stockOut,
    String? unit,
    double? lastPurchasePrice,
    double? minimumStockAlert,
    DateTime? lastTransactionDate,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id,
      userId: userId,
      itemName: itemName ?? this.itemName,
      itemType: itemType ?? this.itemType,
      initialStock: initialStock ?? this.initialStock,
      stockIn: stockIn ?? this.stockIn,
      stockOut: stockOut ?? this.stockOut,
      unit: unit ?? this.unit,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      minimumStockAlert: minimumStockAlert ?? this.minimumStockAlert,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      isDemo: isDemo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'item_name': itemName,
    'item_type': itemType,
    'initial_stock': initialStock,
    'stock_in': stockIn,
    'stock_out': stockOut,
    'remaining_stock': remainingStock,
    'unit': unit,
    'last_purchase_price': lastPurchasePrice,
    'minimum_stock_alert': minimumStockAlert,
    'last_transaction_date': lastTransactionDate.toIso8601String(),
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory InventoryItemModel.fromMap(
    Map<String, dynamic> map,
  ) => InventoryItemModel(
    id: map['id'] ?? '',
    userId: map['user_id'] ?? '',
    itemName: map['item_name'] ?? '',
    itemType: map['item_type'] ?? 'Pupuk',
    initialStock: (map['initial_stock'] as num?)?.toDouble() ?? 0.0,
    stockIn: (map['stock_in'] as num?)?.toDouble() ?? 0.0,
    stockOut: (map['stock_out'] as num?)?.toDouble() ?? 0.0,
    unit: map['unit'] ?? 'kg',
    lastPurchasePrice: (map['last_purchase_price'] as num?)?.toDouble() ?? 0.0,
    minimumStockAlert: (map['minimum_stock_alert'] as num?)?.toDouble() ?? 0.0,
    lastTransactionDate:
        DateTime.tryParse(map['last_transaction_date'] ?? '') ?? DateTime.now(),
    isDemo: map['is_demo'] ?? false,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// Entitas `inventory_transactions` (Riwayat Transaksi Masuk/Keluar Stok)
class InventoryTransactionModel {
  final String id;
  final String userId;
  final String inventoryId;
  final String itemName;
  final String transactionType; // 'Stok Awal', 'Masuk', 'Keluar'
  final double quantity;
  final String unit;
  final double unitPrice;
  final DateTime date;
  final String? cycleId;
  final String notes;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryTransactionModel({
    required this.id,
    required this.userId,
    required this.inventoryId,
    required this.itemName,
    required this.transactionType,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.date,
    this.cycleId,
    this.notes = '',
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'inventory_id': inventoryId,
    'item_name': itemName,
    'transaction_type': transactionType,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'date': date.toIso8601String(),
    'cycle_id': cycleId,
    'notes': notes,
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory InventoryTransactionModel.fromMap(Map<String, dynamic> map) =>
      InventoryTransactionModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        inventoryId: map['inventory_id'] ?? '',
        itemName: map['item_name'] ?? '',
        transactionType: map['transaction_type'] ?? 'Masuk',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: map['unit'] ?? 'kg',
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        cycleId: map['cycle_id'],
        notes: map['notes'] ?? '',
        isDemo: map['is_demo'] ?? false,
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      );
}

/// Entitas `activities` (Pencatatan Aktivitas & Jadwal Tanggal Pertanian)
/// Jenis aktivitas:
/// - 'Pengolahan Lahan'
/// - 'Mulai Penanaman'
/// - 'Pemupukan Pertama'
/// - 'Pemupukan Berikutnya'
/// - 'Penggunaan Pestisida'
/// - 'Perawatan Lahan'
/// - 'Perkiraan Panen'
/// - 'Panen Aktual'
class ActivityModel {
  final String id;
  final String userId;
  final String plotId;
  final String cycleId;
  final String name;
  final String activityType;
  final DateTime date;
  final double cost;
  final bool isCompleted;
  final String? linkedExpenseId;
  final String notes;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.plotId,
    required this.cycleId,
    required this.name,
    required this.activityType,
    required this.date,
    this.cost = 0.0,
    this.isCompleted = false,
    this.linkedExpenseId,
    this.notes = '',
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final actDay = DateTime(date.year, date.month, date.day);
    return actDay.isBefore(today);
  }

  bool get isUpcoming {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final actDay = DateTime(date.year, date.month, date.day);
    return !actDay.isBefore(today);
  }

  ActivityModel copyWith({
    String? name,
    String? activityType,
    DateTime? date,
    double? cost,
    bool? isCompleted,
    String? linkedExpenseId,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ActivityModel(
      id: id,
      userId: userId,
      plotId: plotId,
      cycleId: cycleId,
      name: name ?? this.name,
      activityType: activityType ?? this.activityType,
      date: date ?? this.date,
      cost: cost ?? this.cost,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedExpenseId: linkedExpenseId ?? this.linkedExpenseId,
      notes: notes ?? this.notes,
      isDemo: isDemo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'plot_id': plotId,
    'cycle_id': cycleId,
    'name': name,
    'activity_type': activityType,
    'date': date.toIso8601String(),
    'cost': cost,
    'is_completed': isCompleted,
    'linked_expense_id': linkedExpenseId,
    'notes': notes,
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ActivityModel.fromMap(Map<String, dynamic> map) => ActivityModel(
    id: map['id'] ?? '',
    userId: map['user_id'] ?? '',
    plotId: map['plot_id'] ?? '',
    cycleId: map['cycle_id'] ?? '',
    name: map['name'] ?? '',
    activityType: map['activity_type'] ?? 'Perawatan Lahan',
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
    isCompleted: map['is_completed'] ?? false,
    linkedExpenseId: map['linked_expense_id'],
    notes: map['notes'] ?? '',
    isDemo: map['is_demo'] ?? false,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// Entitas `harvest_records` (Input Hasil Panen Aktual)
/// Rumus:
/// 1 ton = 1.000 kg
/// Hasil panen (kg) = Hasil panen (ton) × 1.000
/// Pendapatan kotor = Total hasil panen (kg) × Harga jual per kg
class HarvestRecordModel {
  final String id;
  final String userId;
  final String plotId;
  final String cycleId;
  final DateTime harvestDate;
  final double yieldTons;
  final double sellingPricePerKg;
  final String notes;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  HarvestRecordModel({
    required this.id,
    required this.userId,
    required this.plotId,
    required this.cycleId,
    required this.harvestDate,
    required this.yieldTons,
    required this.sellingPricePerKg,
    this.notes = '',
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Hasil panen (kg) = Hasil panen (ton) × 1.000
  double get yieldKg => yieldTons * 1000.0;

  /// Pendapatan kotor = Total hasil panen (kg) × Harga jual per kg
  double get grossRevenue => yieldKg * sellingPricePerKg;

  HarvestRecordModel copyWith({
    DateTime? harvestDate,
    double? yieldTons,
    double? sellingPricePerKg,
    String? notes,
    DateTime? updatedAt,
  }) {
    return HarvestRecordModel(
      id: id,
      userId: userId,
      plotId: plotId,
      cycleId: cycleId,
      harvestDate: harvestDate ?? this.harvestDate,
      yieldTons: yieldTons ?? this.yieldTons,
      sellingPricePerKg: sellingPricePerKg ?? this.sellingPricePerKg,
      notes: notes ?? this.notes,
      isDemo: isDemo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'plot_id': plotId,
    'cycle_id': cycleId,
    'harvest_date': harvestDate.toIso8601String(),
    'yield_tons': yieldTons,
    'yield_kg': yieldKg,
    'selling_price_per_kg': sellingPricePerKg,
    'gross_revenue': grossRevenue,
    'notes': notes,
    'is_demo': isDemo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory HarvestRecordModel.fromMap(
    Map<String, dynamic> map,
  ) => HarvestRecordModel(
    id: map['id'] ?? '',
    userId: map['user_id'] ?? '',
    plotId: map['plot_id'] ?? '',
    cycleId: map['cycle_id'] ?? '',
    harvestDate: DateTime.tryParse(map['harvest_date'] ?? '') ?? DateTime.now(),
    yieldTons: (map['yield_tons'] as num?)?.toDouble() ?? 0.0,
    sellingPricePerKg: (map['selling_price_per_kg'] as num?)?.toDouble() ?? 0.0,
    notes: map['notes'] ?? '',
    isDemo: map['is_demo'] ?? false,
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
  );
}

/// Entitas `notifications` (Pengingat Tanggal & Peringatan Stok)
class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'jadwal_akan_datang', 'jadwal_terlambat', 'stok_menipis'
  final String? relatedId;
  final DateTime date;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.date,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'message': message,
    'type': type,
    'related_id': relatedId,
    'date': date.toIso8601String(),
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) =>
      AppNotificationModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        type: map['type'] ?? 'jadwal_akan_datang',
        relatedId: map['related_id'],
        date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        isRead: map['is_read'] ?? false,
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      );
}

/// Entitas `scheduled_reminders` (Pengingat Jadwal Buatan Pengguna untuk Penyiraman, Pemupukan, dll.)
class ScheduledReminderModel {
  final String id;
  final String userId;
  final String
  activityType; // Penyiraman, Pemupukan, Penyemprotan, Perawatan Lahan, Lainnya
  final String? plotId;
  final DateTime scheduledDateTime;
  final String repeatType; // Sekali, Harian, Mingguan, Interval Hari
  final int intervalDays;
  final String notes;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduledReminderModel({
    required this.id,
    required this.userId,
    required this.activityType,
    this.plotId,
    required this.scheduledDateTime,
    this.repeatType = 'Sekali',
    this.intervalDays = 1,
    this.notes = '',
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Menghitung waktu pengingat mendatang berikutnya berdasarkan tanggal, jam, dan pola pengulangan
  DateTime get nextOccurrence {
    final now = DateTime.now();
    if (scheduledDateTime.isAfter(now) || repeatType == 'Sekali') {
      return scheduledDateTime;
    }

    int stepDays = 1;
    if (repeatType == 'Harian') {
      stepDays = 1;
    } else if (repeatType == 'Mingguan') {
      stepDays = 7;
    } else if (repeatType == 'Interval Hari') {
      stepDays = intervalDays < 1 ? 1 : intervalDays;
    }

    DateTime candidate = scheduledDateTime;
    while (!candidate.isAfter(now)) {
      candidate = candidate.add(Duration(days: stepDays));
    }
    return candidate;
  }

  ScheduledReminderModel copyWith({
    String? activityType,
    String? plotId,
    bool clearPlotId = false,
    DateTime? scheduledDateTime,
    String? repeatType,
    int? intervalDays,
    String? notes,
    bool? isEnabled,
    DateTime? updatedAt,
  }) {
    return ScheduledReminderModel(
      id: id,
      userId: userId,
      activityType: activityType ?? this.activityType,
      plotId: clearPlotId ? null : (plotId ?? this.plotId),
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      repeatType: repeatType ?? this.repeatType,
      intervalDays: intervalDays ?? this.intervalDays,
      notes: notes ?? this.notes,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'activity_type': activityType,
    'plot_id': plotId,
    'scheduled_date_time': scheduledDateTime.toIso8601String(),
    'repeat_type': repeatType,
    'interval_days': intervalDays,
    'notes': notes,
    'is_enabled': isEnabled,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ScheduledReminderModel.fromMap(Map<String, dynamic> map) =>
      ScheduledReminderModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        activityType: map['activity_type'] ?? 'Penyiraman',
        plotId: map['plot_id'],
        scheduledDateTime:
            DateTime.tryParse(map['scheduled_date_time'] ?? '') ??
            DateTime.now().add(const Duration(hours: 1)),
        repeatType: map['repeat_type'] ?? 'Sekali',
        intervalDays: (map['interval_days'] as num?)?.toInt() ?? 1,
        notes: map['notes'] ?? '',
        isEnabled: map['is_enabled'] ?? true,
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      );
}
