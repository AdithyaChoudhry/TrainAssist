# Quick Start Guide - TrainAssist API

## Current Status: ✅ PROMPT 2 & 3 COMPLETE

### What's Been Implemented
- ✅ 5 Entity Models (User, Train, Coach, CrowdReport, SOSReport)
- ✅ Database Context with PostgreSQL
- ✅ Data Seeder for initial data
- ✅ Database Migration generated
- ✅ Project builds successfully

### ⚠️ Before You Can Run The API

**PostgreSQL must be installed and running!**

Choose ONE option:

#### Option A: Homebrew (Fastest)
```bash
brew install postgresql@15
brew services start postgresql@15
createdb trainassist
```

#### Option B: Docker
```bash
cd /Users/adithyachoudhrym/TrainAssist
docker-compose up -d
```

#### Option C: Postgres.app
Download and install from: https://postgresapp.com/

---

## Run the API

```bash
cd /Users/adithyachoudhrym/TrainAssist/TrainAssist.Api

# Add EF Core tools to PATH
export PATH="$PATH:/Users/adithyachoudhrym/.dotnet/tools"

# Apply migration to create database schema
dotnet ef database update

# Run the API
dotnet run
```

## Access Points

Once running:
- **Swagger UI**: http://localhost:5000/swagger
- **Health Check**: http://localhost:5000/api/health
- **Base API**: http://localhost:5000/api

## What Happens on Startup

1. ✅ Connects to PostgreSQL
2. ✅ Creates database schema (if using EnsureCreated)
3. ✅ Seeds 3 trains
4. ✅ Seeds 9 coaches (3 per train)
5. ✅ Seeds 9 initial crowd reports
6. ✅ Starts API server

## Sample Seed Data

**Trains:**
- Express 101: CityA → CityB (07:30, Platform 3)
- InterCity 202: CityA → CityC (09:15, Platform 1)
- Local 303: CityB → CityD (12:00, Platform 2)

**Coaches per Train:**
- S1, S2, S3

**Initial Crowd Reports:**
- Mix of Low, Medium, High statuses
- Timestamps 1-5 hours in the past

---

## Database Schema

```
Users
├── Id (Guid, PK)
├── Name (string, required)
└── Phone (string, nullable)

Trains
├── Id (int, PK)
├── TrainName (string)
├── Source (string)
├── Destination (string)
├── Timing (string)
└── Platform (string, nullable)

Coaches
├── Id (int, PK)
├── TrainId (int, FK → Trains)
└── CoachName (string)

CrowdReports
├── Id (int, PK)
├── CoachId (int, FK → Coaches)
├── ReporterName (string)
├── Status (string: Low/Medium/High)
└── Timestamp (DateTime)

SOSReports
├── Id (int, PK)
├── ReporterName (string)
├── TrainId (int?, FK → Trains, nullable)
├── CoachId (int?, FK → Coaches, nullable)
├── Latitude (double?, nullable)
├── Longitude (double?, nullable)
├── Message (string, nullable)
└── Timestamp (DateTime)
```

---

## Commands Reference

```bash
# Build project
dotnet build

# Create new migration
dotnet ef migrations add MigrationName

# Apply migrations
dotnet ef database update

# Remove last migration (if not applied)
dotnet ef migrations remove

# Run the API
dotnet run

# Run with watch (auto-reload on changes)
dotnet watch run
```

---

## Troubleshooting

**"Connection refused"**
→ PostgreSQL is not running. Start it using one of the options above.

**"Database does not exist"**
→ Run: `createdb trainassist` or `dotnet ef database update`

**"dotnet-ef not found"**
→ Run: `export PATH="$PATH:/Users/adithyachoudhrym/.dotnet/tools"`

**"Port 5000 already in use"**
→ Change port in Properties/launchSettings.json

---

## Next Steps

Ready for **PROMPT 4**: Create DTOs (Data Transfer Objects)

---

**Last Updated:** February 18, 2026
