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
from sqlalchemy import create_engine, Column, Integer, String, Text, Float, ForeignKey, DateTime, Boolean, select, desc
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship

load_dotenv()

DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://user:password@host:port/dbname")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- SQLAlchemy Models ---

class UserModel(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="user", nullable=False)
    subscription_status = Column(String, default="basic")
    created_at = Column(DateTime, default=datetime.utcnow)
    
    listings = relationship("ListingModel", back_populates="owner")
    sent_messages = relationship("ChatMessageModel", back_populates="sender")

class ListingModel(Base):
    __tablename__ = "listings"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text)
    price = Column(Float)
    exchange_item = Column(String)
    trade_type = Column(String)
    category = Column(String)
    image_url = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    view_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    owner = relationship("UserModel", back_populates="listings")
    messages = relationship("ChatMessageModel", back_populates="listing", cascade="all, delete-orphan")

class ChatMessageModel(Base):
    __tablename__ = "chat_messages"
    id = Column(Integer, primary_key=True, index=True)
    listing_id = Column(Integer, ForeignKey("listings.id", ondelete="CASCADE"))
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    message_content = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)

    listing = relationship("ListingModel", back_populates="messages")
    sender = relationship("UserModel", back_populates="sent_messages")

class FavoriteModel(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    listing_id = Column(Integer, ForeignKey("listings.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class OfferModel(Base):
    __tablename__ = "offers"
    id = Column(Integer, primary_key=True, index=True)
    buyer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    listing_id = Column(Integer, ForeignKey("listings.id", ondelete="CASCADE"), nullable=False)
    offered_price = Column(Float, nullable=True)
    offered_item = Column(String, nullable=True)
    status = Column(String, default="pending")  # pending, accepted, rejected
    created_at = Column(DateTime, default=datetime.utcnow)
    
    buyer = relationship("UserModel", foreign_keys=[buyer_id])
    listing = relationship("ListingModel")

# Create tables
Base.metadata.create_all(bind=engine)

# --- Pydantic Models ---

class User(BaseModel):
    id: int
    email: str
    username: str
    role: str
    subscription_status: Optional[str] = "basic"

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
    listing: Optional[Listing] = None

    class Config:
        from_attributes = True

class OfferUpdate(BaseModel):
    status: str

class UserRoleUpdate(BaseModel):
    role: str

class UserSubscriptionUpdate(BaseModel):
    subscription_status: str

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

app = FastAPI()
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

@app.post("/token", response_model=Token)
def login_for_access_token(
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
def register_user(user: UserCreate, db: Annotated[Session, Depends(get_db)]):
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
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count}
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
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count}
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
        file_extension = image.filename.split(".")[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = f"static/images/{unique_filename}"
        
        os.makedirs("static/images", exist_ok=True)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        base_url = str(request.base_url).rstrip("/")
        image_url = f"{base_url}/{file_path}"

        new_listing = ListingModel(
            title=title, description=description, price=cashPrice, exchange_item=exchangeItem,
            trade_type=tradeType, category=category, image_url=image_url, user_id=current_user.id
        )
        db.add(new_listing)
        db.commit()
        db.refresh(new_listing)
        
        return {
            "id": new_listing.id, "title": new_listing.title, "description": new_listing.description, 
            "cashPrice": new_listing.price, "exchangeItem": new_listing.exchange_item, 
            "tradeType": new_listing.trade_type, "category": new_listing.category, 
            "imageUrl": new_listing.image_url, "user_id": new_listing.user_id, "view_count": new_listing.view_count
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
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count}
        for l in listings
    ]

@app.get("/listings/{listing_id}", response_model=Listing)
def get_listing(listing_id: int, db: Annotated[Session, Depends(get_db)]):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    
    listing.view_count += 1
    db.commit()
    db.refresh(listing)

    return {
        "id": listing.id, "title": listing.title, "description": listing.description, 
        "cashPrice": listing.price, "exchangeItem": listing.exchange_item, 
        "tradeType": listing.trade_type, "category": listing.category, 
        "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count
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
        "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count
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
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count}
        for l in listings
    ]

# --- Offers Endpoints ---

@app.post("/listings/{listing_id}/offers", response_model=Offer)
def create_offer(
    listing_id: int,
    offer_data: OfferCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
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

@app.get("/users/me/offers", response_model=List[Offer])
def get_my_offers(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    # Offers the current user has made
    offers = db.query(OfferModel).filter(OfferModel.buyer_id == current_user.id).all()
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
    db: Annotated[Session, Depends(get_db)]
):
    # Offers made on the current user's listings
    offers = db.query(OfferModel).join(ListingModel).filter(ListingModel.user_id == current_user.id).all()
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
        "listing": listing_dict
    }

@app.get("/")
def read_root():
    return {"Hello": "World"}

app.mount("/static", StaticFiles(directory="static"), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
