/// Train model representing a train with its details
class Train {
  final int id;
  final String trainName;
  final String source;
  final String destination;
  final String timing;
  final String? platform;

  Train({
    required this.id,
    required this.trainName,
    required this.source,
    required this.destination,
    required this.timing,
    this.platform,
  });

  /// Create a Train object from JSON
  factory Train.fromJson(Map<String, dynamic> json) {
    return Train(
      id: json['id'] as int,
      trainName: json['trainName'] as String,
      source: json['source'] as String,
      destination: json['destination'] as String,
      timing: json['timing'] as String,
      platform: json['platform'] as String?,
    );
  }

  /// Convert Train object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainName': trainName,
      'source': source,
      'destination': destination,
      'timing': timing,
      'platform': platform,
    };
  }

  @override
  String toString() {
    return 'Train(id: $id, trainName: $trainName, source: $source, destination: $destination, timing: $timing, platform: $platform)';
  }
}
