enum LostFoundStatus { lost, found, matched }

class LostFoundItem {
  final String id;
  final String reporterName;
  final String trainName;
  final String coachNumber;
  final String description;
  final LostFoundStatus status;
  final DateTime reportedAt;
  String? matchedWithId;

  LostFoundItem({
    required this.id,
    required this.reporterName,
    required this.trainName,
    required this.coachNumber,
    required this.description,
    required this.status,
    required this.reportedAt,
    this.matchedWithId,
  });

  String get statusLabel {
    switch (status) {
      case LostFoundStatus.lost:
        return 'Lost';
      case LostFoundStatus.found:
        return 'Found';
      case LostFoundStatus.matched:
        return 'Matched ✅';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporterName': reporterName,
        'trainName': trainName,
        'coachNumber': coachNumber,
        'description': description,
        'status': status.index,
        'reportedAt': reportedAt.toIso8601String(),
        'matchedWithId': matchedWithId,
      };

  factory LostFoundItem.fromJson(Map<String, dynamic> j) => LostFoundItem(
        id: j['id'] as String,
        reporterName: j['reporterName'] as String,
        trainName: j['trainName'] as String,
        coachNumber: j['coachNumber'] as String,
        description: j['description'] as String,
        status: LostFoundStatus.values[j['status'] as int],
        reportedAt: DateTime.parse(j['reportedAt'] as String),
        matchedWithId: j['matchedWithId'] as String?,
      );
}
