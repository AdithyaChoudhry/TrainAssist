import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/sos_provider.dart';
import '../providers/user_provider.dart';
import '../services/location_service.dart';

// ── MethodChannel for native power-button service ───────────────────────────
const _sosCh = MethodChannel('com.trainassist/sos');

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);
  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ── Shared state ────────────────────────────────────────────────────────────
  final _contactCtrl = TextEditingController(text: '');
  bool _guardActive = false;

  // Power-button MethodChannel callback
  void _onSosPowerTriggered(MethodCall call) {
    if (call.method == 'power_sos') _triggerLocationSms(fromPower: true);
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _sosCh.setMethodCallHandler((call) async => _onSosPowerTriggered(call));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  // ── Shared helper: get GPS then open SMS composer ──────────────────────────
  Future<void> _triggerLocationSms({bool fromPower = false}) async {
    if (!mounted) return;
    // Show in-progress snack
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        SizedBox(width: 12),
        Text('Getting your location…'),
      ]),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 15),
    ));

    final pos = await LocationService.getCurrentLocation();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not get location — enable GPS and try again.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final link = LocationService.mapsLink(pos.latitude, pos.longitude);
    final body =
        '🆘 EMERGENCY! I need help. My current location:\n$link\n'
        '(Sent from TrainAssist at ${DateFormat('HH:mm, dd MMM').format(DateTime.now())})';

    final phone = _contactCtrl.text.trim();
    final smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': body},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      // Fallback: share sheet
      await Share.share(body, subject: 'Emergency SOS Location');
    }
  }

  // ── Power-button guard toggle ──────────────────────────────────────────────
  Future<void> _toggleGuard() async {
    try {
      if (_guardActive) {
        await _sosCh.invokeMethod('stopSosService');
      } else {
        await _sosCh.invokeMethod('startSosService');
      }
      setState(() => _guardActive = !_guardActive);
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Location'),
            Tab(icon: Icon(Icons.mic), text: 'Voice Note'),
            Tab(icon: Icon(Icons.emergency), text: 'SOS Alert'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _LocationTab(
            contactCtrl: _contactCtrl,
            onSendSms: () => _triggerLocationSms(),
            guardActive: _guardActive,
            onToggleGuard: _toggleGuard,
          ),
          const _VoiceNoteTab(),
          _AlertTab(contactCtrl: _contactCtrl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Live Location via SMS
// ─────────────────────────────────────────────────────────────────────────────

class _LocationTab extends StatefulWidget {
  final TextEditingController contactCtrl;
  final VoidCallback onSendSms;
  final bool guardActive;
  final VoidCallback onToggleGuard;

  const _LocationTab({
    required this.contactCtrl,
    required this.onSendSms,
    required this.guardActive,
    required this.onToggleGuard,
  });

  @override
  State<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<_LocationTab> {
  // Triple-tap detection
  int _tapCount = 0;
  Timer? _tapTimer;
  static const _tapWindow = Duration(milliseconds: 1500);
  static const _tapsNeeded = 3;

  void _handleTap() {
    setState(() => _tapCount++);
    _tapTimer?.cancel();

    if (_tapCount >= _tapsNeeded) {
      _tapCount = 0;
      widget.onSendSms();
      return;
    }

    _tapTimer = Timer(_tapWindow, () {
      if (mounted) setState(() => _tapCount = 0);
    });
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _tapsNeeded - _tapCount;
    final isStarted = _tapCount > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Emergency contact input ─────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Emergency Contact',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: widget.contactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      hintText: '+91 XXXXXXXXXX  (leave empty to pick from contacts)',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Triple-tap SOS button ───────────────────────────────────────
          Center(
            child: Text(
              isStarted
                  ? 'Tap $remaining more time${remaining == 1 ? '' : 's'}…'
                  : 'Tap button 3× to send SOS',
              style: TextStyle(
                  fontSize: 15,
                  color: isStarted ? Colors.red : Colors.grey[600],
                  fontWeight: isStarted ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 140,
              decoration: BoxDecoration(
                color: isStarted ? Colors.red[700] : Colors.red[600],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: isStarted ? 0.6 : 0.3),
                    blurRadius: isStarted ? 24 : 8,
                    spreadRadius: isStarted ? 4 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    isStarted
                        ? '${_tapCount} / $_tapsNeeded'
                        : 'SEND LOCATION SOS',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                  if (!isStarted)
                    const Text('Tap 3 times quickly',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Linear progress indicator showing tap count
          if (isStarted)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _tapCount / _tapsNeeded,
                minHeight: 6,
                backgroundColor: Colors.red[100],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),

          const SizedBox(height: 24),

          // ── One-tap instant share ───────────────────────────────────────
          OutlinedButton.icon(
            onPressed: widget.onSendSms,
            icon: const Icon(Icons.send, color: Colors.red),
            label: const Text('Share Location Now (1 tap)',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 28),

          // ── Power-button guard ──────────────────────────────────────────
          Card(
            color: widget.guardActive ? Colors.red[50] : Colors.grey[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: widget.guardActive ? Colors.red : Colors.grey[300]!),
            ),
            child: ListTile(
              leading: Icon(Icons.power_settings_new,
                  color: widget.guardActive ? Colors.red : Colors.grey),
              title: const Text('Power-button SOS Guard',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                widget.guardActive
                    ? 'Active — press power button 3× to auto-send SOS'
                    : 'Off — tap to activate background guard',
                style: TextStyle(
                    color: widget.guardActive ? Colors.red[700] : Colors.grey[600],
                    fontSize: 12),
              ),
              trailing: Switch(
                value: widget.guardActive,
                onChanged: (_) => widget.onToggleGuard(),
                activeColor: Colors.red,
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            '💡 Power-button guard runs in the background. '
            'Pressing power 3× within 3 seconds automatically opens SMS with your location.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Voice Note
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceNoteTab extends StatefulWidget {
  const _VoiceNoteTab();
  @override
  State<_VoiceNoteTab> createState() => _VoiceNoteTabState();
}

class _VoiceNoteTabState extends State<_VoiceNoteTab> {
  final _recorder  = AudioRecorder();
  final _player    = AudioPlayer();

  bool   _isRecording  = false;
  bool   _isPlaying    = false;
  String? _recordedPath;
  Duration _elapsed    = Duration.zero;
  Timer?  _elapsedTimer;

  static const _maxDuration = Duration(seconds: 60);

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Request permission
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _snack('Microphone permission denied', Colors.red);
      return;
    }

    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/sos_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _elapsed = Duration.zero;
      _recordedPath = null;
    });

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= _maxDuration) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _elapsedTimer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording   = false;
      _recordedPath  = path;
    });
    if (path != null) _snack('Recording saved! Play or share it below.', Colors.green);
  }

  Future<void> _playRecording() async {
    if (_recordedPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isPlaying = true);
    await _player.play(DeviceFileSource(_recordedPath!));
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _shareRecording() async {
    if (_recordedPath == null) return;
    await Share.shareXFiles(
      [XFile(_recordedPath!)],
      text: '🆘 Emergency voice note from TrainAssist\n'
            'Sent at ${DateFormat('HH:mm, dd MMM yyyy').format(DateTime.now())}',
      subject: 'SOS Voice Note',
    );
  }

  Future<void> _deleteRecording() async {
    if (_recordedPath == null) return;
    try { await File(_recordedPath!).delete(); } catch (_) {}
    setState(() { _recordedPath = null; _isPlaying = false; });
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Recording circle ────────────────────────────────────────────
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.red[700],
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: _isRecording ? 0.6 : 0.25),
                    blurRadius: _isRecording ? 30 : 10,
                    spreadRadius: _isRecording ? 8 : 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRecording ? 'STOP' : 'RECORD',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Timer ───────────────────────────────────────────────────────
          Text(
            _isRecording
                ? '${_fmt(_elapsed)} / ${_fmt(_maxDuration)}'
                : _recordedPath != null
                    ? 'Recorded: ${_fmt(_elapsed)}'
                    : 'Tap to start recording (max 60s)',
            style: TextStyle(
                fontSize: 16,
                color: _isRecording ? Colors.red : Colors.grey[700],
                fontWeight: FontWeight.w500),
          ),

          if (_isRecording) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _elapsed.inSeconds / _maxDuration.inSeconds,
                minHeight: 6,
                backgroundColor: Colors.red[100],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // ── Playback + Share (only when recording exists) ───────────────
          if (_recordedPath != null) ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Play / Stop
                    _iconBtn(
                      icon: _isPlaying ? Icons.stop_circle : Icons.play_circle,
                      label: _isPlaying ? 'Stop' : 'Play',
                      color: Colors.blue,
                      onTap: _playRecording,
                    ),
                    // Share
                    _iconBtn(
                      icon: Icons.share,
                      label: 'Share',
                      color: Colors.green[700]!,
                      onTap: _shareRecording,
                    ),
                    // Delete
                    _iconBtn(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: Colors.grey,
                      onTap: _deleteRecording,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              '📤 Share opens WhatsApp, SMS, Email, and more.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Record a short voice note describing your emergency, '
            'then share it via SMS, WhatsApp, or email to your known contacts.\n\n'
            'No internet required for recording. Sharing uses device apps (free).',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — SOS Alert (existing API flow)
// ─────────────────────────────────────────────────────────────────────────────

class _AlertTab extends StatefulWidget {
  final TextEditingController contactCtrl;
  const _AlertTab({required this.contactCtrl});
  @override
  State<_AlertTab> createState() => _AlertTabState();
}

class _AlertTabState extends State<_AlertTab> {
  final _messageController = TextEditingController();
  bool _includeLocation = true;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendSOSAlert() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sosProvider  = Provider.of<SOSProvider>(context, listen: false);

    if (userProvider.userName == null || userProvider.userName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User name not found. Please restart the app.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
          SizedBox(width: 12),
          Text('Confirm SOS Alert'),
        ]),
        content: const Text(
            'Are you sure you want to send an emergency SOS alert? '
            'This will notify railway authorities and emergency services.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Real GPS for API call
    double? lat, lng;
    if (_includeLocation) {
      final pos = await LocationService.getCurrentLocation();
      lat = pos?.latitude;
      lng = pos?.longitude;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    final success = await sosProvider.submitSOS(
      reporterName: userProvider.userName!,
      message: _messageController.text.isNotEmpty ? _messageController.text : null,
      latitude: lat,
      longitude: lng,
    );

    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? '🚨 SOS Alert sent successfully!'
            : 'Failed to send SOS alert. Please try again.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) {
        _messageController.clear();
        setState(() => _includeLocation = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Emergency SOS',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 4),
          Text('Sends alert + GPS to railway authorities',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),

          const SizedBox(height: 20),

          TextField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Additional Message (optional)',
              hintText: 'Describe your emergency…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.message),
            ),
          ),

          CheckboxListTile(
            title: const Text('Include my GPS location'),
            subtitle: const Text('Helps responders find you faster'),
            value: _includeLocation,
            activeColor: Colors.red,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _includeLocation = v ?? true),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 72,
            child: ElevatedButton.icon(
              onPressed: _sendSOSAlert,
              icon: const Icon(Icons.emergency, size: 32),
              label: const Text('SEND SOS ALERT',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RecentSOSReportsScreen())),
            icon: const Icon(Icons.history, color: Colors.red),
            label: const Text('View Recent SOS Reports',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent SOS Reports (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class RecentSOSReportsScreen extends StatefulWidget {
  const RecentSOSReportsScreen({Key? key}) : super(key: key);
  @override
  State<RecentSOSReportsScreen> createState() => _RecentSOSReportsScreenState();
}

class _RecentSOSReportsScreenState extends State<RecentSOSReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<SOSProvider>(context, listen: false).loadRecentReports());
  }

  String _fmt(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)    return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy h:mm a').format(ts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent SOS Reports'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SOSProvider>(builder: (_, prov, __) {
        if (prov.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.red));
        if (prov.errorMessage != null) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(prov.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: prov.loadRecentReports,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]));
        }
        if (prov.recentReports.isEmpty) {
          return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No SOS reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]));
        }
        return RefreshIndicator(
          onRefresh: prov.loadRecentReports,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.recentReports.length,
            itemBuilder: (_, i) {
              final r = prov.recentReports[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                child: ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.emergency, color: Colors.white)),
                  title: Text('SOS from ${r.reporterName}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (r.message != null && r.message!.isNotEmpty)
                      Text(r.message!, style: const TextStyle(fontStyle: FontStyle.italic)),
                    Text(_fmt(r.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (r.latitude != null && r.longitude != null)
                      Text(
                        'Location: ${r.latitude!.toStringAsFixed(4)}, ${r.longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ]),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
