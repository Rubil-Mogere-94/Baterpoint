from typing import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from .config import settings

DATABASE_URL = settings.DATABASE_URL

engine = create_engine(DATABASE_URL, echo=True, future=True)

SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)

Base = declarative_base()

def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
