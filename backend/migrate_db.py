import os
from sqlalchemy import create_engine, text, inspect
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    DATABASE_URL = "sqlite:///./test.db"
    print("WARNING: DATABASE_URL not set, defaulting to SQLite: sqlite:///./test.db")

engine = create_engine(DATABASE_URL)

def migrate():
    print(f"Connecting to {DATABASE_URL}...")
    inspector = inspect(engine)
    
    with engine.connect() as conn:
        # 1. Add missing columns to users
        print("Ensuring missing columns exist in 'users' table...")
        user_columns = [col['name'] for col in inspector.get_columns('users')]
        
        new_cols = {
            "subscription_status": "VARCHAR(50) DEFAULT 'basic'",
            "overall_rating": "FLOAT DEFAULT 0.0",
            "total_reviews": "INTEGER DEFAULT 0",
            "loyalty_points": "INTEGER DEFAULT 0",
            "device_token": "VARCHAR(255) NULL"
        }
        
        for col_name, col_def in new_cols.items():
            if col_name not in user_columns:
                print(f"Adding column {col_name} to users...")
                conn.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_def};"))
        
        # 2. Rename listings.name to listings.title if needed
        print("Checking if 'listings.name' needs to be renamed to 'title'...")
        listing_columns = [col['name'] for col in inspector.get_columns('listings')]
        if 'name' in listing_columns and 'title' not in listing_columns:
            print("Renaming listings.name to listings.title...")
            if "postgresql" in str(engine.url):
                conn.execute(text("ALTER TABLE listings RENAME COLUMN name TO title;"))
            else:
                 # SQLite doesn't support RENAME COLUMN in older versions, but if it's new enough:
                 try:
                    conn.execute(text("ALTER TABLE listings RENAME COLUMN name TO title;"))
                 except Exception as e:
                    print(f"Could not rename column: {e}. You may need to recreate the table.")

        # 4. Add view_count to listings
        if 'view_count' not in listing_columns:
             print("Adding view_count to listings...")
             conn.execute(text("ALTER TABLE listings ADD COLUMN view_count INTEGER DEFAULT 0;"))

        # 5. Handle chat_messages column names
        print("Ensuring 'chat_messages' column names are correct...")
        chat_columns = [col['name'] for col in inspector.get_columns('chat_messages')]
        
        if 'message' in chat_columns and 'message_content' not in chat_columns:
            conn.execute(text("ALTER TABLE chat_messages RENAME COLUMN message TO message_content;"))
        if 'created_at' in chat_columns and 'timestamp' not in chat_columns:
            conn.execute(text("ALTER TABLE chat_messages RENAME COLUMN created_at TO timestamp;"))

        if 'message_content' not in chat_columns and 'message' not in chat_columns:
             conn.execute(text("ALTER TABLE chat_messages ADD COLUMN message_content TEXT;"))
        if 'timestamp' not in chat_columns and 'created_at' not in chat_columns:
             if "postgresql" in str(engine.url):
                 conn.execute(text("ALTER TABLE chat_messages ADD COLUMN timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP;"))
             else:
                 conn.execute(text("ALTER TABLE chat_messages ADD COLUMN timestamp DATETIME DEFAULT CURRENT_TIMESTAMP;"))

        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    migrate()
