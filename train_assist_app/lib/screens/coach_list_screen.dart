import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/train_model.dart';
import '../models/coach_model.dart';
import '../providers/coach_provider.dart';
import '../providers/user_provider.dart';
import '../providers/bluetooth_provider.dart';

/// Screen displaying coaches for a specific train with crowd status
class CoachListScreen extends StatefulWidget {
  final Train train;

  const CoachListScreen({super.key, required this.train});

  @override
  State<CoachListScreen> createState() => _CoachListScreenState();
}

class _CoachListScreenState extends State<CoachListScreen> {
  @override
  void initState() {
    super.initState();
    // Load coaches when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      coachProvider.loadCoaches(widget.train.id);
    });
  }

  Future<void> _handleRefresh() async {
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    await coachProvider.loadCoaches(widget.train.id);
  }

  void _showCrowdReportDialog(Coach coach) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? selectedStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update ${coach.coachName} Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select crowd level:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              
              // Low Option
              _CrowdLevelButton(
                label: 'Low',
                color: Colors.green,
                isSelected: selectedStatus == 'Low',
                onTap: () => setState(() => selectedStatus = 'Low'),
              ),
              
              const SizedBox(height: 8),
              
              // Medium Option
              _CrowdLevelButton(
                label: 'Medium',
                color: Colors.orange,
                isSelected: selectedStatus == 'Medium',
                onTap: () => setState(() => selectedStatus = 'Medium'),
              ),
              
              const SizedBox(height: 8),
              
              // High Option
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

  /// Runs a Bluetooth scan and pre-fills crowd level in the report dialog
  Future<void> _showBluetoothScanDialog(Coach coach) async {
    final btProvider = Provider.of<BluetoothProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    btProvider.clearResult();

    // Show scanning dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ChangeNotifierProvider.value(
        value: btProvider,
        child: Consumer<BluetoothProvider>(
          builder: (_, bt, __) {
            final done = !bt.isScanning && bt.lastResult != null;
            final result = bt.lastResult;
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    done ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                    color: done ? Colors.blue : Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  const Text('Bluetooth Crowd Scan'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!done) ...[  
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      bt.scanProgress.isEmpty
                          ? 'Initialising scan...'
                          : bt.scanProgress,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Detecting nearby Bluetooth devices…',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (result != null) ...[  
                    Icon(
                      Icons.bluetooth_connected,
                      size: 48,
                      color: result.crowdLevel == 'Low'
                          ? Colors.green
                          : result.crowdLevel == 'Medium'
                              ? Colors.orange
                              : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${result.deviceCount} devices detected nearby',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: result.crowdLevel == 'Low'
                            ? Colors.green[50]
                            : result.crowdLevel == 'Medium'
                                ? Colors.orange[50]
                                : Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: result.crowdLevel == 'Low'
                              ? Colors.green
                              : result.crowdLevel == 'Medium'
                                  ? Colors.orange
                                  : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${result.crowdLevel} Crowd',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: result.crowdLevel == 'Low'
                              ? Colors.green[700]
                              : result.crowdLevel == 'Medium'
                                  ? Colors.orange[700]
                                  : Colors.red[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _crowdLevelDescription(result.deviceCount),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (bt.errorMessage != null)
                    Text(bt.errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                ],
              ),
              actions: done && result != null
                  ? [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _submitCrowdReport(
                            coach.id,
                            userProvider.userName ?? 'User',
                            result.crowdLevel,
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: Text('Submit "${result.crowdLevel}"'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: result.crowdLevel == 'Low'
                              ? Colors.green
                              : result.crowdLevel == 'Medium'
                                  ? Colors.orange
                                  : Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ]
                  : null,
            );
          },
        ),
      ),
    );

    // Start the scan after dialog is shown
    await btProvider.startScan();
  }

  String _crowdLevelDescription(int devices) {
    if (devices <= 3) return '0–3 devices = Low crowd (seats available)';
    if (devices <= 8) return '4–8 devices = Medium crowd (some seats available)';
    return '9+ devices = High crowd (standing room only)';
  }

  Future<void> _submitCrowdReport(
    int coachId,
    String reporterName,
    String status,
  ) async {
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Submitting report...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    final success = await coachProvider.submitCrowdReport(
      coachId,
      reporterName,
      status,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Crowd report submitted successfully!'
                : 'Failed to submit report. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachProvider = Provider.of<CoachProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.train.trainName),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Train Details Header
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
                        child: Text(
                          widget.train.source,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.train.destination,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(widget.train.timing),
                      const SizedBox(width: 16),
                      if (widget.train.platform != null) ...[
                        Icon(Icons.location_city, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(widget.train.platform!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Coaches List
            Expanded(
              child: coachProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : coachProvider.coaches.isEmpty
                      ? const Center(
                          child: Text('No coaches found for this train'),
                        )
                      : ListView.builder(
                          itemCount: coachProvider.coaches.length,
                          itemBuilder: (context, index) {
                            final coach = coachProvider.coaches[index];
                            return _CoachCard(
                              coach: coach,
                              onUpdatePressed: () => _showCrowdReportDialog(coach),
                              onBtScanPressed: () => _showBluetoothScanDialog(coach),
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

/// Widget for displaying a single coach card
class _CoachCard extends StatelessWidget {
  final Coach coach;
  final VoidCallback onUpdatePressed;
  final VoidCallback onBtScanPressed;
  final String Function(DateTime?) formatTimestamp;

  const _CoachCard({
    required this.coach,
    required this.onUpdatePressed,
    required this.onBtScanPressed,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach Name and Status
            Row(
              children: [
                Text(
                  coach.coachName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: coach.statusColorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: coach.statusColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: coach.statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        coach.latestStatus ?? 'Unknown',
                        style: TextStyle(
                          color: coach.statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Last Report Info
            if (coach.lastReportedAt != null) ...[
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    formatTimestamp(coach.lastReportedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            if (coach.lastReporterName != null) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Reported by ${coach.lastReporterName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No reports yet',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Bluetooth Auto-Detect Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBtScanPressed,
                icon: const Icon(Icons.bluetooth_searching, size: 18),
                label: const Text('Auto-Detect Crowd (Bluetooth)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Manual Update Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpdatePressed,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Manual Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for crowd level selection button
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
