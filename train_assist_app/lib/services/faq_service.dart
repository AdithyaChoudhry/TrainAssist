import 'chatbot_service.dart';

class FAQItem {
  final String id;
  final String question;
  final String answer;
  final List<LinkItem> links;

  FAQItem({required this.id, required this.question, required this.answer, this.links = const []});
}

class FAQService {
  static List<FAQItem> getCommonFaqs() => [
        FAQItem(
          id: 'where',
          question: '📍 Where is my train?',
          answer:
              'Enter your train number below and tap "Find my train" to get a list of live tracking links including NTES, RailYatri, ixigo, and more — all free!',
        ),
        FAQItem(
          id: 'eta',
          question: '⏱️ When will my train arrive?',
          answer:
              'Check NTES (ntes.in) or RailYatri for live ETA and delay info. Enter your train number in the search below for direct links.',
          links: [
            LinkItem(title: 'NTES live status', url: 'https://www.ntes.in/'),
            LinkItem(title: 'RailYatri ETA', url: 'https://www.railyatri.in/'),
          ],
        ),
        FAQItem(
          id: 'crowd',
          question: '👥 Is my coach crowded?',
          answer:
              'Open the "Search" screen in this app, select your train and coach, and see the latest crowd report submitted by other passengers.',
        ),
        FAQItem(
          id: 'report_crowd',
          question: '📢 How do I report crowd?',
          answer:
              'Go to Search → select your train → tap on a coach → tap "Report Crowd" and choose Low / Medium / High.',
        ),
        FAQItem(
          id: 'map',
          question: '🗺️ Show live train map',
          answer:
              'Open Google Maps and search for your train number, or use RailYatri / ixigo which show a route map with the live train position.',
          links: [
            LinkItem(title: 'RailYatri map', url: 'https://www.railyatri.in/'),
            LinkItem(title: 'ixigo train status', url: 'https://www.ixigo.com/trains'),
          ],
        ),
        FAQItem(
          id: 'nearest',
          question: '📌 Nearest station to me',
          answer:
              'Open Google Maps and search "railway station near me" — it will show the closest stations with distance and directions.',
          links: [
            LinkItem(
                title: 'Google Maps: stations near me',
                url: 'https://www.google.com/maps/search/railway+station+near+me'),
          ],
        ),
        FAQItem(
          id: 'sos',
          question: '🚨 How do I send an SOS?',
          answer:
              'Tap the SOS button on the home screen. You can record a voice note and send it along with your location to the emergency contact.',
        ),
        FAQItem(
          id: 'refund',
          question: '💰 How do I get a ticket refund?',
          answer:
              'Log in to IRCTC (irctc.co.in) and go to My Bookings → Cancel ticket. Refunds are processed within 5–7 business days to the original payment method.',
          links: [
            LinkItem(title: 'IRCTC ticket cancellation', url: 'https://www.irctc.co.in/'),
          ],
        ),
        FAQItem(
          id: 'pnr',
          question: '🎟️ How do I check my PNR status?',
          answer:
              'Enter your 10-digit PNR number on IRCTC or the National Train Enquiry System to get seat confirmation and coach details.',
          links: [
            LinkItem(title: 'NTES PNR status', url: 'https://www.indianrail.gov.in/enquiry/PNRSTAT/PNRStatEnquiry.html'),
            LinkItem(title: 'IRCTC PNR check', url: 'https://www.irctc.co.in/'),
          ],
        ),
        FAQItem(
          id: 'facilities',
          question: '🚽 Facilities in my coach?',
          answer:
              'Most AC coaches have toilets, charging points and bedding. Sleeper coaches have toilets. General coaches have limited facilities. Check your ticket class for details.',
        ),
        FAQItem(
          id: 'contact',
          question: '📞 Contact railway helpline',
          answer:
              'Indian Railways helpline: 139 (24×7 — enquiry, complaints, medical, security). You can also chat via the Rail Madad app.',
          links: [
            LinkItem(title: 'Rail Madad complaint portal', url: 'https://railmadad.indianrailways.gov.in/'),
          ],
        ),
      ];
}
