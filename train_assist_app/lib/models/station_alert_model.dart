class StationAlert {
  final String id;
  final int trainId;
  final String trainName;
  final String destinationStation;
  final DateTime scheduledArrival;
  final bool elderlyMode;
  bool isTriggered;

  StationAlert({
    required this.id,
    required this.trainId,
    required this.trainName,
    required this.destinationStation,
    required this.scheduledArrival,
    this.elderlyMode = false,
    this.isTriggered = false,
  });

  Duration get timeRemaining =>
      scheduledArrival.difference(DateTime.now());

  bool get isExpired => timeRemaining.isNegative;

  String get statusLabel {
    if (isExpired) return 'Completed';
    final mins = timeRemaining.inMinutes;
    if (mins <= 5) return '🔴 ARRIVING NOW';
    if (mins <= 15) return '🟠 Arriving in ${mins}m';
    if (mins <= 30) return '🟡 ${mins} min away';
    return '🟢 ${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainId': trainId,
        'trainName': trainName,
        'destinationStation': destinationStation,
        'scheduledArrival': scheduledArrival.toIso8601String(),
        'elderlyMode': elderlyMode,
        'isTriggered': isTriggered,
      };

  factory StationAlert.fromJson(Map<String, dynamic> j) => StationAlert(
        id: j['id'] as String,
        trainId: j['trainId'] as int,
        trainName: j['trainName'] as String,
        destinationStation: j['destinationStation'] as String,
        scheduledArrival: DateTime.parse(j['scheduledArrival'] as String),
        elderlyMode: j['elderlyMode'] as bool? ?? false,
        isTriggered: j['isTriggered'] as bool? ?? false,
      );
}
