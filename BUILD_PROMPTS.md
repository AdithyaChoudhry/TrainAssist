# Train Assist - Development Prompts Sequence

## Overview
These prompts will guide you through building the Train Assist prototype with Flutter frontend and ASP.NET Core backend with PostgreSQL.

---

## PROMPT 1: Backend Project Setup
```
Create a new ASP.NET Core minimal API project called "TrainAssist.Api" in the TrainAssist workspace.

Requirements:
- Use .NET 7 or later with C# 11
- Set up the project structure with folders: Models, Data, DTOs, Services
- Configure the project to run on HTTP port 5000 and HTTPS port 5001
- Add the following NuGet packages:
  * Microsoft.EntityFrameworkCore
  * Npgsql.EntityFrameworkCore.PostgreSQL
  * Microsoft.EntityFrameworkCore.Design
  * Swashbuckle.AspNetCore (for Swagger)
- Create appsettings.json with a PostgreSQL connection string: "Host=localhost;Database=trainassist;Username=postgres;Password=postgres"
- Create appsettings.Development.json with detailed logging configuration
- Set up basic Program.cs with:
  * Swagger configuration
  * CORS policy allowing all origins (for development)
  * Console logging for all requests

Don't implement the models or database yet, just set up the project structure and configuration.
```

---

## PROMPT 2: Database Models and DbContext
```
In the TrainAssist.Api project, create the following entity models in the Models folder:

1. User.cs:
   - Id (Guid, primary key)
   - Name (string, required, max 100)
   - Phone (string, nullable, max 20)

2. Train.cs:
   - Id (int, primary key, auto-increment)
   - TrainName (string, required, max 100)
   - Source (string, required, max 100)
   - Destination (string, required, max 100)
   - Timing (string, required, max 10) // e.g., "07:30"
   - Platform (string, nullable, max 10)
   - Coaches (navigation property: List<Coach>)

3. Coach.cs:
   - Id (int, primary key, auto-increment)
   - TrainId (int, foreign key to Train)
   - CoachName (string, required, max 10) // e.g., "S1", "S2"
   - Train (navigation property)
   - CrowdReports (navigation property: List<CrowdReport>)

4. CrowdReport.cs:
   - Id (int, primary key, auto-increment)
   - CoachId (int, foreign key to Coach)
   - ReporterName (string, required, max 100)
   - Status (string, required) // "Low", "Medium", "High"
   - Timestamp (DateTime, required, defaults to UTC now)
   - Coach (navigation property)

5. SOSReport.cs:
   - Id (int, primary key, auto-increment)
   - ReporterName (string, required, max 100)
   - TrainId (int?, nullable foreign key)
   - CoachId (int?, nullable foreign key)
   - Latitude (double?, nullable)
   - Longitude (double?, nullable)
   - Message (string, nullable, max 500)
   - Timestamp (DateTime, required, defaults to UTC now)
   - Train (navigation property, nullable)
   - Coach (navigation property, nullable)

Create AppDbContext.cs in the Data folder:
- Inherit from DbContext
- Add DbSet properties for each model
- Configure entity relationships using Fluent API in OnModelCreating
- Add indexes on TrainId, CoachId where needed
- Configure cascade delete appropriately
```

---

## PROMPT 3: Database Migration and Seed Data
```
In the TrainAssist.Api project:

1. Create a DataSeeder.cs class in the Data folder with a static method SeedData(AppDbContext context) that:
   - Checks if data already exists (if Trains.Any() return)
   - Seeds 3 trains:
     * Train 1: "Express 101", "CityA" to "CityB", "07:30", Platform "3"
     * Train 2: "InterCity 202", "CityA" to "CityC", "09:15", Platform "1"
     * Train 3: "Local 303", "CityB" to "CityD", "12:00", Platform "2"
   - For each train, create 3 coaches: S1, S2, S3
   - For each coach, create 1 initial CrowdReport with:
     * ReporterName: "System"
     * Status: Mix of "Low", "Medium", "High" (vary them)
     * Timestamp: Current UTC time minus random hours (1-5 hours ago)
   - Save all changes

2. Update Program.cs to:
   - Register AppDbContext with PostgreSQL
   - After app.Build(), create a scope and call DataSeeder.SeedData
   - Ensure database is created (context.Database.EnsureCreated())

3. Generate and apply the initial migration:
   - Create migration named "InitialCreate"
   - Provide the dotnet commands to run the migration
```

---

## PROMPT 4: DTOs and Response Models
```
In the TrainAssist.Api project, create a DTOs folder with the following response/request classes:

Response DTOs:
1. TrainResponseDto.cs:
   - Id, TrainName, Source, Destination, Timing, Platform

2. CoachStatusDto.cs:
   - CoachId, CoachName, LatestStatus, LastReportedAt, LastReporterName

3. CrowdReportResponseDto.cs:
   - Id, CoachId, ReporterName, Status, Timestamp

4. SOSReportResponseDto.cs:
   - Id, ReporterName, TrainId, CoachId, Latitude, Longitude, Message, Timestamp

Request DTOs:
1. CrowdReportRequestDto.cs:
   - ReporterName (required)
   - Status (required, must be "Low" | "Medium" | "High")

2. SOSReportRequestDto.cs:
   - ReporterName (required)
   - TrainId (optional)
   - CoachId (optional)
   - Latitude (optional)
   - Longitude (optional)
   - Message (optional)

Add data annotations for validation (Required, StringLength, Range) where appropriate.
```

---

## PROMPT 5: Backend API Endpoints - Part 1 (Train & Coach)
```
In the TrainAssist.Api Program.cs, implement the following API endpoints:

1. GET /api/trains
   - Query parameters: source (optional), destination (optional)
   - If both empty, return all trains
   - If provided, filter by source AND/OR destination (case-insensitive contains)
   - Map to TrainResponseDto list
   - Return 200 OK
   - Log to console: "GET /api/trains - Source: {source}, Destination: {destination}"

2. GET /api/trains/{trainId}/coaches
   - Path parameter: trainId (int)
   - Return 404 if train not found
   - For each coach, get the latest CrowdReport (by Timestamp DESC)
   - Map to CoachStatusDto with: CoachId, CoachName, LatestStatus, LastReportedAt, LastReporterName
   - Return 200 OK with list
   - Log to console: "GET /api/trains/{trainId}/coaches"

Use dependency injection for AppDbContext. Add appropriate error handling with try-catch blocks.
```

---

## PROMPT 6: Backend API Endpoints - Part 2 (Crowd Reports)
```
In the TrainAssist.Api Program.cs, implement:

POST /api/coaches/{coachId}/crowd
- Path parameter: coachId (int)
- Request body: CrowdReportRequestDto
- Validate:
  * Coach exists (return 404 if not)
  * Status is "Low", "Medium", or "High" (case-insensitive, return 400 if invalid)
  * ReporterName is not empty (return 400 if empty)
- Create new CrowdReport entity:
  * CoachId = coachId
  * ReporterName = from request
  * Status = normalized to "Low"/"Medium"/"High"
  * Timestamp = DateTime.UtcNow
- Save to database
- Map to CrowdReportResponseDto
- Return 201 Created
- Log to console: "POST /api/coaches/{coachId}/crowd - Reporter: {name}, Status: {status}"

Add input validation and proper error responses with problem details.
```

---

## PROMPT 7: Backend API Endpoints - Part 3 (SOS)
```
In the TrainAssist.Api Program.cs, implement:

1. POST /api/sos
   - Request body: SOSReportRequestDto
   - Validate:
     * ReporterName is required (return 400 if empty)
     * If TrainId provided, verify train exists (return 404 if not found)
     * If CoachId provided, verify coach exists (return 404 if not found)
   - Create new SOSReport entity with all fields
   - Timestamp = DateTime.UtcNow
   - Save to database
   - Map to SOSReportResponseDto
   - Return 201 Created
   - Log to console: "🚨 SOS REPORT - Reporter: {name}, Train: {trainId}, Coach: {coachId}, Message: {message}"

2. GET /api/sos
   - Return last 50 SOS reports ordered by Timestamp DESC
   - Map to SOSReportResponseDto list
   - Return 200 OK
   - Include related Train/Coach names if available

Add comprehensive logging and error handling.
```

---

## PROMPT 8: Backend Testing and Documentation
```
In the TrainAssist.Api project:

1. Ensure Swagger is fully configured:
   - Add XML comments support
   - Add example values for request DTOs
   - Group endpoints by tags (Trains, Coaches, SOS)

2. Create a README.md in the TrainAssist.Api folder with:
   - Prerequisites (PostgreSQL installation)
   - Database setup instructions
   - How to run the project (dotnet restore, dotnet run)
   - Base URLs (http://localhost:5000, https://localhost:5001)
   - Swagger URL (/swagger/index.html)
   - Sample curl commands for each endpoint
   - Example requests and responses

3. Add a docker-compose.yml file (optional) to run PostgreSQL:
   - PostgreSQL 15 image
   - Environment variables for database name, user, password
   - Port mapping 5432:5432
   - Volume for data persistence

Test all endpoints manually via Swagger and document any issues.
```

---

## PROMPT 9: Flutter Project Setup
```
Create a new Flutter project called "train_assist_app" in the TrainAssist workspace.

Requirements:
- Use Flutter stable channel with null-safety
- Create the following folder structure:
  * lib/models/ - data models
  * lib/services/ - API service classes
  * lib/providers/ - state management
  * lib/screens/ - UI screens
  * lib/widgets/ - reusable widgets
  * lib/config/ - configuration constants

- Add the following dependencies to pubspec.yaml:
  * http: ^1.1.0
  * provider: ^6.1.0
  * shared_preferences: ^2.2.0
  * intl: ^0.18.0 (for date formatting)

- Create lib/config/api_config.dart:
  * Define baseUrl constant (default: "http://localhost:5000")
  * Add note about using "http://10.0.2.2:5000" for Android emulator
  * Add note about using local IP for physical devices

- Set up basic main.dart with:
  * MaterialApp
  * Provider setup (ChangeNotifierProvider)
  * Theme configuration (primary color, app bar theme)

Don't create the screens yet, just the project structure.
```

---

## PROMPT 10: Flutter Models
```
In the train_assist_app project, create the following model classes in lib/models/:

1. train_model.dart:
   - Train class with: id, trainName, source, destination, timing, platform
   - factory Train.fromJson(Map<String, dynamic> json)
   - Map<String, dynamic> toJson()

2. coach_model.dart:
   - Coach class with: coachId, coachName, latestStatus, lastReportedAt, lastReporterName
   - factory Coach.fromJson(Map<String, dynamic> json)
   - Add a getter for color based on status: Green for "Low", Yellow/Orange for "Medium", Red for "High"

3. crowd_report_model.dart:
   - CrowdReport class with: id, coachId, reporterName, status, timestamp
   - factory CrowdReport.fromJson(Map<String, dynamic> json)
   - Map<String, dynamic> toJson()

4. sos_report_model.dart:
   - SOSReport class with: id, reporterName, trainId, coachId, latitude, longitude, message, timestamp
   - factory SOSReport.fromJson(Map<String, dynamic> json)
   - Map<String, dynamic> toJson()

All DateTime fields should handle ISO 8601 string parsing. Use proper null-safety.
```

---

## PROMPT 11: Flutter API Service
```
In the train_assist_app project, create lib/services/api_service.dart:

Implement an ApiService class with the following methods:

1. Future<List<Train>> searchTrains({String? source, String? destination})
   - Call GET /api/trains with query parameters
   - Parse JSON response to List<Train>
   - Handle errors with try-catch, return empty list on error

2. Future<List<Coach>> getCoaches(int trainId)
   - Call GET /api/trains/{trainId}/coaches
   - Parse JSON response to List<Coach>
   - Handle 404 and other errors

3. Future<bool> reportCrowd(int coachId, String reporterName, String status)
   - Call POST /api/coaches/{coachId}/crowd
   - Send JSON body with reporterName and status
   - Return true on success (201), false on error
   - Log errors to console

4. Future<bool> reportSOS({
     required String reporterName,
     int? trainId,
     int? coachId,
     double? latitude,
     double? longitude,
     String? message
   })
   - Call POST /api/sos
   - Send JSON body with all fields
   - Return true on success, false on error

5. Future<List<SOSReport>> getRecentSOS()
   - Call GET /api/sos
   - Parse to List<SOSReport>
   - Handle errors

Use http package for all requests. Add proper headers (Content-Type: application/json). Include timeout handling (10 seconds).
```

---

## PROMPT 12: Flutter State Management
```
In the train_assist_app project, create providers in lib/providers/:

1. user_provider.dart (extends ChangeNotifier):
   - String? userName
   - Future<void> saveUserName(String name) - save to SharedPreferences
   - Future<void> loadUserName() - load from SharedPreferences
   - bool get isUserSet => userName != null && userName!.isNotEmpty

2. train_provider.dart (extends ChangeNotifier):
   - List<Train> trains
   - bool isLoading
   - String? errorMessage
   - Future<void> searchTrains(String? source, String? destination)
     * Set isLoading = true
     * Call ApiService.searchTrains
     * Update trains list
     * Set isLoading = false
     * Call notifyListeners()

3. coach_provider.dart (extends ChangeNotifier):
   - List<Coach> coaches
   - bool isLoading
   - Future<void> loadCoaches(int trainId)
   - Future<bool> submitCrowdReport(int coachId, String reporterName, String status)
     * Call ApiService.reportCrowd
     * If success, reload coaches for that train
     * Return success status

Set up all providers in main.dart using MultiProvider.
```

---

## PROMPT 13: Flutter UI - Welcome Screen
```
In the train_assist_app project, create lib/screens/welcome_screen.dart:

Design:
- AppBar with title "Train Assist"
- Center content with:
  * App logo or icon (use Icons.train)
  * Welcome text
  * TextField for entering name (with validation)
  * "Get Started" button
- When button pressed:
  * Validate name is not empty
  * Save name using UserProvider
  * Navigate to SearchScreen

Use Material Design widgets, proper padding, and a clean layout. Add a gradient background for visual appeal.
```

---

## PROMPT 14: Flutter UI - Search Screen
```
Create lib/screens/search_screen.dart:

Design:
- AppBar with title "Search Trains" and actions menu (SOS button, view profile)
- Body with:
  * Two TextFields: Source and Destination (with icons)
  * "Search Trains" elevated button
  * When results available, show ListView of train cards
- Each train card shows:
  * Train name (bold, large)
  * Source → Destination with arrow icon
  * Timing and Platform
  * Tap card to navigate to CoachListScreen
- Show loading indicator while searching
- Show "No trains found" message if empty
- Pull-to-refresh to reload

Use Provider.of<TrainProvider> to access state. Show SnackBar for errors.
```

---

## PROMPT 15: Flutter UI - Coach List Screen
```
Create lib/screens/coach_list_screen.dart:

Design:
- AppBar with train name as title and back button
- Display train details at top (source, destination, timing, platform)
- ListView of coach cards with:
  * Coach name (e.g., "S1") in bold
  * Status chip with color: Green (Low), Orange (Medium), Red (High)
  * Last reported info: "Reported by {name} at {time}"
  * "Update Crowd Status" button
- When update button pressed, show dialog with:
  * Three option buttons: Low (green), Medium (orange), High (red)
  * Submit button
  * Cancel button
- After successful report:
  * Show success SnackBar
  * Reload coaches to show updated status

Use CoachProvider for state. Format timestamps with intl package ("2 hours ago" style).
```

---

## PROMPT 16: Flutter UI - SOS Screen
```
Create lib/screens/sos_screen.dart:

Design:
- AppBar with title "Emergency SOS" in red
- Body with:
  * Large warning icon (Icons.warning_amber_rounded) in red
  * Explanatory text about SOS feature
  * Large red "SEND SOS ALERT" button (takes most of screen space)
  * Optional: TextField for additional message
  * Optional: "Include Location" checkbox
- When SOS button pressed:
  * Show confirmation dialog "Are you sure?"
  * If confirmed:
    - Call ApiService.reportSOS with userName from UserProvider
    - Show success/failure SnackBar
    - Log the action
- Bottom section: "Recent SOS Reports" button to view GET /api/sos results

Make the UI visually alarming with red theme to emphasize emergency nature.
```

---

## PROMPT 17: Flutter UI - Navigation and Polish
```
In the train_assist_app project:

1. Set up navigation in main.dart:
   - Initial route based on UserProvider.isUserSet
   - Define named routes for all screens
   - Add proper route transitions

2. Create lib/widgets/custom_widgets.dart with reusable components:
   - StatusChip widget (shows colored chip based on status)
   - TrainCard widget (reusable train display card)
   - LoadingOverlay widget

3. Add a drawer menu to SearchScreen:
   - User profile (show name)
   - Search Trains (current screen)
   - SOS Emergency
   - Recent SOS Reports
   - About app
   - Logout (clear username)

4. Polish the UI:
   - Consistent color scheme throughout
   - Proper error handling and user feedback
   - Loading states for all async operations
   - Form validation with helpful error messages
   - Smooth animations and transitions

5. Update main.dart to check for saved username on startup and route accordingly.
```

---

## PROMPT 18: Integration Testing and README
```
Complete the Train Assist project:

1. Test the complete flow:
   - Start PostgreSQL database
   - Run backend (dotnet run)
   - Verify Swagger at http://localhost:5000/swagger
   - Test all API endpoints via Swagger
   - Run Flutter app on emulator/device
   - Update ApiConfig with correct base URL
   - Test complete user flow: Welcome → Search → Coaches → Report → SOS

2. Create /TrainAssist/README.md with:
   - Project overview and architecture diagram (ASCII)
   - Prerequisites (PostgreSQL, .NET 7+, Flutter SDK)
   - Backend setup instructions:
     * Database setup
     * Connection string configuration
     * Running migrations
     * Starting the API
   - Frontend setup instructions:
     * Flutter dependencies
     * API base URL configuration (emulator vs device)
     * Running the app
   - Testing guide:
     * Sample test scenarios
     * Expected results
   - Demo script (step-by-step demonstration)
   - Troubleshooting common issues
   - API documentation (endpoint summary)

3. Create a DEMO_SCRIPT.md with detailed steps to showcase all features.

4. Fix any bugs found during testing and document known limitations.
```

---

## PROMPT 19: Docker Setup (Optional Enhancement)
```
Add Docker support to the Train Assist project:

1. In TrainAssist.Api folder, create Dockerfile:
   - Multi-stage build (build and runtime)
   - Use mcr.microsoft.com/dotnet/sdk:7.0 for build
   - Use mcr.microsoft.com/dotnet/aspnet:7.0 for runtime
   - Expose ports 5000 and 5001
   - Set environment variables

2. Create docker-compose.yml in root:
   - Service for PostgreSQL (with volume)
   - Service for backend API (depends on postgres)
   - Network configuration
   - Environment variable configuration

3. Add .dockerignore file

4. Update README with Docker instructions:
   - docker-compose up command
   - Accessing services
   - Stopping and cleaning up

Test the Docker setup to ensure it works correctly.
```

---

## PROMPT 20: Final Improvements and Deployment Prep
```
Finalize the Train Assist project:

1. Code quality improvements:
   - Add XML documentation comments to all backend methods
   - Add code comments for complex logic
   - Ensure consistent naming conventions
   - Remove any debug code or console.log statements

2. Add backend health check endpoint:
   - GET /api/health
   - Returns API version, database connection status, timestamp

3. Flutter improvements:
   - Add app icon (use flutter_launcher_icons package)
   - Add splash screen
   - Implement proper error boundaries
   - Add offline detection and user feedback

4. Create CHANGELOG.md documenting:
   - Initial release features
   - Known limitations
   - Future enhancements planned

5. Security notes in README:
   - This is a prototype, not production-ready
   - No authentication implemented
   - CORS is wide-open for development
   - Recommendations for production deployment

6. Performance optimizations:
   - Add database indexes if missing
   - Implement caching where appropriate
   - Optimize queries with Include() for related data

7. Final testing checklist and sign-off.
```

---

## Notes for Using These Prompts

### Recommended Execution Order:
1. Execute prompts 1-8 sequentially for backend
2. Test backend thoroughly with Swagger
3. Execute prompts 9-12 for Flutter foundation
4. Execute prompts 13-17 for Flutter UI
5. Execute prompt 18 for integration and documentation
6. Optionally execute 19-20 for enhancements

### Tips:
- After each prompt, verify the output works before proceeding
- Adjust API base URLs based on your testing environment
- PostgreSQL must be running before backend starts
- Use Android emulator's 10.0.2.2 or device's local IP for API calls
- Test each API endpoint in Swagger before integrating with Flutter

### Expected Timeline:
- Backend setup and API: 2-3 hours
- Flutter app development: 3-4 hours  
- Integration and testing: 1-2 hours
- Total: ~6-9 hours for complete working prototype

---

**Last Updated:** February 19, 2026
