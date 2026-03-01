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
        print("Checking for avatar_url column in 'users' table...")
        user_columns = [col['name'] for col in inspector.get_columns('users')]
        
        if "avatar_url" not in user_columns:
            print("Adding column avatar_url to users...")
            try:
                conn.execute(text("ALTER TABLE users ADD COLUMN avatar_url TEXT NULL;"))
                print("Column avatar_url added successfully!")
            except Exception as e:
                print(f"Error adding avatar_url: {e}")
        else:
            print("Column avatar_url already exists.")
            
        conn.commit()
        print("Migration complete!")

if __name__ == "__main__":
    migrate()
