from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import Annotated, List

from ..database import get_db
from ..models import UserModel, ListingModel, OfferModel
from ..schemas import Offer, OfferCreate, OfferUpdate, OfferOfficialReview
from ..dependencies import get_current_user
from ..services.fcm import send_push_notification

router = APIRouter(prefix="/offers", tags=["Offers"])

def send_ntfy_alert(topic: str, title: str, body: str, tags: list = None, priority: str = "default"):
    import httpx
    try:
        headers = {"Title": title, "Priority": priority}
        if tags:
            headers["Tags"] = ",".join(tags)
        clean_topic = "".join(c if c.isalnum() or c in "_-" else "_" for c in topic)
        httpx.post(f"https://ntfy.sh/{clean_topic}", headers=headers, content=body.encode("utf-8"), timeout=5.0)
    except Exception:
        pass

@router.post("/{listing_id}", response_model=Offer)
def create_offer(
    listing_id: int,
    offer_data: OfferCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    background_tasks: BackgroundTasks
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
    
    # Notify seller via ntfy.sh and FCM
    seller = listing.owner
    seller_topic = f"baterpoint-user-{seller.id}"
    background_tasks.add_task(
        send_ntfy_alert,
        seller_topic,
        "New Offer Received!",
        f"{current_user.username} made an offer on your '{listing.title}'",
        ["handshake", "package"]
    )
    if seller.device_token:
        background_tasks.add_task(
            send_push_notification,
            seller.device_token,
            "New Offer Received!",
            f"{current_user.username} made an offer on your '{listing.title}'",
            {"screen": "offer_detail", "offer_id": str(new_offer.id)}
        )
        
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
    db: Annotated[Session, Depends(get_db)],
    background_tasks: BackgroundTasks
):
    offer = db.query(OfferModel).filter(OfferModel.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    
    listing = db.query(ListingModel).filter(ListingModel.id == offer.listing_id).first()
    if listing.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to respond to this offer")
    
    old_status = offer.status
    offer.status = offer_update.status
    db.commit()
    db.refresh(offer)
    
    # Notify buyer of status change via ntfy.sh and FCM
    buyer = offer.buyer
    if old_status != offer.status:
        buyer_topic = f"baterpoint-user-{buyer.id}"
        background_tasks.add_task(
            send_ntfy_alert,
            buyer_topic,
            f"Offer {offer.status.capitalize()}!",
            f"Your offer on '{listing.title}' has been {offer.status}.",
            ["bell", "tada" if offer.status.lower() == "accepted" else "information_source"]
        )
        if buyer.device_token:
            background_tasks.add_task(
                send_push_notification,
                buyer.device_token,
                f"Offer {offer.status.capitalize()}",
                f"Your offer on '{listing.title}' has been {offer.status}.",
                {"screen": "offer_detail", "offer_id": str(offer.id)}
            )
        
    return offer

@router.get("/admin/pending-official-reviews", response_model=List[Offer])
def get_pending_official_reviews(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    if current_user.role not in ["admin", "official"]:
        raise HTTPException(
            status_code=403,
            detail="Only verified Barterpoint officials can audit pending trades to prevent scammers."
        )
    return db.query(OfferModel).filter(OfferModel.official_verified == False).order_by(OfferModel.created_at.desc()).all()

@router.put("/{offer_id}/official-review", response_model=Offer)
def review_offer_as_official(
    offer_id: int,
    review_data: OfferOfficialReview,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    background_tasks: BackgroundTasks
):
    if current_user.role not in ["admin", "official"]:
        raise HTTPException(
            status_code=403,
            detail="Access Denied: Trading is only approved by verified Barterpoint officials to avoid scammers and ill wishers."
        )

    offer = db.query(OfferModel).filter(OfferModel.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    listing = db.query(ListingModel).filter(ListingModel.id == offer.listing_id).first()
    listing_title = listing.title if listing else "Item"

    if review_data.status.lower() == "approved":
        offer.official_verified = True
        offer.official_id = current_user.id
        offer.official_notes = review_data.official_notes or "Trade officially verified by Barterpoint safety team. Handover approved."
        status_label = "Approved & Verified"
        tag = "white_check_mark"
    else:
        offer.official_verified = False
        offer.official_id = current_user.id
        offer.official_notes = review_data.official_notes or "Trade rejected by Barterpoint official due to security/authenticity policy."
        offer.status = "rejected"
        status_label = "Rejected by Official"
        tag = "warning"

    db.commit()
    db.refresh(offer)

    # Notify both buyer and seller via ntfy.sh
    for uid in [offer.buyer_id, listing.user_id if listing else None]:
        if uid:
            background_tasks.add_task(
                send_ntfy_alert,
                f"baterpoint-user-{uid}",
                f"Trade {status_label} by Barterpoint Official",
                f"Listing: '{listing_title}'. Notes: {offer.official_notes}",
                ["shield", tag]
            )

    return offer

