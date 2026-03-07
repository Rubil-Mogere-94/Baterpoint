from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form, Request
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import desc, func
from typing import Annotated, Optional, List
import shutil
import uuid
import os
from jose import jwt

from ..database import get_db
from ..models import UserModel, ListingModel, FavoriteModel, DealModel, OfferModel
from ..schemas import Listing, ListingUpdate, Deal, Offer, OfferCreate
from ..dependencies import get_current_user, SECRET_KEY, ALGORITHM

router = APIRouter(prefix="/listings", tags=["Listings"])

# Helper for image upload path
# Assuming execution from backend/ root for now, but safer to be explicit
STATIC_DIR = "static/images"
os.makedirs(STATIC_DIR, exist_ok=True)

@router.post("/", status_code=status.HTTP_201_CREATED)
def create_listing(
    request: Request,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    title: str = Form(...),
    description: Optional[str] = Form(None),
    cashPrice: Optional[float] = Form(None),
    exchangeItem: Optional[str] = Form(None),
    category: str = Form(...),
    tradeType: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        try:
            float_price = float(cashPrice) if cashPrice and str(cashPrice).strip() != "" else None
        except (ValueError, TypeError):
            float_price = None

        file_extension = image.filename.split(".")[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = f"{STATIC_DIR}/{unique_filename}"
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        # Construct full URL based on request
        # This assumes the app mounts /static at the root
        base_url = str(request.base_url).rstrip("/")
        image_url = f"{base_url}/static/images/{unique_filename}"

        new_listing = ListingModel(
            title=title, description=description, price=float_price, exchange_item=exchangeItem,
            trade_type=tradeType, category=category, image_url=image_url, user_id=current_user.id
        )
        db.add(new_listing)
        db.commit()
        db.refresh(new_listing)
        
        return {
            "id": new_listing.id, "title": new_listing.title, "description": new_listing.description, 
            "cashPrice": new_listing.price, "exchangeItem": new_listing.exchange_item, 
            "tradeType": new_listing.trade_type, "category": new_listing.category, 
            "imageUrl": new_listing.image_url, "user_id": new_listing.user_id, "view_count": new_listing.view_count,
            "owner_username": current_user.username, "owner_rating": current_user.overall_rating, 
            "owner_reviews": current_user.total_reviews, "owner_avatar": current_user.avatar_url
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creating listing: {e}")

@router.get("/", response_model=List[Listing])
def get_listings(
    db: Annotated[Session, Depends(get_db)], 
    search: Optional[str] = None,
    category: Optional[str] = None,
    tradeType: Optional[str] = None,
    sortBy: Optional[str] = None,
    order: Optional[str] = 'desc',
    skip: int = 0,
    limit: int = 20
):
    query = db.query(ListingModel)

    if search:
        query = query.filter((ListingModel.title.ilike(f"%{search}%")) | (ListingModel.description.ilike(f"%{search}%")))
    
    if category and category != 'All':
        query = query.filter(ListingModel.category == category)

    if tradeType:
        query = query.filter(ListingModel.trade_type == tradeType)

    if sortBy == 'price':
        query = query.order_by(desc(ListingModel.price) if order == 'desc' else ListingModel.price)
    else:
        query = query.order_by(desc(ListingModel.created_at) if order == 'desc' else ListingModel.created_at)
    
    listings = query.offset(skip).limit(limit).all()
    return listings

@router.get("/matches", response_model=List[Match])
def get_smart_matches(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    limit: int = 10
):
    try:
        # 1. Get user's own listings and categories
        user_listings = current_user.listings
        if not user_listings:
             # If user has no listings, they can't match for a trade
             return []
             
        user_categories = list(set([l.category for l in user_listings]))
        
        # 2. Get user's favorites categories
        fav_listings = db.query(ListingModel).join(FavoriteModel).filter(FavoriteModel.user_id == current_user.id).all()
        fav_categories = list(set([l.category for l in fav_listings]))
        
        # 3. Find potential partners
        # Partners: People who have items in user's favorite categories
        # AND who might want user's items (simplified: they want items in user's categories)
        
        potential_listings = db.query(ListingModel).filter(
            ListingModel.user_id != current_user.id,
            ListingModel.category.in_(fav_categories) if fav_categories else True
        ).all()
        
        matches = []
        for target_listing in potential_listings:
            # Simple scoring:
            # Base 70 if in favorite category
            score = 70
            
            # +10 if user has an item in a category the partner might want 
            # (partner might want user_categories if they are common)
            # For simplicity, let's assume they might want it if it's a popular category
            score += 15
            
            # Random jitter for "variety"
            import random
            score += random.randint(0, 10)
            score = min(score, 99)
            
            # Select which of user's items to offer
            # For simplicity, just pick the first one for now
            user_item = user_listings[0] 
            
            matches.append({
                "match_score": score,
                "user_item": user_item,
                "target_item": target_listing,
                "partner": target_listing.owner,
                "reason": f"{target_listing.owner.username} is looking for {user_item.category} items like yours."
            })
            
        # Sort by score and return limited
        matches.sort(key=lambda x: x['match_score'], reverse=True)
        return matches[:limit]

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error calculating matches: {str(e)}")

@router.get("/recommendations", response_model=List[Listing])
def get_recommendations(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    limit: int = 10
):
    try:
        fav_listings = db.query(ListingModel).join(FavoriteModel).filter(FavoriteModel.user_id == current_user.id).all()
        fav_categories = [l.category for l in fav_listings]
        own_categories = [l.category for l in current_user.listings]
        preferred_categories = list(set(fav_categories + own_categories))
        
        query = db.query(ListingModel).filter(ListingModel.user_id != current_user.id)
        if preferred_categories:
            query = query.filter(ListingModel.category.in_(preferred_categories))
        
        recommendations = query.order_by(desc(ListingModel.view_count)).limit(limit).all()
        
        if len(recommendations) < limit:
            additional_limit = limit - len(recommendations)
            rec_ids = [r.id for r in recommendations]
            trending = db.query(ListingModel).filter(
                ListingModel.user_id != current_user.id,
                ~ListingModel.id.in_(rec_ids) if rec_ids else True
            ).order_by(desc(ListingModel.view_count)).limit(additional_limit).all()
            recommendations.extend(trending)
            
        return [
            {"id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
             "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
             "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
             "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, 
             "owner_reviews": l.owner.total_reviews, "owner_avatar": l.owner.avatar_url}
            for l in recommendations
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching recommendations: {str(e)}")

@router.get("/deal-of-the-hour", response_model=Deal)
def get_deal_of_the_hour(
    db: Annotated[Session, Depends(get_db)]
):
    import random
    from datetime import datetime, timedelta
    try:
        now = datetime.utcnow()
        deal = db.query(DealModel).filter(DealModel.end_time > now).first()
        
        if not deal:
            listing = db.query(ListingModel).filter(ListingModel.price > 0).order_by(func.random()).first()
            if not listing:
                 raise HTTPException(status_code=404, detail="No suitable listing for a deal")
            
            deal = DealModel(
                listing_id=listing.id,
                discount_percentage=random.choice([10, 15, 20, 25, 30, 50]),
                start_time=now,
                end_time=now + timedelta(hours=1)
            )
            db.add(deal)
            db.commit()
            db.refresh(deal)
        
        l = deal.listing
        listing_dict = {
            "id": l.id, "title": l.title, "description": l.description, "cashPrice": l.price, 
            "exchangeItem": l.exchange_item, "tradeType": l.trade_type, "category": l.category, 
            "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
            "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, "owner_reviews": l.owner.total_reviews, "owner_avatar": l.owner.avatar_url
        }
        
        return {
            "id": deal.id,
            "listing_id": deal.listing_id,
            "discount_percentage": deal.discount_percentage,
            "start_time": deal.start_time,
            "end_time": deal.end_time,
            "listing": listing_dict
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error processing deal of the hour: {str(e)}")

@router.get("/{listing_id}", response_model=Listing)
def get_listing(listing_id: int, request: Request, db: Annotated[Session, Depends(get_db)]):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    
    listing.view_count += 1
    db.commit()
    db.refresh(listing)
    
    # Quest update logic omitted for brevity/circular dependency avoidance for now
    # Can be re-added if Quests are moved to a service

    return {
        "id": listing.id, "title": listing.title, "description": listing.description, 
        "cashPrice": listing.price, "exchangeItem": listing.exchange_item, 
        "tradeType": listing.trade_type, "category": listing.category, 
        "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count,
        "owner_username": listing.owner.username, "owner_rating": listing.owner.overall_rating, 
        "owner_reviews": listing.owner.total_reviews, "owner_avatar": listing.owner.avatar_url
    }

@router.put("/{listing_id}", response_model=Listing)
def update_listing(
    listing_id: int,
    listing_update: ListingUpdate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to update this listing")
    
    update_data = listing_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        if key == "cashPrice":
            listing.price = value
        elif key == "exchangeItem":
            listing.exchange_item = value
        elif key == "tradeType":
            listing.trade_type = value
        else:
            setattr(listing, key, value)
    
    db.commit()
    db.refresh(listing)
    return {
        "id": listing.id, "title": listing.title, "description": listing.description, 
        "cashPrice": listing.price, "exchangeItem": listing.exchange_item, 
        "tradeType": listing.trade_type, "category": listing.category, 
        "imageUrl": listing.image_url, "user_id": listing.user_id, "view_count": listing.view_count,
        "owner_username": listing.owner.username, "owner_rating": listing.owner.overall_rating, 
        "owner_reviews": listing.owner.total_reviews, "owner_avatar": listing.owner.avatar_url
    }

@router.delete("/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_listing(
    listing_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to delete this listing")
    
    if listing.image_url:
        try:
            path_parts = listing.image_url.split("/")
            file_path = f"{STATIC_DIR}/{path_parts[-1]}"
            if os.path.exists(file_path):
                os.remove(file_path)
        except Exception as e:
            print(f"Error deleting image file: {e}")

    db.delete(listing)
    db.commit()
    return None

@router.post("/{listing_id}/favorite", status_code=status.HTTP_200_OK)
def toggle_favorite(
    listing_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
        
    favorite = db.query(FavoriteModel).filter(
        FavoriteModel.user_id == current_user.id,
        FavoriteModel.listing_id == listing_id
    ).first()
    
    if favorite:
        db.delete(favorite)
        db.commit()
        return {"status": "unfavorited"}
    else:
        new_fav = FavoriteModel(user_id=current_user.id, listing_id=listing_id)
        db.add(new_fav)
        # update_quest_progress(current_user.id, "favorite", db) # Re-enable later
        db.commit()
        return {"status": "favorited"}

@router.post("/{listing_id}/offers", response_model=Offer)
def create_offer(
    listing_id: int,
    offer_data: OfferCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
    if listing.user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot make an offer on your own listing")
    
    new_offer = OfferModel(
        buyer_id=current_user.id,
        listing_id=listing_id,
        offered_price=offer_data.offered_price,
        offered_item=offer_data.offered_item
    )
    db.add(new_offer)
    db.commit()
    db.refresh(new_offer)
    
    # Returning dict to match Offer schema rich listing expectations if needed
    # but the response_model should handle it if Config.from_attributes is True
    return new_offer
