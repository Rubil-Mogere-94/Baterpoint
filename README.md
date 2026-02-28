# Baterpoint

Baterpoint is a modern peer-to-peer trading and listing platform. It features a robust FastAPI backend and a cross-platform Flutter frontend, supporting real-time chat, listing management, and user authentication.

## Project Structure

- `backend/`: FastAPI application with SQLAlchemy ORM and Socket.IO for real-time communication.
- `frontend/`: Flutter application for Android, iOS, and Web.

## Features

- **Authentication**: Secure JWT-based login and registration.
- **Listings**: Create, view, search, and delete items.
- **Barter Focus**: Bundle trading (multiple items in offers) and Trade Handshake system.
- **Loyalty Shop**: Redeem points earned from quests for premium badges and status.
- **Gamified Quests**: Real-time tracking of viewing, favoriting, and chatting activities.
- **Deal of the Hour**: Time-limited discounts on premium listings.
- **Modern UI**: Glassmorphism, Shimmer effects, Confetti celebrations, and Haptic feedback.
- **Production Ready**: Rate limiting, Request ID tracing, structured logging, and Environment management.

## Getting Started

### Backend Setup

1.  **Navigate to backend directory**:
    ```bash
    cd backend
    ```
2.  **Create and activate a virtual environment**:
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\\Scripts\\activate
    ```
3.  **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Environment Variables**:
    Create a `.env` file in the `backend/` directory:
    ```env
    DATABASE_URL=postgresql://user:password@localhost:5432/baterpoint
    SECRET_KEY=your_secure_key
    ```
5.  **Run the server**:
    ```bash
    uvicorn main:app --reload
    ```

### Frontend Setup (Flutter)

1.  **Navigate to frontend directory**:
    ```bash
    cd frontend
    ```
2.  **Environment Setup**:
    Create a `.env` file in the `frontend/` directory:
    ```env
    API_URL=http://localhost:8000
    ```
3.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the application**:
    ```bash
    flutter run
    ```

## Tech Stack

- **Frontend**: Flutter 3.x, Provider, Socket.io, Lottie (Animations), Confetti.
- **Backend**: Python 3.12, FastAPI, SQLAlchemy, Socket.io, SlowAPI (Rate Limiting).
- **DevOps**: GitHub Actions CI/CD.

## Testing

The backend includes a comprehensive test suite using `pytest`.
```bash
cd backend
pytest
```
