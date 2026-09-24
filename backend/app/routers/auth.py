from fastapi import APIRouter, Depends, HTTPException, status, Request
from typing import Annotated
from datetime import timedelta, datetime, timezone
import httpx

from sqlalchemy.orm import Session

from ..database import get_db
from ..models import UserModel, PasswordResetToken
from ..schemas import Token, UserCreate, User, PasswordResetRequest, PasswordResetConfirm
from ..auth_utils import (
    verify_password, create_access_token, create_refresh_token,
    get_password_hash, decode_token, generate_reset_token, ACCESS_TOKEN_EXPIRE_MINUTES
)
from ..config import settings
from slowapi import Limiter
from slowapi.util import get_remote_address

router = APIRouter(tags=["Authentication"])
limiter = Limiter(key_func=get_remote_address)


from pydantic import BaseModel

class LoginRequest(BaseModel):
    username: str
    password: str


@router.post("/token", response_model=Token)
@limiter.limit("5/minute")
def login_for_access_token(
    request: Request,
    login_data: LoginRequest,
    db: Annotated[Session, Depends(get_db)]
):
    username = login_data.username
    password = login_data.password
    user = db.query(UserModel).filter(UserModel.username == username).first()
    if not user:
        user = db.query(UserModel).filter(UserModel.email == username).first()
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.username}, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    refresh_token = create_refresh_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer", "refresh_token": refresh_token}


@router.post("/register/", response_model=User)
@limiter.limit("3/minute")
def register_user(request: Request, user: UserCreate, db: Annotated[Session, Depends(get_db)]):
    db_user = db.query(UserModel).filter(
        (UserModel.username == user.username) | (UserModel.email == user.email)
    ).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username or email already registered")
    new_user = UserModel(
        username=user.username,
        email=user.email,
        hashed_password=get_password_hash(user.password),
        role=user.role,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.post("/refresh", response_model=Token)
def refresh_token(request: Request, db: Annotated[Session, Depends(get_db)]):
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing refresh token")
    token = auth_header[7:]
    payload = decode_token(token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    username = payload.get("sub")
    user = db.query(UserModel).filter(UserModel.username == username).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    access_token = create_access_token(data={"sub": user.username}, expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    new_refresh = create_refresh_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer", "refresh_token": new_refresh}


@router.post("/forgot")
@limiter.limit("3/minute")
def forgot_password(request: Request, body: PasswordResetRequest, db: Annotated[Session, Depends(get_db)]):
    user = db.query(UserModel).filter(UserModel.email == body.email).first()
    if user:
        token = generate_reset_token()
        expires = datetime.now(timezone.utc) + timedelta(hours=1)
        db.add(PasswordResetToken(user_id=user.id, token=token, expires_at=expires))
        db.commit()
    return {"message": "If that email is registered, a reset link has been sent."}


@router.post("/reset")
def reset_password(request: Request, body: PasswordResetConfirm, db: Annotated[Session, Depends(get_db)]):
    reset = db.query(PasswordResetToken).filter(PasswordResetToken.token == body.token).first()
    if not reset or reset.used or reset.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Invalid or expired reset token")
    user = db.query(UserModel).filter(UserModel.id == reset.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.hashed_password = get_password_hash(body.password)
    reset.used = True
    db.commit()
    return {"message": "Password has been reset successfully."}