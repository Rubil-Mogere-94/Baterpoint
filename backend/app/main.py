import os
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi_socketio import SocketManager
import logging
import uuid
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv

from .database import engine, Base, SessionLocal
from .routers import auth, listings, cart, orders, users, offers, chat

load_dotenv()

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Baterpoint API - Amazon Overhaul",
    description="Refactored and Enhanced API for Baterpoint",
    version="2.0.0"
)

# Limiter setup
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request ID Middleware
@app.middleware("http")
async def add_request_id(request: Request, call_next):
    request_id = str(uuid.uuid4())
    # You could use a contextvar here for structured logging
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response

# SocketManager setup
sio = SocketManager(app=app)

# Include Routers
app.include_router(auth.router)
app.include_router(listings.router)
app.include_router(cart.router)
app.include_router(orders.router)
app.include_router(users.router)
app.include_router(offers.router)
app.include_router(chat.router)

# Mount Static Files
os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/health")
def health_check():
    return {"status": "healthy", "version": "2.0.0"}

# --- Socket.IO Handlers (Simplified for now, can be modularized further) ---

@app.sio.on("connect")
async def handle_connect(sid, environ):
    print(f"Client connected: {sid}")

# Note: Integration with current_user in Socket.IO requires token validation
# which we can copy from the original main.py if needed.

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
