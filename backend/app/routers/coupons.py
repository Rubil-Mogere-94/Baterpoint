from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated, List

from ..database import get_db
from ..models import UserModel, CouponModel
from ..schemas import CouponCreate, Coupon
from ..dependencies import get_current_active_admin_user, get_current_user

router = APIRouter(prefix="/coupons", tags=["Coupons"])

@router.post("/", response_model=Coupon)
def create_coupon(
    coupon_in: CouponCreate,
    current_admin: Annotated[UserModel, Depends(get_current_active_admin_user)],
    db: Annotated[Session, Depends(get_db)]
):
    existing = db.query(CouponModel).filter(CouponModel.code == coupon_in.code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Coupon code already exists")
    
    new_coupon = CouponModel(
        code=coupon_in.code,
        discount_percentage=coupon_in.discount_percentage
    )
    db.add(new_coupon)
    db.commit()
    db.refresh(new_coupon)
    return new_coupon

@router.get("/", response_model=List[Coupon])
def get_coupons(
    current_admin: Annotated[UserModel, Depends(get_current_active_admin_user)],
    db: Annotated[Session, Depends(get_db)]
):
    return db.query(CouponModel).all()

@router.get("/{code}", response_model=Coupon)
def validate_coupon(
    code: str,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    coupon = db.query(CouponModel).filter(CouponModel.code == code, CouponModel.is_active == True).first()
    if not coupon:
        raise HTTPException(status_code=404, detail="Invalid or expired coupon")
    return coupon
