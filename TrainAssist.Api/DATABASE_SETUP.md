# Database Setup Guide for TrainAssist API

## ⚠️ IMPORTANT: PostgreSQL is Required

The TrainAssist API requires PostgreSQL to be running. You have several options:

---

## Option 1: Install PostgreSQL with Homebrew (Recommended for macOS)

```bash
# Install PostgreSQL
brew install postgresql@15

# Start PostgreSQL service
brew services start postgresql@15

# Create the trainassist database
createdb trainassist

# Verify PostgreSQL is running
psql -U $(whoami) -d trainassist -c "SELECT version();"
```

---

## Option 2: Use Docker (If Docker Desktop is installed)

If you have Docker Desktop installed:

```bash
# Start PostgreSQL using docker-compose
cd /Users/adithyachoudhrym/TrainAssist
docker-compose up -d

# Verify PostgreSQL is running
docker ps | grep trainassist_postgres

# View logs
docker-compose logs postgres
```

To stop PostgreSQL:
```bash
docker-compose down
```

---

## Option 3: Install PostgreSQL.app (macOS GUI)

1. Download from: https://postgresapp.com/
2. Install and start Postgres.app
3. Create database:
   ```bash
   psql -U postgres
   CREATE DATABASE trainassist;
   \q
   ```

---

## After PostgreSQL is Running

### Apply Database Migration

```bash
cd /Users/adithyachoudhrym/TrainAssist/TrainAssist.Api

# Add dotnet-ef to PATH (if not already done)
export PATH="$PATH:/Users/adithyachoudhrym/.dotnet/tools"

# Apply the migration to create tables
dotnet ef database update
```

### Run the API

```bash
dotnet run
```

The application will:
1. Create the database schema
2. Seed initial data (3 trains, 9 coaches, 9 crowd reports)
3. Start the API on http://localhost:5000

---

## Verify Setup

Once the API is running:

1. **Check Swagger UI**: http://localhost:5000/swagger
2. **Health Check**: http://localhost:5000/api/health
3. **View Logs**: Console will show database seeding progress

---

## Connection String

The default connection string in `appsettings.json`:
```
Host=localhost;Database=trainassist;Username=postgres;Password=postgres
```

If you need to modify it:
1. Open `TrainAssist.Api/appsettings.json`
2. Update the `DefaultConnection` value
3. Rebuild and run

---

## Troubleshooting

### "Connection refused" or "Could not connect to server"
- PostgreSQL is not running
- Run one of the installation options above

### "database 'trainassist' does not exist"
- Create the database manually:
  ```bash
  psql -U postgres
  CREATE DATABASE trainassist;
  \q
  ```

### "role 'postgres' does not exist"
- Adjust the connection string username to match your PostgreSQL setup
- Or create the postgres user:
  ```bash
  createuser -s postgres
  ```

---

## Quick Start (After PostgreSQL is Running)

```bash
cd /Users/adithyachoudhrym/TrainAssist/TrainAssist.Api
export PATH="$PATH:/Users/adithyachoudhrym/.dotnet/tools"
dotnet ef database update
dotnet run
```

Then open: http://localhost:5000/swagger

---

**Need Help?** Check the logs for specific error messages.
