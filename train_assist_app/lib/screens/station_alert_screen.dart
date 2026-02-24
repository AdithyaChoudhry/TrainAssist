import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/station_alert_provider.dart';
import '../services/local_data_service.dart';
import '../models/station_alert_model.dart';

class StationAlertScreen extends StatefulWidget {
  const StationAlertScreen({super.key});

  @override
  State<StationAlertScreen> createState() => _StationAlertScreenState();
}

class _StationAlertScreenState extends State<StationAlertScreen> {
  final _local = LocalDataService();
  final _destCtrl = TextEditingController();

  int? _selectedTrainId;
  String? _selectedTrainName;
  TimeOfDay _arrivalTime = TimeOfDay.now();
  bool _elderlyMode = false;

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _arrivalTime,
      helpText: 'Select estimated arrival time',
    );
    if (t != null) setState(() => _arrivalTime = t);
  }

  Future<void> _setAlert() async {
    if (_selectedTrainId == null) {
      _snack('Please select a train', Colors.red);
      return;
    }
    if (_destCtrl.text.trim().isEmpty) {
      _snack('Please enter your destination station', Colors.red);
      return;
    }

    final now = DateTime.now();
    var arrival = DateTime(
        now.year, now.month, now.day, _arrivalTime.hour, _arrivalTime.minute);
    // If chosen time already passed today → assume tomorrow
    if (arrival.isBefore(now)) arrival = arrival.add(const Duration(days: 1));

    final alert = StationAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trainId: _selectedTrainId!,
      trainName: _selectedTrainName!,
      destinationStation: _destCtrl.text.trim(),
      scheduledArrival: arrival,
      elderlyMode: _elderlyMode,
    );

    await Provider.of<StationAlertProvider>(context, listen: false)
        .addAlert(alert);

    if (mounted) {
      _snack(
        '✅ Alert set for "${alert.destinationStation}" at ${_arrivalTime.format(context)}',
        Colors.green,
      );
      _destCtrl.clear();
      setState(() {
        _selectedTrainId = null;
        _selectedTrainName = null;
        _elderlyMode = false;
      });
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationAlertProvider>();
    final trains = _local.searchTrains();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Alert'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info card ────────────────────────────────────────────────
            Card(
              color: Colors.indigo[50],
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.indigo[700]),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Set an alert so the app wakes you up before your destination — even if you are asleep!',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Train picker ─────────────────────────────────────────────
            const Text('Select Your Train',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.train),
              ),
              hint: const Text('Choose train'),
              value: _selectedTrainId,
              items: trains
                  .map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text('${t.trainName} (${t.source}→${t.destination})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final t = trains.firstWhere((x) => x.id == v);
                setState(() {
                  _selectedTrainId = v;
                  _selectedTrainName = t.trainName;
                  // Pre-fill destination
                  _destCtrl.text = t.destination;
                });
              },
            ),
            const SizedBox(height: 16),

            // ── Destination ──────────────────────────────────────────────
            const Text('Your Destination Station',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _destCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
                hintText: 'e.g. Mumbai Central',
              ),
            ),
            const SizedBox(height: 16),

            // ── Arrival time ─────────────────────────────────────────────
            const Text('Estimated Arrival Time',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Text(
                      _arrivalTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Text('Tap to change',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Elderly mode ─────────────────────────────────────────────
            SwitchListTile(
              value: _elderlyMode,
              onChanged: (v) => setState(() => _elderlyMode = v),
              title: const Text('Elderly / Deep-sleep Mode'),
              subtitle:
                  const Text('Extra-strong haptic + repeated alerts'),
              secondary: const Icon(Icons.accessibility_new,
                  color: Colors.indigo),
              tileColor: Colors.indigo[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 24),

            // ── Set alert button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _setAlert,
                icon: const Icon(Icons.alarm_add),
                label: const Text('Set Destination Alert',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Active alerts ─────────────────────────────────────────────
            const Text('Active Alerts',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (provider.alerts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.alarm_off,
                          size: 56, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('No active alerts',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              )
            else
              ...provider.alerts.map(
                (alert) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _alertColor(alert),
                      child: const Icon(Icons.alarm, color: Colors.white),
                    ),
                    title: Text(alert.destinationStation,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.trainName, overflow: TextOverflow.ellipsis),
                        Text(alert.statusLabel,
                            style: TextStyle(
                                color: _alertColor(alert),
                                fontWeight: FontWeight.bold)),
                        if (alert.elderlyMode)
                          const Text('👴 Elderly mode ON',
                              style: TextStyle(fontSize: 11)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      onPressed: () =>
                          Provider.of<StationAlertProvider>(context,
                                  listen: false)
                              .removeAlert(alert.id),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _alertColor(StationAlert a) {
    final mins = a.timeRemaining.inMinutes;
    if (mins <= 5) return Colors.red;
    if (mins <= 15) return Colors.orange;
    if (mins <= 30) return Colors.amber;
    return Colors.green;
  }
}
