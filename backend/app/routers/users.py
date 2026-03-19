from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated, List, Optional
from pydantic import EmailStr

from ..database import get_db
from ..models import UserModel, ListingModel, FavoriteModel, ReviewModel, OfferModel
from ..schemas import User, UserUpdate, Listing, Review, ReviewCreate, UserRoleUpdate, UserSubscriptionUpdate, DeviceTokenUpdate, Offer
from ..dependencies import get_current_user, get_current_active_admin_user
from ..auth_utils import get_password_hash

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/me", response_model=User)
async def read_users_me(current_user: Annotated[UserModel, Depends(get_current_user)]):
    return current_user

@router.put("/me", response_model=User)
async def update_user_me(
    user_update: UserUpdate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    if user_update.username:
        existing = db.query(UserModel).filter(UserModel.username == user_update.username).first()
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=400, detail="Username already taken")
        current_user.username = user_update.username
    
    if user_update.email:
        existing = db.query(UserModel).filter(UserModel.email == user_update.email).first()
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=400, detail="Email already registered")
        current_user.email = user_update.email
    
    if user_update.password:
        current_user.hashed_password = get_password_hash(user_update.password)
    
    if user_update.avatar_url:
        current_user.avatar_url = user_update.avatar_url
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.get("/by-email/{email}", response_model=User)
async def get_user_by_email(
    email: EmailStr,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    user = db.query(UserModel).filter(UserModel.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/me/listings", response_model=List[Listing])
async def read_own_listings(current_user: Annotated[UserModel, Depends(get_current_user)]):
    return [
        {"id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
         "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
         "owner_username": current_user.username, "owner_rating": current_user.overall_rating, 
         "owner_reviews": current_user.total_reviews, "owner_avatar": current_user.avatar_url,
         "sustainability_tags": l.sustainability_tags}
        for l in current_user.listings
    ]

@router.get("/me/favorites", response_model=List[Listing])
def get_user_favorites(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    skip: int = 0,
    limit: int = 20
):
    favorites = db.query(FavoriteModel).filter(FavoriteModel.user_id == current_user.id).offset(skip).limit(limit).all()
    listing_ids = [fav.listing_id for fav in favorites]
    if not listing_ids:
        return []
    listings = db.query(ListingModel).filter(ListingModel.id.in_(listing_ids)).all()
    return [
        {"id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
         "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
         "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
         "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, 
         "owner_reviews": l.owner.total_reviews, "owner_avatar": l.owner.avatar_url,
         "sustainability_tags": l.sustainability_tags}
        for l in listings
    ]

@router.get("/me/offers", response_model=List[Offer])
def get_my_offers(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    skip: int = 0,
    limit: int = 20
):
    return db.query(OfferModel).filter(OfferModel.buyer_id == current_user.id).order_by(OfferModel.created_at.desc()).offset(skip).limit(limit).all()

@router.get("/me/received_offers", response_model=List[Offer])
def get_received_offers(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    skip: int = 0,
    limit: int = 20
):
    return db.query(OfferModel).join(ListingModel).filter(ListingModel.user_id == current_user.id).order_by(OfferModel.created_at.desc()).offset(skip).limit(limit).all()

@router.post("/me/device-token")
async def register_device_token(
    update: DeviceTokenUpdate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    current_user.device_token = update.device_token
    db.commit()
    return {"message": "Success"}

# --- Review Endpoints ---

@router.post("/reviews", response_model=Review)
def create_review(
    review_in: ReviewCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    # Verify user hasn't already reviewed this listing
    existing = db.query(ReviewModel).filter(
        ReviewModel.user_id == current_user.id,
        ReviewModel.listing_id == review_in.listing_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="You have already reviewed this item")
        
    listing = db.query(ListingModel).filter(ListingModel.id == review_in.listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
        
    new_review = ReviewModel(
        user_id=current_user.id,
        listing_id=review_in.listing_id,
        rating=review_in.rating,
        comment=review_in.comment
    )
    db.add(new_review)
    
    # Update user/listing rating (simplified)
    # Amazon-like: Update average rating
    # In a real app, you'd trigger a background task for this
    
    db.commit()
    db.refresh(new_review)
    return new_review

# --- Admin Endpoints ---

@router.get("/admin/all", response_model=List[User])
async def get_all_users(
    current_user: Annotated[UserModel, Depends(get_current_active_admin_user)],
    db: Annotated[Session, Depends(get_db)]
):
    return db.query(UserModel).all()

@router.put("/admin/{user_id}/role", response_model=User)
async def update_user_role(
    user_id: int,
    user_role_update: UserRoleUpdate,
    current_user: Annotated[UserModel, Depends(get_current_active_admin_user)],
    db: Annotated[Session, Depends(get_db)]
):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = user_role_update.role
    db.commit()
    db.refresh(user)
    return user
