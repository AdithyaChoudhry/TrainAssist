// API Configuration for Train Assist App
// 
// This file contains the base URL and configuration for connecting to the backend API.
// 
// IMPORTANT NOTES:
// - For testing on localhost (web/desktop): Use "http://localhost:5000"
// - For Android emulator: Use "http://10.0.2.2:5000" (emulator's special alias to host machine)
// - For iOS simulator: Use "http://localhost:5000" (works directly)
// - For physical devices: Use your computer's local IP (e.g., "http://192.168.1.100:5000")
//   * Find your IP: 
//     - macOS/Linux: Run `ifconfig` or `ip addr` 
//     - Windows: Run `ipconfig`
//     - Look for your local network IP (usually starts with 192.168.x.x or 10.0.x.x)

class ApiConfig {
  // Base URL for the backend API
  // Change this based on your testing environment
  // Use 127.0.0.1 in browser to avoid IPv6 (::1) resolution issues that can
  // cause "Failed to fetch" errors when the backend is bound to 127.0.0.1.
  static const String baseUrl = 'http://127.0.0.1:5000';
  
  // API endpoints
  static const String healthEndpoint = '/api/health';
  static const String trainsEndpoint = '/api/trains';
  static const String coachesEndpoint = '/api/trains'; // /{trainId}/coaches
  static const String crowdReportEndpoint = '/api/coaches'; // /{coachId}/crowd
  static const String sosEndpoint = '/api/sos';
  
  // Timeout duration for HTTP requests
  static const Duration requestTimeout = Duration(seconds: 10);
  
  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
