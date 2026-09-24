from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Boolean, func, Text, JSON
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from .database import Base

class UserModel(Base):
    # ... rest of UserModel ...
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="user", nullable=False)
    subscription_status = Column(String, default="basic")
    overall_rating = Column(Float, default=0.0)
    total_reviews = Column(Integer, default=0)
    loyalty_points = Column(Integer, default=0)
    device_token = Column(String, nullable=True)
    successful_trades = Column(Integer, default=0)
    trade_reputation = Column(Float, default=5.0)
    avatar_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    listings = relationship("ListingModel", back_populates="owner")
    sent_messages = relationship("ChatMessageModel", foreign_keys="[ChatMessageModel.sender_id]", back_populates="sender")
    received_messages = relationship("ChatMessageModel", foreign_keys="[ChatMessageModel.recipient_id]", back_populates="recipient")
    received_offers = relationship("OfferModel", back_populates="buyer")
    quests = relationship("UserQuestModel", back_populates="user")
    cart = relationship("CartModel", uselist=False, back_populates="user")
    orders = relationship("OrderModel", back_populates="user")
    reviews = relationship("ReviewModel", back_populates="user")

class ListingModel(Base):
    __tablename__ = "listings"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    price = Column(Float, nullable=True) # cashPrice
    exchange_item = Column(String, nullable=True) # exchangeItem
    trade_type = Column(String) # "Barter", "Sale", or "Both"
    category = Column(String)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    brand_id = Column(Integer, ForeignKey("brands.id"), nullable=True)
    image_url = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    view_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    sustainability_tags = Column(JSON, default=[]) # e.g., ["upcycled", "eco-friendly"]
    embedding = Column(JSON, nullable=True) # vector embedding for similarity
    
    owner = relationship("UserModel", back_populates="listings")
    favorites = relationship("FavoriteModel", back_populates="listing")
    offers = relationship("OfferModel", back_populates="listing")
    reviews = relationship("ReviewModel", back_populates="listing")

class ReviewModel(Base):
    __tablename__ = "reviews"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    listing_id = Column(Integer, ForeignKey("listings.id"))
    rating = Column(Integer, nullable=False) # 1-5
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("UserModel", back_populates="reviews")
    listing = relationship("ListingModel", back_populates="reviews")

class CouponModel(Base):
    __tablename__ = "coupons"
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True, nullable=False)
    discount_percentage = Column(Integer, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class DealModel(Base):
    __tablename__ = "deals"
    id = Column(Integer, primary_key=True, index=True)
    listing_id = Column(Integer, ForeignKey("listings.id"))
    discount_percentage = Column(Integer)
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    
    listing = relationship("ListingModel")

class ChatMessageModel(Base):
    __tablename__ = "chat_messages"
    id = Column(Integer, primary_key=True, index=True)
    listing_id = Column(Integer, ForeignKey("listings.id"), nullable=True)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    message_content = Column(String)
    image_url = Column(String, nullable=True)
    is_read = Column(Boolean, default=False)
    is_forum = Column(Boolean, default=False)
    forum_category = Column(String, nullable=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    sender = relationship("UserModel", foreign_keys=[sender_id], back_populates="sent_messages")
    recipient = relationship("UserModel", foreign_keys=[recipient_id], back_populates="received_messages")
    listing = relationship("ListingModel")

class FavoriteModel(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    listing_id = Column(Integer, ForeignKey("listings.id"))
    
    user = relationship("UserModel")
    listing = relationship("ListingModel", back_populates="favorites")

class OfferModel(Base):
    __tablename__ = "offers"
    id = Column(Integer, primary_key=True, index=True)
    buyer_id = Column(Integer, ForeignKey("users.id"))
    listing_id = Column(Integer, ForeignKey("listings.id"))
    offered_price = Column(Float, nullable=True)
    offered_item = Column(String, nullable=True)
    status = Column(String, default="pending") 
    buyer_confirmed = Column(Boolean, default=False)
    seller_confirmed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    buyer = relationship("UserModel", foreign_keys=[buyer_id])
    listing = relationship("ListingModel")

class QuestModel(Base):
    __tablename__ = "quests"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    goal_type = Column(String, nullable=False) 
    goal_value = Column(Integer, nullable=False)
    points_reward = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class UserQuestModel(Base):
    __tablename__ = "user_quests"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    quest_id = Column(Integer, ForeignKey("quests.id"))
    progress = Column(Integer, default=0)
    completed = Column(Boolean, default=False)
    last_updated = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    user = relationship("UserModel", back_populates="quests")
    quest = relationship("QuestModel")

class RewardModel(Base):
    __tablename__ = "rewards"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    points_cost = Column(Integer, nullable=False)
    reward_type = Column(String, default="badge")

class UserRewardModel(Base):
    __tablename__ = "user_rewards"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    reward_id = Column(Integer, ForeignKey("rewards.id"))
    redeemed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    user = relationship("UserModel")
    reward = relationship("RewardModel")

class NotificationModel(Base):
    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String)
    message = Column(String)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

# --- New Amazon-like Models ---

class CartModel(Base):
    __tablename__ = "carts"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    user = relationship("UserModel", back_populates="cart")
    items = relationship("CartItemModel", back_populates="cart", cascade="all, delete-orphan")

class CartItemModel(Base):
    __tablename__ = "cart_items"
    id = Column(Integer, primary_key=True, index=True)
    cart_id = Column(Integer, ForeignKey("carts.id"))
    listing_id = Column(Integer, ForeignKey("listings.id"))
    quantity = Column(Integer, default=1)
    
    cart = relationship("CartModel", back_populates="items")
    listing = relationship("ListingModel")

class OrderModel(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String, default="pending") # pending, paid, shipped, delivered, cancelled
    total_amount = Column(Float, nullable=False)
    shipping_address = Column(String, nullable=True)
    shipping_address_id = Column(Integer, ForeignKey("addresses.id"), nullable=True)
    shipping_method_id = Column(Integer, ForeignKey("shipping_methods.id"), nullable=True)
    order_tax = Column(Float, default=0.0)
    order_discount = Column(Float, default=0.0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    user = relationship("UserModel", back_populates="orders")
    items = relationship("OrderItemModel", back_populates="order")

class OrderItemModel(Base):
    __tablename__ = "order_items"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    listing_id = Column(Integer, ForeignKey("listings.id"))
    quantity = Column(Integer, default=1)
    price_at_purchase = Column(Float, nullable=False)
    
    order = relationship("OrderModel", back_populates="items")
    listing = relationship("ListingModel")

class AddressModel(Base):
    __tablename__ = "addresses"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    email = Column(String, nullable=True)
    company = Column(String, nullable=True)
    country = Column(String, nullable=True)
    city = Column(String, nullable=False)
    address1 = Column(String, nullable=False)
    address2 = Column(String, nullable=True)
    zip_postal_code = Column(String, nullable=False)
    phone_number = Column(String, nullable=True)
    created_on_utc = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    user = relationship("UserModel", backref="addresses")

class CategoryModel(Base):
    __tablename__ = "categories"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    description = Column(String, nullable=True)
    parent_category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    published = Column(Boolean, default=True)
    display_order = Column(Integer, default=0)
    created_on_utc = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class BrandModel(Base):
    __tablename__ = "brands"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    description = Column(String, nullable=True)
    published = Column(Boolean, default=True)
    display_order = Column(Integer, default=0)
    created_on_utc = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class ListingAttributeModel(Base):
    __tablename__ = "listing_attributes"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    
class ListingAttributeValueModel(Base):
    __tablename__ = "listing_attribute_values"
    id = Column(Integer, primary_key=True, index=True)
    attribute_id = Column(Integer, ForeignKey("listing_attributes.id"))
    listing_id = Column(Integer, ForeignKey("listings.id"))
    name = Column(String, nullable=False)
    price_adjustment = Column(Float, default=0.0)
    quantity = Column(Integer, default=0)
    is_pre_selected = Column(Boolean, default=False)
    display_order = Column(Integer, default=0)

    attribute = relationship("ListingAttributeModel")
    listing = relationship("ListingModel", backref="attributes")

class ShippingMethodModel(Base):
    __tablename__ = "shipping_methods"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    display_order = Column(Integer, default=0)
