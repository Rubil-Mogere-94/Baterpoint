from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta, timezone
from typing import Annotated, List
import random

from ..database import get_db
from ..models import UserModel, ListingModel, OfferModel, OrderModel, OrderItemModel
from ..dependencies import get_current_user

router = APIRouter(prefix="/analytics", tags=["Analytics"])

@router.get("/seller")
def get_seller_analytics(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    days: int = 30
):
    since = datetime.now(timezone.utc) - timedelta(days=days)
    
    # Seller's listings
    listings = db.query(ListingModel).filter(ListingModel.user_id == current_user.id).all()
    listing_ids = [l.id for l in listings]
    
    if not listing_ids:
        return {
            "total_views": 0,
            "offers_received": 0,
            "completed_orders": 0,
            "total_revenue": 0.0,
            "daily_stats": [],
            "listing_performance": []
        }
    
    # Total Views (aggregate from listings)
    total_views = sum(l.view_count for l in listings)
    
    # Offers Received
    offers_count = db.query(OfferModel).filter(
        OfferModel.listing_id.in_(listing_ids),
        OfferModel.created_at >= since
    ).count()
    
    # Completed Orders (Sold items)
    # Joining OrderItemModel with OrderModel to filter by status and date
    completed_orders = db.query(OrderItemModel).join(OrderModel).filter(
        OrderItemModel.listing_id.in_(listing_ids),
        OrderModel.status == "delivered", # Assuming delivered means completed sale
        OrderModel.created_at >= since
    ).count()
    
    # Revenue
    revenue = db.query(func.sum(OrderItemModel.price_at_purchase * OrderItemModel.quantity)).join(OrderModel).filter(
        OrderItemModel.listing_id.in_(listing_ids),
        OrderModel.status == "delivered",
        OrderModel.created_at >= since
    ).scalar() or 0.0
    
    # Daily Views Breakdown
    # Note: We don't have a ListingView history model, so we'll mock this or use created_at
    # In a real app, you'd have a separate table for daily views.
    # Here we'll just return a placeholder daily breakdown for the chart.
    daily_stats = []
    for i in range(days):
        day = (datetime.now(timezone.utc) - timedelta(days=i)).date()
        daily_stats.append({
            "date": day.isoformat(),
            "views": random_views(day, current_user.id) # Helper for demo
        })
    daily_stats.reverse()
    
    # Individual Listing Performance
    performance = []
    for l in listings:
        performance.append({
            "listing_id": l.id,
            "title": l.title,
            "views": l.view_count,
            "offers": db.query(OfferModel).filter(OfferModel.listing_id == l.id).count()
        })
    
    return {
        "total_views": total_views,
        "offers_received": offers_count,
        "completed_orders": completed_orders,
        "total_revenue": revenue,
        "daily_stats": daily_stats,
        "listing_performance": sorted(performance, key=lambda x: x["views"], reverse=True)[:5]
    }

def random_views(day, user_id):
    import random
    # Seed with day and user_id for consistent "random" values
    random.seed(str(day) + str(user_id))
    return random.randint(5, 50)
