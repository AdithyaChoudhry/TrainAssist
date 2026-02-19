# API Endpoints Testing Guide

## Prerequisites

Make sure PostgreSQL is running and the API is started:

```bash
# Start PostgreSQL (choose one method from DATABASE_SETUP.md)
brew services start postgresql@15
# OR
docker-compose up -d

# Run the API
cd /Users/adithyachoudhrym/TrainAssist/TrainAssist.Api
export PATH="$PATH:/Users/adithyachoudhrym/.dotnet/tools"
dotnet ef database update  # First time only
dotnet run
```

Access Swagger UI at: http://localhost:5000/swagger

---

## Implemented Endpoints

### 1. GET /api/health
**Purpose:** Health check endpoint

**Test:**
```bash
curl http://localhost:5000/api/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-02-19T07:50:00Z",
  "version": "1.0.0"
}
```

---

### 2. GET /api/trains
**Purpose:** Search trains by source and/or destination

**Test Cases:**

**A. Get all trains:**
```bash
curl http://localhost:5000/api/trains
```

**B. Filter by source:**
```bash
curl "http://localhost:5000/api/trains?source=CityA"
```

**C. Filter by destination:**
```bash
curl "http://localhost:5000/api/trains?destination=CityB"
```

**D. Filter by both:**
```bash
curl "http://localhost:5000/api/trains?source=CityA&destination=CityB"
```

**Expected Response (all trains):**
```json
[
  {
    "id": 1,
    "trainName": "Express 101",
    "source": "CityA",
    "destination": "CityB",
    "timing": "07:30",
    "platform": "3"
  },
  {
    "id": 2,
    "trainName": "InterCity 202",
    "source": "CityA",
    "destination": "CityC",
    "timing": "09:15",
    "platform": "1"
  },
  {
    "id": 3,
    "trainName": "Local 303",
    "source": "CityB",
    "destination": "CityD",
    "timing": "12:00",
    "platform": "2"
  }
]
```

---

### 3. GET /api/trains/{trainId}/coaches
**Purpose:** Get coaches for a train with latest crowd status

**Test:**
```bash
# Get coaches for train 1
curl http://localhost:5000/api/trains/1/coaches
```

**Expected Response:**
```json
[
  {
    "coachId": 1,
    "coachName": "S1",
    "latestStatus": "Low",
    "lastReportedAt": "2026-02-19T02:30:00Z",
    "lastReporterName": "System"
  },
  {
    "coachId": 2,
    "coachName": "S2",
    "latestStatus": "Medium",
    "lastReportedAt": "2026-02-19T03:15:00Z",
    "lastReporterName": "System"
  },
  {
    "coachId": 3,
    "coachName": "S3",
    "latestStatus": "High",
    "lastReportedAt": "2026-02-19T01:45:00Z",
    "lastReporterName": "System"
  }
]
```

**Test - Train not found:**
```bash
curl http://localhost:5000/api/trains/999/coaches
```

**Expected Response:** 404 Not Found
```json
{
  "error": "Train with ID 999 not found"
}
```

---

### 4. POST /api/coaches/{coachId}/crowd
**Purpose:** Submit a crowd report for a coach

**Test - Valid Request:**
```bash
curl -X POST http://localhost:5000/api/coaches/1/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "John Doe",
    "status": "High"
  }'
```

**Expected Response:** 201 Created
```json
{
  "id": 10,
  "coachId": 1,
  "reporterName": "John Doe",
  "status": "High",
  "timestamp": "2026-02-19T07:50:30Z"
}
```

**Test - Case Insensitive Status:**
```bash
curl -X POST http://localhost:5000/api/coaches/2/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "Jane Smith",
    "status": "low"
  }'
```

**Expected:** Status normalized to "Low" (201 Created)

**Test - Invalid Status:**
```bash
curl -X POST http://localhost:5000/api/coaches/1/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "Test User",
    "status": "VeryHigh"
  }'
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "Status must be 'Low', 'Medium', or 'High'"
}
```

**Test - Coach Not Found:**
```bash
curl -X POST http://localhost:5000/api/coaches/999/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "Test User",
    "status": "Low"
  }'
```

**Expected Response:** 404 Not Found
```json
{
  "error": "Coach with ID 999 not found"
}
```

**Test - Empty Reporter Name:**
```bash
curl -X POST http://localhost:5000/api/coaches/1/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "",
    "status": "Low"
  }'
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "Reporter name is required"
}
```

---

## Testing Workflow

### 1. Using Swagger UI (Recommended)

1. Open http://localhost:5000/swagger
2. Expand each endpoint
3. Click "Try it out"
4. Fill in parameters
5. Click "Execute"
6. View response

### 2. Using curl (Command Line)

Use the curl commands above to test each endpoint.

### 3. Testing Sequence

**Complete Flow Test:**

```bash
# 1. Check API health
curl http://localhost:5000/api/health

# 2. Get all trains
curl http://localhost:5000/api/trains

# 3. Get coaches for train 1
curl http://localhost:5000/api/trains/1/coaches

# 4. Submit a crowd report (note the returned ID and timestamp)
curl -X POST http://localhost:5000/api/coaches/1/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "Test User",
    "status": "High"
  }'

# 5. Get coaches again to see the updated status
curl http://localhost:5000/api/trains/1/coaches

# The first coach (S1) should now show your new report as the latest
```

---

## Console Logs to Expect

When testing, you should see these logs in the API console:

```
📥 GET /api/trains from ::1
GET /api/trains - Source: all, Destination: all
📤 GET /api/trains - Status: 200

📥 GET /api/trains/1/coaches from ::1
GET /api/trains/1/coaches
📤 GET /api/trains/1/coaches - Status: 200

📥 POST /api/coaches/1/crowd from ::1
POST /api/coaches/1/crowd - Reporter: Test User, Status: High
📤 POST /api/coaches/1/crowd - Status: 201
```

---

## Validation Tests

### Status Validation
- ✅ "Low" → Accepted
- ✅ "Medium" → Accepted
- ✅ "High" → Accepted
- ✅ "low" → Normalized to "Low"
- ✅ "MEDIUM" → Normalized to "Medium"
- ✅ "high" → Normalized to "High"
- ❌ "VeryHigh" → 400 Bad Request
- ❌ "" → 400 Bad Request
- ❌ null → 400 Bad Request

### Reporter Name Validation
- ✅ "John Doe" → Accepted
- ✅ String up to 100 chars → Accepted
- ❌ "" (empty) → 400 Bad Request
- ❌ "   " (whitespace) → 400 Bad Request
- ❌ String > 100 chars → 400 Bad Request

---

## Expected Seed Data

After initial database seeding, you should have:

**Trains:** 3 (IDs: 1, 2, 3)
**Coaches:** 9 (3 per train)
**Initial Crowd Reports:** 9 (1 per coach with "System" as reporter)

**Coach IDs:**
- Train 1: Coach 1 (S1), Coach 2 (S2), Coach 3 (S3)
- Train 2: Coach 4 (S1), Coach 5 (S2), Coach 6 (S3)
- Train 3: Coach 7 (S1), Coach 8 (S2), Coach 9 (S3)

---

## Next Steps

After verifying these endpoints work:

1. ✅ PROMPT 4 - DTOs created
2. ✅ PROMPT 5 - Train & Coach endpoints implemented
3. ✅ PROMPT 6 - Crowd report endpoint implemented
4. 🔜 PROMPT 7 - SOS endpoints (to be implemented next)

---

**Last Updated:** February 19, 2026
