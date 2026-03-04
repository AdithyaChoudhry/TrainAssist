import 'dart:math';

class SimpleChatBot {
  // Returns a quick reply for a given user message.
  // This is intentionally small and rule-based so it runs entirely on-device.
  static String reply(String message) {
    final m = message.trim().toLowerCase();
    if (m.isEmpty) return "Say something — I can help with SOS, location, or app features.";

    if (RegExp(r'hi|hello|hey|good (morning|evening|afternoon)').hasMatch(m)) {
      return "Hello — I'm TrainAssist helper. Ask me to 'trigger SOS', 'share location', or 'help'.";
    }
    if (m.contains('sos') || m.contains('emergency') || m.contains('help me')) {
      return "To trigger SOS, use the big button or triple-tap; enable Guard to use Vol‑UP x3. I cannot trigger SOS automatically from this chat for safety.";
    }
    if (m.contains('location') || m.contains('where am i') || m.contains('share location')) {
      return "The app will include your current location in SOS messages when GPS is enabled. Open the SOS screen and ensure Location permission is granted.";
    }
    if (m.contains('whatsapp')) {
      return "WhatsApp: the app opens WhatsApp with a prefilled message; enable Accessibility AutoSend in device Accessibility settings to auto-press Send.";
    }
    if (m.contains('email') || m.contains('smtp')) {
      return "Email: go to Contacts/SMTP settings and provide SMTP host, user and App Password (for Gmail use an App Password). The app sends emails via the backend.";
    }
    if (m.contains('contacts') || m.contains('numbers')) {
      return "Add up to 3 emergency contacts and 3 email recipients in the Contacts section; SMS will be sent automatically to saved numbers.";
    }
    // fallback small chatter
    final replies = [
      "I can help with SOS flow, location, voice note uploads, and WhatsApp hints.",
      "Try: 'How do I send SOS?', 'How to enable Accessibility?', or 'Help with SMTP'.",
      "I'm offline and local — I can't browse the web, but I can explain app features.",
    ];
    return replies[Random().nextInt(replies.length)];
  }
}
