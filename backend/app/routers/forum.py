from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated, List, Optional
from datetime import datetime

from ..database import get_db
from ..models import UserModel, ChatMessageModel
from ..schemas import ForumMessage
from ..dependencies import get_current_user

router = APIRouter(prefix="/forum", tags=["Forum"])

@router.get("/messages", response_model=List[ForumMessage])
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
