import 'package:flutter/foundation.dart';

import '../repositories/farm_repository.dart';
import '../services/app_data_service.dart';

/// State Management Provider untuk TaniJagung
class FarmProvider extends ChangeNotifier {
  final FarmRepository repository = FarmRepository();

  FarmProvider() {
    AppDataService().addListener(_onServiceUpdated);
  }

  void _onServiceUpdated() {
    notifyListeners();
  }

  @override
  void dispose() {
    AppDataService().removeListener(_onServiceUpdated);
    super.dispose();
  }
}
