# Baterpoint: Mixed-Currency Trading Platform

Baterpoint is a **mixed-currency peer-to-peer trading platform** uniting **Barter Trade** (asset/commodity exchange) and **Currency Trade** (cash purchase/sale) into a unified, hybrid marketplace. It solves the classic "double coincidence of wants" limitation of traditional barter by enabling **hybrid settlements** (trading physical items plus cash adjustments) alongside pure barter and direct cash transactions.

## 💱 The Mixed-Currency Architecture

Baterpoint treats physical assets and fiat currency as complementary media of exchange:

1. **Barter Trade (Asset-to-Asset)**: Trade items or services directly with zero cash required, secured by a mutual Handshake confirmation protocol.
2. **Currency Trade (Fiat Sales)**: Instant cash buy/sell transactions in local currency (e.g., KES) with cart, checkout, and order fulfillment.
3. **Mixed Trade (Hybrid Settlement)**: Combine physical goods with a cash top-up/sweetener to resolve valuation differences (e.g., *Smart TV + KSh 8,000 for a Gaming Laptop*).
4. **Gamified Reputation & Loyalty Units**: Earn trade reputation, tier badges, and loyalty points that reward honest, sustainable trading.

## 🎨 Design System
Baterpoint features a modern, responsive design system built for clear trade identification:
- **Trade Badging**: Instant visual distinction between `BARTER`, `CURRENCY`, and `MIXED TRADE`.
- **Dual Valuation Display**: Benchmark fiat prices alongside barter exchange preferences.
- **Micro-animations & Haptics**: Smooth transitions with `flutter_animate` and tactile trade feedback.

## 🚀 Key Features

- **Barter-First Trading**: Core focus on direct item-for-item trades with "Handshake" confirmation system and multi-item bundle trading
- **Flexible Trade Types**: List items as Barter-only, Sale-only, or Both (trade or cash)
- **AI-Powered Recommendations**: Personalized listing suggestions using semantic embeddings (`all-MiniLM-L6-v2`) and cosine similarity
- **Seller Analytics**: Comprehensive dashboard for sellers to track views, offers, conversion rates, and revenue
- **Authentication**: Secure JWT-based login, registration, and **Google Social Login** (OAuth2)
- **Push Notifications**: Real-time alerts for new offers, messages, and order updates via Firebase Cloud Messaging (FCM)
- **Sustainability Badges**: Eco-conscious trading with badges for "upcycled", "locally made", and "eco-friendly" items
- **Loyalty Shop**: Redeem points for exclusive profile badges and status upgrades
- **Gamified Quests**: Real-time progress tracking for listing views, favorites, and chat engagement
- **AI Valuations**: Real-time item valuation using AI (Valuator Screen) — *currently a demo estimate*
- **Modern AR Showcase**: Immersive AR-style item viewing
- **Production Ready**: Rate limiting (SlowAPI), Request ID tracing, structured logging, and robust environment management

## 🔄 Mixed-Currency Trading System

Baterpoint's trading engine operates on three unified settlement modalities:

- **Settlement Modes**: Each listing can be `Barter` (goods-only), `Sale` (fiat currency only), or `Mixed` (accepts pure barter, cash buyout, or hybrid trade).
- **Hybrid Offers**: Make offers combining item assets + cash delta adjustments to balance perceived values.
- **Handshake Confirmation**: Secure dual confirmation where both parties verify receipt of both goods and cash before completion.
- **Multi-Item Bundles**: Bundle multiple items together or mix items and cash in a single transaction.
- **Smart Matching & Valuation**: AI valuation and semantic matching recommend compatible trades and identify fair cash differentials.

## 🛠️ Prerequisites & Troubleshooting

### Linux Build Error: Missing Linker
If you encounter this error during `flutter run`:
`ERROR: Target dart_build failed: Error: Failed to find any of [ld.lld, ld] in LocalDirectory: '/usr/lib/llvm-18/bin'`

**Fix:** Install the missing LLVM 18 linker and compiler:
```bash
sudo apt update && sudo apt install -y lld-18 clang-18
sudo ln -sf /usr/bin/ld.lld-18 /usr/lib/llvm-18/bin/ld.lld
```

### Python bcrypt Compatibility
If you see warnings about "error reading bcrypt version", ensure bcrypt < 4.0.0 is installed:
```bash
pip install "bcrypt<4.0.0"
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

# Seed the database with modern trade entries (optional - tables auto-create on startup)
python3 seed_data.py

# Launch the full stack with a single command
cd ..
./run_all.sh
```

### API Documentation
Once the backend is running, access:
- **Swagger UI**: http://localhost:8000/api/v1/docs
- **ReDoc**: http://localhost:8000/api/v1/redoc
- **Health Check**: http://localhost:8000/health

### 3. Frontend Setup (Flutter)
```bash
cd frontend
flutter pub get

# Launch on Linux Desktop
flutter run -d linux
```

## 📐 Project Structure

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
├── services/      # API Clients (ApiService, AuthService)
└── screens/       
    ├── home/           # Market, search, listings grid
    ├── details/        # Product details with cart/offer actions
    ├── listing/        # Create listing form (photo, category, trade type, price)
    ├── valuation/      # AI Valuator screen (demo estimate)
    ├── auth/           # Login/register with token persistence
    ├── chat/           # API-backed inbox
    ├── profile/        # Real user profile + own listings
    └── cart/           # Live cart with subtotal & order creation
```

## ▶️ Run the Application

You can launch the entire Baterpoint stack with a single command.

### Using Make
```bash
./run_all.sh
```
Launch the full stack (backend + frontend) with a single command (no Docker required).

### Using the helper script
```bash
./run.sh
```
The `run.sh` script performs the same steps (Docker Compose up and Flutter run) and can be used directly if you prefer a shell script.

**Note:** The script requires Flutter to be installed and available in your `PATH`. Install Flutter from https://flutter.dev and ensure `flutter` is callable.

## 📜 License
Internal Project - All Rights Reserved.