import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/train_model.dart';
import '../models/coach_model.dart';
import '../providers/coach_provider.dart';
import '../providers/user_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../services/bluetooth_service.dart';
import '../services/local_data_service.dart';

/// Screen displaying coaches for a specific train with crowd status.
/// Bluetooth scan runs automatically in the background — no BT icon shown.
class CoachListScreen extends StatefulWidget {
  final Train train;

  const CoachListScreen({super.key, required this.train});

  @override
  State<CoachListScreen> createState() => _CoachListScreenState();
}

class _CoachListScreenState extends State<CoachListScreen> {
  /// Per-coach BT scan results, keyed by coach.id.
  /// Only populated when user explicitly taps "Scan MY Coach" on a specific coach.
  final Map<int, BluetoothScanResult> _btResults = {};
  final Map<int, bool> _scanningCoach = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CoachProvider>(context, listen: false)
          .loadCoaches(widget.train.id);
    });
  }

  /// Runs a BT scan for ONE specific coach (the one the user says they're in).
  /// BLE scans physical surroundings — it's only meaningful for the coach
  /// you are currently standing inside.
  Future<void> _runScanForCoach(Coach coach) async {
    if (_scanningCoach[coach.id] == true) return;
    setState(() => _scanningCoach[coach.id] = true);
    final service = BluetoothCrowdService();
    try {
      final result = await service.scanForCrowd();
      if (mounted) {
        setState(() {
          _btResults[coach.id] = result;
          _scanningCoach[coach.id] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _scanningCoach[coach.id] = false);
    }
  }

  Future<void> _handleRefresh() async {
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    await coachProvider.loadCoaches(widget.train.id);
  }

  void _showCrowdReportDialog(Coach coach) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Pre-fill with BT-detected level if available
    String? selectedStatus = _btResults[coach.id]?.crowdLevel;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update ${coach.coachName} Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show density hint if BT data available
              if (_btResults[coach.id] != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sensors, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Auto-detected: ${_btResults[coach.id]!.summaryLine}',
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text('Select crowd level:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              _CrowdLevelButton(
                label: 'Low',
                color: Colors.green,
                isSelected: selectedStatus == 'Low',
                onTap: () => setState(() => selectedStatus = 'Low'),
              ),
              const SizedBox(height: 8),
              _CrowdLevelButton(
                label: 'Medium',
                color: Colors.orange,
                isSelected: selectedStatus == 'Medium',
                onTap: () => setState(() => selectedStatus = 'Medium'),
              ),
              const SizedBox(height: 8),
              _CrowdLevelButton(
                label: 'High',
                color: Colors.red,
                isSelected: selectedStatus == 'High',
                onTap: () => setState(() => selectedStatus = 'High'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _submitCrowdReport(
                        coach.id,
                        userProvider.userName!,
                        selectedStatus!,
                      );
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCrowdReport(
      int coachId, String reporterName, String status) async {
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Submitting report...'),
          ]),
          duration: Duration(seconds: 2),
        ),
      );
    }
    final success =
        await coachProvider.submitCrowdReport(coachId, reporterName, status);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Report submitted!'
              : 'Failed — please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Never';
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final coachProvider = Provider.of<CoachProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.train.trainName)),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // ── Train header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.train.source,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(widget.train.destination,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(widget.train.timing),
                      const SizedBox(width: 16),
                      if (widget.train.platform != null) ...[
                        Icon(Icons.location_city,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(widget.train.platform!),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Coach list ──────────────────────────────────────────────────
            Expanded(
              child: coachProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : coachProvider.coaches.isEmpty
                      ? const Center(
                          child: Text('No coaches found for this train'))
                      : ListView(
                          children: [
                            // ── Train heatmap ───────────────────────────────
                            _TrainHeatmap(coaches: coachProvider.coaches),
                            // ── Best coach banner ───────────────────────────
                            _BestCoachBanner(coaches: coachProvider.coaches),
                            // ── Individual coach cards ──────────────────────
                            ...coachProvider.coaches.map((coach) => _CoachCard(
                              coach: coach,
                              btResult: _btResults[coach.id],
                              isScanning: _scanningCoach[coach.id] == true,
                              onUpdatePressed: () =>
                                  _showCrowdReportDialog(coach),
                              onScanMyCoachPressed: () async {
                                await _runScanForCoach(coach);
                              },
                              formatTimestamp: _formatTimestamp,
                              cleanlinessScore: LocalDataService().getCleanlinessScore(coach.id),
                              onCleanlinessChanged: (score) {
                                LocalDataService().updateCleanliness(coach.id, score);
                                setState(() {});
                              },
                            )),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach card with inline density visualisation
// ─────────────────────────────────────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  final Coach coach;
  final BluetoothScanResult? btResult;
  final bool isScanning;
  final VoidCallback onUpdatePressed;
  final VoidCallback onScanMyCoachPressed;
  final String Function(DateTime?) formatTimestamp;
  final int cleanlinessScore;
  final void Function(int) onCleanlinessChanged;

  const _CoachCard({
    required this.coach,
    required this.btResult,
    required this.isScanning,
    required this.onUpdatePressed,
    required this.onScanMyCoachPressed,
    required this.formatTimestamp,
    required this.cleanlinessScore,
    required this.onCleanlinessChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasBt = btResult != null;

    // Determine the "display" crowd level:
    // BT result takes precedence over stored server status if it's fresher.
    final displayLevel = hasBt ? btResult!.crowdLevel : (coach.latestStatus ?? 'Unknown');
    final displayColor = _crowdColor(displayLevel);
    final displayColorLight = displayColor.withValues(alpha: 0.12);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: name + status chip ───────────────────────────────────
            Row(
              children: [
                Flexible(
                  child: Text(
                    coach.coachName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: displayColorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: displayColor, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: displayColor),
                      const SizedBox(width: 5),
                      Text(
                        displayLevel,
                        style: TextStyle(
                          color: displayColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // "I'm in this coach" scan button
                if (isScanning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Tooltip(
                    message: "I'm in this coach — scan crowd",
                    child: InkWell(
                      onTap: onScanMyCoachPressed,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.sensors,
                            size: 22,
                            color: btResult != null
                                ? Colors.blue[600]
                                : Colors.grey[400]),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Occupancy density bar (BT data) ─────────────────────────────
            if (hasBt) ...[
              _DensityBar(result: btResult!),
              const SizedBox(height: 10),
            ],

            // ── Last manual report info ─────────────────────────────────────
            if (coach.lastReportedAt != null)
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(formatTimestamp(coach.lastReportedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            if (coach.lastReporterName != null)
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('Reported by ${coach.lastReporterName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              )
            else if (!hasBt)
              Text('No reports yet',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic)),

            const SizedBox(height: 12),

            // ── Action buttons ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isScanning ? null : onScanMyCoachPressed,
                    icon: Icon(isScanning ? Icons.hourglass_top : Icons.sensors,
                        size: 16),
                    label: Text(isScanning ? 'Scanning…' : "Scan MY Coach"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUpdatePressed,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Report'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Cleanliness rating ───────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.cleaning_services, size: 15, color: Colors.brown[400]),
                const SizedBox(width: 5),
                Text('Clean:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(width: 6),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => onCleanlinessChanged(star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Icon(
                            star <= cleanlinessScore
                                ? Icons.star
                                : Icons.star_border,
                            color: star <= cleanlinessScore
                                ? Colors.amber
                                : Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 5),
                Text('$cleanlinessScore/5',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _crowdColor(String level) {
    switch (level) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Train heatmap — horizontal visual of all coaches colour-coded by crowd level
// ─────────────────────────────────────────────────────────────────────────────

class _TrainHeatmap extends StatelessWidget {
  final List<Coach> coaches;
  const _TrainHeatmap({required this.coaches});

  Color _levelColor(String? level) {
    switch (level) {
      case 'Low':    return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High':   return Colors.red;
      default:       return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.train, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Train Crowd Heatmap',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Coach blocks — horizontally scrollable for 25+ coaches
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Engine icon
                Container(
                  width: 30,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.directions_railway,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 3),
                ...coaches.map((coach) {
                  final color = _levelColor(coach.latestStatus);
                  final short = coach.coachName.split(' - ').first;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 42,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      border: Border.all(color: color, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(short,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color)),
                        const SizedBox(height: 2),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legendDot(Colors.green,  'Low'),
              const SizedBox(width: 10),
              _legendDot(Colors.orange, 'Medium'),
              const SizedBox(width: 10),
              _legendDot(Colors.red,    'High'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Best Coach Recommendation Banner
// ─────────────────────────────────────────────────────────────────────────────

class _BestCoachBanner extends StatelessWidget {
  final List<Coach> coaches;
  const _BestCoachBanner({required this.coaches});

  Coach? _bestCoach() {
    const priority = {'Low': 0, 'Medium': 1, 'High': 2};
    final sorted = List<Coach>.from(coaches)
      ..sort((a, b) => (priority[a.latestStatus] ?? 3)
          .compareTo(priority[b.latestStatus] ?? 3));
    return sorted.isNotEmpty ? sorted.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final best = _bestCoach();
    if (best == null) return const SizedBox.shrink();

    final isLow = best.latestStatus == 'Low';
    final color = isLow ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.recommend, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best coach to board',
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600)),
                Text(
                  best.coachName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color),
            ),
            child: Text(
              best.latestStatus ?? 'Unknown',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Density bar widget — shows estimated occupancy visually
// ─────────────────────────────────────────────────────────────────────────────

class _DensityBar extends StatelessWidget {
  final BluetoothScanResult result;

  const _DensityBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = (result.occupancyPercent / 100.0).clamp(0.0, 1.0);
    final barColor = result.crowdLevel == 'Low'
        ? Colors.green
        : result.crowdLevel == 'Medium'
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sensors, size: 14, color: Colors.blue[400]),
            const SizedBox(width: 4),
            Text(
              result.isRealScan
                  ? '${result.insideCoachCount} devices in range'
                  : '~${result.rawDeviceCount} devices detected',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Spacer(),
            Text(
              'Est. ${result.estimatedOccupancy} / $kDefaultCoachCapacity seats',
              style: TextStyle(
                  fontSize: 12,
                  color: barColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          result.isRealScan
              ? 'Live BT scan  •  scan radius ≈${kBleEffectiveRangeMetres.toInt()} m  •  '
                '${(scanCoverageFraction * 100).toStringAsFixed(0)}% coach covered'
              : 'Proximity estimate  •  based on coach geometry',
          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crowd level selection button (reused in dialog)
// ─────────────────────────────────────────────────────────────────────────────

class _CrowdLevelButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CrowdLevelButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
