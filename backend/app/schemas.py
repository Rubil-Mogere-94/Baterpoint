from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime

class User(BaseModel):
    id: int
    email: str
    username: str
    role: str
    subscription_status: Optional[str] = "basic"
    overall_rating: Optional[float] = 0.0
    total_reviews: Optional[int] = 0
    loyalty_points: Optional[int] = 0
    device_token: Optional[str] = None
    successful_trades: Optional[int] = 0
    trade_reputation: Optional[float] = 5.0
    avatar_url: Optional[str] = None

    class Config:
        from_attributes = True

class UserCreate(BaseModel):
    username: str
    email: str
    password: str = Field(min_length=8, max_length=72)
    role: str = "user"

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class ReviewCreate(BaseModel):
    listing_id: int
    rating: int = Field(ge=1, le=5)
    comment: Optional[str] = None

class Review(BaseModel):
    id: int
    user_id: int
    listing_id: int
    rating: int
    comment: Optional[str] = None
    created_at: datetime
    username: Optional[str] = None # For convenience

    class Config:
        from_attributes = True

class Listing(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    cashPrice: Optional[float] = None
    exchangeItem: Optional[str] = None
    category: str
    tradeType: str
    imageUrl: Optional[str] = None
    user_id: int
    view_count: int
    owner_username: Optional[str] = None
    owner_rating: Optional[float] = 0.0
    owner_reviews: Optional[int] = 0
    owner_avatar: Optional[str] = None
    average_rating: Optional[float] = 0.0
    reviews: List[Review] = []

    class Config:
        from_attributes = True

class OfferCreate(BaseModel):
    offered_price: Optional[float] = None
    offered_item: Optional[str] = None

class Offer(BaseModel):
    id: int
    buyer_id: int
    listing_id: int
    offered_price: Optional[float] = None
    offered_item: Optional[str] = None
    status: str
    buyer_confirmed: bool = False
    seller_confirmed: bool = False
    listing: Optional[Listing] = None

    class Config:
        from_attributes = True

class Quest(BaseModel):
    id: int
    title: str
    description: str
    goal_type: str
    goal_value: int
    points_reward: int

    class Config:
        from_attributes = True

class UserQuest(BaseModel):
    id: int
    quest_id: int
    progress: int
    completed: bool
    quest: Quest

    class Config:
        from_attributes = True

class Reward(BaseModel):
    id: int
    title: str
    description: str
    points_cost: int
    reward_type: str

    class Config:
        from_attributes = True

class UserReward(BaseModel):
    id: int
    reward_id: int
    redeemed_at: datetime
    reward: Reward

    class Config:
        from_attributes = True

class Notification(BaseModel):
    id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

class InboxItem(BaseModel):
    other_user_id: int
    other_user_email: str
    other_user_username: str
    other_user_avatar: Optional[str] = None
    last_message: str
    last_message_time: datetime
    unread_count: int
    listing_id: Optional[int] = None

class ForumMessage(BaseModel):
    id: int
    sender_id: int
    sender_username: str
    message_content: str
    image_url: Optional[str] = None
    forum_category: str
    timestamp: datetime
    class Config:
        from_attributes = True

class Deal(BaseModel):
    id: int
    listing_id: int
    discount_percentage: int
    start_time: datetime
    end_time: datetime
    listing: Listing

    class Config:
        from_attributes = True

class OfferUpdate(BaseModel):
    status: str

class UserRoleUpdate(BaseModel):
    role: str

class UserSubscriptionUpdate(BaseModel):
    subscription_status: str

class DeviceTokenUpdate(BaseModel):
    device_token: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8, max_length=72)
    avatar_url: Optional[str] = None

class ListingUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    cashPrice: Optional[float] = None
    exchangeItem: Optional[str] = None
    category: Optional[str] = None
    tradeType: Optional[str] = None

# --- New Amazon-like Schemas ---

class CartItemCreate(BaseModel):
    listing_id: int
    quantity: Optional[int] = 1

class CartItem(BaseModel):
    id: int
    cart_id: int
    listing_id: int
    quantity: int
    listing: Listing

    class Config:
        from_attributes = True

class Cart(BaseModel):
    id: int
    user_id: int
    items: List[CartItem] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class OrderItem(BaseModel):
    id: int
    listing_id: int
    quantity: int
    price_at_purchase: float
    listing: Listing
    
    class Config:
        from_attributes = True

class OrderCreate(BaseModel):
    shipping_address: str

class Order(BaseModel):
    id: int
    user_id: int
    status: str
    total_amount: float
    shipping_address: Optional[str] = None
    created_at: datetime
    items: List[OrderItem] = []

    class Config:
        from_attributes = True
