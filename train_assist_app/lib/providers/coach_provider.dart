import 'package:flutter/foundation.dart';
import '../models/coach_model.dart';
import '../services/local_data_service.dart';

/// Provider for managing coach list and crowd report submissions (local data).
class CoachProvider extends ChangeNotifier {
  final LocalDataService _local = LocalDataService();

  List<Coach> _coaches = [];
  bool _isLoading = false;
  int? _currentTrainId;

  List<Coach> get coaches => _coaches;
  bool get isLoading => _isLoading;
  int? get currentTrainId => _currentTrainId;

  /// Load coaches for a specific train from local data.
  Future<void> loadCoaches(int trainId) async {
    _isLoading = true;
    _currentTrainId = trainId;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 150));
    _coaches = _local.getCoachesForTrain(trainId);

    _isLoading = false;
    notifyListeners();
  }

  /// Submit a crowd report — updates in-memory status and reloads coaches.
  Future<bool> submitCrowdReport(
    int coachId,
    String reporterName,
    String status,
  ) async {
    try {
      _local.updateStatus(coachId, status);
      if (_currentTrainId != null) {
        await loadCoaches(_currentTrainId!);
      }
      return true;
    } catch (e) {
      debugPrint('Error submitting crowd report: $e');
      return false;
    }
  }

  /// Clear current coaches list.
  void clearCoaches() {
    _coaches = [];
    _currentTrainId = null;
    notifyListeners();
  }
}
