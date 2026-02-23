#!/usr/bin/env bash
set -euo pipefail

# start_services.sh
# Stops any process on port 5000, starts backend and Flutter web in Chrome,
# logs output to /tmp/backend.log and /tmp/flutter_web.log, and writes PIDs.

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_DIR="$ROOT_DIR/TrainAssist.Api"
APP_DIR="$ROOT_DIR/train_assist_app"
BACKEND_LOG="/tmp/backend.log"
FRONTEND_LOG="/tmp/flutter_web.log"

echo "Checking prerequisites..."
command -v dotnet >/dev/null 2>&1 || { echo "dotnet not found in PATH. Install .NET SDK and retry."; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "flutter not found in PATH. Install Flutter SDK and retry."; exit 1; }

echo "Stopping any process on port 5000..."
lsof -ti :5000 | xargs -r kill -9 || true

echo "Starting backend (TrainAssist.Api)..."
if [ ! -d "$API_DIR" ]; then
  echo "Backend folder not found: $API_DIR"; exit 1
fi
cd "$API_DIR"
nohup dotnet run --urls http://127.0.0.1:5000 > "$BACKEND_LOG" 2>&1 &
echo $! > /tmp/backend.pid
sleep 2
echo "=== Backend log (last 50 lines) ==="
tail -n 50 "$BACKEND_LOG" || true
echo
echo "Checking backend health..."
curl -sS http://127.0.0.1:5000/api/health || echo "Warning: health endpoint did not respond yet. Check $BACKEND_LOG"

echo
echo "Starting Flutter web in Chrome (train_assist_app)..."
if [ ! -d "$APP_DIR" ]; then
  echo "Flutter app folder not found: $APP_DIR"; exit 1
fi
cd "$APP_DIR"
nohup flutter run -d chrome --web-port 8080 > "$FRONTEND_LOG" 2>&1 &
echo $! > /tmp/flutter_web.pid
sleep 4
echo "=== Flutter web log (last 50 lines) ==="
tail -n 50 "$FRONTEND_LOG" || true

echo
echo "Done. Open http://localhost:8080 in Chrome to use the app."
echo "Backend health: http://127.0.0.1:5000/api/health"
echo "Backend log: $BACKEND_LOG"
echo "Flutter log: $FRONTEND_LOG"

exit 0
