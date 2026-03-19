from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Annotated
from datetime import timedelta
import httpx

from ..database import get_db
from ..models import UserModel
from ..schemas import Token, UserCreate, User
from ..auth_utils import verify_password, create_access_token, get_password_hash, ACCESS_TOKEN_EXPIRE_MINUTES
from ..config import settings
from slowapi import Limiter
from slowapi.util import get_remote_address

router = APIRouter(tags=["Authentication"])
limiter = Limiter(key_func=get_remote_address)

@router.post("/token", response_model=Token)
@limiter.limit("5/minute")
def login_for_access_token(
    request: Request,
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()], 
    db: Annotated[Session, Depends(get_db)]
):
    user = db.query(UserModel).filter(UserModel.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.username}, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/register/", response_model=User)
@limiter.limit("3/minute")
def register_user(request: Request, user: UserCreate, db: Annotated[Session, Depends(get_db)]):
    db_user = db.query(UserModel).filter((UserModel.username == user.username) | (UserModel.email == user.email)).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username or email already registered")
    
    new_user = UserModel(
        username=user.username,
        email=user.email,
        hashed_password=get_password_hash(user.password),
        role=user.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/google", response_model=Token)
async def google_login(token: str, db: Session = Depends(get_db)):
    """
    Verifies a Google ID token and returns an access token.
    """
    GOOGLE_CLIENT_ID = settings.GOOGLE_CLIENT_ID
    if not GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=500, detail="Google Login not configured on server")

    # Verify token with Google
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://oauth2.googleapis.com/tokeninfo?id_token={token}"
        )
    
    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Invalid Google token")
    
    user_info = response.json()
    if user_info['aud'] != GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=400, detail="Invalid audience")
    
    email = user_info['email']
    name = user_info.get('name', email.split('@')[0])
    
    # Find or create user
    user = db.query(UserModel).filter(UserModel.email == email).first()
    if not user:
        # Create new user
        user = UserModel(
            username=name,
            email=email,
            hashed_password=get_password_hash(str(timedelta(days=random_days()))), # Dummy pass
            role="user"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    access_token = create_access_token(data={"sub": user.username}, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    return {"access_token": access_token, "token_type": "bearer"}

def random_days():
    import random
    return random.randint(1000, 9999)
