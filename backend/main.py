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
    # await app.sio.emit("message", {"data": "Connected to server"}, room=sid) # Removed initial welcome, client will authenticate

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
        db = next(db_gen) # Get a database connection
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
            db_gen.close() # Close the database connection
        except Exception:
            pass # Already closed or not assigned

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
    print(f"Client {sid} ({active_sids[sid]['username']}) joined room {room}")

    # Fetch and send message history
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
                room=sid # Send only to the joining client
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

    # Store message in DB
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

        # Broadcast message to the room
        # Include sender's own message for consistent display across clients
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
    else:
        print(f"Client disconnected: {sid} (unauthenticated)")

# --- Security and Authentication ---
SECRET_KEY = os.environ.get("SECRET_KEY", "a_super_secret_key_that_should_be_in_env")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- Pydantic Models ---
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
    exchange: Optional[str] = None
    category: str
    tradeType: str
    imageUrl: Optional[str] = None
    user_id: int

class UserRoleUpdate(BaseModel):
    role: str

class UserSubscriptionUpdate(BaseModel):
    subscription_status: str

# --- Database ---
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
        print("Connected to database.")
        
        # Drop tables in correct order to handle foreign key constraints
        print("Dropping existing tables if they exist...")
        cur.execute("DROP TABLE IF EXISTS chat_messages CASCADE;")
        cur.execute("DROP TABLE IF EXISTS listings CASCADE;")
        cur.execute("DROP TABLE IF EXISTS users CASCADE;")
        print("Tables dropped.")

        print("Creating 'users' table...")
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
        print("'users' table created.")

        print("Creating 'listings' table...")
        cur.execute("""
            CREATE TABLE listings (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                price DECIMAL(10, 2),
                trade_type VARCHAR(50),
                category VARCHAR(255),
                image_url TEXT,
                user_id INTEGER REFERENCES users(id),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)
        print("'listings' table created.")

        print("Creating 'chat_messages' table...")
        cur.execute("""
            CREATE TABLE chat_messages (
                id SERIAL PRIMARY KEY,
                trade_id INTEGER REFERENCES listings(id) ON DELETE CASCADE,
                sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                message_content TEXT NOT NULL,
                timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)
        print("'chat_messages' table created.")

        conn.commit()
        cur.close()
        print("--- Database initialization complete ---")
    except Exception as e:
        print(f"Error initializing database: {e}")
        if conn:
            conn.rollback() # Rollback in case of error during table creation
    finally:
        if conn:
            conn.close()

# --- Password and JWT Utilities ---
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    # bcrypt can only handle passwords up to 72 bytes
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

# --- Authentication Endpoints ---
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
    # Check if user already exists
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
    cur.execute("SELECT id, name, description, price, trade_type, category, image_url, user_id FROM listings WHERE user_id = %s", (current_user.id,))
    listings = cur.fetchall()
    cur.close()
    return [
        {"id": row[0], "title": row[1], "description": row[2], "price": row[3], "tradeType": row[4], 
         "category": row[5], "imageUrl": row[6], "user_id": row[7]}
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
    # Before updating, check if the subscription_status column exists.
    # If not, add it to the users table. This is a simple migration approach.
    cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='subscription_status';")
    if cur.fetchone() is None:
        print("Adding 'subscription_status' column to 'users' table...")
        cur.execute("ALTER TABLE users ADD COLUMN subscription_status VARCHAR(50) DEFAULT 'basic';")
        db.commit()
        print("'subscription_status' column added.")

    cur.execute(
        "UPDATE users SET subscription_status = %s WHERE id = %s RETURNING id, username, email, role, subscription_status;",
        (user_subscription_update.subscription_status, user_id)
    )
    updated_user = cur.fetchone()
    db.commit()
    cur.close()
    if updated_user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    # Need to return a User object, but the User model doesn't have subscription_status yet.
    # For now, let's return a basic User object and then update the User model.
    # This will be handled in a subsequent step.
    return User(id=updated_user[0], username=updated_user[1], email=updated_user[2], role=updated_user[3], subscription_status=updated_user[4])

# --- App Endpoints (Modified and New) ---
# ... (current user dependency will be added in Phase 3)

@app.post("/listings/", status_code=status.HTTP_201_CREATED)
def create_listing(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)],
    title: str = Form(...),
    description: Optional[str] = Form(None),
    cashPrice: Optional[float] = Form(None),
    exchange: Optional[str] = Form(None),
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
            "INSERT INTO listings (name, description, price, trade_type, category, image_url, user_id) VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id;",
            (title, description, cashPrice, tradeType, category, image_url, user_id)
        )
        listing_id = cur.fetchone()[0]
        db.commit()
        
        return {
            "id": listing_id, "title": title, "description": description, "cashPrice": cashPrice,
            "tradeType": tradeType, "category": category, "imageUrl": image_url, "user_id": user_id
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
    sortBy: Optional[str] = None, # e.g., 'created_at', 'price'
    order: Optional[str] = 'desc' # 'asc' or 'desc'
):
    cur = db.cursor()
    try:
        query = "SELECT id, name, description, price, trade_type, category, image_url, user_id FROM listings"
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
                order = 'desc' # default to desc
            query += f" ORDER BY {sortBy} {order.upper()}"
        
        cur.execute(query, tuple(params))
        listings = cur.fetchall()
        
        return [
            {"id": row[0], "title": row[1], "description": row[2], "price": row[3], "tradeType": row[4], 
             "category": row[5], "imageUrl": row[6], "user_id": row[7]}
            for row in listings
        ]
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error fetching listings: {e}")
    finally:
        cur.close()

@app.get("/")
def read_root():
    return {"Hello": "World"}

# Call init_db directly to ensure it runs on startup
init_db()

# Configure CORS
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