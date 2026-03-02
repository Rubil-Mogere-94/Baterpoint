from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import Annotated, List, Optional
from datetime import datetime

from ..database import get_db
from ..models import UserModel, ChatMessageModel
from ..schemas import InboxItem, ForumMessage
from ..dependencies import get_current_user

router = APIRouter(prefix="/chat", tags=["Chat"])

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

@router.get("/forum/messages", response_model=List[ForumMessage])
async def get_forum_messages(
    db: Annotated[Session, Depends(get_db)],
    category: Optional[str] = None
):
    query = db.query(ChatMessageModel).filter(ChatMessageModel.is_forum == True)
    if category:
        query = query.filter(ChatMessageModel.forum_category == category)
    
    messages = query.order_by(ChatMessageModel.timestamp).all()
    return [
        ForumMessage(
            id=m.id,
            sender_id=m.sender_id,
            sender_username=m.sender.username,
            message_content=m.message_content,
            image_url=m.image_url,
            forum_category=m.forum_category or "general",
            timestamp=m.timestamp
        ) for m in messages
    ]
