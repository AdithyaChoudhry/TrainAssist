/// Crowd report model representing a crowd status report for a coach
class CrowdReport {
  final int id;
  final int coachId;
  final String reporterName;
  final String status;
  final DateTime timestamp;

  CrowdReport({
    required this.id,
    required this.coachId,
    required this.reporterName,
    required this.status,
    required this.timestamp,
  });

  /// Create a CrowdReport object from JSON
  factory CrowdReport.fromJson(Map<String, dynamic> json) {
    return CrowdReport(
      id: json['id'] as int,
      coachId: json['coachId'] as int,
      reporterName: json['reporterName'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert CrowdReport object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coachId': coachId,
      'reporterName': reporterName,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CrowdReport(id: $id, coachId: $coachId, reporterName: $reporterName, status: $status, timestamp: $timestamp)';
  }
}
