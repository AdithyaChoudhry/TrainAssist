import 'package:flutter/foundation.dart';
import '../models/train_model.dart';
import '../services/api_service.dart';

/// Provider for managing train search and train list state
class TrainProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Train> _trains = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Train> get trains => _trains;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Search for trains by source and/or destination
  Future<void> searchTrains(String? source, String? destination) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _trains = await _apiService.searchTrains(
        source: source,
        destination: destination,
      );
      
      if (_trains.isEmpty && (source != null || destination != null)) {
        _errorMessage = 'No trains found matching your search';
      }
    } catch (e) {
      _errorMessage = 'Failed to search trains: $e';
      _trains = [];
      print('Error in searchTrains: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Clear current search results
  void clearResults() {
    _trains = [];
    _errorMessage = null;
    notifyListeners();
  }
}
