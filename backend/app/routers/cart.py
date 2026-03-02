from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated

from ..database import get_db
from ..models import UserModel, CartModel, CartItemModel, ListingModel
from ..schemas import Cart, CartItem, CartItemCreate
from ..dependencies import get_current_user

router = APIRouter(prefix="/cart", tags=["Cart"])

@router.get("/", response_model=Cart)
def get_my_cart(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    cart = db.query(CartModel).filter(CartModel.user_id == current_user.id).first()
    if not cart:
        # Create cart if not exists
        cart = CartModel(user_id=current_user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    return cart

@router.post("/items", response_model=Cart)
def add_to_cart(
    item: CartItemCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    cart = db.query(CartModel).filter(CartModel.user_id == current_user.id).first()
    if not cart:
        cart = CartModel(user_id=current_user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
        
    listing = db.query(ListingModel).filter(ListingModel.id == item.listing_id).first()
    if not listing:
        raise HTTPException(status_code=404, detail="Listing not found")
        
    if listing.user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot add your own item to cart")
        
    # Check if item already in cart
    existing_item = db.query(CartItemModel).filter(
        CartItemModel.cart_id == cart.id,
        CartItemModel.listing_id == item.listing_id
    ).first()
    
    if existing_item:
        existing_item.quantity += item.quantity
    else:
        new_item = CartItemModel(
            cart_id=cart.id,
            listing_id=item.listing_id,
            quantity=item.quantity
        )
        db.add(new_item)
        
    db.commit()
    db.refresh(cart)
    return cart

@router.delete("/items/{item_id}", response_model=Cart)
def remove_from_cart(
    item_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    cart = db.query(CartModel).filter(CartModel.user_id == current_user.id).first()
    if not cart:
         raise HTTPException(status_code=404, detail="Cart not found")
         
    item = db.query(CartItemModel).filter(CartItemModel.id == item_id, CartItemModel.cart_id == cart.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not in cart")
        
    db.delete(item)
    db.commit()
    db.refresh(cart)
    return cart

@router.put("/items/{item_id}", response_model=Cart)
def update_cart_item_quantity(
    item_id: int,
    quantity: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    if quantity <= 0:
         return remove_from_cart(item_id, current_user, db)

    cart = db.query(CartModel).filter(CartModel.user_id == current_user.id).first()
    if not cart:
         raise HTTPException(status_code=404, detail="Cart not found")
         
    item = db.query(CartItemModel).filter(CartItemModel.id == item_id, CartItemModel.cart_id == cart.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not in cart")
        
    item.quantity = quantity
    db.commit()
    db.refresh(cart)
    return cart
