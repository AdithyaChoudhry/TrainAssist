import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sos_provider.dart';
import '../providers/user_provider.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final _messageController = TextEditingController();
  bool _includeLocation = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendSOSAlert() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sosProvider = Provider.of<SOSProvider>(context, listen: false);

    if (userProvider.userName == null || userProvider.userName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User name not found. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Confirm SOS Alert'),
          ],
        ),
        content: const Text(
          'Are you sure you want to send an emergency SOS alert? '
          'This will notify authorities and emergency services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    // Send SOS report
    final success = await sosProvider.submitSOS(
      reporterName: userProvider.userName!,
      message: _messageController.text.isNotEmpty ? _messageController.text : null,
      // In a real app, you would get actual location here
      latitude: _includeLocation ? 12.9716 : null, // Example coordinates
      longitude: _includeLocation ? 77.5946 : null,
    );

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // Show result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '🚨 SOS Alert sent successfully!'
                : 'Failed to send SOS alert. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      if (success) {
        // Clear the message after successful submission
        _messageController.clear();
        setState(() {
          _includeLocation = false;
        });
      }
    }

    print('SOS Alert sent by ${userProvider.userName} - Success: $success');
  }

  void _viewRecentReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecentSOSReportsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Warning Icon
              const Icon(
                Icons.warning_amber_rounded,
                size: 120,
                color: Colors.red,
              ),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Emergency SOS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Explanation
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'About SOS Feature:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Use this feature only in genuine emergencies\n'
                        '• Your alert will be sent to railway authorities\n'
                        '• Emergency services will be notified\n'
                        '• Location will help responders find you quickly\n'
                        '• Provide additional details if possible',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Message TextField
              TextField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Additional Message (Optional)',
                  hintText: 'Describe your emergency...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.message),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Include Location Checkbox
              CheckboxListTile(
                title: const Text('Include my location'),
                subtitle: const Text('Helps emergency services locate you'),
                value: _includeLocation,
                onChanged: (value) {
                  setState(() {
                    _includeLocation = value ?? false;
                  });
                },
                activeColor: Colors.red,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              
              const SizedBox(height: 32),
              
              // Large SOS Button
              SizedBox(
                height: 80,
                child: ElevatedButton(
                  onPressed: _sendSOSAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emergency, size: 36),
                      SizedBox(width: 16),
                      Text(
                        'SEND SOS ALERT',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Recent Reports Button
              OutlinedButton.icon(
                onPressed: _viewRecentReports,
                icon: const Icon(Icons.history),
                label: const Text('View Recent SOS Reports'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Recent SOS Reports Screen
class RecentSOSReportsScreen extends StatefulWidget {
  const RecentSOSReportsScreen({Key? key}) : super(key: key);

  @override
  State<RecentSOSReportsScreen> createState() => _RecentSOSReportsScreenState();
}

class _RecentSOSReportsScreenState extends State<RecentSOSReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Load reports when screen opens
    Future.microtask(() {
      Provider.of<SOSProvider>(context, listen: false).loadRecentReports();
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy h:mm a').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent SOS Reports'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SOSProvider>(
        builder: (context, sosProvider, child) {
          if (sosProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          if (sosProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    sosProvider.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => sosProvider.loadRecentReports(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (sosProvider.recentReports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'No SOS reports found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All clear! No emergency alerts have been sent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: sosProvider.loadRecentReports,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sosProvider.recentReports.length,
              itemBuilder: (context, index) {
                final report = sosProvider.recentReports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.emergency, color: Colors.white),
                    ),
                    title: Text(
                      'SOS from ${report.reporterName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (report.message != null && report.message!.isNotEmpty)
                          Text(
                            report.message!,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(report.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (report.trainId != null)
                          Text(
                            'Train ID: ${report.trainId}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (report.latitude != null && report.longitude != null)
                          Text(
                            'Location: ${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
