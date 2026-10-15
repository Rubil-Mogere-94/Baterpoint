#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BACKEND_ONLY=false
if [[ "${1:-}" == "--backend-only" ]]; then
  BACKEND_ONLY=true
  shift
fi

# Find Flutter on PATH or in common per-user SDK locations.
if [[ "$BACKEND_ONLY" == false ]] && ! command -v flutter >/dev/null 2>&1; then
  for candidate in \
    "$HOME/development/flutter/bin/flutter" \
    "$HOME/develop/flutter/bin/flutter" \
    "$HOME/flutter/bin/flutter" \
    "$HOME/sdk/flutter/bin/flutter"; do
    if [[ -x "$candidate" ]]; then
      export PATH="$(dirname -- "$candidate"):$PATH"
      break
    fi
  done
fi

if [[ "$BACKEND_ONLY" == false ]] && ! command -v flutter >/dev/null 2>&1; then
  cat >&2 <<'EOF_MSG'
ERROR: Flutter SDK was not found, so the full application cannot start.

Install Flutter and add its bin directory to PATH. For example:
  git clone https://github.com/flutter/flutter.git -b stable "$HOME/development/flutter"
  echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> "$HOME/.bashrc"
  source "$HOME/.bashrc"

Then verify with: flutter doctor -v

To run only the FastAPI backend in the meantime, use:
  ./run_all.sh --backend-only
EOF_MSG
  exit 127
fi

FLUTTER_DEVICE="${FLUTTER_DEVICE:-linux}"
if [[ "$BACKEND_ONLY" == false ]]; then
  if [[ "$FLUTTER_DEVICE" == "linux" ]]; then
    flutter config --enable-linux-desktop >/dev/null
  fi
  echo "Preparing Flutter frontend (device: $FLUTTER_DEVICE)..."
  (cd frontend && flutter pub get)
fi

echo "Setting up Python virtual environment..."
if [[ ! -d backend/venv ]]; then
  python3 -m venv backend/venv
fi
# shellcheck disable=SC1091
source backend/venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r backend/requirements.txt

echo "Starting FastAPI backend..."
(cd backend && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000) &
BACKEND_PID=$!
FRONTEND_PID=""

cleanup() {
  if [[ -n "${FRONTEND_PID:-}" ]] && kill -0 "$FRONTEND_PID" 2>/dev/null; then
    kill "$FRONTEND_PID" 2>/dev/null || true
  fi
  if [[ -n "${BACKEND_PID:-}" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null || true
  fi
  wait 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ "$BACKEND_ONLY" == true ]]; then
  echo "Backend-only mode. API docs: http://127.0.0.1:8000/api/v1/docs"
  wait "$BACKEND_PID"
else
  sleep 2
  echo "Launching Flutter frontend on $FLUTTER_DEVICE..."
  (cd frontend && flutter run -d "$FLUTTER_DEVICE") &
  FRONTEND_PID=$!

  # Stop the other process if either service exits.
  set +e
  wait -n "$BACKEND_PID" "$FRONTEND_PID"
  STATUS=$?
  set -e
  exit "$STATUS"
fi
