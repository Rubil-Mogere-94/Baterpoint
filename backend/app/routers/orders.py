from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated, List

from ..database import get_db
from ..models import UserModel, CartModel, OrderModel, OrderItemModel, ListingModel
from ..schemas import Order, OrderCreate
from ..dependencies import get_current_user

router = APIRouter(prefix="/orders", tags=["Orders"])

@router.post("/", response_model=Order)
def create_order(
    order_in: OrderCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    # 1. Get cart
    cart = db.query(CartModel).filter(CartModel.user_id == current_user.id).first()
    if not cart or not cart.items:
        raise HTTPException(status_code=400, detail="Cart is empty")
        
    # 2. Calculate total and verify availability
    total_amount = 0
    order_items = []
    for cart_item in cart.items:
        listing = cart_item.listing
        if not listing:
             continue
        
        # Amazon-like: Verify item still has a price and is for sale
        if listing.trade_type == "Barter" and not listing.price:
             raise HTTPException(status_code=400, detail=f"Item {listing.title} is barter-only")
             
        item_price = listing.price or 0
        total_amount += item_price * cart_item.quantity
        
        order_items.append(OrderItemModel(
            listing_id=listing.id,
            quantity=cart_item.quantity,
            price_at_purchase=item_price
        ))
        
    # 3. Create order
    new_order = OrderModel(
        user_id=current_user.id,
        status="pending",
        total_amount=total_amount,
        shipping_address=order_in.shipping_address,
        items=order_items
    )
    db.add(new_order)
    
    # 4. Clear cart
    for item in cart.items:
        db.delete(item)
        
    db.commit()
    db.refresh(new_order)
    return new_order

@router.get("/", response_model=List[Order])
def get_my_orders(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    return db.query(OrderModel).filter(OrderModel.user_id == current_user.id).order_by(OrderModel.created_at.desc()).all()

@router.get("/{order_id}", response_model=Order)
def get_order_detail(
    order_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    order = db.query(OrderModel).filter(OrderModel.id == order_id, OrderModel.user_id == current_user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order
