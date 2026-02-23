import 'package:flutter/foundation.dart';
import '../models/train_model.dart';
import '../services/local_data_service.dart';

/// Provider for managing train search — uses hardcoded local data, no backend.
class TrainProvider extends ChangeNotifier {
  final LocalDataService _local = LocalDataService();

  List<Train> _trains = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Train> get trains => _trains;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Search for trains by source and/or destination (local, instant).
  Future<void> searchTrains(String? source, String? destination) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulate a brief loading tick so the spinner is visible.
    await Future.delayed(const Duration(milliseconds: 200));

    _trains = _local.searchTrains(source: source, destination: destination);

    if (_trains.isEmpty && (source != null || destination != null)) {
      _errorMessage = 'No trains found matching your search';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear current search results.
  void clearResults() {
    _trains = [];
    _errorMessage = null;
    notifyListeners();
  }
}
