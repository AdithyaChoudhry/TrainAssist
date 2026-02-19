# Train Assist - Real-Time Train Crowd & Emergency Reporting System

A comprehensive train assistance platform consisting of a Flutter mobile application and ASP.NET Core backend API for real-time crowd status reporting and emergency SOS alerts.

## 🎯 Project Overview

**Train Assist** helps commuters:
- 🚂 **Search Trains** - Find trains by source and destination
- 👥 **Check Coach Status** - View real-time crowd levels (Low/Medium/High) for each coach
- 📊 **Report Crowd Levels** - Contribute crowd status updates
- 🚨 **Emergency SOS** - Submit and view emergency alerts with location data

## 📋 Prerequisites

Before running the backend API, ensure you have:

- **.NET 10.0 SDK** - [Download here](https://dotnet.microsoft.com/download)
- **PostgreSQL 14+** - [Download here](https://www.postgresql.org/download/)
- **Git** (optional) - For cloning the repository

## 🗄️ Database Setup

### Option 1: Using Docker (Recommended for Development)

```bash
# Start PostgreSQL container
docker-compose up -d

# Verify container is running
docker ps
```

### Option 2: Local PostgreSQL Installation

1. Install PostgreSQL on your machine
2. Create a new database named `trainassist`
3. Update connection string in `TrainAssist.Api/appsettings.json`

### Option 3: Use Existing PostgreSQL Server

Update the connection string in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=your-host;Port=5432;Database=trainassist;Username=your-user;Password=your-password"
  }
}
```

## 🚀 Running the Backend API

### 1. Navigate to API Project

```bash
cd TrainAssist.Api
```

### 2. Restore Dependencies

```bash
dotnet restore
```

### 3. Apply Database Migrations

```bash
dotnet ef database update
```

This will:
- Create all tables (Users, Trains, Coaches, CrowdReports, SOSReports)
- Seed initial demo data (3 trains, 9 coaches, 9 crowd reports)

### 4. Run the Application

```bash
dotnet run
```

The API will start on:
- **HTTP**: http://localhost:5000
- **HTTPS**: https://localhost:5001
- **Swagger UI**: http://localhost:5000/swagger

## 📡 API Endpoints

### Health Check

**GET** `/api/health`

Check if the API is running.

```bash
curl http://localhost:5000/api/health
```

**Response:**
```json
{
  "status": "Healthy",
  "timestamp": "2025-02-18T19:30:00Z",
  "database": "Connected"
}
```

---

### Train Endpoints

#### Search Trains

**GET** `/api/trains?source={source}&destination={destination}`

Search for trains by source and/or destination (case-insensitive).

**Parameters:**
- `source` (optional): Source station name
- `destination` (optional): Destination station name

**Example:**
```bash
curl "http://localhost:5000/api/trains?source=Mumbai&destination=Pune"
```

**Response:**
```json
[
  {
    "id": 1,
    "trainName": "Deccan Express",
    "source": "Mumbai CST",
    "destination": "Pune",
    "timing": "06:30 AM",
    "platform": "Platform 1"
  }
]
```

---

#### Get Train Coaches with Status

**GET** `/api/trains/{trainId}/coaches`

Get all coaches for a specific train with their latest crowd status.

**Example:**
```bash
curl http://localhost:5000/api/trains/1/coaches
```

**Response:**
```json
[
  {
    "id": 1,
    "trainId": 1,
    "coachName": "S1",
    "latestStatus": "Medium",
    "lastReportedAt": "2025-02-18T15:30:00Z"
  },
  {
    "id": 2,
    "trainId": 1,
    "coachName": "S2",
    "latestStatus": "Low",
    "lastReportedAt": "2025-02-18T14:20:00Z"
  }
]
```

---

### Crowd Reporting Endpoints

#### Report Coach Crowd Status

**POST** `/api/coaches/{coachId}/crowd`

Submit a crowd status report for a specific coach.

**Request Body:**
```json
{
  "reporterName": "John Doe",
  "status": "High"
}
```

**Status Values:** `Low`, `Medium`, `High` (case-insensitive)

**Example:**
```bash
curl -X POST http://localhost:5000/api/coaches/1/crowd \
  -H "Content-Type: application/json" \
  -d '{
    "reporterName": "John Doe",
    "status": "High"
  }'
```

**Response (201 Created):**
```json
{
  "id": 10,
  "coachId": 1,
  "reporterName": "John Doe",
  "status": "High",
  "timestamp": "2025-02-18T19:30:00Z"
}
```

---

### SOS Emergency Endpoints

#### Submit SOS Report

**POST** `/api/sos`

Submit an emergency SOS report with optional location and train/coach information.

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

**All fields except `reporterName` are optional.**

**Example:**
```bash
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
```

**Response (201 Created):**
```json
{
  "id": 1,
  "reporterName": "Jane Smith",
  "trainId": 1,
  "coachId": 3,
  "latitude": 19.0760,
  "longitude": 72.8777,
  "message": "Medical emergency in coach S3",
  "timestamp": "2025-02-18T19:35:00Z"
}
```

---

#### Get Recent SOS Reports

**GET** `/api/sos`

Retrieve the last 50 SOS reports, ordered by most recent first.

**Example:**
```bash
curl http://localhost:5000/api/sos
```

**Response:**
```json
[
  {
    "id": 1,
    "reporterName": "Jane Smith",
    "trainId": 1,
    "coachId": 3,
    "latitude": 19.0760,
    "longitude": 72.8777,
    "message": "Medical emergency in coach S3",
    "timestamp": "2025-02-18T19:35:00Z"
  }
]
```

---

## 🧪 Testing the API

### Using Swagger UI (Recommended)

1. Start the API: `dotnet run`
2. Open browser: http://localhost:5000/swagger
3. Explore and test all endpoints interactively

### Using curl (Command Line)

See the examples above for each endpoint.

### Using Postman

1. Import the Swagger JSON: http://localhost:5000/swagger/v1/swagger.json
2. Create requests for each endpoint

## 📁 Project Structure

```
TrainAssist/
├── TrainAssist.Api/
│   ├── Models/              # Entity models (User, Train, Coach, etc.)
│   ├── DTOs/                # Data Transfer Objects
│   ├── Data/                # Database context and seeding
│   ├── Migrations/          # EF Core migrations
│   ├── Program.cs           # Main application entry point
│   ├── appsettings.json     # Configuration
│   └── TrainAssist.Api.csproj
├── docker-compose.yml       # PostgreSQL container setup
└── README.md               # This file
```

## 🗂️ Database Schema

### Tables

1. **Users** - User accounts (Id, Name, Phone)
2. **Trains** - Train information (Id, TrainName, Source, Destination, Timing, Platform)
3. **Coaches** - Train coaches (Id, TrainId, CoachName)
4. **CrowdReports** - Crowd status reports (Id, CoachId, ReporterName, Status, Timestamp)
5. **SOSReports** - Emergency reports (Id, ReporterName, TrainId, CoachId, Lat, Long, Message, Timestamp)

### Sample Seeded Data

The database is automatically seeded with:
- 3 Trains: Deccan Express, Shatabdi Express, Rajdhani Express
- 9 Coaches: 3 coaches per train (S1, S2, S3)
- 9 Initial Crowd Reports: Various statuses with timestamps

## 🔧 Development

### Rebuild Database

```bash
# Drop existing database
dotnet ef database drop

# Recreate and seed
dotnet ef database update
```

### Create New Migration

```bash
dotnet ef migrations add YourMigrationName
```

### View Logs

Application logs are displayed in the console with emoji indicators:
- 🟢 Request started
- 🔵 Response completed
- 🚨 SOS report created

## 🐳 Docker Support

### Start PostgreSQL

```bash
docker-compose up -d
```

### Stop PostgreSQL

```bash
docker-compose down
```

### View Logs

```bash
docker-compose logs -f
```

## 🛠️ Technologies Used

- **Backend**: ASP.NET Core 10.0 (Minimal APIs)
- **Database**: PostgreSQL 14+
- **ORM**: Entity Framework Core 10.0.3
- **API Documentation**: Swagger/OpenAPI (Swashbuckle)
- **Logging**: Built-in .NET logging
- **Container**: Docker & Docker Compose

## 📝 Configuration

### appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=trainassist;Username=trainassist_user;Password=trainassist_pass"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

## 🚧 Troubleshooting

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -h localhost -p 5432 -U trainassist_user -d trainassist

# Check if container is running
docker ps

# View container logs
docker logs trainassist-postgres
```

### Migration Issues

```bash
# Reset migrations
dotnet ef migrations remove

# Recreate migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update
```

### Port Already in Use

Change ports in [Properties/launchSettings.json](TrainAssist.Api/Properties/launchSettings.json) if 5000/5001 are occupied.

## 📖 Next Steps

1. ✅ Backend API (Complete)
2. 🔄 Flutter Mobile App (In Progress)
3. 📱 UI Implementation
4. 🔗 API Integration
5. 🧪 End-to-End Testing
6. 🚀 Deployment

## 📄 License

This is a prototype application for demonstration purposes.

## 👥 Contributors

Built as part of the Train Assist project initiative.

---

**Ready to start?** Run `dotnet run` and visit http://localhost:5000/swagger 🚀
