import 'package:flutter/foundation.dart';
import '../models/sos_report_model.dart';
import '../services/api_service.dart';

class SOSProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<SOSReport> _recentReports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SOSReport> get recentReports => _recentReports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Submit an SOS report
  Future<bool> submitSOS({
    required String reporterName,
    int? trainId,
    int? coachId,
    double? latitude,
    double? longitude,
    String? message,
  }) async {
    try {
      print('Submitting SOS report for $reporterName');
      
      final success = await _apiService.reportSOS(
        reporterName: reporterName,
        trainId: trainId,
        coachId: coachId,
        latitude: latitude,
        longitude: longitude,
        message: message,
      );

      if (success) {
        print('SOS report submitted successfully');
        // Reload recent reports after successful submission
        await loadRecentReports();
      }

      return success;
    } catch (e) {
      print('Error submitting SOS: $e');
      _errorMessage = 'Failed to submit SOS report';
      notifyListeners();
      return false;
    }
  }

  /// Load recent SOS reports
  Future<void> loadRecentReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Loading recent SOS reports');
      _recentReports = await _apiService.getRecentSOS();
      _errorMessage = null;
    } catch (e) {
      print('Error loading SOS reports: $e');
      _errorMessage = 'Failed to load SOS reports';
      _recentReports = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all reports
  void clearReports() {
    _recentReports = [];
    _errorMessage = null;
    notifyListeners();
  }
}
