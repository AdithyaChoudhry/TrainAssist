/// SOS report model representing an emergency SOS alert
class SOSReport {
  final int id;
  final String reporterName;
  final int? trainId;
  final int? coachId;
  final double? latitude;
  final double? longitude;
  final String? message;
  final DateTime timestamp;

  SOSReport({
    required this.id,
    required this.reporterName,
    this.trainId,
    this.coachId,
    this.latitude,
    this.longitude,
    this.message,
    required this.timestamp,
  });

  /// Create a SOSReport object from JSON
  factory SOSReport.fromJson(Map<String, dynamic> json) {
    return SOSReport(
      id: json['id'] as int,
      reporterName: json['reporterName'] as String,
      trainId: json['trainId'] as int?,
      coachId: json['coachId'] as int?,
      latitude: json['latitude'] != null 
          ? (json['latitude'] as num).toDouble() 
          : null,
      longitude: json['longitude'] != null 
          ? (json['longitude'] as num).toDouble() 
          : null,
      message: json['message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert SOSReport object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterName': reporterName,
      'trainId': trainId,
      'coachId': coachId,
      'latitude': latitude,
      'longitude': longitude,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if location data is available
  bool get hasLocation => latitude != null && longitude != null;

  @override
  String toString() {
    return 'SOSReport(id: $id, reporterName: $reporterName, trainId: $trainId, coachId: $coachId, latitude: $latitude, longitude: $longitude, message: $message, timestamp: $timestamp)';
  }
}
