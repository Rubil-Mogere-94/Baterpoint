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
        print("Ensuring WhatsApp/Forum columns exist in 'chat_messages' table...")
        chat_columns = [col['name'] for col in inspector.get_columns('chat_messages')]
        
        new_cols = {
            "recipient_id": "INTEGER REFERENCES users(id) NULL",
            "is_forum": "BOOLEAN DEFAULT FALSE",
            "forum_category": "TEXT NULL"
        }
        
        for col_name, col_def in new_cols.items():
            if col_name not in chat_columns:
                print(f"Adding column {col_name} to chat_messages...")
                # SQLite doesn't support complex ALTER TABLE with REFERENCES in some versions
                # but for simplicity we'll try the standard syntax.
                try:
                    conn.execute(text(f"ALTER TABLE chat_messages ADD COLUMN {col_name} {col_def};"))
                except Exception as e:
                    print(f"Error adding {col_name}: {e}")
                    # Fallback for simple column addition if complex fails
                    conn.execute(text(f"ALTER TABLE chat_messages ADD COLUMN {col_name} {col_def.split(' ')[0]};"))
        
        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    migrate()
