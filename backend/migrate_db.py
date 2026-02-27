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
        # 1. Add missing columns to users
        print("Ensuring missing columns exist in 'users' table...")
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) DEFAULT 'basic';"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS overall_rating FLOAT DEFAULT 0.0;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0;"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS device_token VARCHAR(255) NULL;"))
        
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

        # 5. Handle chat_messages column names
        print("Ensuring 'chat_messages' column names are correct...")
        conn.execute(text("""
            DO $$ 
            BEGIN 
                IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chat_messages' AND column_name='message') THEN
                    ALTER TABLE chat_messages RENAME COLUMN message TO message_content;
                END IF;
                IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chat_messages' AND column_name='created_at') THEN
                    ALTER TABLE chat_messages RENAME COLUMN created_at TO timestamp;
                END IF;
                -- If columns don't exist at all, they might not be created by Base.metadata.create_all if the table was old.
                -- But usually create_all would create them if the table is new.
                -- Let's ensure they exist if the rename didn't happen.
                ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS message_content TEXT;
                ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
            END $$;
        """))

        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    migrate()
