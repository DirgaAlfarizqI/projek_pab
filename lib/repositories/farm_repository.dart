import '../models/app_models.dart';
import '../services/app_data_service.dart';

/// Repository terstruktur yang menghubungkan UI/Provider dengan layanan database (Firestore & Local Persistence)
class FarmRepository {
  final AppDataService _dataService = AppDataService();

  AppDataService get rawService => _dataService;

  UserModel? get currentUser => _dataService.currentUser;
  List<PlotModel> get plots => _dataService.plots;
  List<PlantingCycleModel> get cycles => _dataService.cycles;
  List<PlantingCycleModel> get activeCycles => _dataService.activeCycles;
  List<CropInputModel> get cropInputs => _dataService.cropInputs;
  List<ExpenseModel> get expenses => _dataService.expenses;
  List<InventoryItemModel> get inventory => _dataService.inventory;
  List<InventoryTransactionModel> get inventoryTransactions =>
      _dataService.inventoryTransactions;
  List<ActivityModel> get activities => _dataService.activities;
  List<HarvestRecordModel> get harvests => _dataService.harvests;
  List<PredictionModel> get predictions => _dataService.predictions;

  CycleFinancialSummary getCycleSummary(String cycleId) =>
      _dataService.calculateCycleSummary(cycleId);
}
