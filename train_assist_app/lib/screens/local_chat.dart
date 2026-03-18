import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/simple_chat_bot.dart';
import '../services/location_service.dart';

class LocalChatScreen extends StatefulWidget {
  const LocalChatScreen({super.key});
  @override
  State<LocalChatScreen> createState() => _LocalChatScreenState();
}

class _LocalChatScreenState extends State<LocalChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  // Each message: {'who': 'me'|'bot', 'text': '...', 'links': [BotLink,...]}
  final List<Map<String, dynamic>> _msgs = [];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _addBotReply(BotReply r) {
    if (!mounted) return;
    setState(() => _msgs.add({'who': 'bot', 'text': r.text, 'links': r.links}));
    _scrollToBottom();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _msgs.add({'who': 'me', 'text': text, 'links': <BotLink>[]}));
    _ctrl.clear();
    _scrollToBottom();

    // Location intent handled specially with async GPS
    if (text.toLowerCase().contains('location') || text.toLowerCase().contains('where am i')) {
      _addBotReply(const BotReply('Getting your current location...'));
      Future.microtask(() async {
        if (!mounted) return;
        try {
          final pos = await LocationService.getCurrentLocation();
          if (pos == null) {
            _addBotReply(const BotReply('Unable to read GPS — ensure Location is enabled.'));
            return;
          }
          final addr = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
          final msg = addr != null
              ? 'You are at: $addr\nCoordinates: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
              : 'Coordinates: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} (address unavailable)';
          _addBotReply(BotReply(msg));
        } catch (e) {
          _addBotReply(BotReply('Location error: $e'));
        }
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _addBotReply(SimpleChatBot.reply(text));
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  Widget _buildBubble(Map<String, dynamic> m) {
    final isMe = m['who'] == 'me';
    final links = (m['links'] as List<BotLink>?) ?? [];
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isMe ? Colors.red[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m['text'] as String? ?? ''),
            if (links.isNotEmpty) ...
              [
                const SizedBox(height: 8),
                ...links.map((l) => InkWell(
                      onTap: () => _openUrl(l.url),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          const Icon(Icons.open_in_new, size: 15, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(l.title,
                                style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    fontSize: 13)),
                          ),
                        ]),
                      ),
                    )),
              ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TrainAssist Chat'), backgroundColor: Colors.red[700]),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length,
            itemBuilder: (_, i) => _buildBubble(_msgs[i]),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                      hintText: 'Ask: where is my train? PNR? SOS?...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(icon: const Icon(Icons.send, color: Colors.red), onPressed: _send),
            ]),
          ),
        ),
      ]),
    );
  }
}
