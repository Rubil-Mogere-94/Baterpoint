import os
import psycopg2
from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.staticfiles import StaticFiles
from typing import Annotated, Optional
from pydantic import BaseModel
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
import shutil
import uuid

load_dotenv() # Load environment variables from .env file

app = FastAPI()

# Mount the static directory to serve images
os.makedirs("static/images", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://user:password@host:port/dbname")

# Configure CORS
origins = [
    "http://localhost:3000",  # Frontend URL
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

class Listing(BaseModel):
    title: str
    description: Optional[str] = None
    cashPrice: Optional[float] = None
    exchange: Optional[str] = None
    category: str
    tradeType: str
    imageUrl: Optional[str] = None

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
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        cur.execute("""
            DROP TABLE IF EXISTS items;
            CREATE TABLE IF NOT EXISTS listings (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                price DECIMAL(10, 2),
                trade_type VARCHAR(50),
                category VARCHAR(255),
                image_url TEXT
            );
        """)
        conn.commit()
        cur.close()
    except Exception as e:
        print(f"Error initializing database: {e}")
    finally:
        if conn:
            conn.close()

@app.on_event("startup")
async def startup_event():
    init_db()

@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.post("/listings/", status_code=status.HTTP_201_CREATED)
def create_listing(
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
        # Generate a unique filename
        file_extension = image.filename.split(".")[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = f"static/images/{unique_filename}"
        
        # Save the uploaded file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        # Construct the image URL
        image_url = f"http://localhost:8000/{file_path}"

        cur.execute(
            "INSERT INTO listings (name, description, price, trade_type, category, image_url) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id;",
            (title, description, cashPrice, tradeType, category, image_url)
        )
        listing_id = cur.fetchone()[0]
        db.commit()
        
        return {
            "id": listing_id,
            "title": title,
            "description": description,
            "cashPrice": cashPrice,
            "tradeType": tradeType,
            "category": category,
            "imageUrl": image_url
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Error creating listing: {e}")
    finally:
        cur.close()

@app.get("/listings/")
def get_listings(db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]):
    cur = db.cursor()
    try:
        cur.execute("SELECT id, name, description, price, trade_type, category, image_url FROM listings;")
        listings = cur.fetchall()
        return [
            {"id": listing[0], "title": listing[1], "description": listing[2], "price": listing[3], "tradeType": listing[4], "category": listing[5], "imageUrl": listing[6]}
            for listing in listings
        ]
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error fetching listings: {e}")
    finally:
        cur.close()