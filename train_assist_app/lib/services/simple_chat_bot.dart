import 'dart:math';

class BotLink {
  final String title;
  final String url;
  const BotLink(this.title, this.url);
}

class BotReply {
  final String text;
  final List<BotLink> links;
  const BotReply(this.text, {this.links = const []});
}

class SimpleChatBot {
  // Returns a BotReply for a given user message.
  // Rule-based, runs entirely on-device — no network needed.
  static BotReply reply(String message) {
    final m = message.trim().toLowerCase();
    if (m.isEmpty) {
      return const BotReply("Say something — ask 'where is my train?', 'SOS', or 'help'.");
    }

    // ── Greetings ────────────────────────────────────────────────────────────
    if (RegExp(r'\b(hi|hello|hey|good (morning|evening|afternoon))\b').hasMatch(m)) {
      return const BotReply(
          "Hello! 👋 I'm TrainAssist assistant. Try asking:\n"
          "• Where is my train?\n"
          "• When will my train arrive?\n"
          "• How do I check PNR?\n"
          "• How to send SOS?");
    }

    // ── Where is my train / track train / live status ─────────────────────
    if (m.contains('where is my train') ||
        m.contains('track my train') ||
        m.contains('find my train') ||
        m.contains('train location') ||
        m.contains('live status') ||
        m.contains('train running')) {
      return const BotReply(
          "Here are the best free sites to track your train live:",
          links: [
            BotLink('NTES — Official live running status', 'https://www.ntes.in/'),
            BotLink('RailYatri live tracker', 'https://www.railyatri.in/live-train-status'),
            BotLink('ixigo train status', 'https://www.ixigo.com/trains'),
            BotLink('Google: search train status', 'https://www.google.com/search?q=live+train+running+status'),
            BotLink('Google Maps: stations near me', 'https://www.google.com/maps/search/railway+station+near+me'),
          ]);
    }

    // ── ETA / arrival / delay ─────────────────────────────────────────────
    if (m.contains('arrive') || m.contains('arrival') || m.contains('eta') ||
        m.contains('delay') || m.contains('late') || m.contains('on time')) {
      return const BotReply(
          "To check live ETA and delay info for your train:",
          links: [
            BotLink('NTES live running status', 'https://www.ntes.in/'),
            BotLink('RailYatri ETA & delay', 'https://www.railyatri.in/live-train-status'),
            BotLink('ixigo ETA', 'https://www.ixigo.com/trains'),
          ]);
    }

    // ── PNR status ────────────────────────────────────────────────────────
    if (m.contains('pnr')) {
      return const BotReply(
          "Check your 10-digit PNR status here:",
          links: [
            BotLink('IRCTC PNR status', 'https://www.irctc.co.in/'),
            BotLink('NTES PNR enquiry', 'https://www.indianrail.gov.in/enquiry/PNRSTAT/PNRStatEnquiry.html'),
          ]);
    }

    // ── Ticket / booking / refund ─────────────────────────────────────────
    if (m.contains('ticket') || m.contains('book') || m.contains('refund') || m.contains('cancel')) {
      return const BotReply(
          "For ticket booking, cancellation and refunds:",
          links: [
            BotLink('IRCTC — book & cancel tickets', 'https://www.irctc.co.in/'),
            BotLink('IRCTC refund status', 'https://www.irctc.co.in/'),
          ]);
    }

    // ── Platform / station ────────────────────────────────────────────────
    if (m.contains('platform') || m.contains('station') || m.contains('nearest station')) {
      return const BotReply(
          "Find your platform or nearest station:",
          links: [
            BotLink('National Train Enquiry (platform)', 'https://enquiry.indianrail.gov.in/mntes/'),
            BotLink('Google Maps: nearest station', 'https://www.google.com/maps/search/railway+station+near+me'),
          ]);
    }

    // ── Crowd status ──────────────────────────────────────────────────────
    if (m.contains('crowd') || m.contains('occupancy') || m.contains('full') || m.contains('seats')) {
      return const BotReply(
          "Open the Search screen in this app, pick your train and tap a coach to see the latest crowd report from other passengers. You can also submit one yourself!");
    }

    // ── SOS / emergency ───────────────────────────────────────────────────
    if (m.contains('sos') || m.contains('emergency') || m.contains('help me') || m.contains('accident')) {
      return const BotReply(
          "🚨 To trigger SOS:\n"
          "• Tap the big SOS button or triple-tap the screen.\n"
          "• With Guard Mode: press Vol-UP 3 times.\n"
          "• Your location + voice note will be sent to saved contacts.\n\n"
          "Railway emergency helpline: 182\nGeneral helpline: 139",
          links: [
            BotLink('Rail Madad complaint / emergency portal', 'https://railmadad.indianrailways.gov.in/'),
          ]);
    }

    // ── Helpline / contact ────────────────────────────────────────────────
    if (m.contains('helpline') || m.contains('contact') || m.contains('complaint') || m.contains('number')) {
      return const BotReply(
          "Indian Railways helplines:\n"
          "• 139 — General enquiry, complaints, medical, security (24×7)\n"
          "• 182 — Railway Police / security emergency\n"
          "• 138 — Vigilance / corruption",
          links: [
            BotLink('Rail Madad portal', 'https://railmadad.indianrailways.gov.in/'),
          ]);
    }

    // ── Location ──────────────────────────────────────────────────────────
    if (m.contains('location') || m.contains('where am i') || m.contains('share location')) {
      return const BotReply(
          "The app includes your GPS location in SOS messages automatically. Make sure Location permission is granted in device Settings.");
    }

    // ── WhatsApp ──────────────────────────────────────────────────────────
    if (m.contains('whatsapp')) {
      return const BotReply(
          "WhatsApp: the app opens WhatsApp with a prefilled SOS message. Enable Accessibility → AutoSend in device Accessibility settings to auto-press Send.");
    }

    // ── Email / SMTP ──────────────────────────────────────────────────────
    if (m.contains('email') || m.contains('smtp')) {
      return const BotReply(
          "Email: go to Contacts/SMTP settings and provide SMTP host, user and App Password (for Gmail use an App Password). The app sends emails via the backend.");
    }

    // ── Contacts ──────────────────────────────────────────────────────────
    if (m.contains('contacts') || m.contains('numbers')) {
      return const BotReply(
          "Add up to 3 emergency contacts and 3 email recipients in the Contacts section; SMS will be sent automatically to saved numbers.");
    }

    // ── Help / what can you do ────────────────────────────────────────────
    if (m.contains('help') || m.contains('what can') || m.contains('features')) {
      return const BotReply(
          "I can answer questions like:\n"
          "• 'Where is my train?'\n"
          "• 'When will my train arrive?'\n"
          "• 'Check PNR status'\n"
          "• 'How do I cancel my ticket?'\n"
          "• 'Nearest station to me'\n"
          "• 'How to send SOS?'\n"
          "• 'Railway helpline number'");
    }

    // ── Fallback ──────────────────────────────────────────────────────────
    final fallbacks = [
      "Try asking: 'Where is my train?', 'Check PNR', 'Train helpline number', or 'How to send SOS?'",
      "I can help with train tracking, PNR, tickets, crowd reports, and SOS. What do you need?",
      "Not sure I understood that. Ask 'help' to see what I can do.",
    ];
    return BotReply(fallbacks[Random().nextInt(fallbacks.length)]);
  }
}
