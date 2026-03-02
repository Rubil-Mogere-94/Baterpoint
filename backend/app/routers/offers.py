from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated, List

from ..database import get_db
from ..models import UserModel, ListingModel, OfferModel
from ..schemas import Offer, OfferCreate, OfferUpdate
from ..dependencies import get_current_user

router = APIRouter(prefix="/offers", tags=["Offers"])

@router.post("/{listing_id}", response_model=Offer)
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
    return new_offer

@router.get("/me/sent", response_model=List[Offer])
def get_my_sent_offers(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    return db.query(OfferModel).filter(OfferModel.buyer_id == current_user.id).all()

@router.get("/me/received", response_model=List[Offer])
def get_my_received_offers(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    return db.query(OfferModel).join(ListingModel).filter(ListingModel.user_id == current_user.id).all()

@router.put("/{offer_id}", response_model=Offer)
def update_offer_status(
    offer_id: int,
    offer_update: OfferUpdate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    offer = db.query(OfferModel).filter(OfferModel.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    
    listing = db.query(ListingModel).filter(ListingModel.id == offer.listing_id).first()
    if listing.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to respond to this offer")
    
    offer.status = offer_update.status
    db.commit()
    db.refresh(offer)
    return offer
