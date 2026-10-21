from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import Annotated, List, Optional
from datetime import datetime

from ..database import get_db
from ..models import UserModel, ChatMessageModel, ListingModel
from ..schemas import InboxItem, ForumMessage, ChatMessageCreate, ChatMessageResponse, ShopkeeperInfo
from ..dependencies import get_current_user
from ..auth_utils import get_password_hash

router = APIRouter(prefix="/chat", tags=["Chat"])

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

def get_or_create_shopkeeper(db: Session) -> UserModel:
    shopkeeper = db.query(UserModel).filter(
        (UserModel.username == "Shopkeeper") | (UserModel.email == "shopkeeper@barterpoint.com")
    ).first()
    if not shopkeeper:
        shopkeeper = UserModel(
            username="Shopkeeper",
            email="shopkeeper@barterpoint.com",
            hashed_password=get_password_hash("ShopkeeperSecretPass123!"),
            role="official",
            overall_rating=5.0,
            total_reviews=250,
            avatar_url="https://api.dicebear.com/7.x/bottts/png?seed=Shopkeeper"
        )
        db.add(shopkeeper)
        db.commit()
        db.refresh(shopkeeper)
    return shopkeeper

@router.get("/shopkeeper", response_model=ShopkeeperInfo)
def get_shopkeeper(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    shopkeeper = get_or_create_shopkeeper(db)
    if current_user.id != shopkeeper.id:
        existing = db.query(ChatMessageModel).filter(
            ChatMessageModel.sender_id == shopkeeper.id,
            ChatMessageModel.recipient_id == current_user.id
        ).first()
        if not existing:
            welcome = ChatMessageModel(
                sender_id=shopkeeper.id,
                recipient_id=current_user.id,
                message_content="Karibu Barterpoint Shop! 🏪 I am your verified Shopkeeper (Mweka Duka). To prevent scammers, buyers do not transact directly with suppliers in private. I inspect item quality, approve trade swaps, and guarantee safe escrow handover. How can I help you today?",
                is_read=False
            )
            db.add(welcome)
            db.commit()

    return ShopkeeperInfo(
        id=shopkeeper.id,
        username=shopkeeper.username,
        role=shopkeeper.role,
        avatar_url=shopkeeper.avatar_url,
        title="Verified Barterpoint Shopkeeper (Mweka Duka)",
        subtitle="Official Store Desk • Escrow & Trade Verification"
    )

@router.get("/inbox", response_model=List[InboxItem])
async def get_inbox(
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    sent = db.query(ChatMessageModel).filter(ChatMessageModel.sender_id == current_user.id, ChatMessageModel.is_forum == False)
    received = db.query(ChatMessageModel).filter(ChatMessageModel.recipient_id == current_user.id, ChatMessageModel.is_forum == False)
    
    all_msgs = sent.union(received).order_by(desc(ChatMessageModel.timestamp)).all()
    
    inbox = {}
    for msg in all_msgs:
        other_user_id = msg.recipient_id if msg.sender_id == current_user.id else msg.sender_id
        if other_user_id is None: continue 
        
        if other_user_id not in inbox:
            other_user = db.query(UserModel).filter(UserModel.id == other_user_id).first()
            if not other_user: continue
            
            unread_count = db.query(ChatMessageModel).filter(
                ChatMessageModel.sender_id == other_user_id,
                ChatMessageModel.recipient_id == current_user.id,
                ChatMessageModel.is_read == False
            ).count()
            
            name = other_user.username
            if other_user.username == "Shopkeeper" or other_user.role in ['admin', 'official']:
                name = f"🏪 Barterpoint Shopkeeper ({other_user.username})"

            inbox[other_user_id] = {
                "other_user_id": other_user.id,
                "other_user_email": other_user.email,
                "other_user_username": name,
                "other_user_avatar": other_user.avatar_url,
                "last_message": msg.message_content or "[Image]",
                "last_message_time": msg.timestamp,
                "unread_count": unread_count,
                "listing_id": msg.listing_id
            }

    return list(inbox.values())

@router.get("/public-threads")
def get_public_threads(
    db: Annotated[Session, Depends(get_db)]
):
    """Returns listings that have active public comments."""
    listing_ids = db.query(ChatMessageModel.listing_id).filter(
        ChatMessageModel.listing_id.isnot(None),
        ChatMessageModel.is_forum == False
    ).distinct().limit(20).all()
    
    ids = [lid[0] for lid in listing_ids if lid[0] is not None]
    listings = db.query(ListingModel).filter(ListingModel.id.in_(ids)).all()
    
    result = []
    for l in listings:
        comment_count = db.query(ChatMessageModel).filter(
            ChatMessageModel.listing_id == l.id,
            ChatMessageModel.is_forum == False
        ).count()
        last_comment = db.query(ChatMessageModel).filter(
            ChatMessageModel.listing_id == l.id,
            ChatMessageModel.is_forum == False
        ).order_by(desc(ChatMessageModel.timestamp)).first()

        result.append({
            "listing_id": l.id,
            "title": l.title,
            "image_url": l.image_url,
            "price": l.price,
            "trade_type": l.trade_type,
            "comment_count": comment_count,
            "last_comment": last_comment.message_content if last_comment else "No comments yet",
            "last_comment_time": last_comment.timestamp if last_comment else l.created_at
        })
    return result

@router.get("/conversation/{other_user_id}", response_model=List[ChatMessageResponse])
async def get_conversation(
    other_user_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    # Fetch messages between both users
    messages = db.query(ChatMessageModel).filter(
        ((ChatMessageModel.sender_id == current_user.id) & (ChatMessageModel.recipient_id == other_user_id)) |
        ((ChatMessageModel.sender_id == other_user_id) & (ChatMessageModel.recipient_id == current_user.id)),
        ChatMessageModel.is_forum == False
    ).order_by(ChatMessageModel.timestamp.asc()).all()

    # Mark unread messages sent to current_user as read
    for m in messages:
        if m.recipient_id == current_user.id and not m.is_read:
            m.is_read = True
    db.commit()

    return messages

@router.post("/send", response_model=ChatMessageResponse)
async def send_message(
    payload: ChatMessageCreate,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    recipient = db.query(UserModel).filter(UserModel.id == payload.recipient_id).first()
    if not recipient:
        raise HTTPException(status_code=404, detail="Recipient user not found")

    is_official_chat = (
        recipient.role in ['admin', 'official'] or 
        recipient.username == 'Shopkeeper' or 
        current_user.role in ['admin', 'official'] or
        current_user.username == 'Shopkeeper'
    )
    if not is_official_chat:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Direct private messaging between buyers and suppliers is disabled to prevent scams. Barterpoint operates as a supervised shop: please post inquiries publicly on the listing comments or contact the Barterpoint Shopkeeper Desk."
        )

    new_msg = ChatMessageModel(
        sender_id=current_user.id,
        recipient_id=payload.recipient_id,
        listing_id=payload.listing_id,
        message_content=payload.message_content,
        is_read=False
    )
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

    # Dispatch instant notification to recipient
    send_ntfy_alert(
        topic=f"baterpoint-user-{recipient.id}",
        title=f"Message from {current_user.username}",
        body=payload.message_content,
        tags=["speech_balloon", "envelope"]
    )

    return new_msg


