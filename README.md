# Baterpoint

Baterpoint is a modern peer-to-peer trading and listing platform. It features a robust FastAPI backend and a cross-platform Flutter frontend, supporting real-time chat, listing management, and user authentication.

## Project Structure

- `backend/`: FastAPI application with SQLAlchemy ORM and Socket.IO for real-time communication.
- `frontend/`: Flutter application for Android, iOS, and Web.

## Features

- **Authentication**: Secure JWT-based login and registration.
- **Listings**: Create, view, search, and delete items.
- **Server-side Filtering**: Efficient search and category filtering powered by the backend.
- **Real-time Chat**: Instant messaging for trade negotiations using Socket.IO.
- **Image Support**: Upload and display item images with automatic cleanup on deletion.
- **Modern UX**: Pull-to-refresh, search debouncing, and Hero animations.

## Getting Started

### Backend Setup

1.  **Navigate to backend directory**:
    ```bash
    cd backend
    ```
2.  **Create and activate a virtual environment**:
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```
3.  **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Environment Variables**:
    Create a `.env` file with the following:
    ```env
    DATABASE_URL=postgresql://user:password@localhost:5432/baterpoint
    SECRET_KEY=your_secret_key
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
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```
    *Note: For Android/iOS, ensure the `apiUrl` in `lib/constants.dart` points to your machine's local IP address instead of `localhost`.*

## Tech Stack

- **Frontend**: Flutter, Provider (State Management), Socket.io Client.
- **Backend**: Python, FastAPI, SQLAlchemy, Socket.io (python-socketio).
- **Database**: PostgreSQL (Production), SQLite (Testing).

## Testing

The backend includes a comprehensive test suite using `pytest`. Tests utilize an in-memory SQLite database for speed and isolation.

To run tests:
```bash
cd backend
pytest
```
