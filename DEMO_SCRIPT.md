# Train Assist - Demo Script

This guide provides a complete walkthrough to demonstrate all features of the Train Assist application.

## Prerequisites

Before starting the demo:

1. ✅ PostgreSQL is running
2. ✅ Backend API is running (`dotnet run` in TrainAssist.Api)
3. ✅ Backend is accessible at http://localhost:5000
4. ✅ Flutter app is ready to run
5. ✅ Device/emulator is connected

## Quick Start

```bash
# Terminal 1: Start Backend
cd TrainAssist/TrainAssist.Api
dotnet run

# Terminal 2: Start Flutter App
cd TrainAssist/train_assist_app
flutter run
```

---

## Demo Flow (15-20 minutes)

### Part 1: Backend Verification (3 minutes)

#### Step 1.1: Verify API Health

Open browser: `http://localhost:5000/swagger`

- ✅ Swagger UI should load
- ✅ All 6 endpoints should be visible

#### Step 1.2: Test Health Endpoint

In Swagger, expand `GET /api/health`:
- Click "Try it out"
- Click "Execute"
- **Expected Response:**
  ```json
  {
    "status": "Healthy",
    "version": "1.0.0",
    "timestamp": "2026-02-19T..."
  }
  ```

#### Step 1.3: Verify Seed Data

Expand `GET /api/trains`:
- Click "Try it out"
- Leave parameters empty
- Click "Execute"
- **Expected:** 3 trains (Express 101, InterCity 202, Local 303)

---

### Part 2: First Time User Experience (4 minutes)

#### Step 2.1: Launch App

```bash
flutter run
```

**Expected:** Welcome Screen with gradient background

#### Step 2.2: Enter User Name

- **Screen:** Welcome to Train Assist
- **Action:** Enter name "Demo User" in text field
- **Verify:** "Get Started" button is visible
- Click "Get Started"
- **Expected:** Navigate to Search Screen

#### Step 2.3: Explore Search Screen

- **Screen:** Search Trains (with AppBar)
- **Verify:** 
  - Two text fields (Source and Destination)
  - Search button present
  - Drawer menu icon (hamburger) visible
  - SOS emergency icon in AppBar
  - Profile icon in AppBar

---

### Part 3: Train Search and Navigation (5 minutes)

#### Step 3.1: Search All Trains

- **Action:** Click "Search Trains" (with empty fields)
- **Expected:** Show SnackBar: "Please enter source or destination"

#### Step 3.2: Search by Source

- **Action:** 
  - Enter Source: "CityA"
  - Click "Search Trains"
- **Expected:** 
  - Loading indicator briefly appears
  - 2 train cards displayed (Express 101, InterCity 202)
  - Each card shows:
    * Train icon
    * Train name (bold)
    * Source → Destination with arrow
    * Timing and Platform info

#### Step 3.3: Search by Destination

- **Action:**
  - Clear Source field
  - Enter Destination: "CityB"
  - Click "Search Trains"
- **Expected:** 
  - 1 train card (Express 101)

#### Step 3.4: Pull to Refresh

- **Action:** Pull down on the train list
- **Expected:** Refresh indicator, then re-fetches results

---

### Part 4: Coach Status and Crowd Reporting (5 minutes)

#### Step 4.1: View Coach List

- **Action:** Tap on "Express 101" card
- **Expected:** Navigate to Coach List Screen
- **Screen Shows:**
  - AppBar: "Express 101"
  - Train details at top
  - 3 coach cards (S1, S2, S3)
  - Each coach has:
    * Coach name
    * Colored status chip (Green/Orange/Red)
    * Last reported info
    * "Update Crowd Status" button

#### Step 4.2: Update Crowd Status - Low

- **Action:** Tap "Update Crowd Status" on S1
- **Expected:** Dialog appears with title "Update Crowd Status for S1"
- **Dialog Contains:**
  - Coach name
  - 3 buttons: Low (Green), Medium (Orange), High (Red)
  - Cancel button
- **Action:** Click "Low" button
- **Expected:**
  - Dialog closes
  - Success SnackBar: "Crowd status updated successfully!"
  - Coach list refreshes
  - S1 now shows GREEN chip
  - Last reported info updated to "Demo User" and current time

#### Step 4.3: Update Crowd Status - High

- **Action:** Tap "Update Crowd Status" on S2
- **Action:** Click "High" button
- **Expected:**
  - S2 now shows RED chip
  - Success message appears

#### Step 4.4: Verify Relative Timestamps

- **Verify:** Each coach shows "Just now" or "X minutes ago"

---

### Part 5: Drawer Menu Navigation (3 minutes)

#### Step 5.1: Open Drawer

- **Action:** Click hamburger icon (top-left) or swipe from left
- **Expected:** Drawer opens with:
  - Header with gradient background
  - User avatar icon
  - User name: "Demo User"
  - Menu items:
    * Search Trains (selected/highlighted)
    * SOS Emergency (red icon)
    * Recent SOS Reports
    * About
    * Logout (red icon)

#### Step 5.2: Navigate to About

- **Action:** Tap "About"
- **Expected:** About dialog appears with:
  - App name: "Train Assist"
  - Version: "1.0.0"
  - Train icon
  - Description text

---

### Part 6: Emergency SOS Feature (5 minutes)

#### Step 6.1: Open SOS Screen

- **Action:** From drawer, tap "SOS Emergency"
- **Expected:** Navigate to Emergency SOS Screen
- **Screen Shows:**
  - Red AppBar: "Emergency SOS"
  - Large red warning icon (120px)
  - Title: "Emergency SOS" in red
  - Info card explaining SOS feature
  - Message text field (optional)
  - "Include my location" checkbox
  - Large red "SEND SOS ALERT" button
  - "View Recent SOS Reports" button at bottom

#### Step 6.2: Send SOS Alert (Without Message)

- **Action:** Click "SEND SOS ALERT"
- **Expected:** Confirmation dialog appears
  - Title: "Confirm SOS Alert"
  - Warning icon
  - Message: "Are you sure you want to send..."
  - Cancel and "Send Alert" buttons
- **Action:** Click "Send Alert"
- **Expected:**
  - Loading indicator appears briefly
  - Success SnackBar: "🚨 SOS Alert sent successfully!"
  - Message field is cleared
  - Checkbox is unchecked

#### Step 6.3: Send SOS Alert (With Message and Location)

- **Action:** 
  - Enter message: "Medical emergency in coach S1"
  - Check "Include my location"
  - Click "SEND SOS ALERT"
- **Action:** Confirm in dialog
- **Expected:** 
  - Success message
  - Alert sent with message and location

#### Step 6.4: View Recent SOS Reports

- **Action:** Click "View Recent SOS Reports"
- **Expected:** Navigate to Recent SOS Reports Screen
- **Screen Shows:**
  - Red AppBar: "Recent SOS Reports"
  - List of SOS cards (2 items from previous steps)
  - Each card shows:
    * Red emergency icon
    * "SOS from Demo User"
    * Message (if provided)
    * Relative timestamp
    * Location coordinates (if included)

#### Step 6.5: Pull to Refresh SOS Reports

- **Action:** Pull down on SOS reports list
- **Expected:** Refreshes and reloads reports

---

### Part 7: User Profile and Logout (2 minutes)

#### Step 7.1: View Profile

- **Action:** From Search Screen, tap profile icon (top-right)
- **Expected:** Profile dialog shows
  - "Logged in as: Demo User"

#### Step 7.2: Logout

- **Action:** 
  - Open drawer
  - Tap "Logout"
- **Expected:** Confirmation dialog appears
  - "Are you sure you want to logout?"
  - Cancel and Logout buttons
- **Action:** Click "Logout"
- **Expected:**
  - Navigate back to Welcome Screen
  - Name field is empty

#### Step 7.3: Verify Persistence

- **Action:** 
  - Enter name again: "Test User 2"
  - Click "Get Started"
- **Action:** 
  - Hot restart the app (press 'R' in terminal)
- **Expected:** 
  - App opens directly to Search Screen (not Welcome)
  - Drawer shows "Test User 2"

---

## Advanced Demo Scenarios

### Scenario A: Multiple Users Reporting

**Setup:** Have Swagger open alongside the app

1. In App: Update S1 to "High"
2. In Swagger: Use `POST /api/coaches/1/crowd` with different reporterName
   ```json
   {
     "reporterName": "John Smith",
     "status": "Medium"
   }
   ```
3. In App: Pull to refresh on Coach List
4. **Verify:** S1 now shows "Medium" and "John Smith"

### Scenario B: Search Different Routes

1. Search "CityA" → "CityB": Should show Express 101
2. Search "CityA" → "CityC": Should show InterCity 202
3. Search "CityB" → anything: Should show Local 303
4. Clear both fields and search: Should show error

### Scenario C: Rapid Status Updates

1. Open Coach List for any train
2. Rapidly update all 3 coaches:
   - S1 → Low
   - S2 → Medium
   - S3 → High
3. **Verify:** All updates succeed, chips show correct colors

### Scenario D: SOS from Different Screens

1. From Search Screen: Tap SOS icon in AppBar
2. Send SOS
3. Go back, search train, open coaches
4. From drawer: Open SOS again
5. **Verify:** Both navigation paths work correctly

---

## Validation Checklist

Use this checklist to ensure all features work:

### Welcome Screen
- [ ] Gradient background displays correctly
- [ ] Train icon visible
- [ ] Name field accepts input
- [ ] Validation prevents empty name
- [ ] "Get Started" navigates to Search

### Search Screen
- [ ] Source and destination fields work
- [ ] Search button triggers API call
- [ ] Loading indicator shows during search
- [ ] Train cards display correctly
- [ ] Error message for empty search
- [ ] Pull-to-refresh works
- [ ] Drawer menu opens
- [ ] SOS icon navigates to SOS screen
- [ ] Profile icon shows user dialog

### Coach List Screen
- [ ] Train details display at top
- [ ] All coaches load correctly
- [ ] Status chips show correct colors
- [ ] Relative timestamps format correctly
- [ ] Update dialog opens
- [ ] All status updates work (Low/Medium/High)
- [ ] Success/error messages appear
- [ ] List auto-refreshes after update

### SOS Screen
- [ ] Red warning theme throughout
- [ ] Warning icon displays
- [ ] Message field accepts input (500 char limit)
- [ ] Location checkbox works
- [ ] Confirmation dialog shows
- [ ] Cancel works in dialog
- [ ] Send alert succeeds
- [ ] Success/failure messages show
- [ ] Fields clear after success
- [ ] Recent reports button works

### Recent SOS Reports
- [ ] Reports list loads
- [ ] Empty state shows when no reports
- [ ] Cards show all report details
- [ ] Timestamps are relative
- [ ] Location displays when included
- [ ] Pull-to-refresh works
- [ ] Loading and error states work

### Drawer Menu
- [ ] Header shows user info
- [ ] All menu items present
- [ ] Current screen is highlighted
- [ ] Navigation works for all items
- [ ] About dialog shows correctly
- [ ] Logout confirmation works
- [ ] Logout returns to Welcome

### Data Persistence
- [ ] User name saves locally
- [ ] App remembers logged-in state
- [ ] Hot reload preserves state
- [ ] Logout clears saved data
- [ ] Re-login saves new name

---

## Common Demo Issues and Solutions

### Issue 1: Cannot Connect to API
**Symptoms:** All API calls fail, error messages in app

**Solutions:**
1. Verify backend is running: `curl http://localhost:5000/api/health`
2. Check API base URL in `lib/config/api_config.dart`
3. Android emulator: Must use `10.0.2.2` not `localhost`
4. iOS simulator: Can use `localhost`
5. Physical device: Use computer's IP address

### Issue 2: No Trains Show Up
**Symptoms:** Search returns empty list

**Solutions:**
1. Check backend logs for errors
2. Verify seed data: Open Swagger → GET /api/trains
3. Check database: `psql trainassist -c "SELECT * FROM \"Trains\";"`
4. Re-run seeder: Restart backend API

### Issue 3: Status Updates Don't Reflect
**Symptoms:** Update succeeds but UI doesn't change

**Solutions:**
1. Check network tab for 201 Created response
2. Manually pull-to-refresh
3. Navigate away and back
4. Check backend logs for errors

### Issue 4: SOS Doesn't Send
**Symptoms:** Send SOS fails

**Solutions:**
1. Check backend logs for exceptions
2. Verify user name is set (not null)
3. Check network connectivity
4. Try with minimal data (no message/location)

### Issue 5: App Crashes on Startup
**Symptoms:** App won't launch or crashes immediately

**Solutions:**
1. `flutter clean && flutter pub get`
2. Delete app from device/emulator
3. Rebuild: `flutter run`
4. Check console for stack traces

---

## Performance Benchmarks

Expected performance metrics:

| Operation | Expected Time | Acceptable Range |
|-----------|---------------|------------------|
| App startup | < 2 seconds | 1-3 seconds |
| Search trains | < 1 second | 0.5-2 seconds |
| Load coaches | < 1 second | 0.5-2 seconds |
| Update status | < 1 second | 0.5-2 seconds |
| Send SOS | < 1 second | 0.5-2 seconds |
| Load SOS reports | < 1 second | 0.5-2 seconds |

---

## Screenshots Checklist

For documentation or presentation, capture these screens:

1. **Welcome Screen** - First impression
2. **Search Screen** - With train results
3. **Coach List** - Showing color-coded statuses
4. **Update Dialog** - Status selection
5. **SOS Screen** - Main emergency UI
6. **SOS Confirmation** - Dialog before send
7. **Recent SOS Reports** - List view
8. **Drawer Menu** - Navigation menu
9. **About Dialog** - App info
10. **Swagger UI** - API documentation

---

## Demo Tips

### For Live Presentations:

1. **Prepare ahead:**
   - Start backend before presentation
   - Have emulator/device ready and visible
   - Clear any old test data if needed
   - Have Swagger open in browser

2. **During demo:**
   - Explain each screen briefly before interacting
   - Point out Material Design elements
   - Highlight color coding (Green/Orange/Red)
   - Emphasize the emergency/SOS features
   - Show both app UI and Swagger together

3. **If something fails:**
   - Have Swagger as backup to show API works
   - Explain the backend/frontend architecture
   - Show the code structure as alternative

4. **Key talking points:**
   - Real-world problem solving (crowd reporting)
   - Safety feature (SOS)
   - Clean architecture (MVVM with Provider)
   - RESTful API design
   - Responsive Material Design
   - Proper error handling
   - State management best practices

---

## Post-Demo Cleanup

```bash
# Stop backend
# Press Ctrl+C in backend terminal

# Stop Flutter app
# Press 'q' in Flutter terminal

# Optional: Reset database
cd TrainAssist/TrainAssist.Api
dotnet ef database drop --force
dotnet ef database update

# Optional: Clear app data
# Uninstall app from device/emulator
```

---

## Extended Demo (30+ minutes)

For a more thorough demonstration, add these scenarios:

### Backend Integration Demo

1. Show Program.cs explaining minimal API structure
2. Open PostgreSQL and show database tables
3. Demonstrate adding a new train via Swagger
4. Show it appear in the app immediately

### Code Walkthrough

1. Show Provider pattern implementation
2. Explain API service architecture
3. Demonstrate hot reload capability
4. Show widget composition

### Error Handling Demo

1. Stop backend → Show error messages in app
2. Invalid data → Show validation messages
3. Network timeout → Show timeout handling

### Data Flow Demo

1. User updates status in app
2. Show POST request in backend logs
3. Show new row in database
4. Show updated data in Swagger GET
5. Refresh app to see update

---

**Demo Script Complete!**

*This script covers all major features and provides comprehensive testing scenarios. Adapt timing and depth based on your audience.*

**Last Updated:** February 19, 2026
