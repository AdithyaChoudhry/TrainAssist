# Train Assist API - Complete Endpoint Reference

Base URL: `http://localhost:5000` (HTTP) or `https://localhost:5001` (HTTPS)

Swagger UI: `http://localhost:5000/swagger`

---

## 📋 Table of Contents

1. [Health Check](#health-check)
2. [Train Endpoints](#train-endpoints)
3. [Coach Endpoints](#coach-endpoints)
4. [SOS Endpoints](#sos-endpoints)
5. [Error Responses](#error-responses)
6. [Status Codes](#status-codes)

---

## Health Check

### GET /api/health

**Description:** Check if the API service is running and database is connected.

**Authentication:** None

**Query Parameters:** None

**Request Example:**
```bash
curl -X GET http://localhost:5000/api/health
```

**Response Example (200 OK):**
```json
{
  "status": "Healthy",
  "timestamp": "2025-02-18T19:30:00.123Z",
  "database": "Connected"
}
```

**Response Fields:**
- `status` (string): Always "Healthy" if API is running
- `timestamp` (datetime): Current UTC timestamp
- `database` (string): "Connected" if database is accessible

---

## Train Endpoints

### GET /api/trains

**Description:** Search for trains by source and/or destination stations.

**Authentication:** None

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | string | No | Source station name (case-insensitive) |
| `destination` | string | No | Destination station name (case-insensitive) |

**Filtering Logic:**
- If both parameters are provided: Returns trains matching BOTH source AND destination
- If only `source` is provided: Returns all trains from that source
- If only `destination` is provided: Returns all trains to that destination
- If neither is provided: Returns all trains

**Request Examples:**

```bash
# All trains
curl -X GET http://localhost:5000/api/trains

# Trains from Mumbai
curl -X GET "http://localhost:5000/api/trains?source=Mumbai"

# Trains to Pune
curl -X GET "http://localhost:5000/api/trains?destination=Pune"

# Trains from Mumbai to Pune
curl -X GET "http://localhost:5000/api/trains?source=Mumbai&destination=Pune"
```

**Response Example (200 OK):**
```json
[
  {
    "id": 1,
    "trainName": "Deccan Express",
    "source": "Mumbai CST",
    "destination": "Pune",
    "timing": "06:30 AM",
    "platform": "Platform 1"
  },
  {
    "id": 2,
    "trainName": "Shatabdi Express",
    "source": "Delhi",
    "destination": "Agra",
    "timing": "08:00 AM",
    "platform": "Platform 3"
  }
]
```

**Response Fields:**
- `id` (integer): Unique train identifier
- `trainName` (string): Name of the train
- `source` (string): Source/origin station
- `destination` (string): Destination station
- `timing` (string): Departure/arrival time
- `platform` (string): Platform number

**Status Codes:**
- `200 OK`: Success (returns empty array `[]` if no trains match)

---

### GET /api/trains/{trainId}/coaches

**Description:** Get all coaches for a specific train with their latest crowd status.

**Authentication:** None

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `trainId` | integer | Yes | The ID of the train |

**Request Example:**
```bash
curl -X GET http://localhost:5000/api/trains/1/coaches
```

**Response Example (200 OK):**
```json
[
  {
    "id": 1,
    "trainId": 1,
    "coachName": "S1",
    "latestStatus": "High",
    "lastReportedAt": "2025-02-18T18:30:00Z"
  },
  {
    "id": 2,
    "trainId": 1,
    "coachName": "S2",
    "latestStatus": "Medium",
    "lastReportedAt": "2025-02-18T17:45:00Z"
  },
  {
    "id": 3,
    "trainId": 1,
    "coachName": "S3",
    "latestStatus": null,
    "lastReportedAt": null
  }
]
```

**Response Fields:**
- `id` (integer): Unique coach identifier
- `trainId` (integer): Parent train ID
- `coachName` (string): Coach name/number (e.g., "S1", "S2")
- `latestStatus` (string|null): Most recent crowd status ("Low", "Medium", "High", or null if never reported)
- `lastReportedAt` (datetime|null): Timestamp of the most recent report (UTC), or null if never reported

**Status Codes:**
- `200 OK`: Success (returns empty array `[]` if train has no coaches)
- `404 Not Found`: Train with the specified ID does not exist

**Error Response (404):**
```json
{
  "error": "Train with ID 999 not found"
}
```

---

## Coach Endpoints

### POST /api/coaches/{coachId}/crowd

**Description:** Submit a crowd status report for a specific coach.

**Authentication:** None

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `coachId` | integer | Yes | The ID of the coach |

**Request Body:**
```json
{
  "reporterName": "John Doe",
  "status": "High"
}
```

**Request Body Fields:**
| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `reporterName` | string | Yes | Max 100 chars | Name of the person reporting |
| `status` | string | Yes | "Low", "Medium", or "High" (case-insensitive) | Crowd level |

**Status Normalization:**
The API automatically normalizes status values to proper case:
- `"low"`, `"LOW"`, `"Low"` → `"Low"`
- `"medium"`, `"MEDIUM"`, `"Medium"` → `"Medium"`
- `"high"`, `"HIGH"`, `"High"` → `"High"`

**Request Examples:**

```bash
# Report high crowd
curl -X POST http://localhost:5000/api/coaches/1/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "John Doe",
    "status": "High"
  }'

# Report medium crowd (case-insensitive)
curl -X POST http://localhost:5000/api/coaches/2/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "Jane Smith",
    "status": "medium"
  }'
```

**Response Example (201 Created):**
```json
{
  "id": 15,
  "coachId": 1,
  "reporterName": "John Doe",
  "status": "High",
  "timestamp": "2025-02-18T19:45:00Z"
}
```

**Response Fields:**
- `id` (integer): Unique report identifier
- `coachId` (integer): Coach that was reported on
- `reporterName` (string): Name of the reporter
- `status` (string): Normalized crowd status
- `timestamp` (datetime): When the report was created (UTC)

**Status Codes:**
- `201 Created`: Report successfully created
- `400 Bad Request`: Invalid request data (missing fields, invalid status)
- `404 Not Found`: Coach with the specified ID does not exist

**Error Response Examples:**

```json
// 400 - Invalid status
{
  "error": "Status must be Low, Medium, or High"
}

// 404 - Coach not found
{
  "error": "Coach with ID 999 not found"
}
```

---

## SOS Endpoints

### POST /api/sos

**Description:** Submit an emergency SOS report with optional location and train/coach information.

**Authentication:** None

**Request Body:**
```json
{
  "reporterName": "Jane Smith",
  "trainId": 1,
  "coachId": 3,
  "latitude": 19.0760,
  "longitude": 72.8777,
  "message": "Medical emergency in coach S3"
}
```

**Request Body Fields:**
| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `reporterName` | string | Yes | Max 100 chars | Name of the person reporting |
| `trainId` | integer | No | Must be valid train ID if provided | Associated train (optional) |
| `coachId` | integer | No | Must be valid coach ID if provided | Associated coach (optional) |
| `latitude` | decimal | No | -90 to 90 | GPS latitude coordinate |
| `longitude` | decimal | No | -180 to 180 | GPS longitude coordinate |
| `message` | string | No | Max 500 chars | Emergency details/description |

**Important Notes:**
- Only `reporterName` is required
- If `trainId` or `coachId` are provided, they must exist in the database
- Location coordinates are optional but useful for emergency response
- All timestamps are recorded in UTC

**Request Examples:**

```bash
# Full SOS report with all fields
curl -X POST http://localhost:5000/api/sos \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "Jane Smith",
    "trainId": 1,
    "coachId": 3,
    "latitude": 19.0760,
    "longitude": 72.8777,
    "message": "Medical emergency in coach S3"
  }'

# Minimal SOS report (only name required)
curl -X POST http://localhost:5000/api/sos \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "Emergency Reporter",
    "message": "Need immediate assistance"
  }'

# SOS with location only
curl -X POST http://localhost:5000/api/sos \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "John Doe",
    "latitude": 18.9750,
    "longitude": 72.8258,
    "message": "Lost at station"
  }'
```

**Response Example (201 Created):**
```json
{
  "id": 5,
  "reporterName": "Jane Smith",
  "trainId": 1,
  "coachId": 3,
  "latitude": 19.0760,
  "longitude": 72.8777,
  "message": "Medical emergency in coach S3",
  "timestamp": "2025-02-18T19:50:00Z"
}
```

**Response Fields:**
- `id` (integer): Unique SOS report identifier
- `reporterName` (string): Name of the reporter
- `trainId` (integer|null): Associated train ID (if provided)
- `coachId` (integer|null): Associated coach ID (if provided)
- `latitude` (decimal|null): GPS latitude (if provided)
- `longitude` (decimal|null): GPS longitude (if provided)
- `message` (string|null): Emergency message (if provided)
- `timestamp` (datetime): When the report was created (UTC)

**Status Codes:**
- `201 Created`: SOS report successfully created
- `400 Bad Request`: Missing reporter name or invalid data
- `404 Not Found`: Specified trainId or coachId does not exist

**Error Response Examples:**

```json
// 400 - Missing reporter name
{
  "error": "Reporter name is required"
}

// 404 - Invalid train ID
{
  "error": "Train with ID 999 not found"
}

// 404 - Invalid coach ID
{
  "error": "Coach with ID 888 not found"
}
```

---

### GET /api/sos

**Description:** Retrieve the most recent 50 SOS reports, ordered by timestamp (newest first).

**Authentication:** None

**Query Parameters:** None

**Request Example:**
```bash
curl -X GET http://localhost:5000/api/sos
```

**Response Example (200 OK):**
```json
[
  {
    "id": 5,
    "reporterName": "Jane Smith",
    "trainId": 1,
    "coachId": 3,
    "latitude": 19.0760,
    "longitude": 72.8777,
    "message": "Medical emergency in coach S3",
    "timestamp": "2025-02-18T19:50:00Z"
  },
  {
    "id": 4,
    "reporterName": "Emergency Reporter",
    "trainId": null,
    "coachId": null,
    "latitude": null,
    "longitude": null,
    "message": "Need immediate assistance",
    "timestamp": "2025-02-18T19:45:00Z"
  },
  {
    "id": 3,
    "reporterName": "John Doe",
    "trainId": 2,
    "coachId": null,
    "latitude": 18.9750,
    "longitude": 72.8258,
    "message": "Lost at station",
    "timestamp": "2025-02-18T19:30:00Z"
  }
]
```

**Response Fields:**
- Array of SOS report objects (same structure as POST response)
- Ordered by `timestamp` descending (newest first)
- Limited to 50 most recent reports
- Empty array `[]` if no reports exist

**Status Codes:**
- `200 OK`: Success (always returns an array, even if empty)

---

## Error Responses

All error responses follow a consistent structure:

```json
{
  "error": "Descriptive error message"
}
```

**Generic Server Error (500):**
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.6.1",
  "title": "An error occurred while processing your request.",
  "status": 500
}
```

---

## Status Codes

| Code | Meaning | Used In |
|------|---------|---------|
| `200 OK` | Request successful, data returned | GET /api/trains, GET /api/trains/{id}/coaches, GET /api/sos, GET /api/health |
| `201 Created` | Resource successfully created | POST /api/coaches/{id}/crowd, POST /api/sos |
| `400 Bad Request` | Invalid request data (validation failed) | POST /api/coaches/{id}/crowd, POST /api/sos |
| `404 Not Found` | Resource does not exist | GET /api/trains/{id}/coaches, POST /api/coaches/{id}/crowd, POST /api/sos (invalid trainId/coachId) |
| `500 Internal Server Error` | Server-side error occurred | Any endpoint (unexpected errors) |

---

## Request Headers

All POST requests must include:

```
Content-Type: application/json
```

---

## Response Headers

All responses include:

```
Content-Type: application/json; charset=utf-8
```

---

## Data Types

| Type | Format | Example |
|------|--------|---------|
| `integer` | Whole number | `1`, `42`, `999` |
| `string` | UTF-8 text | `"Mumbai CST"`, `"John Doe"` |
| `decimal` | Floating point | `19.0760`, `72.8777` |
| `datetime` | ISO 8601 UTC | `"2025-02-18T19:50:00Z"` |
| `boolean` | true/false | `true`, `false` |
| `null` | No value | `null` |

---

## Best Practices

### 1. **Always check HTTP status codes**
```javascript
if (response.status === 200) {
  // Success - process data
} else if (response.status === 404) {
  // Resource not found
} else if (response.status === 400) {
  // Validation error
}
```

### 2. **Handle empty results**
```javascript
const trains = await fetch('/api/trains').then(r => r.json());
if (trains.length === 0) {
  console.log("No trains found");
}
```

### 3. **Use case-insensitive status values**
```javascript
// All valid - will be normalized to "Medium"
{ "status": "medium" }
{ "status": "MEDIUM" }
{ "status": "Medium" }
```

### 4. **Validate coordinates before submission**
```javascript
function isValidLatitude(lat) {
  return lat >= -90 && lat <= 90;
}

function isValidLongitude(lng) {
  return lng >= -180 && lng <= 180;
}
```

### 5. **Include error handling**
```javascript
try {
  const response = await fetch('/api/sos', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(sosData)
  });
  
  if (!response.ok) {
    const error = await response.json();
    console.error('Error:', error.error);
  }
} catch (err) {
  console.error('Network error:', err);
}
```

---

## Testing Examples

### Using JavaScript Fetch API

```javascript
// Search trains
const trains = await fetch('http://localhost:5000/api/trains?source=Mumbai')
  .then(r => r.json());

// Get coach status
const coaches = await fetch('http://localhost:5000/api/trains/1/coaches')
  .then(r => r.json());

// Report crowd
const report = await fetch('http://localhost:5000/api/coaches/1/crowd', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    reporterName: 'John Doe',
    status: 'High'
  })
}).then(r => r.json());

// Submit SOS
const sos = await fetch('http://localhost:5000/api/sos', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    reporterName: 'Jane Smith',
    trainId: 1,
    message: 'Emergency'
  })
}).then(r => r.json());
```

### Using Flutter HTTP Package

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// Search trains
final trainsResponse = await http.get(
  Uri.parse('http://localhost:5000/api/trains?source=Mumbai')
);
final trains = jsonDecode(trainsResponse.body);

// Report crowd
final crowdResponse = await http.post(
  Uri.parse('http://localhost:5000/api/coaches/1/crowd'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'reporterName': 'John Doe',
    'status': 'High'
  })
);
```

---

## Rate Limiting

Currently **no rate limiting** is enforced. This may change in production.

---

## CORS

CORS is **enabled for all origins** in development mode. Adjust in production as needed.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-02-18 | Initial API release with all 6 endpoints |

---

**Questions or Issues?** Check the [README.md](README.md) for troubleshooting or run the API with Swagger UI at http://localhost:5000/swagger for interactive documentation.
