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

  // ── 5 coach composition templates (displayName, [morning, day, eve]) ────────

  /// Template 0 — Premium Express (Rajdhani, Shatabdi, Vande Bharat, Deccan Queen)
  static const List<(String, List<String>)> _tplPremium = [
    ('GS-1 - General',     ['High',   'High',   'High'  ]),
    ('GS-2 - General',     ['High',   'High',   'High'  ]),
    ('CC-1 - Chair Car',   ['Medium', 'Medium', 'High'  ]),
    ('CC-2 - Chair Car',   ['Medium', 'Medium', 'High'  ]),
    ('CC-3 - Chair Car',   ['Medium', 'Low',    'Medium']),
    ('CC-4 - Chair Car',   ['Low',    'Low',    'Medium']),
    ('EC-1 - Exec Chair',  ['Low',    'Low',    'Medium']),
    ('EC-2 - Exec Chair',  ['Low',    'Low',    'Low'   ]),
    ('B1 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B2 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B3 - AC 3 Tier',     ['Low',    'Low',    'Medium']),
    ('B4 - AC 3 Tier',     ['Low',    'Low',    'Low'   ]),
    ('B5 - AC 3 Tier',     ['Medium', 'Medium', 'High'  ]),
    ('A1 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('A2 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('A3 - AC 2 Tier',     ['Low',    'Low',    'Medium']),
    ('HA1 - First AC',     ['Low',    'Low',    'Low'   ]),
    ('HA2 - First AC',     ['Low',    'Low',    'Low'   ]),
    ('D1 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('D2 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('PC - Pantry Car',    ['Medium', 'Low',    'Medium']),
    ('SLR1 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('SLR2 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('GEN1 - General',     ['High',   'High',   'High'  ]),
    ('GEN2 - General',     ['High',   'High',   'High'  ]),
  ];

  /// Template 1 — Classic Mail (Howrah Mail, Golden Temple, Punjab Mail, GT Express)
  static const List<(String, List<String>)> _tplMail = [
    ('GS-1 - General',     ['High',   'High',   'High'  ]),
    ('GS-2 - General',     ['High',   'High',   'High'  ]),
    ('GS-3 - General',     ['High',   'Medium', 'High'  ]),
    ('GS-4 - General',     ['High',   'Medium', 'High'  ]),
    ('S1 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S2 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S3 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S4 - Sleeper',       ['Medium', 'Medium', 'High'  ]),
    ('S5 - Sleeper',       ['Medium', 'Low',    'Medium']),
    ('S6 - Sleeper',       ['Medium', 'Low',    'High'  ]),
    ('S7 - Sleeper',       ['Medium', 'Low',    'Medium']),
    ('S8 - Sleeper',       ['Low',    'Low',    'Medium']),
    ('B1 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B2 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B3 - AC 3 Tier',     ['Low',    'Low',    'Medium']),
    ('B4 - AC 3 Tier',     ['Low',    'Low',    'Low'   ]),
    ('A1 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('A2 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('H1 - First AC',      ['Low',    'Low',    'Low'   ]),
    ('H2 - First AC',      ['Low',    'Low',    'Low'   ]),
    ('D1 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('D2 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('SLR1 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('SLR2 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('PC - Pantry Car',    ['Medium', 'Low',    'Medium']),
  ];

  /// Template 2 — Long Distance (Duronto, Kerala Express, Coromandel, Gitanjali)
  static const List<(String, List<String>)> _tplLong = [
    ('GS-1 - General',     ['High',   'High',   'High'  ]),
    ('GS-2 - General',     ['High',   'High',   'High'  ]),
    ('S1 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S2 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S3 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S4 - Sleeper',       ['Medium', 'Medium', 'High'  ]),
    ('S5 - Sleeper',       ['Medium', 'Low',    'Medium']),
    ('S6 - Sleeper',       ['Medium', 'Low',    'High'  ]),
    ('S7 - Sleeper',       ['Low',    'Low',    'Medium']),
    ('B1 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B2 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B3 - AC 3 Tier',     ['Low',    'Low',    'Medium']),
    ('B4 - AC 3 Tier',     ['Low',    'Low',    'Low'   ]),
    ('B5 - AC 3 Tier',     ['Medium', 'Medium', 'High'  ]),
    ('B6 - AC 3 Tier',     ['Low',    'Low',    'Medium']),
    ('A1 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('A2 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('A3 - AC 2 Tier',     ['Low',    'Low',    'Medium']),
    ('H1 - First AC',      ['Low',    'Low',    'Low'   ]),
    ('H2 - First AC',      ['Low',    'Low',    'Low'   ]),
    ('D1 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('D2 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('SLR1 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('SLR2 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('PC - Pantry Car',    ['Medium', 'Low',    'Medium']),
  ];

  /// Template 3 — Budget/Garib Rath (Garib Rath, Aug Kranti, Sampark Kranti, Mangala)
  static const List<(String, List<String>)> _tplBudget = [
    ('GS-1 - General',     ['High',   'High',   'High'  ]),
    ('GS-2 - General',     ['High',   'High',   'High'  ]),
    ('S1 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S2 - Sleeper',       ['Medium', 'Medium', 'High'  ]),
    ('S3 - Sleeper',       ['Medium', 'Low',    'Medium']),
    ('S4 - Sleeper',       ['Low',    'Low',    'Medium']),
    ('B1 - AC 3 Tier',     ['High',   'Medium', 'High'  ]),
    ('B2 - AC 3 Tier',     ['High',   'Medium', 'High'  ]),
    ('B3 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B4 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B5 - AC 3 Tier',     ['Low',    'Low',    'Medium']),
    ('B6 - AC 3 Tier',     ['Low',    'Low',    'Low'   ]),
    ('B7 - AC 3 Tier',     ['Medium', 'Medium', 'High'  ]),
    ('B8 - AC 3 Tier',     ['Low',    'Low',    'Medium']),
    ('A1 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('A2 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('D1 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('D2 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('SLR1 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('SLR2 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('PC - Pantry Car',    ['Medium', 'Low',    'Medium']),
    ('GEN1 - General',     ['High',   'High',   'High'  ]),
    ('GEN2 - General',     ['High',   'High',   'High'  ]),
    ('GEN3 - General',     ['High',   'Medium', 'High'  ]),
    ('GEN4 - General',     ['High',   'Medium', 'High'  ]),
  ];

  /// Template 4 — Regional South (Chennai Express, Brindavan, Navjeevan, Konkan Kanya)
  static const List<(String, List<String>)> _tplRegional = [
    ('GS-1 - General',     ['High',   'High',   'High'  ]),
    ('GS-2 - General',     ['High',   'High',   'High'  ]),
    ('GS-3 - General',     ['High',   'Medium', 'High'  ]),
    ('UR-1 - Unreserved',  ['High',   'High',   'High'  ]),
    ('UR-2 - Unreserved',  ['High',   'High',   'High'  ]),
    ('S1 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S2 - Sleeper',       ['High',   'Medium', 'High'  ]),
    ('S3 - Sleeper',       ['Medium', 'Medium', 'High'  ]),
    ('S4 - Sleeper',       ['Medium', 'Low',    'Medium']),
    ('S5 - Sleeper',       ['Medium', 'Low',    'High'  ]),
    ('S6 - Sleeper',       ['Low',    'Low',    'Medium']),
    ('B1 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B2 - AC 3 Tier',     ['Medium', 'Low',    'Medium']),
    ('B3 - AC 3 Tier',     ['Low',    'Low',    'Medium']),
    ('A1 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('A2 - AC 2 Tier',     ['Low',    'Low',    'Low'   ]),
    ('D1 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('D2 - Divyaangjan',   ['Low',    'Low',    'Low'   ]),
    ('SLR1 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('SLR2 - Guard/Lug',   ['High',   'Medium', 'High'  ]),
    ('PC - Pantry Car',    ['Medium', 'Low',    'Medium']),
    ('GEN4 - General',     ['High',   'Medium', 'High'  ]),
    ('GEN5 - General',     ['High',   'Medium', 'High'  ]),
    ('GEN6 - General',     ['High',   'High',   'High'  ]),
    ('GEN7 - General',     ['High',   'High',   'High'  ]),
  ];

  /// trainId → template index
  static const Map<int, int> _trainTpl = {
    1: 0, 2: 0, 5: 0, 9: 0,    // Premium (Rajdhani, Shatabdi, Vande Bharat, Deccan Queen)
    6: 1, 11: 1, 12: 1, 20: 1, // Classic Mail (Howrah, Golden Temple, GT, Punjab)
    3: 2, 7: 2, 14: 2, 15: 2,  // Long Distance (Duronto, Kerala, Coromandel, Gitanjali)
    4: 3, 10: 3, 13: 3, 17: 3, // Budget (Garib Rath, Aug Kranti, Mangala, Sampark)
    8: 4, 16: 4, 18: 4, 19: 4, // Regional South (Chennai, Brindavan, Navjeevan, Konkan)
  };

  static const _levels = ['Low', 'Medium', 'High'];

  /// Apply per-train offset so every train shows unique crowd distribution.
  /// trainId mod patterns create 5 distinct 'popularity profiles':
  ///   0 = very busy (+2 shift), 1 = busy (+1), 2 = normal (0),
  ///   3 = light (-1),            4 = very light (-2)
  static String _variedLevel(String base, int trainId, int slot) {
    final baseIdx = _levels.indexOf(base);
    // Combine trainId and slot position for extra per-coach randomness
    const offsets = [-1, 0, 1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, -1,
                      0, 1, -1, 0, 1]; // 20 entries matching 20 trains
    final trainOffset = offsets[trainId - 1];
    // Also add a small slot-based jitter so coaches of same type differ
    final slotJitter = ((trainId * 3 + slot * 7) % 3) - 1; // -1, 0, or 1
    final combined = (baseIdx + trainOffset + slotJitter).clamp(0, 2);
    return _levels[combined];
  }

  // ── Hardcoded coaches per train ───────────────────────────────────────────
  static Map<int, List<Coach>> _buildCoaches() {
    final hour = DateTime.now().hour;
    final bucket = hour < 9 ? 0 : (hour < 17 ? 1 : 2);

    final templates = [_tplPremium, _tplMail, _tplLong, _tplBudget, _tplRegional];
    final result = <int, List<Coach>>{};
    for (int trainId = 1; trainId <= 20; trainId++) {
      final slots = templates[_trainTpl[trainId] ?? 2];
      result[trainId] = List.generate(slots.length, (slot) {
        final (name, patterns) = slots[slot];
        final base = patterns[bucket];
        // Fixed crowd coaches: always show their base level
        final isFixed = name.startsWith('GS') ||
            name.startsWith('GEN') ||
            name.startsWith('UR') ||
            name.startsWith('SLR') ||
            name.startsWith('PC') ||
            name.startsWith('D');
        final level = isFixed ? base : _variedLevel(base, trainId, slot);
        return Coach(
          id: (trainId - 1) * 25 + slot + 1,
          trainId: trainId,
          coachName: name,
          latestStatus: level,
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
