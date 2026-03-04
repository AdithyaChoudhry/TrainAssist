import 'package:flutter/material.dart';
import '../services/simple_chat_bot.dart';
import '../services/location_service.dart';

class LocalChatScreen extends StatefulWidget {
  const LocalChatScreen({super.key});
  @override
  State<LocalChatScreen> createState() => _LocalChatScreenState();
}

class _LocalChatScreenState extends State<LocalChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final List<Map<String, String>> _msgs = [];

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _msgs.add({'who': 'me', 'text': text}));
    _ctrl.clear();
    // If the user asks for location, attempt live location + reverse geocode.
    if (text.toLowerCase().contains('location') || text.toLowerCase().contains('where am')) {
      Future.microtask(() async {
        if (!mounted) return;
        setState(() => _msgs.add({'who': 'bot', 'text': 'Getting current location...'}));
        try {
          final pos = await LocationService.getCurrentLocation();
          if (pos == null) {
            setState(() => _msgs.add({'who': 'bot', 'text': 'Unable to read GPS — ensure Location is enabled.'}));
            return;
          }
          final addr = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
          final msg = addr != null
              ? 'You are at: $addr\nCoordinates: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
              : 'Coordinates: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} (address unavailable)';
          setState(() => _msgs.add({'who': 'bot', 'text': msg}));
        } catch (e) {
          setState(() => _msgs.add({'who': 'bot', 'text': 'Location error: $e'}));
        }
      });
      return;
    }

    final reply = SimpleChatBot.reply(text);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _msgs.add({'who': 'bot', 'text': reply}));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TrainAssist Chat'), backgroundColor: Colors.red[700]),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length,
            itemBuilder: (_, i) {
              final m = _msgs[i];
              final isMe = m['who'] == 'me';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.red[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(m['text'] ?? ''),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Row(children: [
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(hintText: 'Ask me about SOS, WhatsApp, location...'),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(icon: const Icon(Icons.send, color: Colors.red), onPressed: _send),
          ]),
        ),
      ]),
    );
  }
}
