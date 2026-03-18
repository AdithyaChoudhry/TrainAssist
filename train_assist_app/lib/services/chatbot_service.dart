import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Attempts multiple development host addresses so physical Android devices
/// (which can't reach 127.0.0.1 on the host) still work when possible.

class LinkItem {
  final String title;
  final String url;

  LinkItem({required this.title, required this.url});

  factory LinkItem.fromJson(Map<String, dynamic> j) => LinkItem(
        title: j['title'] as String? ?? '',
        url: j['url'] as String? ?? '',
      );
}

class ChatbotService {
  /// Fetch templated links for a train number and optional date.
  static Future<List<LinkItem>> getTrainLinks(String trainNumber, {String? date}) async {
    final endpointPath = '/api/trains/$trainNumber/links' + (date != null ? '?date=$date' : '');

    // Candidate base URLs to try (in order). Update ApiConfig.baseUrl for a
    // permanent change if your device needs a specific host/IP.
    final candidates = <String>[
      ApiConfig.baseUrl, // configured base URL
      'http://10.0.2.2:5000', // Android emulator
      'http://localhost:5000', // sometimes reachable depending on tooling
    ];

    Exception? lastError;
    for (final base in candidates) {
      try {
        final uri = Uri.parse('$base$endpointPath');
        final resp = await http.get(uri).timeout(ApiConfig.requestTimeout);
        if (resp.statusCode != 200) {
          lastError = Exception('API returned ${resp.statusCode} from $base');
          continue;
        }

        final decoded = json.decode(resp.body) as Map<String, dynamic>;
        final links = (decoded['links'] as List<dynamic>?) ?? [];
        return links.map((e) => LinkItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        lastError = Exception('Request to $base failed: $e');
        // try next candidate
      }
    }

    // All candidates failed — return a rich set of web fallback links
    // so the chatbot always gives useful results without the backend.
    final d = date ?? DateTime.now().toString().split('T').first;
    return [
      LinkItem(title: 'Google: train $trainNumber status',
          url: 'https://www.google.com/search?q=Train+$trainNumber+status+$d'),
      LinkItem(title: 'Google Maps: find station/train',
          url: 'https://www.google.com/maps/search/train+station+$trainNumber'),
      LinkItem(title: 'WhereIsMyTrain app (Play Store)',
          url: 'https://play.google.com/store/apps/details?id=com.whereismytrain.android'),
      LinkItem(title: 'National Train Enquiry (India)',
          url: 'https://www.indianrail.gov.in/enquiry/PNRSTAT/PNRStatEnquiry.html'),
      LinkItem(title: 'Rail Enquiry – Live train status',
          url: 'https://enquiry.indianrail.gov.in/mntes/'),
      LinkItem(title: 'NTES Live train running status',
          url: 'https://www.ntes.in/'),
      LinkItem(title: 'RailYatri live train tracker',
          url: 'https://www.railyatri.in/live-train-status?train_num=$trainNumber'),
      LinkItem(title: 'ixigo train status',
          url: 'https://www.ixigo.com/train-tracking/$trainNumber/train-status'),
      LinkItem(title: 'Google: operator contact',
          url: 'https://www.google.com/search?q=railway+operator+contact+helpline'),
    ];
  }
}
