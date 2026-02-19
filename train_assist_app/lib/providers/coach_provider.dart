import 'package:flutter/foundation.dart';
import '../models/coach_model.dart';
import '../services/api_service.dart';

/// Provider for managing coach list and crowd report submissions
class CoachProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Coach> _coaches = [];
  bool _isLoading = false;
  int? _currentTrainId;
  
  List<Coach> get coaches => _coaches;
  bool get isLoading => _isLoading;
  int? get currentTrainId => _currentTrainId;
  
  /// Load coaches for a specific train
  Future<void> loadCoaches(int trainId) async {
    _isLoading = true;
    _currentTrainId = trainId;
    notifyListeners();
    
    try {
      _coaches = await _apiService.getCoaches(trainId);
    } catch (e) {
      print('Error loading coaches: $e');
      _coaches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Submit a crowd report for a specific coach
  /// Returns true if successful, false otherwise
  Future<bool> submitCrowdReport(
    int coachId,
    String reporterName,
    String status,
  ) async {
    try {
      final success = await _apiService.reportCrowd(
        coachId,
        reporterName,
        status,
      );
      
      if (success && _currentTrainId != null) {
        // Reload coaches to show updated status
        await loadCoaches(_currentTrainId!);
      }
      
      return success;
    } catch (e) {
      print('Error submitting crowd report: $e');
      return false;
    }
  }
  
  /// Clear current coaches list
  void clearCoaches() {
    _coaches = [];
    _currentTrainId = null;
    notifyListeners();
  }
}
