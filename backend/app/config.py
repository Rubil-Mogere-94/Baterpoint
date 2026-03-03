from pydantic_settings import BaseSettings
from typing import List, Optional
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Baterpoint API"
    VERSION: str = "2.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "CHANGEME_DEFAULTS_ARE_UNSAFE_FOR_PRODUCTION")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./test.db")
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"] # Should be restricted in production
    
    # File Storage
    STATIC_DIR: str = "static"
    CHAT_IMAGES_DIR: str = "static/chat_images"
    LISTING_IMAGES_DIR: str = "static/images"

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
