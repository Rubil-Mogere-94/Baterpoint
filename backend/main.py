import os
import psycopg2
from fastapi import FastAPI, Depends, HTTPException, status
from typing import Annotated

app = FastAPI()

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
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS items (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                price DECIMAL(10, 2),
                trade_type VARCHAR(50)
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

@app.post("/items/", status_code=status.HTTP_201_CREATED)
def create_item(name: str, description: str, price: float, trade_type: str, db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]):
    cur = db.cursor()
    try:
        cur.execute(
            "INSERT INTO items (name, description, price, trade_type) VALUES (%s, %s, %s, %s) RETURNING id;",
            (name, description, price, trade_type)
        )
        item_id = cur.fetchone()[0]
        db.commit()
        return {"id": item_id, "name": name, "description": description, "price": price, "trade_type": trade_type}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Error creating item: {e}")
    finally:
        cur.close()

@app.get("/items/")
def get_items(db: Annotated[psycopg2.extensions.connection, Depends(get_db_connection)]):
    cur = db.cursor()
    try:
        cur.execute("SELECT id, name, description, price, trade_type FROM items;")
        items = cur.fetchall()
        return [
            {"id": item[0], "name": item[1], "description": item[2], "price": item[3], "trade_type": item[4]}
            for item in items
        ]
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error fetching items: {e}")
    finally:
        cur.close()