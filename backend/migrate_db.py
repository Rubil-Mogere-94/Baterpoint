import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.environ.get("DATABASE_URL")

if not DATABASE_URL:
    print("Error: DATABASE_URL not found in .env file.")
    exit(1)

engine = create_engine(DATABASE_URL)

def migrate():
    print(f"Connecting to {DATABASE_URL}...")
    with engine.connect() as conn:
        # 1. Add subscription_status to users if it doesn't exist
        print("Ensuring 'subscription_status' exists in 'users' table...")
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'basic';"))
        
        # 2. Rename listings.name to listings.title if needed
        print("Checking if 'listings.name' needs to be renamed to 'title'...")
        conn.execute(text("""
            DO $$ 
            BEGIN 
                IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='listings' AND column_name='name') THEN
                    ALTER TABLE listings RENAME COLUMN name TO title;
                END IF;
            END $$;
        """))

        # 4. Add view_count to listings if it doesn't exist
        print("Ensuring 'view_count' exists in 'listings' table...")
        conn.execute(text("ALTER TABLE listings ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;"))

        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    migrate()
