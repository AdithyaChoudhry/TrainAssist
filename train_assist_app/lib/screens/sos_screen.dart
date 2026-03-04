import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../providers/sos_provider.dart';
import '../providers/user_provider.dart';
import '../services/location_service.dart';
import '../config/api_config.dart';

const _sosCh = MethodChannel('com.trainassist/sos');

class _LogEntry {
  final String msg;
  final IconData icon;
  final Color color;
  _LogEntry(this.msg, {this.icon = Icons.info_outline, this.color = Colors.black87});
}

// ═══════════════════════════════════════════════════════════════
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});
  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(3, (_) => TextEditingController());
  bool _guardActive = false;
  bool _sosRunning  = false;
  final List<_LogEntry> _log = [];
  int   _tapCount   = 0;
  Timer? _tapTimer;
  final _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _sosCh.setMethodCallHandler((call) async {
      if (call.method == 'power_sos') _startAutoSos();
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    _tapTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < 3; i++) {
      _ctrls[i].text = prefs.getString('sos_contact_$i') ?? '';
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < 3; i++) {
      await prefs.setString('sos_contact_$i', _ctrls[i].text.trim());
    }
    _addLog('Contacts saved', icon: Icons.check_circle, color: Colors.green);
  }

  List<String> get _phones =>
      _ctrls.map((c) => c.text.trim()).where((p) => p.isNotEmpty).toList();

  void _addLog(String msg,
      {IconData icon = Icons.info_outline, Color color = Colors.black87}) {
    if (!mounted) return;
    setState(() => _log.add(_LogEntry(msg, icon: icon, color: color)));
  }

  // ─── MAIN AUTO-SOS FLOW ───────────────────────────────────────────────────
  Future<void> _startAutoSos() async {
    if (_sosRunning) return;
    setState(() {
      _sosRunning = true;
      _log.clear();
    });
    _addLog('SOS triggered!', icon: Icons.emergency, color: Colors.red);

    try {
      // 1 ─ GPS
      _addLog('Getting GPS...', icon: Icons.gps_fixed, color: Colors.blue);
      final pos = await LocationService.getCurrentLocation();
      final mapsLink =
          pos != null ? LocationService.mapsLink(pos.latitude, pos.longitude) : null;
      if (mapsLink != null) {
        _addLog('Location: ${pos!.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
            icon: Icons.location_on, color: Colors.green);
      } else {
        _addLog('GPS unavailable', icon: Icons.gps_off, color: Colors.orange);
      }

      // 2 ─ Auto-record 15 s
      String? audioUrl;
      if (await _recorder.hasPermission()) {
        _addLog('Recording 15 s voice note...', icon: Icons.mic, color: Colors.blue);
        final dir  = await getTemporaryDirectory();
        final path = '${dir.path}/sos_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
          path: path,
        );
        await Future.delayed(const Duration(seconds: 15));
        final saved = await _recorder.stop();
        if (saved != null) {
          _addLog('Uploading voice note...', icon: Icons.upload, color: Colors.blue);
          audioUrl = await _uploadVoiceNote(saved);
          _addLog(
            audioUrl != null ? 'Voice note uploaded' : 'Upload failed (SMS without audio)',
            icon: audioUrl != null ? Icons.check_circle : Icons.warning,
            color: audioUrl != null ? Colors.green : Colors.orange,
          );
          try { File(saved).deleteSync(); } catch (_) {}
        }
      } else {
        _addLog('Mic permission denied', icon: Icons.mic_off, color: Colors.orange);
      }

      // 3 ─ Build SMS body
      final now = DateFormat('HH:mm, dd MMM').format(DateTime.now());
      final sb  = StringBuffer()
        ..writeln('SOS EMERGENCY - TrainAssist')
        ..writeln('Time: $now');
      if (mapsLink != null) sb.writeln('Location: $mapsLink');
      if (audioUrl  != null) sb.writeln('Voice note: $audioUrl');
      sb.write('Please help immediately!');
      // Notify recipient to check email for the voice note
      sb.write(' Check your email immediately.');
      final smsBody = sb.toString();

      // 4 ─ Send SMS to all saved contacts
      final phones = _phones;
          if (phones.isEmpty) {
        _addLog('No contacts — opening SMS composer',
            icon: Icons.sms, color: Colors.orange);
        await _openComposer('', smsBody);
      } else {
        _addLog('Sending to ${phones.length} contact(s)...',
            icon: Icons.send, color: Colors.blue);
        for (final phone in phones) {
          final ok = await _sendSmsNative(phone, smsBody);
          if (ok) {
            _addLog('Sent to $phone', icon: Icons.check, color: Colors.green);
          } else {
            _addLog('Composer fallback: $phone',
                icon: Icons.open_in_new, color: Colors.orange);
            await _openComposer(phone, smsBody);
          }
        }
      }

      // Attempt to email the voice note automatically (best-effort).
      // Reads 'sos_email' from SharedPreferences if set.
      if (audioUrl != null) {
        await _sendEmailAutomatic(audioUrl, mapsLink);
      }

      // 5 ─ POST to backend
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final sosProv  = Provider.of<SOSProvider>(context, listen: false);
      if (userProv.userName?.isNotEmpty == true) {
        final ok = await sosProv.submitSOS(
          reporterName: userProv.userName!,
          message: 'Auto SOS. Audio: ${audioUrl ?? "N/A"}',
          latitude:  pos?.latitude,
          longitude: pos?.longitude,
        );
        if (ok && mounted) {
          _addLog('Alert sent to railway authorities',
              icon: Icons.check_circle, color: Colors.green);
        }
      }

      _addLog('SOS complete', icon: Icons.done_all, color: Colors.green);
    } catch (e) {
      _addLog('Error: $e', icon: Icons.error, color: Colors.red);
    } finally {
      if (mounted) setState(() => _sosRunning = false);
    }
  }

  Future<String?> _uploadVoiceNote(String filePath) async {
    try {
      final req = http.MultipartRequest(
        'POST', Uri.parse('${ApiConfig.baseUrl}/api/uploads'),
      );
      req.files.add(await http.MultipartFile.fromPath('file', filePath));
      req.headers['Accept'] = 'application/json';
      final res  = await req.send().timeout(const Duration(seconds: 30));
      final body = await res.stream.bytesToString();
      if (res.statusCode == 200 || res.statusCode == 201) {
        return (jsonDecode(body) as Map)['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _sendSmsNative(String phone, String body) async {
    final status = await Permission.sms.request();
    if (status != PermissionStatus.granted) return false;
    try {
      await _sosCh.invokeMethod('sendSms', {'phone': phone, 'body': body});
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _sendEmailAutomatic(String audioUrl, String? mapsLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('sos_email') ?? '';
      if (email.isEmpty) {
        _addLog('No SOS email configured; skipping email send', icon: Icons.email, color: Colors.orange);
        return;
      }

      final payload = jsonEncode({
        'to': email,
        'subject': 'TrainAssist SOS Voice Note',
        'body': 'You have received a voice note from an SOS. Location: ${mapsLink ?? "N/A"}',
        'attachmentUrl': audioUrl,
      });

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/sendmail');
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: payload).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        _addLog('Voice note emailed to $email', icon: Icons.email, color: Colors.green);
      } else {
        _addLog('Email send failed', icon: Icons.email, color: Colors.orange);
      }
    } catch (e) {
      _addLog('Email error: $e', icon: Icons.email, color: Colors.red);
    }
  }

  Future<void> _openComposer(String phone, String body) async {
    final uri = Uri(
      scheme: 'sms', path: phone, queryParameters: {'body': body},
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _toggleGuard() async {
    try {
      await _sosCh.invokeMethod(
          _guardActive ? 'stopSosService' : 'startSosService');
      setState(() => _guardActive = !_guardActive);
    } on PlatformException catch (e) {
      _addLog('Guard error: ${e.message}', icon: Icons.error, color: Colors.red);
    }
  }

  void _handleManualTap() {
    _tapCount++;
    _tapTimer?.cancel();
    if (_tapCount >= 3) {
      _tapCount = 0;
      _startAutoSos();
      return;
    }
    _tapTimer = Timer(const Duration(milliseconds: 1500),
        () { if (mounted) setState(() => _tapCount = 0); });
    setState(() {});
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const RecentSOSReportsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTriggerCard(),
            const SizedBox(height: 16),
            _buildGuardCard(),
            const SizedBox(height: 16),
            _buildContactsCard(),
            if (_log.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLogCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerCard() {
    final left = 3 - _tapCount;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(children: [
          if (_sosRunning)
            Column(children: [
              const SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                    strokeWidth: 6, color: Colors.red),
              ),
              const SizedBox(height: 12),
              Text('Running SOS sequence...',
                  style: TextStyle(
                      color: Colors.red[700], fontWeight: FontWeight.bold)),
            ])
          else
            GestureDetector(
              onTap: _handleManualTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tapCount > 0 ? Colors.red[800] : Colors.red[600],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red
                          .withValues(alpha: _tapCount > 0 ? 0.65 : 0.3),
                      blurRadius: _tapCount > 0 ? 32 : 10,
                      spreadRadius: _tapCount > 0 ? 6 : 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emergency, size: 64, color: Colors.white),
                    const SizedBox(height: 4),
                    Text(
                      _tapCount > 0 ? 'Tap $left more...' : 'S O S',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            'Triple-tap button  •  Vol-UP x3 (in app)  •  Notification button',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          if (_tapCount > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _tapCount / 3,
                minHeight: 5,
                backgroundColor: Colors.red[100],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildGuardCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: _guardActive ? Colors.red : Colors.grey[300]!),
      ),
      color: _guardActive ? Colors.red[50] : Colors.white,
      child: SwitchListTile(
        secondary: Icon(Icons.shield,
            color: _guardActive ? Colors.red : Colors.grey, size: 30),
        title: Text(_guardActive ? 'SOS Guard ACTIVE' : 'SOS Guard Off',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          _guardActive
              ? 'Vol-UP x3 or notification button fires auto-SOS'
              : 'Enable for background emergency trigger',
          style: TextStyle(
              fontSize: 12,
              color: _guardActive ? Colors.red[700] : Colors.grey[600]),
        ),
        value: _guardActive,
        activeColor: Colors.red,
        onChanged: (_) => _toggleGuard(),
      ),
    );
  }

  Widget _buildContactsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.contacts, color: Colors.red),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Emergency Contacts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton.icon(
                onPressed: _saveContacts,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'SMS is sent AUTOMATICALLY to every saved number.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < 3; i++) ...[
              TextField(
                controller: _ctrls[i],
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  labelText: 'Contact ${i + 1}',
                  hintText: '+91 XXXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone, color: Colors.red),
                ),
              ),
              if (i < 2) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.terminal, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              const Text('SOS Log',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _log.clear()),
                child: const Text('Clear',
                    style: TextStyle(color: Colors.grey)),
              ),
            ]),
            const Divider(height: 8),
            for (final e in _log.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(e.icon, size: 15, color: e.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(e.msg,
                          style: TextStyle(fontSize: 12, color: e.color)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Recent SOS Reports screen
// ═══════════════════════════════════════════════════════════════

class RecentSOSReportsScreen extends StatefulWidget {
  const RecentSOSReportsScreen({super.key});
  @override
  State<RecentSOSReportsScreen> createState() =>
      _RecentSOSReportsScreenState();
}

class _RecentSOSReportsScreenState extends State<RecentSOSReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<SOSProvider>(context, listen: false).loadRecentReports());
  }

  String _fmt(DateTime ts) {
    final d = DateTime.now().difference(ts);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours   < 1) return '${d.inMinutes}m ago';
    if (d.inDays    < 1) return '${d.inHours}h ago';
    if (d.inDays    < 7) return '${d.inDays}d ago';
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
        if (prov.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
        }
        if (prov.errorMessage != null) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No SOS reports',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
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
                      child:
                          Icon(Icons.emergency, color: Colors.white)),
                  title: Text('SOS from ${r.reporterName}',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.message != null && r.message!.isNotEmpty)
                          Text(r.message!,
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic)),
                        Text(_fmt(r.timestamp),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        if (r.latitude != null && r.longitude != null)
                          Text(
                            'Loc: ${r.latitude!.toStringAsFixed(4)}, '
                            '${r.longitude!.toStringAsFixed(4)}',
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
