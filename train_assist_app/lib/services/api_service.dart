import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/train_model.dart';
import '../models/coach_model.dart';
import '../models/sos_report_model.dart';

/// API Service for communicating with the Train Assist backend
class ApiService {
  /// Search for trains by source and/or destination
  /// Returns empty list if no trains found or if an error occurs
  Future<List<Train>> searchTrains({String? source, String? destination}) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (source != null && source.isNotEmpty) {
        queryParams['source'] = source;
      }
      if (destination != null && destination.isNotEmpty) {
        queryParams['destination'] = destination;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.trainsEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Train.fromJson(json)).toList();
      } else {
        print('Error searching trains: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception in searchTrains: $e');
      return [];
    }
  }

  /// Get all coaches for a specific train
  /// Returns empty list if train not found or if an error occurs
  Future<List<Coach>> getCoaches(int trainId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.coachesEndpoint}/$trainId/coaches');

      final response = await http.get(uri).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Coach.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('Train with ID $trainId not found');
        return [];
      } else {
        print('Error getting coaches: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception in getCoaches: $e');
      return [];
    }
  }

  /// Report crowd status for a coach
  /// Returns true on success (201), false on error
  Future<bool> reportCrowd(int coachId, String reporterName, String status) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.crowdReportEndpoint}/$coachId/crowd');

      final body = json.encode({
        'reporterName': reporterName,
        'status': status,
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 201) {
        print('Crowd report submitted successfully for coach $coachId');
        return true;
      } else {
        print('Error reporting crowd: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception in reportCrowd: $e');
      return false;
    }
  }

  /// Submit an SOS emergency report
  /// Returns true on success, false on error
  Future<bool> reportSOS({
    required String reporterName,
    int? trainId,
    int? coachId,
    double? latitude,
    double? longitude,
    String? message,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sosEndpoint}');

      final requestBody = <String, dynamic>{
        'reporterName': reporterName,
      };

      // Add optional fields only if they are not null
      if (trainId != null) requestBody['trainId'] = trainId;
      if (coachId != null) requestBody['coachId'] = coachId;
      if (latitude != null) requestBody['latitude'] = latitude;
      if (longitude != null) requestBody['longitude'] = longitude;
      if (message != null && message.isNotEmpty) requestBody['message'] = message;

      final body = json.encode(requestBody);

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 201) {
        print('SOS report submitted successfully');
        return true;
      } else {
        print('Error submitting SOS report: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception in reportSOS: $e');
      return false;
    }
  }

  /// Get recent SOS reports
  /// Returns empty list if an error occurs
  Future<List<SOSReport>> getRecentSOS() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sosEndpoint}');

      final response = await http.get(uri).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => SOSReport.fromJson(json)).toList();
      } else {
        print('Error getting SOS reports: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception in getRecentSOS: $e');
      return [];
    }
  }

  /// Health check to verify API connectivity
  /// Returns true if API is reachable and healthy
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.healthEndpoint}');

      final response = await http.get(uri).timeout(ApiConfig.requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Exception in checkHealth: $e');
      return false;
    }
  }
}
