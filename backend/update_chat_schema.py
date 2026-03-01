import os
from sqlalchemy import create_engine, text, inspect
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(DATABASE_URL)

def migrate():
    print(f"Connecting to {DATABASE_URL}...")
    inspector = inspect(engine)
    
    with engine.connect() as conn:
        print("Ensuring missing columns exist in 'chat_messages' table...")
        chat_columns = [col['name'] for col in inspector.get_columns('chat_messages')]
        
        new_cols = {
            "image_url": "TEXT NULL",
            "is_read": "BOOLEAN DEFAULT FALSE"
        }
        
        for col_name, col_def in new_cols.items():
            if col_name not in chat_columns:
                print(f"Adding column {col_name} to chat_messages...")
                conn.execute(text(f"ALTER TABLE chat_messages ADD COLUMN {col_name} {col_def};"))
        
        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    migrate()
