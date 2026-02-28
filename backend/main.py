import os
from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form, Request
from fastapi.staticfiles import StaticFiles
from typing import Annotated, Optional, List
from pydantic import BaseModel, Field, EmailStr
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
import shutil
import uuid
from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi_socketio import SocketManager
from sqlalchemy import create_engine, Column, Integer, String, Text, Float, ForeignKey, DateTime, Boolean, select, desc, func
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
import random
import logging
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Configure Structured Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [%(name)s] [request_id=%(request_id)s] %(message)s",
)
logger = logging.getLogger("baterpoint")

# Custom log filter to inject request_id
class RequestIdFilter(logging.Filter):
    def filter(self, record):
        record.request_id = getattr(logging.thread_local, "request_id", "N/A")
        return True

logger.addFilter(RequestIdFilter())
logging.thread_local = type('obj', (object,), {'request_id': 'N/A'})

load_dotenv()

# Default to SQLite for easier local development if DATABASE_URL is not set
DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    DATABASE_URL = "sqlite:///./test.db"
    print("WARNING: DATABASE_URL not set, defaulting to SQLite: sqlite:///./test.db")

# SQLite needs specific connect_args for multithreading
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL, 
        connect_args={"check_same_thread": False},
        pool_pre_ping=True,
        pool_recycle=3600
    )
else:
    # pool_pre_ping=True helps with "SSL connection has been closed unexpectedly" errors
    # by verifying the connection is still alive before using it.
    engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=3600)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

limiter = Limiter(key_func=get_remote_address)
app = FastAPI()
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# --- SQLAlchemy Models ---

class UserModel(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="user", nullable=False)
    subscription_status = Column(String, default="basic")
    overall_rating = Column(Float, default=0.0)
    total_reviews = Column(Integer, default=0)
    loyalty_points = Column(Integer, default=0)
    device_token = Column(String, nullable=True)
    successful_trades = Column(Integer, default=0)
    trade_reputation = Column(Float, default=5.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    listings = relationship("ListingModel", back_populates="owner")
    chat_messages = relationship("ChatMessageModel", back_populates="sender")
    received_offers = relationship("OfferModel", back_populates="buyer")
    quests = relationship("UserQuestModel", back_populates="user")

class DealModel(Base):
    __tablename__ = "deals"
    id = Column(Integer, primary_key=True, index=True)
    listing_id = Column(Integer, ForeignKey("listings.id"))
    discount_percentage = Column(Integer)
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    
    listing = relationship("ListingModel")

class ListingModel(Base):
    __tablename__ = "listings"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    price = Column(Float, nullable=True) # cashPrice
    exchange_item = Column(String, nullable=True) # exchangeItem
    trade_type = Column(String) # "Barter", "Sale", or "Both"
    category = Column(String)
    image_url = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    view_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    owner = relationship("UserModel", back_populates="listings")
    favorites = relationship("FavoriteModel", back_populates="listing")
    offers = relationship("OfferModel", back_populates="listing")

class ChatMessageModel(Base):
    __tablename__ = "chat_messages"
    id = Column(Integer, primary_key=True, index=True)
    listing_id = Column(Integer, ForeignKey("listings.id"))
    sender_id = Column(Integer, ForeignKey("users.id"))
    message_content = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)

    sender = relationship("UserModel", back_populates="chat_messages")

class FavoriteModel(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    listing_id = Column(Integer, ForeignKey("listings.id"))
    
    user = relationship("UserModel")
    listing = relationship("ListingModel", back_populates="favorites")

class OfferModel(Base):
    __tablename__ = "offers"
    id = Column(Integer, primary_key=True, index=True)
    buyer_id = Column(Integer, ForeignKey("users.id"))
    listing_id = Column(Integer, ForeignKey("listings.id"))
    offered_price = Column(Float, nullable=True)
    offered_item = Column(String, nullable=True)
    status = Column(String, default="pending") # "pending", "accepted", "rejected", "completed"
    buyer_confirmed = Column(Boolean, default=False)
    seller_confirmed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    buyer = relationship("UserModel", foreign_keys=[buyer_id])
    listing = relationship("ListingModel")

class QuestModel(Base):
    __tablename__ = "quests"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    goal_type = Column(String, nullable=False) # e.g., "view", "favorite", "offer"
    goal_value = Column(Integer, nullable=False)
    points_reward = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class UserQuestModel(Base):
    __tablename__ = "user_quests"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    quest_id = Column(Integer, ForeignKey("quests.id"))
    progress = Column(Integer, default=0)
    completed = Column(Boolean, default=False)
    last_updated = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("UserModel", back_populates="quests")
    quest = relationship("QuestModel")

class RewardModel(Base):
    __tablename__ = "rewards"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    points_cost = Column(Integer, nullable=False)
    reward_type = Column(String, default="badge") # e.g., badge, status, discount

class UserRewardModel(Base):
    __tablename__ = "user_rewards"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    reward_id = Column(Integer, ForeignKey("rewards.id"))
    redeemed_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("UserModel")
    reward = relationship("RewardModel")

class NotificationModel(Base):
    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String)
    message = Column(String)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

# --- Pydantic Models ---

class User(BaseModel):
    id: int
    email: str
    username: str
    role: str
    subscription_status: Optional[str] = "basic"
    overall_rating: Optional[float] = 0.0
    total_reviews: Optional[int] = 0
    loyalty_points: Optional[int] = 0
    device_token: Optional[str] = None
    successful_trades: Optional[int] = 0
    trade_reputation: Optional[float] = 5.0

    class Config:
        from_attributes = True

class UserCreate(BaseModel):
    username: str
    email: str
    password: str = Field(min_length=8, max_length=72)
    role: str = "user"

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class Listing(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    cashPrice: Optional[float] = None
    exchangeItem: Optional[str] = None
    category: str
    tradeType: str
    imageUrl: Optional[str] = None
    user_id: int
    view_count: int
    owner_username: Optional[str] = None
    owner_rating: Optional[float] = 0.0
    owner_reviews: Optional[int] = 0

    class Config:
        from_attributes = True

class OfferCreate(BaseModel):
    offered_price: Optional[float] = None
    offered_item: Optional[str] = None

class Offer(BaseModel):
    id: int
    buyer_id: int
    listing_id: int
    offered_price: Optional[float] = None
    offered_item: Optional[str] = None
    status: str
    buyer_confirmed: bool = False
    seller_confirmed: bool = False
    listing: Optional[Listing] = None

    class Config:
        from_attributes = True

class Quest(BaseModel):
    id: int
    title: str
    description: str
    goal_type: str
    goal_value: int
    points_reward: int

    class Config:
        from_attributes = True

class UserQuest(BaseModel):
    id: int
    quest_id: int
    progress: int
    completed: bool
    quest: Quest

    class Config:
        from_attributes = True

class Reward(BaseModel):
    id: int
    title: str
    description: str
    points_cost: int
    reward_type: str

    class Config:
        from_attributes = True

class UserReward(BaseModel):
    id: int
    reward_id: int
    redeemed_at: datetime
    reward: Reward

    class Config:
        from_attributes = True

class Notification(BaseModel):
    id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

class Deal(BaseModel):
    id: int
    listing_id: int
    discount_percentage: int
    start_time: datetime
    end_time: datetime
    listing: Listing

    class Config:
        from_attributes = True

class OfferUpdate(BaseModel):
    status: str

class UserRoleUpdate(BaseModel):
    role: str

class UserSubscriptionUpdate(BaseModel):
    subscription_status: str

class DeviceTokenUpdate(BaseModel):
    device_token: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8, max_length=72)

class ListingUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    cashPrice: Optional[float] = None
    exchangeItem: Optional[str] = None
    category: Optional[str] = None
    tradeType: Optional[str] = None

# --- FastAPI App & Socket.IO ---

app = FastAPI(
    title="Baterpoint API",
    description="Premium Barter & E-commerce Platform API",
    version="1.0.0"
)

# Request ID Middleware
@app.middleware("http")
async def add_request_id(request: Request, call_next):
    request_id = str(uuid.uuid4())
    logging.thread_local.request_id = request_id
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response

sio = SocketManager(app=app)

SECRET_KEY = os.environ.get("SECRET_KEY", "a_super_secret_key_that_should_be_in_env")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Store active connections
active_sids = {} # {sid: {'user_id': int, 'username': str, 'trade_id': int}}

async def get_sio_current_user(token: str, db: Session):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(UserModel).filter(UserModel.username == username).first()
    if user is None:
        raise credentials_exception
    return user

@app.sio.on("connect")
async def handle_connect(sid, environ):
    print(f"Client connected: {sid}")

@app.sio.on("authenticate")
async def authenticate(sid, data):
    token = data.get("token")
    if not token:
        await app.sio.emit("auth_error", {"detail": "Authentication token missing"}, room=sid)
        return

    db = SessionLocal()
    try:
        current_user = await get_sio_current_user(token, db)
        active_sids[sid] = {'user_id': current_user.id, 'username': current_user.username}
        await app.sio.emit("authenticated", {"username": current_user.username, "user_id": current_user.id}, room=sid)
        print(f"Client {sid} authenticated as {current_user.username}")
    except HTTPException as e:
        await app.sio.emit("auth_error", {"detail": e.detail}, room=sid)
    except Exception as e:
        print(f"Authentication error for {sid}: {e}")
        await app.sio.emit("auth_error", {"detail": "Server error during authentication"}, room=sid)
    finally:
        db.close()

@app.sio.on("join_trade_chat")
async def join_trade_chat(sid, data):
    if sid not in active_sids or 'user_id' not in active_sids[sid]:
        await app.sio.emit("auth_error", {"detail": "Not authenticated"}, room=sid)
        return

    trade_id = data.get("trade_id")
    if not trade_id:
        await app.sio.emit("chat_error", {"detail": "Trade ID missing"}, room=sid)
        return

    room = f"trade_{trade_id}"
    app.sio.enter_room(sid, room)
    active_sids[sid]['trade_id'] = trade_id
    await app.sio.emit("joined_trade_chat", {"trade_id": trade_id, "room": room}, room=sid)
    await app.sio.emit("status_message", {"message": f"{active_sids[sid]['username']} has joined the chat."}, room=room, skip_sid=sid)

    db = SessionLocal()
    try:
        messages = db.query(ChatMessageModel).filter(ChatMessageModel.listing_id == trade_id).order_by(ChatMessageModel.timestamp).all()
        for msg in messages:
            await app.sio.emit(
                "message",
                {
                    "sender": msg.sender.username,
                    "message": msg.message_content,
                    "timestamp": msg.timestamp.isoformat(),
                    "trade_id": trade_id
                },
                room=sid
            )
    except Exception as e:
        print(f"Error fetching message history for trade {trade_id}: {e}")
        await app.sio.emit("chat_error", {"detail": "Error fetching message history"}, room=sid)
    finally:
        db.close()

@app.sio.on("send_message")
async def send_message(sid, data):
    if sid not in active_sids or 'user_id' not in active_sids[sid] or 'trade_id' not in active_sids[sid]:
        await app.sio.emit("auth_error", {"detail": "Not authenticated or not in a trade chat"}, room=sid)
        return

    message_content = data.get("message")
    trade_id = active_sids[sid]['trade_id']
    sender_id = active_sids[sid]['user_id']
    sender_username = active_sids[sid]['username']

    if not message_content:
        return

    db = SessionLocal()
    try:
        new_msg = ChatMessageModel(listing_id=trade_id, sender_id=sender_id, message_content=message_content)
        db.add(new_msg)
        db.commit()

        # Update quest progress for chat
        update_quest_progress(sender_id, "chat", db)

        await app.sio.emit(
            "message",
            {
                "sender": sender_username,
                "message": message_content,
                "timestamp": datetime.utcnow().isoformat(),
                "trade_id": trade_id
            },
            room=f"trade_{trade_id}"
        )
    except Exception as e:
        print(f"Error saving or broadcasting message for trade {trade_id}: {e}")
        await app.sio.emit("chat_error", {"detail": "Server error during message sending"}, room=sid)
    finally:
        db.close()

@app.sio.on("disconnect")
async def handle_disconnect(sid):
    if sid in active_sids:
        username = active_sids[sid].get('username', 'Unknown')
        trade_id = active_sids[sid].get('trade_id')
        if trade_id:
            room = f"trade_{trade_id}"
            app.sio.leave_room(sid, room)
            await app.sio.emit("status_message", {"message": f"{username} has left the chat."}, room=room, skip_sid=sid)
        del active_sids[sid]
        print(f"Client disconnected: {sid} ({username})")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)], db: Annotated[Session, Depends(get_db)]):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(UserModel).filter(UserModel.username == username).first()
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_admin_user(current_user: Annotated[UserModel, Depends(get_current_user)]):
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not an admin user")
    return current_user

@app.get("/users/me", response_model=User)
async def read_users_me(current_user: Annotated[UserModel, Depends(get_current_user)]):
    return current_user

@app.post("/users/me/device-token")
async def register_device_token(
    update: DeviceTokenUpdate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    current_user.device_token = update.device_token
    db.commit()
    return {"message": "Success"}

@app.post("/token", response_model=Token)
@limiter.limit("5/minute")
def login_for_access_token(
    request: Request,
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()], 
    db: Annotated[Session, Depends(get_db)]
):
    user = db.query(UserModel).filter(UserModel.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.username}, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/register/", response_model=User)
@limiter.limit("3/minute")
def register_user(request: Request, user: UserCreate, db: Annotated[Session, Depends(get_db)]):
    db_user = db.query(UserModel).filter((UserModel.username == user.username) | (UserModel.email == user.email)).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username or email already registered")
    
    new_user = UserModel(
        username=user.username,
        email=user.email,
        hashed_password=get_password_hash(user.password),
        role=user.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.get("/users/me/listings", response_model=List[Listing])
async def read_own_listings(current_user: Annotated[UserModel, Depends(get_current_user)]):
    return [
        {"id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
         "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
         "owner_username": current_user.username, "owner_rating": current_user.overall_rating, "owner_reviews": current_user.total_reviews}
        for l in current_user.listings
    ]

@app.get("/users/me/chats", response_model=List[Listing])
async def read_user_chats(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    listings = db.query(ListingModel).join(ChatMessageModel).filter(
        (ChatMessageModel.sender_id == current_user.id) | (ListingModel.user_id == current_user.id)
    ).distinct().all()
    
    return [
        {"id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
         "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
         "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, "owner_reviews": l.owner.total_reviews}
        for l in listings
    ]

@app.get("/admin/users", response_model=List[User])
async def get_all_users(
    current_user: Annotated[UserModel, Depends(get_current_active_admin_user)],
    db: Annotated[Session, Depends(get_db)]
):
    return db.query(UserModel).all()

@app.put("/admin/users/{user_id}/role", response_model=User)
async def update_user_role(
    user_id: int,
    user_role_update: UserRoleUpdate,
    current_user: Annotated[UserModel, Depends(get_current_active_admin_user)],
    db: Annotated[Session, Depends(get_db)]
):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = user_role_update.role
    db.commit()
    db.refresh(user)
    return user

@app.put("/admin/users/{user_id}/subscription", response_model=User)
async def update_user_subscription(
    user_id: int,
    user_subscription_update: UserSubscriptionUpdate,
    current_user: Annotated[UserModel, Depends(get_current_active_admin_user)],
    db: Annotated[Session, Depends(get_db)]
):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.subscription_status = user_subscription_update.subscription_status
    db.commit()
    db.refresh(user)
    return user

@app.post("/listings/", status_code=status.HTTP_201_CREATED)
def create_listing(
    request: Request,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    title: str = Form(...),
    description: Optional[str] = Form(None),
    cashPrice: Optional[float] = Form(None),
    exchangeItem: Optional[str] = Form(None),
    category: str = Form(...),
    tradeType: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        # Handle empty strings from form data for float conversion
        try:
            float_price = float(cashPrice) if cashPrice and str(cashPrice).strip() != "" else None
        except (ValueError, TypeError):
            float_price = None

        file_extension = image.filename.split(".")[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = f"static/images/{unique_filename}"
        
        os.makedirs("static/images", exist_ok=True)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        base_url = str(request.base_url).rstrip("/")
        image_url = f"{base_url}/{file_path}"

        new_listing = ListingModel(
            title=title, description=description, price=float_price, exchange_item=exchangeItem,
            trade_type=tradeType, category=category, image_url=image_url, user_id=current_user.id
        )
        db.add(new_listing)
        db.commit()
        db.refresh(new_listing)
        
        return {
            "id": new_listing.id, "title": new_listing.title, "description": new_listing.description, 
            "cashPrice": new_listing.price, "exchangeItem": new_listing.exchange_item, 
            "tradeType": new_listing.trade_type, "category": new_listing.category, 
            "imageUrl": new_listing.image_url, "user_id": new_listing.user_id, "view_count": new_listing.view_count,
            "owner_username": current_user.username, "owner_rating": current_user.overall_rating, "owner_reviews": current_user.total_reviews
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creating listing: {e}")

@app.get("/listings/", response_model=List[Listing])
def get_listings(
    db: Annotated[Session, Depends(get_db)], 
    search: Optional[str] = None,
    category: Optional[str] = None,
    tradeType: Optional[str] = None,
    sortBy: Optional[str] = None,
    order: Optional[str] = 'desc',
    skip: int = 0,
    limit: int = 20
):
    query = db.query(ListingModel)

    if search:
        query = query.filter((ListingModel.title.ilike(f"%{search}%")) | (ListingModel.description.ilike(f"%{search}%")))
    
    if category and category != 'All':
        query = query.filter(ListingModel.category == category)

    if tradeType:
        query = query.filter(ListingModel.trade_type == tradeType)

    if sortBy == 'price':
        query = query.order_by(desc(ListingModel.price) if order == 'desc' else ListingModel.price)
    else:
        query = query.order_by(desc(ListingModel.created_at) if order == 'desc' else ListingModel.created_at)
    
    listings = query.offset(skip).limit(limit).all()
    return [
        {"id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
         "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
         "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, "owner_reviews": l.owner.total_reviews}
        for l in listings
    ]

@app.get("/listings/{listing_id}", response_model=Listing)
def get_listing(listing_id: int, request: Request, db: Annotated[Session, Depends(get_db)]):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    
    listing.view_count += 1
    db.commit()
    db.refresh(listing)

    # Optional: Update quest progress for viewing
    # Note: current_user is needed, so let's add it as an optional dependency or handled by token if present
    auth_header = request.headers.get("Authorization")
    if auth_header:
        try:
            token = auth_header.split(" ")[1]
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            username: str = payload.get("sub")
            if username:
                user = db.query(UserModel).filter(UserModel.username == username).first()
                if user:
                    update_quest_progress(user.id, "view", db)
        except:
            pass

    return {
        "id": listing.id, "title": listing.title, "description": listing.description, 
        "cashPrice": listing.price, "exchangeItem": listing.exchange_item, 
        "tradeType": listing.trade_type, "category": listing.category, 
        "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count,
        "owner_username": listing.owner.username, "owner_rating": listing.owner.overall_rating, "owner_reviews": listing.owner.total_reviews
    }

@app.put("/users/me", response_model=User)
async def update_user_me(
    user_update: UserUpdate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    if user_update.username:
        # Check if username already taken
        existing = db.query(UserModel).filter(UserModel.username == user_update.username).first()
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=400, detail="Username already taken")
        current_user.username = user_update.username
    
    if user_update.email:
        existing = db.query(UserModel).filter(UserModel.email == user_update.email).first()
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=400, detail="Email already registered")
        current_user.email = user_update.email
    
    if user_update.password:
        current_user.hashed_password = get_password_hash(user_update.password)
    
    db.commit()
    db.refresh(current_user)
    return current_user

@app.put("/listings/{listing_id}", response_model=Listing)
def update_listing(
    listing_id: int,
    listing_update: ListingUpdate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to update this listing")
    
    update_data = listing_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        if key == "cashPrice":
            listing.price = value
        elif key == "exchangeItem":
            listing.exchange_item = value
        elif key == "tradeType":
            listing.trade_type = value
        else:
            setattr(listing, key, value)
    
    db.commit()
    db.refresh(listing)
    return {
        "id": listing.id, "title": listing.title, "description": listing.description, 
        "cashPrice": listing.price, "exchangeItem": listing.exchange_item, 
        "tradeType": listing.trade_type, "category": listing.category, 
        "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count,
        "owner_username": listing.owner.username, "owner_rating": listing.owner.overall_rating, "owner_reviews": listing.owner.total_reviews
    }

@app.delete("/listings/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_listing(
    listing_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to delete this listing")
    
    # Delete image file if it exists
    if listing.image_url:
        try:
            # Extract path from URL
            path_parts = listing.image_url.split("/")
            file_path = "/".join(path_parts[-3:]) # Assuming static/images/filename
            if os.path.exists(file_path):
                os.remove(file_path)
        except Exception as e:
            print(f"Error deleting image file: {e}")

    db.delete(listing)
    db.commit()
    return None

@app.post("/listings/{listing_id}/favorite", status_code=status.HTTP_200_OK)
def toggle_favorite(
    listing_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
        
    favorite = db.query(FavoriteModel).filter(
        FavoriteModel.user_id == current_user.id,
        FavoriteModel.listing_id == listing_id
    ).first()
    
    if favorite:
        db.delete(favorite)
        db.commit()
        return {"status": "unfavorited"}
    else:
        new_fav = FavoriteModel(user_id=current_user.id, listing_id=listing_id)
        db.add(new_fav)
        update_quest_progress(current_user.id, "favorite", db)
        db.commit()
        return {"status": "favorited"}

@app.get("/users/me/favorites", response_model=List[Listing])
def get_user_favorites(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    favorites = db.query(FavoriteModel).filter(FavoriteModel.user_id == current_user.id).all()
    listing_ids = [fav.listing_id for fav in favorites]
    if not listing_ids:
        return []
        
    listings = db.query(ListingModel).filter(ListingModel.id.in_(listing_ids)).order_by(desc(ListingModel.created_at)).all()
    return [
        {"id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
         "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
         "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, "owner_reviews": l.owner.total_reviews}
        for l in listings
    ]

@app.get("/listings/recommendations", response_model=List[Listing])
def get_recommendations(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    limit: int = 10
):
    try:
        # 1. Get categories of user's favorites
        fav_listings = db.query(ListingModel).join(FavoriteModel).filter(FavoriteModel.user_id == current_user.id).all()
        fav_categories = [l.category for l in fav_listings]
        
        # 2. Get categories of user's own listings
        own_categories = [l.category for l in current_user.listings]
        
        preferred_categories = list(set(fav_categories + own_categories))
        
        query = db.query(ListingModel).filter(ListingModel.user_id != current_user.id)
        
        if preferred_categories:
            query = query.filter(ListingModel.category.in_(preferred_categories))
        
        # Sort by view_count for "recommendation" quality
        recommendations = query.order_by(desc(ListingModel.view_count)).limit(limit).all()
        
        # If not enough recommendations, fill with trending items
        if len(recommendations) < limit:
            additional_limit = limit - len(recommendations)
            rec_ids = [r.id for r in recommendations]
            trending = db.query(ListingModel).filter(
                ListingModel.user_id != current_user.id,
                ~ListingModel.id.in_(rec_ids) if rec_ids else True
            ).order_by(desc(ListingModel.view_count)).limit(additional_limit).all()
            recommendations.extend(trending)
            
        return [
            {"id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
             "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
             "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
             "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, "owner_reviews": l.owner.total_reviews}
            for l in recommendations
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching recommendations: {str(e)}")

# --- Offers Endpoints ---

@app.post("/listings/{listing_id}/offers", response_model=Offer)
def create_offer(
    listing_id: int,
    offer_data: OfferCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    try:
        listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
        if not listing:
            raise HTTPException(status_code=404, detail="Listing not found")
        if listing.user_id == current_user.id:
            raise HTTPException(status_code=400, detail="Cannot make an offer on your own listing")
        
        new_offer = OfferModel(
            buyer_id=current_user.id,
            listing_id=listing_id,
            offered_price=offer_data.offered_price,
            offered_item=offer_data.offered_item
        )
        db.add(new_offer)
        update_quest_progress(current_user.id, "offer", db)
        db.commit()
        db.refresh(new_offer)
        return {
            "id": new_offer.id,
            "buyer_id": new_offer.buyer_id,
            "listing_id": new_offer.listing_id,
            "offered_price": new_offer.offered_price,
            "offered_item": new_offer.offered_item,
            "status": new_offer.status,
            "listing": {
                "id": listing.id, "title": listing.title, "description": listing.description, 
                "cashPrice": listing.price, "exchangeItem": listing.exchange_item, 
                "tradeType": listing.trade_type, "category": listing.category, 
                "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error creating offer: {str(e)}")

@app.get("/users/me/offers", response_model=List[Offer])
def get_my_offers(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    skip: int = 0,
    limit: int = 10
):
    # Offers the current user has made
    offers = db.query(OfferModel).filter(OfferModel.buyer_id == current_user.id).offset(skip).limit(limit).all()
    # Eager load listing for rich display
    result = []
    for offer in offers:
        l = db.query(ListingModel).filter(ListingModel.id == offer.listing_id).first()
        listing_dict = None
        if l:
            listing_dict = {
                "id": l.id, "title": l.title, "description": l.description, 
                "cashPrice": l.price, "exchangeItem": l.exchange_item, 
                "tradeType": l.trade_type, "category": l.category, 
                "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count
            }
        result.append({
            "id": offer.id,
            "buyer_id": offer.buyer_id,
            "listing_id": offer.listing_id,
            "offered_price": offer.offered_price,
            "offered_item": offer.offered_item,
            "status": offer.status,
            "listing": listing_dict
        })
    return result

@app.get("/users/me/received_offers", response_model=List[Offer])
def get_received_offers(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    skip: int = 0,
    limit: int = 10
):
    # Offers made on the current user's listings
    offers = db.query(OfferModel).join(ListingModel).filter(ListingModel.user_id == current_user.id).offset(skip).limit(limit).all()
    result = []
    for offer in offers:
        l = db.query(ListingModel).filter(ListingModel.id == offer.listing_id).first()
        listing_dict = None
        if l:
            listing_dict = {
                "id": l.id, "title": l.title, "description": l.description, 
                "cashPrice": l.price, "exchangeItem": l.exchange_item, 
                "tradeType": l.trade_type, "category": l.category, 
                "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count
            }
        result.append({
            "id": offer.id,
            "buyer_id": offer.buyer_id,
            "listing_id": offer.listing_id,
            "offered_price": offer.offered_price,
            "offered_item": offer.offered_item,
            "status": offer.status,
            "listing": listing_dict
        })
    return result

@app.put("/offers/{offer_id}", response_model=Offer)
def update_offer_status(
    offer_id: int,
    offer_update: OfferUpdate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    offer = db.query(OfferModel).filter(OfferModel.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    
    listing = db.query(ListingModel).filter(ListingModel.id == offer.listing_id).first()
    if listing.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to respond to this offer")
    
    if offer_update.status not in ["accepted", "rejected", "pending"]:
         raise HTTPException(status_code=400, detail="Invalid status")
         
    offer.status = offer_update.status
    db.commit()
    db.refresh(offer)
    listing_dict = None
    if listing:
        listing_dict = {
            "id": listing.id, "title": listing.title, "description": listing.description, 
            "cashPrice": listing.price, "exchangeItem": listing.exchange_item, 
            "tradeType": listing.trade_type, "category": listing.category, 
            "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count
        }
    return {
        "id": offer.id,
        "buyer_id": offer.buyer_id,
        "listing_id": offer.listing_id,
        "offered_price": offer.offered_price,
        "offered_item": offer.offered_item,
        "status": offer.status,
        "buyer_confirmed": offer.buyer_confirmed,
        "seller_confirmed": offer.seller_confirmed,
        "listing": listing_dict
    }

@app.post("/offers/{offer_id}/confirm", response_model=Offer)
def confirm_trade(
    offer_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    try:
        offer = db.query(OfferModel).filter(OfferModel.id == offer_id).first()
        if not offer:
            raise HTTPException(status_code=404, detail="Offer not found")
        if offer.status != "accepted":
            raise HTTPException(status_code=400, detail="Trade must be accepted before confirmation")
        
        listing = db.query(ListingModel).filter(ListingModel.id == offer.listing_id).first()
        
        if current_user.id == offer.buyer_id:
            offer.buyer_confirmed = True
        elif current_user.id == listing.user_id:
            offer.seller_confirmed = True
        else:
            raise HTTPException(status_code=403, detail="Not authorized to confirm this trade")
        
        if offer.buyer_confirmed and offer.seller_confirmed:
            offer.status = "completed"
            # Update stats
            buyer = db.query(UserModel).filter(UserModel.id == offer.buyer_id).first()
            seller = db.query(UserModel).filter(UserModel.id == listing.user_id).first()
            
            buyer.successful_trades = (buyer.successful_trades or 0) + 1
            seller.successful_trades = (seller.successful_trades or 0) + 1
            
            # Simple reputation boost
            buyer.trade_reputation = min(5.0, (buyer.trade_reputation or 5.0) + 0.1)
            seller.trade_reputation = min(5.0, (seller.trade_reputation or 5.0) + 0.1)
            
            # Reward loyalty points
            buyer.loyalty_points += 50
            seller.loyalty_points += 50
            
            send_push_notification(buyer.id, "🤝 Trade Completed!", f"Your exchange for '{listing.title}' is officially complete.", db)
            send_push_notification(seller.id, "🤝 Trade Completed!", f"Your exchange for '{listing.title}' is officially complete.", db)
        
        db.commit()
        db.refresh(offer)
        
        listing_dict = {
            "id": listing.id, "title": listing.title, "description": listing.description, 
            "cashPrice": listing.price, "exchangeItem": listing.exchange_item, 
            "tradeType": listing.trade_type, "category": listing.category, 
            "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count
        }
        
        return {
            "id": offer.id,
            "buyer_id": offer.buyer_id,
            "listing_id": offer.listing_id,
            "offered_price": offer.offered_price,
            "offered_item": offer.offered_item,
            "status": offer.status,
            "buyer_confirmed": offer.buyer_confirmed,
            "seller_confirmed": offer.seller_confirmed,
            "listing": listing_dict
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error confirming trade: {str(e)}")

@app.get("/users/me/quests", response_model=List[UserQuest])
def get_user_quests(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    # Initialize quests if user has none
    user_quests = db.query(UserQuestModel).filter(UserQuestModel.user_id == current_user.id).all()
    if not user_quests:
        all_quests = db.query(QuestModel).all()
        # Seed if no quests in DB at all
        if not all_quests:
            seed_quests = [
                QuestModel(title="Explorer", description="View 5 different listings", goal_type="view", goal_value=5, points_reward=50),
                QuestModel(title="Collector", description="Favorite 3 listings", goal_type="favorite", goal_value=3, points_reward=30),
                QuestModel(title="Negotiator", description="Make 1 offer", goal_type="offer", goal_value=1, points_reward=100),
                QuestModel(title="Chat Master", description="Send 5 chat messages", goal_type="chat", goal_value=5, points_reward=50),
            ]
            db.add_all(seed_quests)
            db.commit()
            all_quests = seed_quests
            
        user_quests = [UserQuestModel(user_id=current_user.id, quest_id=q.id) for q in all_quests]
        db.add_all(user_quests)
        db.commit()
        for uq in user_quests:
            db.refresh(uq)
            
    return user_quests

@app.post("/users/me/quests/{user_quest_id}/claim")
def claim_quest_reward(
    user_quest_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    try:
        uq = db.query(UserQuestModel).filter(UserQuestModel.id == user_quest_id, UserQuestModel.user_id == current_user.id).first()
        if not uq:
            raise HTTPException(status_code=404, detail="Quest not found")
        if uq.completed:
            raise HTTPException(status_code=400, detail="Quest already completed")
        if uq.progress < uq.quest.goal_value:
            raise HTTPException(status_code=400, detail="Quest progress not complete")
            
        uq.completed = True
        current_user.loyalty_points += uq.quest.points_reward
        db.commit()
        return {"message": "Success", "points_awarded": uq.quest.points_reward, "total_points": current_user.loyalty_points}
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error claiming quest reward: {str(e)}")

def update_quest_progress(user_id: int, goal_type: str, db: Session, amount: int = 1):
    user_quests = db.query(UserQuestModel).join(QuestModel).filter(
        UserQuestModel.user_id == user_id,
        QuestModel.goal_type == goal_type,
        UserQuestModel.completed == False
    ).all()
    
    for uq in user_quests:
        if uq.progress < uq.quest.goal_value:
            uq.progress += amount
            uq.last_updated = datetime.utcnow()
    db.commit()

@app.get("/listings/deal-of-the-hour", response_model=Deal)
def get_deal_of_the_hour(
    db: Annotated[Session, Depends(get_db)]
):
    try:
        now = datetime.utcnow()
        deal = db.query(DealModel).filter(DealModel.end_time > now).first()
        
        if not deal:
            # Create a new deal
            # Pick a random listing with a price
            listing = db.query(ListingModel).filter(ListingModel.price > 0).order_by(func.random()).first()
            if not listing:
                 raise HTTPException(status_code=404, detail="No suitable listing for a deal")
            
            deal = DealModel(
                listing_id=listing.id,
                discount_percentage=random.choice([10, 15, 20, 25, 30, 50]),
                start_time=now,
                end_time=now + timedelta(hours=1)
            )
            db.add(deal)
            db.commit()
            db.refresh(deal)
        
        # Construct the rich listing dictionary
        l = deal.listing
        listing_dict = {
            "id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
            "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
            "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
            "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, "owner_reviews": l.owner.total_reviews
        }
        
        return {
            "id": deal.id,
            "listing_id": deal.listing_id,
            "discount_percentage": deal.discount_percentage,
            "start_time": deal.start_time,
            "end_time": deal.end_time,
            "listing": listing_dict
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error processing deal of the hour: {str(e)}")

# --- Loyalty Shop Endpoints ---

@app.get("/rewards/", response_model=List[Reward])
def get_rewards(db: Annotated[Session, Depends(get_db)]):
    rewards = db.query(RewardModel).all()
    if not rewards:
        # Seed rewards
        seed = [
            RewardModel(title="Premium Status", description="Get a premium badge and 24h featured listings", points_cost=500, reward_type="status"),
            RewardModel(title="Verified Badge", description="Show a green checkmark on your profile", points_cost=200, reward_type="badge"),
            RewardModel(title="Deal Hunter", description="Receive notifications for ultra-deals 5 mins earlier", points_cost=300, reward_type="badge"),
        ]
        db.add_all(seed)
        db.commit()
        rewards = db.query(RewardModel).all()
    return rewards

@app.post("/rewards/{reward_id}/redeem", response_model=UserReward)
def redeem_reward(
    reward_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    try:
        reward = db.query(RewardModel).filter(RewardModel.id == reward_id).first()
        if not reward:
            raise HTTPException(status_code=404, detail="Reward not found")
        
        if current_user.loyalty_points < reward.points_cost:
            raise HTTPException(status_code=400, detail="Not enough loyalty points")
        
        # Check if already redeemed (optional, depending on type)
        if reward.reward_type == "badge":
            existing = db.query(UserRewardModel).filter(
                UserRewardModel.user_id == current_user.id,
                UserRewardModel.reward_id == reward_id
            ).first()
            if existing:
                raise HTTPException(status_code=400, detail="Reward already redeemed")
    
        # Deduct points
        current_user.loyalty_points -= reward.points_cost
        
        # Update status if applicable
        if reward.reward_type == "status" and reward.title == "Premium Status":
            current_user.subscription_status = "premium"
    
        user_reward = UserRewardModel(user_id=current_user.id, reward_id=reward.id)
        db.add(user_reward)
        db.commit()
        db.refresh(user_reward)
        
        # Send notification
        send_push_notification(current_user.id, "Reward Redeemed!", f"You've successfully redeemed {reward.title}.", db)
        
        return user_reward
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error redeeming reward: {str(e)}")

@app.get("/users/me/notifications", response_model=List[Notification])
def get_my_notifications(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    try:
        return db.query(NotificationModel).filter(NotificationModel.user_id == current_user.id).order_by(desc(NotificationModel.created_at)).all()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching notifications: {str(e)}")

def send_push_notification(user_id: int, title: str, message: str, db: Session):
    # Mocking FCM/APNS: Log to console and save to DB
    print(f"[PUSH NOTIFICATION] To User {user_id}: {title} - {message}")
    
    new_notif = NotificationModel(user_id=user_id, title=title, message=message)
    db.add(new_notif)
    db.commit()
    
    # In a real app, you'd trigger FCM here using user's device_token
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user and user.device_token:
        # mock_fcm.send(user.device_token, title, message)
        pass

@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(select(1))
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": str(e)}

@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(select(1))
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": str(e)}

app.mount("/static", StaticFiles(directory="static"), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
