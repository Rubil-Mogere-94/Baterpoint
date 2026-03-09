from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
from typing import Annotated

from ..database import get_db
from ..models import UserModel, OrderModel, ListingModel
from ..dependencies import get_current_active_admin_user

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/analytics")
def get_analytics(
    current_admin: Annotated[UserModel, Depends(get_current_active_admin_user)],
    db: Annotated[Session, Depends(get_db)]
):
    # DAU (Daily Active Users) - simplified to users created in last 24h
    yesterday = datetime.utcnow() - timedelta(days=1)
    new_users_24h = db.query(UserModel).filter(UserModel.created_at >= yesterday).count()
    
    total_sales = db.query(func.sum(OrderModel.total_amount)).filter(OrderModel.status == "paid").scalar() or 0.0
    active_listings = db.query(ListingModel).count()
    
    return {
        "estimated_dau": new_users_24h,
        "total_sales": total_sales,
        "total_active_listings": active_listings
    }
