import '../models/train_model.dart';
import '../models/coach_model.dart';

/// All train and coach data is hardcoded here — no backend required.
class LocalDataService {
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;
  LocalDataService._internal();

  // ── Hardcoded trains ──────────────────────────────────────────────────────
  static final List<Train> _allTrains = [
    Train(id: 1,  trainName: 'Rajdhani Express',      source: 'New Delhi',  destination: 'Mumbai Central',    timing: '16:35', platform: '1'),
    Train(id: 2,  trainName: 'Shatabdi Express',       source: 'New Delhi',  destination: 'Bhopal',            timing: '06:00', platform: '3'),
    Train(id: 3,  trainName: 'Duronto Express',        source: 'Mumbai',     destination: 'Kolkata',           timing: '11:05', platform: '2'),
    Train(id: 4,  trainName: 'Garib Rath Express',     source: 'Chennai',    destination: 'New Delhi',         timing: '22:30', platform: '5'),
    Train(id: 5,  trainName: 'Vande Bharat Express',   source: 'Varanasi',   destination: 'New Delhi',         timing: '06:00', platform: '1'),
    Train(id: 6,  trainName: 'Howrah Mail',            source: 'Howrah',     destination: 'Mumbai',            timing: '19:10', platform: '4'),
    Train(id: 7,  trainName: 'Kerala Express',         source: 'Trivandrum', destination: 'New Delhi',         timing: '11:30', platform: '2'),
    Train(id: 8,  trainName: 'Chennai Express',        source: 'Mumbai',     destination: 'Chennai',           timing: '21:00', platform: '6'),
    Train(id: 9,  trainName: 'Deccan Queen',           source: 'Pune',       destination: 'Mumbai',            timing: '07:15', platform: '1'),
    Train(id: 10, trainName: 'August Kranti Rajdhani', source: 'Mumbai',     destination: 'Hazrat Nizamuddin', timing: '17:40', platform: '3'),
    Train(id: 11, trainName: 'Golden Temple Mail',     source: 'Mumbai',     destination: 'Amritsar',          timing: '21:35', platform: '2'),
    Train(id: 12, trainName: 'GT Express',             source: 'Chennai',    destination: 'New Delhi',         timing: '07:00', platform: '4'),
    Train(id: 13, trainName: 'Mangala Lakshadweep',    source: 'Mangaluru',  destination: 'Hazrat Nizamuddin', timing: '07:30', platform: '1'),
    Train(id: 14, trainName: 'Coromandel Express',     source: 'Howrah',     destination: 'Chennai',           timing: '14:50', platform: '5'),
    Train(id: 15, trainName: 'Gitanjali Express',      source: 'Howrah',     destination: 'Mumbai',            timing: '13:55', platform: '3'),
    Train(id: 16, trainName: 'Brindavan Express',      source: 'Chennai',    destination: 'Bengaluru',         timing: '07:40', platform: '2'),
    Train(id: 17, trainName: 'Sampark Kranti',         source: 'Bengaluru',  destination: 'Hazrat Nizamuddin', timing: '20:00', platform: '6'),
    Train(id: 18, trainName: 'Navjeevan Express',      source: 'Ahmedabad',  destination: 'Chennai',           timing: '18:55', platform: '4'),
    Train(id: 19, trainName: 'Konkan Kanya Express',   source: 'Mumbai',     destination: 'Kochi',             timing: '23:00', platform: '1'),
    Train(id: 20, trainName: 'Punjab Mail',            source: 'Mumbai',     destination: 'Firozpur',          timing: '19:05', platform: '3'),
  ];

  // ── 25 coach slots with realistic crowd patterns per time-of-day ──────────
  // Each entry: (displayName, [morning/night, day, evening-rush])
  static const List<(String, List<String>)> _coachSlots = [
    ('GS-1 - General',      ['High',   'High',   'High'  ]),
    ('GS-2 - General',      ['High',   'High',   'High'  ]),
    ('GS-3 - General',      ['High',   'Medium', 'High'  ]),
    ('S1 - Sleeper',        ['High',   'Medium', 'High'  ]),
    ('S2 - Sleeper',        ['High',   'Medium', 'High'  ]),
    ('S3 - Sleeper',        ['High',   'Medium', 'High'  ]),
    ('S4 - Sleeper',        ['Medium', 'Medium', 'High'  ]),
    ('S5 - Sleeper',        ['Medium', 'Low',    'Medium']),
    ('S6 - Sleeper',        ['Medium', 'Low',    'High'  ]),
    ('S7 - Sleeper',        ['Medium', 'Low',    'Medium']),
    ('S8 - Sleeper',        ['Low',    'Low',    'Medium']),
    ('S9 - Sleeper',        ['Low',    'Low',    'Medium']),
    ('B1 - AC 3 Tier',      ['Medium', 'Low',    'Medium']),
    ('B2 - AC 3 Tier',      ['Medium', 'Low',    'Medium']),
    ('B3 - AC 3 Tier',      ['Low',    'Low',    'Medium']),
    ('B4 - AC 3 Tier',      ['Low',    'Low',    'Low'   ]),
    ('B5 - AC 3 Tier',      ['Medium', 'Medium', 'High'  ]),
    ('B6 - AC 3 Tier',      ['Low',    'Low',    'Medium']),
    ('A1 - AC 2 Tier',      ['Low',    'Low',    'Low'   ]),
    ('A2 - AC 2 Tier',      ['Low',    'Low',    'Low'   ]),
    ('A3 - AC 2 Tier',      ['Low',    'Low',    'Medium']),
    ('H1 - First AC',       ['Low',    'Low',    'Low'   ]),
    ('H2 - First AC',       ['Low',    'Low',    'Low'   ]),
    ('D1 - Divyaangjan',    ['Low',    'Low',    'Low'   ]),
    ('D2 - Divyaangjan',    ['Low',    'Low',    'Low'   ]),
  ];  // 25 slots total

  // ── Hardcoded coaches per train ───────────────────────────────────────────
  static Map<int, List<Coach>> _buildCoaches() {
    final hour = DateTime.now().hour;
    final bucket = hour < 9 ? 0 : (hour < 17 ? 1 : 2);

    final result = <int, List<Coach>>{};
    for (int trainId = 1; trainId <= 20; trainId++) {
      result[trainId] = List.generate(_coachSlots.length, (slot) {
        final (name, patterns) = _coachSlots[slot];
        return Coach(
          id: (trainId - 1) * 25 + slot + 1,
          trainId: trainId,
          coachName: name,
          latestStatus: patterns[bucket],
        );
      });
    }
    return result;
  }

  static final Map<int, List<Coach>> _coachesByTrain = _buildCoaches();

  /// Cleanliness scores: coachId → 1-5 (default 3).
  static final Map<int, int> _cleanliness = {};

  // ── Public API ────────────────────────────────────────────────────────────

  /// Return all trains, optionally filtered by source and/or destination.
  List<Train> searchTrains({String? source, String? destination}) {
    var results = List<Train>.from(_allTrains);

    if (source != null && source.isNotEmpty) {
      final q = source.toLowerCase();
      results = results
          .where((t) => t.source.toLowerCase().contains(q))
          .toList();
    }

    if (destination != null && destination.isNotEmpty) {
      final q = destination.toLowerCase();
      results = results
          .where((t) => t.destination.toLowerCase().contains(q))
          .toList();
    }

    return results;
  }

  /// Return coaches for a given train id.
  List<Coach> getCoachesForTrain(int trainId) {
    return List<Coach>.from(_coachesByTrain[trainId] ?? []);
  }

  /// Update crowd status in memory.
  void updateStatus(int coachId, String status) {
    _coachesByTrain.forEach((_, coaches) {
      for (int i = 0; i < coaches.length; i++) {
        if (coaches[i].id == coachId) {
          coaches[i] = Coach(
            id: coaches[i].id,
            trainId: coaches[i].trainId,
            coachName: coaches[i].coachName,
            latestStatus: status,
            lastReportedAt: DateTime.now(),
          );
        }
      }
    });
  }

  /// Get cleanliness score (1-5) for a coach. Defaults to 3.
  int getCleanlinessScore(int coachId) => _cleanliness[coachId] ?? 3;

  /// Update cleanliness score in memory (1-5).
  void updateCleanliness(int coachId, int score) {
    _cleanliness[coachId] = score.clamp(1, 5);
  }
}
