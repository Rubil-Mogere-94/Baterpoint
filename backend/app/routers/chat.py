from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import Annotated, List, Optional
from datetime import datetime

from ..database import get_db
from ..models import UserModel, ChatMessageModel
from ..schemas import InboxItem, ForumMessage, ChatMessageCreate, ChatMessageResponse
from ..dependencies import get_current_user

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
            
            inbox[other_user_id] = {
                "other_user_id": other_user.id,
                "other_user_email": other_user.email,
                "other_user_username": other_user.username,
                "other_user_avatar": other_user.avatar_url,
                "last_message": msg.message_content or "[Image]",
                "last_message_time": msg.timestamp,
                "unread_count": unread_count,
                "listing_id": msg.listing_id
            }
            
    return list(inbox.values())

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

