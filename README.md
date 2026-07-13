# Baterpoint

Baterpoint is a premium, peer-to-peer trading and listing platform. It features a robust FastAPI backend and a cross-platform Flutter frontend, supporting real-time chat, listing management, and a gamified loyalty system.

## 🎨 V2 Design System
Baterpoint has been upgraded to a premium **V2 Design System**, prioritizing visual excellence and smooth user experience:
- **Glassmorphism & Holographics**: Featuring custom `HolographicBackground` mesh gradients and heavy blur effects for a premium feel.
- **Centralized Tokens**: Unified spacing, radii, and shadow tokens for consistent UI across the entire app.
- **Modern Typography**: Powered by Google Fonts (Outfit and Inter) for a sleek, contemporary look.
- **Micro-animations**: Enhanced with `flutter_animate`, shimmer loaders, and celebratory confetti effects.

## 🚀 Key Features

- **AI-Powered Recommendations**: Personalized listing suggestions using semantic embeddings (`all-MiniLM-L6-v2`) and cosine similarity.
- **Seller Analytics**: Comprehensive dashboard for sellers to track views, offers, conversion rates, and revenue.
- **Authentication**: Secure JWT-based login, registration, and **Google Social Login** (OAuth2).
- **Push Notifications**: Real-time alerts for new offers, messages, and order updates via Firebase Cloud Messaging (FCM).
- **Sustainability Badges**: Eco-conscious trading with badges for "upcycled", "locally made", and "eco-friendly" items.
- **Barter Focus**: Multi-item bundle trading and a "Handshake" confirmation system.
- **Loyalty Shop**: Redeem points for exclusive profile badges and status upgrades.
- **Gamified Quests**: Real-time progress tracking for listing views, favorites, and chat engagement.
- **AI Valuations**: Real-time item valuation using AI (Valuator Screen).
- **Modern AR Showcase**: Immersive AR-style item viewing.
- **Production Ready**: Rate limiting (SlowAPI), Request ID tracing, structured logging, and robust environment management.

## 🛠️ Prerequisites & Troubleshooting

### Linux Build Error: Missing Linker
If you encounter this error during `flutter run`:
`ERROR: Target dart_build failed: Error: Failed to find any of [ld.lld, ld] in LocalDirectory: '/usr/lib/llvm-18/bin'`

**Fix:** Install the missing LLVM 18 linker and compiler:
```bash
sudo apt update && sudo apt install -y lld-18 clang-18
sudo ln -sf /usr/bin/ld.lld-18 /usr/lib/llvm-18/bin/ld.lld
```

## ⚙️ Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/Rubil-Mogere-94/Baterpoint.git
cd Baterpoint
```

### 2. Backend Setup (FastAPI)
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Seed the database with modern trade entries
python3 seed_data.py

# Launch the backend
/home/solregem/Baterpoint/backend/venv/bin/python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 3. Frontend Setup (Flutter)
```bash
cd frontend
flutter pub get

# Launch on Linux Desktop
flutter run -d linux
```


# ## 📐 Project Structure

```text
backend/app/
├── models.py      # SQLAlchemy Database Models
├── schemas.py     # Pydantic Schemas
├── services/      # Business Logic (Recommendations, FCM)
└── routers/       # API Endpoints (Analytics, AI, etc.)

frontend/lib/
├── constants/     # Core Design Tokens (Theme, UI Constants)
├── models/        # Type-safe Data Models
├── providers/     # State Management (Auth, Analytics, Recommendations)
├── services/      # API Clients (ListingService, AuthService)
└── screens/       # Feature Screens (AI Valuator, Analytics Dashboard)
```

## ▶️ Run the Application

You can launch the entire Baterpoint stack with a single command.

### Using Make
```bash
make run
```
This target starts the backend services via Docker Compose and then runs the Flutter frontend.

### Using the helper script
```bash
./run.sh
```
The `run.sh` script performs the same steps (Docker Compose up and Flutter run) and can be used directly if you prefer a shell script.

Both methods achieve the same result – the full stack is up and running with one command. 🚀

Ensure Docker and Flutter are installed and your environment meets the prerequisites described earlier.

## 📜 License
Internal Project - All Rights Reserved.
