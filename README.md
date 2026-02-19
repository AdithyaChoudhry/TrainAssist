# Train Assist

A comprehensive mobile application for train passengers to report crowd status in coaches and send emergency SOS alerts. Built with Flutter frontend and ASP.NET Core backend with PostgreSQL database.

## 📱 Project Overview

Train Assist helps passengers:
- **Search trains** by source and destination
- **View real-time crowd status** for each coach (Low/Medium/High)
- **Report crowd conditions** to help fellow passengers
- **Send emergency SOS alerts** with location and custom messages
- **View recent SOS reports** from the system

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │  Welcome   │  │   Search   │  │   Coach    │           │
│  │  Screen    │→ │   Screen   │→ │    List    │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│                        ↓                                     │
│                  ┌────────────┐                             │
│                  │    SOS     │                             │
│                  │   Screen   │                             │
│                  └────────────┘                             │
│                        ↓                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         State Management (Provider Pattern)          │  │
│  │  UserProvider │ TrainProvider │ CoachProvider │ SOS  │  │
│  └──────────────────────────────────────────────────────┘  │
│                        ↓                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              API Service Layer (HTTP)                │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────┬───────────────────────────────┘
                              │ REST API
                              ↓
┌─────────────────────────────────────────────────────────────┐
│            ASP.NET Core Minimal API (.NET 10)               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │   Trains   │  │   Coaches  │  │    SOS     │           │
│  │  Endpoints │  │  Endpoints │  │  Endpoints │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│                        ↓                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Entity Framework Core (EF Core 10)           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────┬───────────────────────────────┘
                              │ Npgsql Driver
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                      │
│  ┌────────┐  ┌────────┐  ┌──────────────┐  ┌──────────┐   │
│  │ Trains │  │Coaches │  │ CrowdReports │  │   SOS    │   │
│  │        │←─┤        │←─┤              │  │ Reports  │   │
│  └────────┘  └────────┘  └──────────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Prerequisites

### Backend Requirements
- **.NET SDK 10.0** or later
- **PostgreSQL 15** or later
- **Visual Studio Code** or any C# IDE (optional)

### Frontend Requirements
- **Flutter SDK 3.8.1** or later
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **Xcode** (for emulators/simulators)
- **VS Code with Flutter extension** (recommended)

### Verify Installations

```bash
# Check .NET version
dotnet --version
# Should show 10.0.x or later

# Check PostgreSQL
psql --version
# Should show PostgreSQL 15.x or later

# Check Flutter
flutter --version
# Should show Flutter 3.8.1 or later

# Check Flutter doctor
flutter doctor
```

## 🚀 Backend Setup

### 1. Database Setup

**Option A: Using PostgreSQL locally**

```bash
# macOS (using Homebrew)
brew install postgresql@15
brew services start postgresql@15

# Create database
createdb trainassist

# Or using psql
psql postgres
CREATE DATABASE trainassist;
\q
```

**Option B: Using Docker**

```bash
docker run --name trainassist-postgres \
  -e POSTGRES_DB=trainassist \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:15
```

### 2. Configure Connection String

Edit `TrainAssist.Api/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=trainassist;Username=postgres;Password=postgres"
  }
}
```

**Note:** Change `postgres` password if you're using a different password.

### 3. Restore Dependencies

```bash
cd TrainAssist/TrainAssist.Api
dotnet restore
```

### 4. Run Database Migrations

```bash
# Create initial migration (already created)
dotnet ef migrations add InitialCreate

# Apply migrations to database
dotnet ef database update
```

### 5. Start the Backend API

```bash
dotnet run
```

The API will be available at:
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:5001`
- Swagger UI: `http://localhost:5000/swagger`

**Expected Output:**

```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5000
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:5001
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

### 6. Verify Backend with Swagger

Open browser: `http://localhost:5000/swagger`

You should see all API endpoints:
- `GET /api/health` - Health check
- `GET /api/trains` - Search trains
- `GET /api/trains/{trainId}/coaches` - Get coaches for a train
- `POST /api/coaches/{coachId}/crowd` - Report crowd status
- `POST /api/sos` - Send SOS alert
- `GET /api/sos` - Get recent SOS reports

## 📱 Frontend Setup

### 1. Navigate to Flutter App

```bash
cd TrainAssist/train_assist_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Base URL

Edit `lib/config/api_config.dart`:

**For Android Emulator:**
```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:5000';
}
```

**For iOS Simulator:**
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:5000';
}
```

**For Physical Device:**
```dart
class ApiConfig {
  // Replace with your computer's IP address
  static const String baseUrl = 'http://192.168.x.x:5000';
}
```

**To find your IP address:**
```bash
# macOS/Linux
ifconfig | grep "inet "

# Windows
ipconfig
```

### 4. Run the Flutter App

**Check available devices:**
```bash
flutter devices
```

**Run on specific device:**
```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode (faster)
flutter run --release
```

### 5. Build APK (Android)

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

## 🧪 Testing Guide

### Backend Testing

#### 1. Test Health Endpoint

```bash
curl http://localhost:5000/api/health
```

**Expected Response:**
```json
{
  "status": "Healthy",
  "version": "1.0.0",
  "timestamp": "2026-02-19T10:30:00Z"
}
```

#### 2. Test Train Search

```bash
# Get all trains
curl http://localhost:5000/api/trains

# Search by source
curl "http://localhost:5000/api/trains?source=CityA"

# Search by destination
curl "http://localhost:5000/api/trains?destination=CityB"
```

**Expected Response:**
```json
[
  {
    "id": 1,
    "trainName": "Express 101",
    "source": "CityA",
    "destination": "CityB",
    "timing": "07:30",
    "platform": "3"
  }
]
```

#### 3. Test Coach List

```bash
curl http://localhost:5000/api/trains/1/coaches
```

**Expected Response:**
```json
[
  {
    "coachId": 1,
    "coachName": "S1",
    "latestStatus": "Low",
    "lastReportedAt": "2026-02-19T06:30:00Z",
    "lastReporterName": "System"
  }
]
```

#### 4. Test Crowd Reporting

```bash
curl -X POST http://localhost:5000/api/coaches/1/crowd \
  -H "Content-Type: application/json" \
  -d '{"reporterName":"John","status":"High"}'
```

#### 5. Test SOS Reporting

```bash
curl -X POST http://localhost:5000/api/sos \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName":"John",
    "trainId":1,
    "coachId":1,
    "latitude":12.9716,
    "longitude":77.5946,
    "message":"Emergency help needed"
  }'
```

### Frontend Testing

#### 1. Run Unit Tests

```bash
cd train_assist_app
flutter test
```

#### 2. Run Flutter Analyze

```bash
flutter analyze
```

#### 3. Manual Testing Flow

1. **Welcome Screen**
   - Open app → Should show "Welcome to Train Assist"
   - Enter name (e.g., "John Doe")
   - Tap "Get Started"
   - Should navigate to Search Screen

2. **Search Trains**
   - Enter Source: "CityA"
   - Enter Destination: "CityB"
   - Tap "Search Trains"
   - Should show list of trains (Express 101, etc.)

3. **View Coach Status**
   - Tap on a train card
   - Should show coaches (S1, S2, S3)
   - Each coach shows color-coded status

4. **Report Crowd Status**
   - Tap "Update Crowd Status" on any coach
   - Select Low/Medium/High
   - Tap Submit
   - Should show success message
   - Coach status should update

5. **SOS Feature**
   - Open drawer menu (hamburger icon)
   - Tap "SOS Emergency"
   - Enter optional message
   - Check "Include my location"
   - Tap "SEND SOS ALERT"
   - Confirm in dialog
   - Should show success message

6. **Recent SOS Reports**
   - From SOS Screen, tap "View Recent SOS Reports"
   - Should show list of recent SOS alerts

7. **Logout**
   - Open drawer → Tap "Logout"
   - Confirm logout
   - Should return to Welcome Screen

## 📚 API Documentation

### Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/trains` | Search trains (optional: source, destination) |
| GET | `/api/trains/{trainId}/coaches` | Get coaches with crowd status |
| POST | `/api/coaches/{coachId}/crowd` | Report crowd status |
| POST | `/api/sos` | Send emergency SOS |
| GET | `/api/sos` | Get recent SOS reports (last 50) |

### Request/Response Examples

See [TrainAssist.Api/README.md](TrainAssist.Api/README.md) for detailed API documentation.

## 🎬 Demo Script

For a complete step-by-step demonstration, see [DEMO_SCRIPT.md](DEMO_SCRIPT.md).

## 🐛 Troubleshooting

### Backend Issues

**Problem: Database connection failed**
```
Solution:
1. Verify PostgreSQL is running: pg_isready
2. Check connection string in appsettings.json
3. Ensure database exists: psql -l | grep trainassist
4. Reset database: dotnet ef database drop, then dotnet ef database update
```

**Problem: Port 5000 already in use**
```
Solution:
1. Find process: lsof -i :5000
2. Kill process: kill -9 <PID>
3. Or change port in Program.cs
```

**Problem: Migration errors**
```
Solution:
1. Delete Migrations folder
2. Run: dotnet ef migrations add InitialCreate
3. Run: dotnet ef database update
```

### Frontend Issues

**Problem: Cannot connect to API**
```
Solution:
1. Verify backend is running: curl http://localhost:5000/api/health
2. Check API base URL in lib/config/api_config.dart
3. Android emulator: Use 10.0.2.2 instead of localhost
4. Physical device: Use computer's IP address (not localhost)
```

**Problem: Hot reload not working**
```
Solution:
1. Press 'r' in terminal to hot reload
2. Press 'R' for hot restart
3. Or restart: flutter run
```

**Problem: Build errors**
```
Solution:
1. Clean build: flutter clean
2. Get dependencies: flutter pub get
3. Rebuild: flutter run
```

**Problem: SharedPreferences not working**
```
Solution:
1. Clear app data on device/emulator
2. Uninstall and reinstall app
3. Check permissions in AndroidManifest.xml
```

## 🔒 Security Notes

⚠️ **This is a prototype, NOT production-ready!**

### Current Limitations:
- **No authentication** - Anyone can submit reports
- **No authorization** - All endpoints are public
- **CORS is wide-open** - Allows all origins
- **No rate limiting** - Susceptible to spam/DoS
- **No input sanitization** - Basic validation only
- **No data encryption** - Passwords stored in plain text
- **No API keys** - No request verification

### Recommendations for Production:
1. Add JWT authentication and authorization
2. Implement API key validation
3. Add rate limiting (e.g., using AspNetCoreRateLimit)
4. Sanitize and validate all inputs
5. Use HTTPS only (disable HTTP)
6. Restrict CORS to specific origins
7. Add logging and monitoring (Application Insights, Serilog)
8. Use environment variables for secrets (not appsettings.json)
9. Add database connection pooling
10. Implement proper error handling and logging

## 📦 Project Structure

```
TrainAssist/
├── TrainAssist.Api/          # Backend API
│   ├── Data/                 # DbContext, DataSeeder
│   ├── DTOs/                 # Request/Response DTOs
│   ├── Models/               # Entity models
│   ├── Migrations/           # EF Core migrations
│   ├── Program.cs            # API endpoints
│   └── appsettings.json      # Configuration
│
├── train_assist_app/         # Flutter app
│   ├── lib/
│   │   ├── config/           # API configuration
│   │   ├── models/           # Data models
│   │   ├── providers/        # State management
│   │   ├── screens/          # UI screens
│   │   ├── services/         # API service
│   │   ├── widgets/          # Reusable widgets
│   │   └── main.dart         # App entry point
│   ├── test/                 # Unit tests
│   └── pubspec.yaml          # Flutter dependencies
│
├── README.md                 # This file
└── DEMO_SCRIPT.md           # Demo guide
```

## 🚧 Known Limitations

1. **Location Services**: Currently uses mock coordinates - needs actual GPS integration
2. **Real-time Updates**: No WebSocket/SignalR - requires manual refresh
3. **Image Upload**: Not implemented - could add photos to SOS reports
4. **Offline Support**: No offline caching - requires internet connection
5. **Push Notifications**: Not implemented - could notify about SOS alerts
6. **User Accounts**: No persistent user accounts - just name storage
7. **Data Validation**: Basic validation - could be more comprehensive
8. **Pagination**: Returns all data - needs pagination for large datasets
9. **Search Filters**: Limited to source/destination - could add date/time filters
10. **Admin Panel**: No admin UI - requires direct database access

## 🔮 Future Enhancements

- User authentication with Firebase/Auth0
- Real-time updates using WebSockets
- Push notifications for SOS alerts
- Geolocation integration for accurate location
- Photo upload for incident reporting
- Admin dashboard for monitoring
- Analytics and reporting
- Multi-language support
- Dark mode
- Accessibility improvements
- Unit and integration tests
- CI/CD pipeline
- Docker containerization
- Cloud deployment (Azure/AWS)

## 📄 License

This is a prototype project for educational purposes. Not licensed for production use.

## 👨‍💻 Development

### Backend Stack
- ASP.NET Core 10.0 (Minimal API)
- Entity Framework Core 10.0.3
- PostgreSQL with Npgsql driver
- Swagger/OpenAPI for documentation

### Frontend Stack
- Flutter 3.8.1
- Dart with null-safety
- Provider for state management
- HTTP for API communication
- SharedPreferences for local storage
- Material Design 3

## 📞 Support

For issues and questions:
1. Check Troubleshooting section above
2. Review DEMO_SCRIPT.md for usage examples
3. Check API documentation in Swagger
4. Review logs in backend console

---

**Built with ❤️ using Flutter and ASP.NET Core**

*Last Updated: February 19, 2026*
