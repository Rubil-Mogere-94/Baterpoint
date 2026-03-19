from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import random
import asyncio
from typing import List

from ..database import get_db
from ..models import ListingModel, UserModel
from ..schemas import Listing
from ..dependencies import get_current_user
from ..services.recommendations import recommend_for_user, find_similar_listings

router = APIRouter(prefix="/ai", tags=["AI"])

# Mock AI Valuations
EVALUATIONS = [
    {"value": 50, "comment": "A classic! But probably covered in dust. I'd give you 50 Barter Coins for it if I was feeling generous."},
    {"value": 120, "comment": "Ooh, shiny! This has some decent utility. Solid 120 Barter Coins."},
    {"value": 500, "comment": "Woah, hold onto your hats! This is a rare find. Easily worth 500 Barter Coins to the right collector."},
    {"value": 15, "comment": "Are you sure this isn't literal trash? Just kidding... mostly. 15 Barter Coins, take it or leave it."},
    {"value": 250, "comment": "Very practical. A solid middle-tier barter item. I bet someone would trade a nice watch for this. 250 Coins."},
]

@router.post("/evaluate", status_code=status.HTTP_200_OK)
async def evaluate_item(item_name: str, description: str = ""):
    """
    Simulates an AI evaluating an item for barter.
    Returns a mocked value and a snarky/helpful comment.
    """
    # Simulate some "thinking" time for the UI to show off its scanning animation
    await asyncio.sleep(1.5) 
    
    evaluation = random.choice(EVALUATIONS)
    fuzzy_value = evaluation["value"] + random.randint(-5, 15)
    
    return {
        "item_name": item_name,
        "estimated_value": fuzzy_value,
        "ai_comment": evaluation["comment"],
        "confidence_score": round(random.uniform(0.7, 0.98), 2)
    }

@router.get("/recommendations", response_model=List[Listing])
async def get_ai_recommendations(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 10
):
    """
    Returns AI-powered listing recommendations based on user interests.
    """
    recommendations = recommend_for_user(db, current_user.id, limit)
    return [
        {
            "id": l.id, "title": l.title, "description": l.description, 
            "cashPrice": l.price, "exchangeItem": l.exchange_item, 
            "tradeType": l.trade_type, "category": l.category, 
            "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
            "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, 
            "owner_reviews": l.owner.total_reviews, "owner_avatar": l.owner.avatar_url,
            "sustainability_tags": l.sustainability_tags
        }
        for l in recommendations
    ]

@router.get("/listings/{listing_id}/similar", response_model=List[Listing])
async def get_similar_listings(
    listing_id: int,
    db: Session = Depends(get_db),
    limit: int = 10
):
    """
    Finds listings similar to the given one using vector embeddings.
    """
    similar = find_similar_listings(db, listing_id, limit)
    return [
        {
            "id": l.id, "title": l.title, "description": l.description, 
            "cashPrice": l.price, "exchangeItem": l.exchange_item, 
            "tradeType": l.trade_type, "category": l.category, 
            "imageUrl": l.image_url, "user_id": l.user_id, "view_count": l.view_count,
            "owner_username": l.owner.username, "owner_rating": l.owner.overall_rating, 
            "owner_reviews": l.owner.total_reviews, "owner_avatar": l.owner.avatar_url,
            "sustainability_tags": l.sustainability_tags
        }
        for l in similar
    ]
