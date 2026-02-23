import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/train_model.dart';
import '../models/coach_model.dart';
import '../providers/coach_provider.dart';
import '../providers/user_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../services/bluetooth_service.dart';

/// Screen displaying coaches for a specific train with crowd status.
/// Bluetooth scan runs automatically in the background — no BT icon shown.
class CoachListScreen extends StatefulWidget {
  final Train train;

  const CoachListScreen({super.key, required this.train});

  @override
  State<CoachListScreen> createState() => _CoachListScreenState();
}

class _CoachListScreenState extends State<CoachListScreen> {
  /// Per-coach BT scan results, keyed by coach.id
  final Map<int, BluetoothScanResult> _btResults = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      coachProvider.loadCoaches(widget.train.id).then((_) {
        // Auto-scan all coaches silently after they load
        _autoScanAll(coachProvider.coaches);
      });
    });
  }

  /// Runs a BT scan for each coach silently in the background.
  Future<void> _autoScanAll(List<Coach> coaches) async {
    for (final coach in coaches) {
      if (!mounted) return;
      await _runScanForCoach(coach);
    }
  }

  /// Runs a single scan and stores result for [coach].
  Future<void> _runScanForCoach(Coach coach) async {
    final service = BluetoothCrowdService();
    try {
      final result = await service.scanForCrowd();
      if (mounted) {
        setState(() => _btResults[coach.id] = result);
      }
    } catch (_) {
      // Silently ignore — UI falls back to last reported status
    }
  }

  Future<void> _handleRefresh() async {
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    await coachProvider.loadCoaches(widget.train.id);
    // Re-scan after refresh
    _autoScanAll(coachProvider.coaches);
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
                      : ListView.builder(
                          itemCount: coachProvider.coaches.length,
                          itemBuilder: (context, index) {
                            final coach = coachProvider.coaches[index];
                            return _CoachCard(
                              coach: coach,
                              btResult: _btResults[coach.id],
                              onUpdatePressed: () =>
                                  _showCrowdReportDialog(coach),
                              onRescanPressed: () async {
                                // Rescan just this coach
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Re-scanning…'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                await _runScanForCoach(coach);
                              },
                              formatTimestamp: _formatTimestamp,
                            );
                          },
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
  final VoidCallback onUpdatePressed;
  final VoidCallback onRescanPressed;
  final String Function(DateTime?) formatTimestamp;

  const _CoachCard({
    required this.coach,
    required this.btResult,
    required this.onUpdatePressed,
    required this.onRescanPressed,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final hasBt = btResult != null;

    // Determine the "display" crowd level:
    // BT result takes precedence over stored server status if it's fresher.
    final displayLevel = hasBt ? btResult!.crowdLevel : (coach.latestStatus ?? 'Unknown');
    final displayColor = _crowdColor(displayLevel);
    final displayColorLight = displayColor.withOpacity(0.12);

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
                Text(
                  coach.coachName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: displayColorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: displayColor, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: displayColor),
                      const SizedBox(width: 6),
                      Text(
                        displayLevel,
                        style: TextStyle(
                          color: displayColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Tiny re-scan icon (no label — invisible to casual users)
                Tooltip(
                  message: 'Re-scan nearby devices',
                  child: InkWell(
                    onTap: onRescanPressed,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.refresh,
                          size: 18, color: Colors.grey[400]),
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

            // ── Manual update button only ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpdatePressed,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Report Crowd Status'),
              ),
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
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
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
