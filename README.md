# Baterpoint

Baterpoint is a premium, peer-to-peer trading and listing platform. It features a robust FastAPI backend and a cross-platform Flutter frontend, supporting real-time chat, listing management, and a gamified loyalty system.

## 🎨 V2 Design System
Baterpoint has been upgraded to a premium **V2 Design System**, prioritizing visual excellence and smooth user experience:
- **Glassmorphism & Holographics**: Featuring custom `HolographicBackground` mesh gradients and heavy blur effects for a premium feel.
- **Centralized Tokens**: Unified spacing, radii, and shadow tokens for consistent UI across the entire app.
- **Modern Typography**: Powered by Google Fonts (Outfit and Inter) for a sleek, contemporary look.
- **Micro-animations**: Enhanced with `flutter_animate`, shimmer loaders, and celebratory confetti effects.

## 🚀 Features

- **Authentication**: Secure JWT-based login and registration.
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
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
# Create .env with DATABASE_URL and SECRET_KEY
uvicorn app.main:app --reload
```

### 3. Frontend Setup (Flutter)
```bash
cd frontend
# Create .env with API_URL=http://localhost:8000
flutter pub get
flutter run
```

## 📐 Project Structure

```text
frontend/lib/
├── constants/     # Core Design Tokens (Theme, UI Constants)
├── models/        # Type-safe Data Models
├── providers/     # State Management (Auth, Theme)
├── screens/       # Feature Screens (AI Valuator, BaterPass, etc.)
├── services/      # API Clients & Environment Config
└── widgets/       # Reusable UI Components (ListingCard, Shimmer, etc.)
```

## 📜 License
Internal Project - All Rights Reserved.
