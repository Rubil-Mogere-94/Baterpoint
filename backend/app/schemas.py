from pydantic import BaseModel, Field, EmailStr, ConfigDict
from typing import Optional, List
from datetime import datetime

class User(BaseModel):
    model_config = ConfigDict(from_attributes=True)
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
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    listing_id: int
    rating: int
    comment: Optional[str] = None
    created_at: datetime
    username: Optional[str] = None # For convenience

class Listing(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
    id: int
    title: str
    description: Optional[str] = None
    cashPrice: Optional[float] = Field(None, alias="price", validation_alias="price")
    exchangeItem: Optional[str] = Field(None, alias="exchange_item", validation_alias="exchange_item")
    category: str
    tradeType: str = Field(..., alias="trade_type", validation_alias="trade_type")
    imageUrl: Optional[str] = Field(None, alias="image_url", validation_alias="image_url")
    user_id: int
    view_count: int
    owner_username: Optional[str] = None
    owner_rating: Optional[float] = 0.0
    owner_reviews: Optional[int] = 0
    owner_avatar: Optional[str] = None
    average_rating: Optional[float] = 0.0
    reviews: List[Review] = []
    sustainability_tags: List[str] = []

class OfferCreate(BaseModel):
    offered_price: Optional[float] = None
    offered_item: Optional[str] = None

class Offer(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    buyer_id: int
    listing_id: int
    offered_price: Optional[float] = None
    offered_item: Optional[str] = None
    status: str
    buyer_confirmed: bool = False
    seller_confirmed: bool = False
    listing: Optional[Listing] = None

class Quest(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    description: str
    goal_type: str
    goal_value: int
    points_reward: int

class UserQuest(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    quest_id: int
    progress: int
    completed: bool
    quest: Quest

class Reward(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    description: str
    points_cost: int
    reward_type: str

class UserReward(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    reward_id: int
    redeemed_at: datetime
    reward: Reward

class Notification(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime

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
    model_config = ConfigDict(from_attributes=True)
    id: int
    sender_id: int
    sender_username: str
    message_content: str
    image_url: Optional[str] = None
    forum_category: str
    timestamp: datetime

class Deal(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    listing_id: int
    discount_percentage: int
    start_time: datetime
    end_time: datetime
    listing: Listing

class CouponCreate(BaseModel):
    code: str
    discount_percentage: int = Field(ge=1, le=100)

class Coupon(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    code: str
    discount_percentage: int
    is_active: bool
    created_at: datetime

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
    sustainability_tags: Optional[List[str]] = None

# --- New Amazon-like Schemas ---

class CartItemCreate(BaseModel):
    listing_id: int
    quantity: Optional[int] = 1

class CartItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    cart_id: int
    listing_id: int
    quantity: int
    listing: Listing

class Cart(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    items: List[CartItem] = []
    created_at: datetime
    updated_at: datetime

class OrderItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    listing_id: int
    quantity: int
    price_at_purchase: float
    listing: Listing

class AddressBase(BaseModel):
    first_name: str
    last_name: str
    email: Optional[EmailStr] = None
    company: Optional[str] = None
    country: Optional[str] = None
    city: str
    address1: str
    address2: Optional[str] = None
    zip_postal_code: str
    phone_number: Optional[str] = None

class AddressCreate(AddressBase):
    pass

class Address(AddressBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    created_on_utc: datetime

class ShippingMethod(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    description: Optional[str] = None
    display_order: int

class OrderCreate(BaseModel):
    shipping_address_id: Optional[int] = None
    shipping_method_id: Optional[int] = None
    coupon_code: Optional[str] = None

class Order(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    status: str
    total_amount: float
    shipping_address_id: Optional[int] = None
    shipping_method_id: Optional[int] = None
    order_tax: float
    order_discount: float
    created_at: datetime
    items: List[OrderItem] = []

class Match(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    match_score: int
    user_item: Listing
    target_item: Listing
    partner: User
    reason: str
