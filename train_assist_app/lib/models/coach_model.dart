import 'package:flutter/material.dart';

/// Coach model representing a train coach with crowd status
class Coach {
  final int id;
  final int trainId;
  final String coachName;
  final String? latestStatus;
  final DateTime? lastReportedAt;
  final String? lastReporterName;

  Coach({
    required this.id,
    required this.trainId,
    required this.coachName,
    this.latestStatus,
    this.lastReportedAt,
    this.lastReporterName,
  });

  /// Create a Coach object from JSON
  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] as int,
      trainId: json['trainId'] as int,
      coachName: json['coachName'] as String,
      latestStatus: json['latestStatus'] as String?,
      lastReportedAt: json['lastReportedAt'] != null
          ? DateTime.parse(json['lastReportedAt'] as String)
          : null,
      lastReporterName: json['lastReporterName'] as String?,
    );
  }

  /// Get color based on crowd status
  /// Green for "Low", Orange/Yellow for "Medium", Red for "High"
  Color get statusColor {
    if (latestStatus == null) {
      return Colors.grey; // No status reported
    }

    switch (latestStatus!.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get a lighter shade of the status color for backgrounds
  Color get statusColorLight {
    if (latestStatus == null) {
      return Colors.grey.shade200;
    }

    switch (latestStatus!.toLowerCase()) {
      case 'low':
        return Colors.green.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'high':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  /// Convert Coach object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainId': trainId,
      'coachName': coachName,
      'latestStatus': latestStatus,
      'lastReportedAt': lastReportedAt?.toIso8601String(),
      'lastReporterName': lastReporterName,
    };
  }

  @override
  String toString() {
    return 'Coach(id: $id, trainId: $trainId, coachName: $coachName, latestStatus: $latestStatus, lastReportedAt: $lastReportedAt)';
  }
}
