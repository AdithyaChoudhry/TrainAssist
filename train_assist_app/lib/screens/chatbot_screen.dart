import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chatbot_service.dart';
import '../services/faq_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _trainController = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;
  List<LinkItem> _links = [];
  String? _error;

  @override
  void dispose() {
    _trainController.dispose();
    super.dispose();
  }

  Widget _buildFaqButtons() {
    final faqs = FAQService.getCommonFaqs();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: faqs.map((f) {
        return ActionChip(
          label: Text(f.question, style: const TextStyle(fontSize: 12)),
          onPressed: () => _showFaq(f),
        );
      }).toList(),
    );
  }

  void _showFaq(FAQItem f) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(f.question),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(f.answer),
              if (f.links.isNotEmpty) ...
                [
                  const SizedBox(height: 12),
                  const Text('Quick links:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...f.links.map((l) => InkWell(
                        onTap: () { Navigator.pop(context); _openUrl(l.url); },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            const Icon(Icons.open_in_new, size: 16),
                            const SizedBox(width: 6),
                            Expanded(child: Text(l.title,
                                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
                          ]),
                        ),
                      )),
                ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _fetchLinks() async {
    final train = _trainController.text.trim();
    if (train.isEmpty) {
      setState(() => _error = 'Please enter a train number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _links = [];
    });

    try {
      final dateStr = _selectedDate == null ? null : DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final links = await ChatbotService.getTrainLinks(train, date: dateStr);
      setState(() => _links = links);
    } catch (e) {
      setState(() => _error = 'Failed to fetch links: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showTroubleshoot() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Troubleshoot: API unreachable'),
        content: const SingleChildScrollView(
          child: Text(
            'If the app cannot reach the backend API on your device:\n\n'
            '- For physical Android devices: set `ApiConfig.baseUrl` to your computer\'s LAN IP, e.g. http://192.168.1.100:5000\n'
            '- For Android emulators: try http://10.0.2.2:5000\n'
            '- If you run the app with `flutter run`, consider using `adb reverse tcp:5000 tcp:5000` to forward the port\n\n'
            'After updating `ApiConfig.baseUrl`, restart the app.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TrainAssist Chatbot')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── FAQ section ──────────────────────────────────────────────────
            const Text('Frequently Asked Questions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _buildFaqButtons(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('or find your train')),
                Expanded(child: Divider()),
              ]),
            ),
            // ── Train finder ─────────────────────────────────────────────────
            TextField(
              controller: _trainController,
              decoration: const InputDecoration(
                  labelText: 'Train number', hintText: 'e.g. 12345',
                  prefixIcon: Icon(Icons.train)),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Text(
                  _selectedDate == null ? 'Today (no date chosen)' : DateFormat.yMMMd().format(_selectedDate!),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Pick date')),
            ]),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : _fetchLinks,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: const Text('Find my train'),
            ),
            const SizedBox(height: 12),
            // ── Results / error ───────────────────────────────────────────────
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_links.isNotEmpty) ...
              [
                Text('Found ${_links.length} links for train ${_trainController.text.trim()} — tap to open',
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    itemCount: _links.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final l = _links[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.open_in_new, size: 20),
                        title: Text(l.title),
                        onTap: () => _openUrl(l.url),
                      );
                    },
                  ),
                ),
              ],
            if (!_loading && _links.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('👆 Tap an FAQ above, or enter a train number and tap "Find my train".'),
              ),
          ],
        ),
      ),
    );
  }
}
