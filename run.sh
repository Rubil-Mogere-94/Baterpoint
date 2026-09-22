#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Setup virtual environment for backend
echo "Setting up virtual environment..."
if [ ! -d "backend/venv" ]; then
  python3 -m venv backend/venv
fi
source backend/venv/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt

# Start FastAPI backend
echo "Starting FastAPI backend..."
cd backend
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!
cd ..

# Give backend a moment to start
sleep 2

# Launch Flutter frontend if available
if command -v flutter >/dev/null 2>&1; then
  echo "Launching Flutter frontend..."
  (cd frontend && flutter run) &
  FRONTEND_PID=$!
else
  echo "Flutter not found, skipping frontend."
fi

# Wait for processes
wait $BACKEND_PID
if [ -n "$FRONTEND_PID" ]; then
  wait $FRONTEND_PID
fi
