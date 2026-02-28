# Baterpoint

Baterpoint is a premium, peer-to-peer trading and listing platform. It features a robust FastAPI backend and a cross-platform Flutter frontend, supporting real-time chat, listing management, and a gamified loyalty system.

## Features

- **Authentication**: Secure JWT-based login and registration.
- **Barter Focus**: Multi-item bundle trading and a "Handshake" confirmation system.
- **Loyalty Shop**: Redeem points for exclusive profile badges and status upgrades.
- **Gamified Quests**: Real-time progress tracking for listing views, favorites, and chat engagement.
- **Deal of the Hour**: Dynamic discounts on highlighted listings to drive platform activity.
- **Modern UI**: Polished glassmorphism design, shimmer loading, confetti celebrations, and haptic feedback.
- **Production Ready**: Rate limiting (SlowAPI), Request ID tracing, structured logging, and robust environment management.

## Prerequisites & Troubleshooting

### Linux Build Error: Missing Linker
If you encounter this error during `flutter run`:
`ERROR: Target dart_build failed: Error: Failed to find any of [ld.lld, ld] in LocalDirectory: '/usr/lib/llvm-18/bin'`

**Fix:** Install the missing LLVM 18 linker and compiler:
```bash
sudo apt update && sudo apt install -y lld-18 clang-18
```
If the error persists after installation, manually link the binary:
```bash
sudo ln -s /usr/bin/ld.lld-18 /usr/lib/llvm-18/bin/ld.lld
```

## Getting Started

### Backend Setup (FastAPI)

1.  **Environment Activation**:
    ```bash
    cd backend
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\\Scripts\\activate
    ```
2.  **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
3.  **Local Configuration**:
    Create a `.env` file in the `backend/` directory:
    ```env
    DATABASE_URL=sqlite:///./test.db # or your PostgreSQL URL
    SECRET_KEY=generate_a_secure_random_key_here
    ```
4.  **Launch API**:
    ```bash
    uvicorn main:app --reload
    ```

### Frontend Setup (Flutter)

1.  **Environment Configuration**:
    Create a `.env` file in the `frontend/` directory:
    ```env
    API_URL=http://localhost:8000
    ```
    *Note: Use your machine's local IP (e.g., 10.0.2.2 for Android emulator or 192.168.1.x for physical devices) instead of localhost.*

2.  **Dependencies & Run**:
    ```bash
    flutter pub get
    flutter run
    ```

## Tech Stack

- **Frontend**: Flutter 3.x, Provider, Socket.io, Lottie (Animations), Confetti.
- **Backend**: Python 3.12, FastAPI, SQLAlchemy, Socket.io, SlowAPI (Rate Limiting).
- **Observability**: Structured Logging with UUID Request ID tracing.
- **DevOps**: GitHub Actions (Backend CI).

## Testing

The backend includes a comprehensive test suite using `pytest`.
```bash
cd backend
pytest
```
