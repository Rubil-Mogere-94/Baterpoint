import sys
import os
from sqlalchemy.orm import Session
from datetime import datetime

# Add the current directory to sys.path to allow importing from 'app'
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine, Base
from app.models import UserModel, ListingModel, CategoryModel
from app.auth_utils import get_password_hash

def seed_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        # 1. Clear related tables to avoid ForeignKeyViolation
        db.query(ReviewModel).delete()
        db.query(OfferModel).delete()
        db.query(FavoriteModel).delete()
        
        # 2. Create a default user if not exists
        user = db.query(UserModel).filter(UserModel.username == "demo_trader").first()

        if not user:
            user = UserModel(
                username="demo_trader",
                email="trader@baterpoint.com",
                hashed_password=get_password_hash("password123"),
                role="user"
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            print(f"Created user: {user.username}")

        # 2. Clear old listings to avoid duplicates in demo
        db.query(ListingModel).delete()
        
        # 3. Create Sample Listings
        listings_data = [
            {
                "title": "MacBook Pro M2",
                "description": "Like new MacBook Pro M2, 16GB RAM, 512GB SSD. Perfect for developers.",
                "price": 1200.0,
                "exchange_item": "High-end Gaming PC or Sony A7IV",
                "trade_type": "Both",
                "category": "Electronics",
                "image_url": "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80"
            },
            {
                "title": "Electric Guitar - Fender Strat",
                "description": "Beautiful sunburst Fender Stratocaster. Great tone, well-maintained.",
                "price": 800.0,
                "exchange_item": "Acoustic Guitar + Cash",
                "trade_type": "Barter",
                "category": "Music",
                "image_url": "https://images.unsplash.com/photo-1550291652-6ea9114a47b1?auto=format&fit=crop&w=800&q=80"
            },
            {
                "title": "Minimalist Oak Coffee Table",
                "description": "Solid oak coffee table, Scandinavian design. Minor scratches on the side.",
                "price": 250.0,
                "exchange_item": "Comfortable Armchair",
                "trade_type": "Both",
                "category": "Furniture",
                "image_url": "https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&w=800&q=80"
            },
            {
                "title": "DJI Mini 3 Pro",
                "description": "Compact drone with 4K camera. Includes extra batteries and carrying case.",
                "price": 600.0,
                "exchange_item": "GoPro Hero 11",
                "trade_type": "Sale",
                "category": "Electronics",
                "image_url": "https://images.unsplash.com/photo-1508614589041-895b88991e3e?auto=format&fit=crop&w=800&q=80"
            },
            {
                "title": "Vintage Film Camera",
                "description": "Canon AE-1 Program. Fully functional with 50mm f/1.8 lens.",
                "price": 150.0,
                "exchange_item": "Film rolls (Portra 400)",
                "trade_type": "Barter",
                "category": "Photography",
                "image_url": "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80"
            }
        ]

        for item in listings_data:
            listing = ListingModel(
                title=item["title"],
                description=item["description"],
                price=item["price"],
                exchange_item=item["exchange_item"],
                trade_type=item["trade_type"],
                category=item["category"],
                image_url=item["image_url"],
                user_id=user.id,
                sustainability_tags=[]
            )
            db.add(listing)
        
        db.commit()
        print(f"Successfully seeded {len(listings_data)} listings.")

    except Exception as e:
        print(f"Error seeding database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_db()
