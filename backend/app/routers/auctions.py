from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import Annotated, List, Optional
from datetime import datetime, timezone, timedelta

from ..database import get_db
from ..models import UserModel, AuctionModel, BidModel
from ..schemas import AuctionCreate, AuctionResponse, BidCreate, BidResponse, AuctionStats
from ..dependencies import get_current_user
from .chat import send_ntfy_alert

router = APIRouter(prefix="/auctions", tags=["Auctions"])

def format_auction(a: AuctionModel, db: Session) -> AuctionResponse:
    now = datetime.now(timezone.utc)
    # Ensure timezone awareness if naive
    ends_at = a.ends_at
    if ends_at.tzinfo is None:
        ends_at = ends_at.replace(tzinfo=timezone.utc)

    is_ended = (now >= ends_at) or (a.status in ["ended", "sold"])
    if now >= ends_at and a.status == "active":
        a.status = "ended"
        db.commit()

    highest_bidder_name = None
    if a.highest_bidder_id:
        hb = db.query(UserModel).filter(UserModel.id == a.highest_bidder_id).first()
        if hb:
            highest_bidder_name = hb.username

    seller_name = None
    seller = db.query(UserModel).filter(UserModel.id == a.seller_id).first()
    if seller:
        seller_name = seller.username

    # Format recent bids
    bids = []
    for b in a.bids[:10]:
        bidder = db.query(UserModel).filter(UserModel.id == b.bidder_id).first()
        bids.append(BidResponse(
            id=b.id,
            auction_id=b.auction_id,
            bidder_id=b.bidder_id,
            bidder_username=bidder.username if bidder else "Bidder",
            bid_amount=b.bid_amount,
            timestamp=b.timestamp
        ))

    return AuctionResponse(
        id=a.id,
        title=a.title,
        description=a.description,
        image_url=a.image_url,
        condition_type=a.condition_type or "damaged_repair",
        damage_details=a.damage_details,
        recyclable_materials=a.recyclable_materials or [],
        starting_bid=a.starting_bid,
        current_bid=a.current_bid,
        min_increment=a.min_increment,
        highest_bidder_id=a.highest_bidder_id,
        highest_bidder_username=highest_bidder_name,
        seller_id=a.seller_id,
        seller_username=seller_name,
        status=a.status,
        created_at=a.created_at,
        ends_at=a.ends_at,
        total_bids=a.total_bids or len(a.bids),
        is_ended=is_ended,
        bids=bids
    )

@router.get("/", response_model=List[AuctionResponse])
def get_auctions(
    db: Annotated[Session, Depends(get_db)],
    condition_type: Optional[str] = None,
    material: Optional[str] = None,
    search: Optional[str] = None,
    status_filter: Optional[str] = "active",
    skip: int = 0,
    limit: int = 30
):
    query = db.query(AuctionModel)
    if status_filter and status_filter != "all":
        query = query.filter(AuctionModel.status == status_filter)

    if condition_type:
        query = query.filter(AuctionModel.condition_type == condition_type)

    if search:
        query = query.filter(
            (AuctionModel.title.ilike(f"%{search}%")) |
            (AuctionModel.description.ilike(f"%{search}%"))
        )

    auctions = query.order_by(desc(AuctionModel.created_at)).offset(skip).limit(limit).all()

    # Material filter in memory if JSON column
    if material:
        auctions = [a for a in auctions if material.lower() in [str(m).lower() for m in (a.recyclable_materials or [])]]

    return [format_auction(a, db) for a in auctions]

@router.get("/stats/summary", response_model=AuctionStats)
def get_auction_stats(db: Annotated[Session, Depends(get_db)]):
    active_count = db.query(AuctionModel).filter(AuctionModel.status == "active").count()
    total_bids = db.query(BidModel).count()
    salvage_count = db.query(AuctionModel).count()
    return AuctionStats(
        total_active_auctions=active_count,
        total_bids_placed=total_bids,
        salvage_items_diverted=salvage_count,
        recyclable_categories=["E-Waste & Electronics", "Scrap Metal & Alloys", "Recyclable Plastics", "Upcyclable Timber & Wood", "Spare Parts"]
    )

@router.get("/{auction_id}", response_model=AuctionResponse)
def get_auction_detail(
    auction_id: int,
    db: Annotated[Session, Depends(get_db)]
):
    a = db.query(AuctionModel).filter(AuctionModel.id == auction_id).first()
    if not a:
        raise HTTPException(status_code=404, detail="Auction item not found")
    return format_auction(a, db)

@router.post("/", response_model=AuctionResponse, status_code=status.HTTP_201_CREATED)
def create_auction(
    payload: AuctionCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    duration = max(1, min(payload.duration_hours, 168)) # max 7 days
    ends_at = datetime.now(timezone.utc) + timedelta(hours=duration)

    new_auction = AuctionModel(
        title=payload.title,
        description=payload.description,
        image_url=payload.image_url,
        condition_type=payload.condition_type,
        damage_details=payload.damage_details,
        recyclable_materials=payload.recyclable_materials,
        starting_bid=payload.starting_bid,
        current_bid=payload.starting_bid,
        min_increment=payload.min_increment,
        seller_id=current_user.id,
        status="active",
        ends_at=ends_at,
        total_bids=0
    )
    db.add(new_auction)
    db.commit()
    db.refresh(new_auction)

    return format_auction(new_auction, db)

@router.post("/{auction_id}/bid", response_model=AuctionResponse)
def place_bid(
    auction_id: int,
    payload: BidCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    a = db.query(AuctionModel).filter(AuctionModel.id == auction_id).first()
    if not a:
        raise HTTPException(status_code=404, detail="Auction item not found")

    now = datetime.now(timezone.utc)
    ends_at = a.ends_at
    if ends_at.tzinfo is None:
        ends_at = ends_at.replace(tzinfo=timezone.utc)

    if now >= ends_at or a.status != "active":
        a.status = "ended"
        db.commit()
        raise HTTPException(status_code=400, detail="This auction has already ended")

    if a.seller_id == current_user.id:
        raise HTTPException(status_code=400, detail="Sellers cannot bid on their own auction items")

    min_required = a.current_bid + a.min_increment if a.total_bids > 0 else a.starting_bid
    if payload.bid_amount < min_required:
        raise HTTPException(
            status_code=400,
            detail=f"Bid too low. Minimum acceptable bid is KSh {min_required:,.2f}"
        )

    previous_highest_bidder = a.highest_bidder_id

    # Record new bid
    new_bid = BidModel(
        auction_id=a.id,
        bidder_id=current_user.id,
        bid_amount=payload.bid_amount
    )
    db.add(new_bid)

    # Update auction state
    a.current_bid = payload.bid_amount
    a.highest_bidder_id = current_user.id
    a.total_bids = (a.total_bids or 0) + 1
    db.commit()
    db.refresh(a)

    # Notify previous highest bidder if outbid
    if previous_highest_bidder and previous_highest_bidder != current_user.id:
        send_ntfy_alert(
            topic=f"baterpoint-user-{previous_highest_bidder}",
            title=f"Outbid on '{a.title}'! ⚡",
            body=f"Someone placed a higher bid of KSh {payload.bid_amount:,.2f}. Place another bid now!",
            tags=["warning", "hammer"]
        )

    # Notify seller of new bid
    send_ntfy_alert(
        topic=f"baterpoint-user-{a.seller_id}",
        title=f"New Bid on '{a.title}'! 🔨",
        body=f"@{current_user.username} placed a bid of KSh {payload.bid_amount:,.2f}",
        tags=["moneybag", "hammer"]
    )

    return format_auction(a, db)
