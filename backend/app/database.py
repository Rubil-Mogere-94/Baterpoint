from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from .config import settings

# Determine async database URL
DATABASE_URL = settings.DATABASE_URL
if DATABASE_URL.startswith("sqlite"):
    # Use aiosqlite driver for async SQLite
    async_database_url = f"sqlite+aiosqlite:///{DATABASE_URL.split('sqlite:///')[1]}"
else:
    # Replace postgres driver with asyncpg
    async_database_url = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

# Create async engine
engine = create_async_engine(async_database_url, echo=True, future=True)

# Async session factory
AsyncSessionLocal = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)

# Base model class
Base = declarative_base()

# Dependency that yields an async session
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
