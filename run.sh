#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Start backend services using Docker Compose.
echo "Starting backend services..."
docker compose up --build -d

# Navigate to the Flutter frontend directory and run the app.
echo "Running Flutter frontend..."
cd frontend && flutter run
