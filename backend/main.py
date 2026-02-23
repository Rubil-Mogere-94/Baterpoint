import os
import psycopg2
from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.staticfiles import StaticFiles
from typing import Annotated, Optional, List
from pydantic import BaseModel, Field
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
import shutil
import uuid
from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi_socketio import SocketManager

load_dotenv()

app = FastAPI()
sio = SocketManager(app=app) # Initialize SocketManager

@app.sio.on("connect")
async def handle_connect(sid, environ):
    print(f"Client connected: {sid}")

# Helper function to get current user from token in Socket.IO context
async def get_sio_current_user(token: str, db_connection: psycopg2.extensions.connection):
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
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
    
    cur = db_connection.cursor()
    cur.execute("SELECT id, username, email, role FROM users WHERE username = %s", (token_data.username,))
    user = cur.fetchone()
    cur.close()
    if user is None:
        raise credentials_exception
    return User(id=user[0], username=user[1], email=user[2], role=user[3])

# Store active connections and their associated user/trade_id
active_sids = {} # {sid: {'user_id': int, 'username': str, 'trade_id': int}}

@app.sio.on("authenticate")
async def authenticate(sid, data):
    token = data.get("token")
    if not token:
        await app.sio.emit("auth_error", {"detail": "Authentication token missing"}, room=sid)
        return

    db_gen = get_db_connection()
    try:
        db = next(db_gen)
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
        try:
            db_gen.close()
        except Exception:
            pass

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

    db_gen = get_db_connection()
    try:
        db = next(db_gen)
        cur = db.cursor()
        cur.execute(
            """
            SELECT cm.message_content, u.username, cm.timestamp
            FROM chat_messages cm
            JOIN users u ON cm.sender_id = u.id
            WHERE cm.trade_id = %s
            ORDER BY cm.timestamp
            """,
            (trade_id,)
        )
        messages = cur.fetchall()
        cur.close()
        for msg_content, sender_username, timestamp in messages:
            await app.sio.emit(
                "message",
                {
                    "sender": sender_username,
                    "message": msg_content,
                    "timestamp": timestamp.isoformat(),
                    "trade_id": trade_id
                },
                room=sid
            )
    except Exception as e:
        print(f"Error fetching message history for trade {trade_id}: {e}")
        await app.sio.emit("chat_error", {"detail": "Error fetching message history"}, room=sid)
    finally:
        try:
            db_gen.close()
        except Exception:
            pass

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

    db_gen = get_db_connection()
    try:
        db = next(db_gen)
        cur = db.cursor()
        cur.execute(
            "INSERT INTO chat_messages (trade_id, sender_id, message_content) VALUES (%s, %s, %s)",
            (trade_id, sender_id, message_content)
        )
        db.commit()
        cur.close()

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
        try:
            db_gen.close()
        except Exception:
            pass

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

SECRET_KEY = os.environ.get("SECRET_KEY", "a_super_secret_key_that_should_be_in_env")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

class User(BaseModel):
    id: int
    email: str
    username: str
    role: str
    subscription_status: Optional[str] = "basic"

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

class UserRoleUpdate(BaseModel):
    role: str

class UserSubscriptionUpdate(BaseModel):
    subscription_status: str

os.makedirs("static/images", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")
DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://user:password@host:port/dbname")

def get_db_connection():
    conn = None
    try:
        conn = psycopg2.connect(DATABASE_URL)
        yield conn
    finally:
        if conn:
            conn.close()

def init_db():
    conn = None
    try:
        print("--- Attempting to initialize database ---")
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        
        cur.execute("DROP TABLE IF EXISTS chat_messages CASCADE;")
        cur.execute("DROP TABLE IF EXISTS listings CASCADE;")
        cur.execute("DROP TABLE IF EXISTS users CASCADE;")

        cur.execute("""
            CREATE TABLE users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(255) UNIQUE NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                hashed_password VARCHAR(255) NOT NULL,
                role VARCHAR(50) DEFAULT 'user' NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)

        cur.execute("""
            CREATE TABLE listings (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                price DECIMAL(10, 2),
                exchange_item TEXT,
                trade_type VARCHAR(50),
                category VARCHAR(255),
                image_url TEXT,
                user_id INTEGER REFERENCES users(id),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)

        cur.execute("""
            CREATE TABLE chat_messages (
                id SERIAL PRIMARY KEY,
                trade_id INTEGER REFERENCES listings(id) ON DELETE CASCADE,
                sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                message_content TEXT NOT NULL,
                timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)

        conn.commit()
        cur.close()
        print("--- Database initialization complete ---")
    except Exception as e:
        print(f"Error initializing database: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    if isinstance(password, str):
        password = password.encode('utf-8')
    if len(password) > 72:
        password = password[:72]
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)], db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]):
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
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
    
    cur = db.cursor()
    cur.execute("SELECT id, username, email, role FROM users WHERE username = %s", (token_data.username,))
    user = cur.fetchone()
    cur.close()
    if user is None:
        raise credentials_exception
    return User(id=user[0], username=user[1], email=user[2], role=user[3])

async def get_current_active_admin_user(current_user: Annotated[User, Depends(get_current_user)]):
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not an admin user")
    return current_user

@app.get("/users/me", response_model=User)
async def read_users_me(current_user: Annotated[User, Depends(get_current_user)]):
    return current_user

@app.post("/token", response_model=Token)
def login_for_access_token(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()], 
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]
):
    cur = db.cursor()
    cur.execute("SELECT id, username, hashed_password FROM users WHERE username = %s", (form_data.username,))
    user = cur.fetchone()
    cur.close()
    if not user or not verify_password(form_data.password, user[2]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user[1]}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/register/", response_model=User)
def register_user(user: UserCreate, db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]):
    cur = db.cursor()
    cur.execute("SELECT id FROM users WHERE username = %s OR email = %s", (user.username, user.email))
    if cur.fetchone():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered",
        )
    
    hashed_password = get_password_hash(user.password)
    cur.execute(
        "INSERT INTO users (username, email, hashed_password, role) VALUES (%s, %s, %s, %s) RETURNING id, username, email, role;",
        (user.username, user.email, hashed_password, user.role)
    )
    new_user = cur.fetchone()
    db.commit()
    cur.close()
    return {"id": new_user[0], "username": new_user[1], "email": new_user[2], "role": new_user[3]}

@app.get("/users/me/listings", response_model=List[Listing])
async def read_own_listings(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]
):
    cur = db.cursor()
    cur.execute("SELECT id, name, description, price, exchange_item, trade_type, category, image_url, user_id FROM listings WHERE user_id = %s", (current_user.id,))
    listings = cur.fetchall()
    cur.close()
    return [
        {"id": row[0], "title": row[1], "description": row[2], "cashPrice": row[3], "exchangeItem": row[4], "tradeType": row[5], 
         "category": row[6], "imageUrl": row[7], "user_id": row[8]}
        for row in listings
    ]

@app.get("/users/me/chats", response_model=List[Listing])
async def read_user_chats(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]
):
    cur = db.cursor()
    # Find all listings where the user has sent or received a message
    # Or listings that the user OWNS and have messages
    cur.execute("""
        SELECT DISTINCT l.id, l.name, l.description, l.price, l.exchange_item, l.trade_type, l.category, l.image_url, l.user_id
        FROM listings l
        JOIN chat_messages cm ON l.id = cm.trade_id
        WHERE cm.sender_id = %s OR l.user_id = %s
    """, (current_user.id, current_user.id))
    listings = cur.fetchall()
    cur.close()
    return [
        {"id": row[0], "title": row[1], "description": row[2], "cashPrice": row[3], "exchangeItem": row[4], "tradeType": row[5], 
         "category": row[6], "imageUrl": row[7], "user_id": row[8]}
        for row in listings
    ]

@app.get("/admin/users", response_model=List[User])
async def get_all_users(
    current_user: Annotated[User, Depends(get_current_active_admin_user)],
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]
):
    cur = db.cursor()
    cur.execute("SELECT id, username, email, role FROM users;")
    users = cur.fetchall()
    cur.close()
    return [
        {"id": row[0], "username": row[1], "email": row[2], "role": row[3]}
        for row in users
    ]

@app.put("/admin/users/{user_id}/role", response_model=User)
async def update_user_role(
    user_id: int,
    user_role_update: UserRoleUpdate,
    current_user: Annotated[User, Depends(get_current_active_admin_user)],
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]
):
    cur = db.cursor()
    cur.execute("UPDATE users SET role = %s WHERE id = %s RETURNING id, username, email, role;", (user_role_update.role, user_id))
    updated_user = cur.fetchone()
    db.commit()
    cur.close()
    if updated_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return User(id=updated_user[0], username=updated_user[1], email=updated_user[2], role=updated_user[3])

@app.put("/admin/users/{user_id}/subscription", response_model=User)
async def update_user_subscription(
    user_id: int,
    user_subscription_update: UserSubscriptionUpdate,
    current_user: Annotated[User, Depends(get_current_active_admin_user)],
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]
):
    cur = db.cursor()
    cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='subscription_status';")
    if cur.fetchone() is None:
        cur.execute("ALTER TABLE users ADD COLUMN subscription_status VARCHAR(50) DEFAULT 'basic';")
        db.commit()

    cur.execute(
        "UPDATE users SET subscription_status = %s WHERE id = %s RETURNING id, username, email, role, subscription_status;",
        (user_subscription_update.subscription_status, user_id)
    )
    updated_user = cur.fetchone()
    db.commit()
    cur.close()
    if updated_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    return User(id=updated_user[0], username=updated_user[1], email=updated_user[2], role=updated_user[3], subscription_status=updated_user[4])

@app.post("/listings/", status_code=status.HTTP_201_CREATED)
def create_listing(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)],
    title: str = Form(...),
    description: Optional[str] = Form(None),
    cashPrice: Optional[float] = Form(None),
    exchangeItem: Optional[str] = Form(None),
    category: str = Form(...),
    tradeType: str = Form(...),
    image: UploadFile = File(...)
):
    cur = db.cursor()
    try:
        user_id = current_user.id
        file_extension = image.filename.split(".")[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = f"static/images/{unique_filename}"
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        image_url = f"http://localhost:8000/{file_path}"

        cur.execute(
            "INSERT INTO listings (name, description, price, exchange_item, trade_type, category, image_url, user_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id;",
            (title, description, cashPrice, exchangeItem, tradeType, category, image_url, user_id)
        )
        listing_id = cur.fetchone()[0]
        db.commit()
        
        return {
            "id": listing_id, "title": title, "description": description, "cashPrice": cashPrice,
            "exchangeItem": exchangeItem, "tradeType": tradeType, "category": category, "imageUrl": image_url, "user_id": user_id
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Error creating listing: {e}")
    finally:
        cur.close()

@app.get("/listings/", response_model=List[Listing])
def get_listings(
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)], 
    search: Optional[str] = None,
    category: Optional[str] = None,
    tradeType: Optional[str] = None,
    sortBy: Optional[str] = None,
    order: Optional[str] = 'desc'
):
    cur = db.cursor()
    try:
        query = "SELECT id, name, description, price, exchange_item, trade_type, category, image_url, user_id FROM listings"
        params = []
        conditions = []

        if search:
            conditions.append(" (name ILIKE %s OR description ILIKE %s) ")
            search_term = f"%{search}%"
            params.extend([search_term, search_term])
        
        if category:
            conditions.append(" category = %s ")
            params.append(category)

        if tradeType:
            conditions.append(" trade_type = %s ")
            params.append(tradeType)

        if conditions:
            query += " WHERE " + " AND ".join(conditions)

        if sortBy in ['created_at', 'price']:
            if order.lower() not in ['asc', 'desc']:
                order = 'desc'
            query += f" ORDER BY {sortBy} {order.upper()}"
        
        cur.execute(query, tuple(params))
        listings = cur.fetchall()
        
        return [
            {"id": row[0], "title": row[1], "description": row[2], "cashPrice": row[3], "exchangeItem": row[4],
             "tradeType": row[5], "category": row[6], "imageUrl": row[7], "user_id": row[8]}
            for row in listings
        ]
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error fetching listings: {e}")
    finally:
        cur.close()

@app.get("/")
def read_root():
    return {"Hello": "World"}

init_db()

origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:5173",
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
