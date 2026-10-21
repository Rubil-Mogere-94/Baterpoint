import sys
import os
import httpx
from sqlalchemy.orm import Session
from datetime import datetime

# Add current directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine, Base
from app.models import UserModel, ListingModel, CategoryModel, ReviewModel, OfferModel, FavoriteModel, ChatMessageModel, AuctionModel, BidModel
from app.auth_utils import get_password_hash

MOCK_STORE_URL = "https://fake-store-api.mock.beeceptor.com"

# High-resolution Unsplash images mapped to Beeceptor product names
IMAGE_MAP = {
    "smartphone": "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80",
    "laptop": "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80",
    "wireless headphones": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=800&q=80",
    "smartwatch": "https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80",
    "professional dslr camera": "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80",
    "smart tv": "https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?auto=format&fit=crop&w=800&q=80",
    "tablet": "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?auto=format&fit=crop&w=800&q=80",
    "gaming console": "https://images.unsplash.com/photo-1486401899868-0e435ed85128?auto=format&fit=crop&w=800&q=80",
    "energy-efficient refrigerator": "https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?auto=format&fit=crop&w=800&q=80",
}

EXCHANGE_MAP = {
    "smartphone": "Tablet or DSLR Camera + KSh 5,000",
    "laptop": "High-end Gaming PC or Sony A7IV",
    "wireless headphones": "Smartwatch or Mechanical Keyboard",
    "smartwatch": "Fitness tracker or AirPods + cash",
    "professional dslr camera": "Drone or iPhone 13 Pro",
    "smart tv": None, # Cash only
    "tablet": "Nintendo Switch or Kindle Oasis",
    "gaming console": "Gaming Laptop or VR Headset",
    "energy-efficient refrigerator": None, # Cash only
}

TRADE_TYPE_MAP = {
    "wireless headphones": "Barter",
    "smart tv": "Sale",
    "energy-efficient refrigerator": "Sale",
}

def fetch_beeceptor_products():
    try:
        response = httpx.get(f"{MOCK_STORE_URL}/api/products", timeout=10.0)
        if response.status_code == 200:
            return response.json()
    except Exception as exc:
        print(f"Warning: Could not fetch from {MOCK_STORE_URL}/api/products: {exc}")
    return None

def fetch_beeceptor_users():
    try:
        response = httpx.get(f"{MOCK_STORE_URL}/api/users", timeout=10.0)
        if response.status_code == 200:
            return response.json()
    except Exception as exc:
        print(f"Warning: Could not fetch from {MOCK_STORE_URL}/api/users: {exc}")
    return None

def fetch_dummyjson_products(limit=15):
    try:
        response = httpx.get(f"https://dummyjson.com/products?limit={limit}", timeout=10.0)
        if response.status_code == 200:
            return response.json().get("products", [])
    except Exception as exc:
        print(f"Warning: Could not fetch from https://dummyjson.com/products: {exc}")
    return []

def seed_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        # 1. Clear related tables
        db.query(ReviewModel).delete()
        db.query(OfferModel).delete()
        db.query(FavoriteModel).delete()
        db.query(ListingModel).delete()

        # 2. Seed Default User
        user = db.query(UserModel).filter(UserModel.username == "demo_trader").first()
        if not user:
            user = UserModel(
                username="demo_trader",
                email="trader@baterpoint.com",
                hashed_password=get_password_hash("password123"),
                role="user",
                trade_reputation=4.9,
                successful_trades=14
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            print(f"Created primary user: {user.username}")

        # Seed Official Barterpoint Shopkeeper (Mweka Duka)
        shopkeeper = db.query(UserModel).filter(UserModel.username == "Shopkeeper").first()
        if not shopkeeper:
            shopkeeper = UserModel(
                username="Shopkeeper",
                email="shopkeeper@barterpoint.com",
                hashed_password=get_password_hash("ShopkeeperPass123!"),
                role="official",
                trade_reputation=5.0,
                successful_trades=500,
                avatar_url="https://api.dicebear.com/7.x/bottts/png?seed=Shopkeeper"
            )
            db.add(shopkeeper)
            db.commit()
            db.refresh(shopkeeper)
            print("Created verified Barterpoint Shopkeeper (Mweka Duka)")

        # Seed extra users from Beeceptor if available
        mock_users = fetch_beeceptor_users()
        created_users = [user]
        if mock_users:
            for mu in mock_users:
                uname = mu.get("username", "mock_user")
                if not db.query(UserModel).filter(UserModel.username == uname).first():
                    nu = UserModel(
                        username=uname,
                        email=mu.get("email", f"{uname}@example.com"),
                        hashed_password=get_password_hash("password123"),
                        role="user",
                        trade_reputation=4.8
                    )
                    db.add(nu)
                    db.commit()
                    db.refresh(nu)
                    created_users.append(nu)
            print(f"Synced {len(created_users)} users from Beeceptor / local.")

        # 3. Fetch products from Beeceptor mock store
        beeceptor_products = fetch_beeceptor_products()

        if beeceptor_products:
            print(f"Syncing {len(beeceptor_products)} products from {MOCK_STORE_URL}...")
            for idx, p in enumerate(beeceptor_products):
                name = p.get("name", f"Product #{p.get('product_id', idx)}")
                lower_name = name.lower()
                image = IMAGE_MAP.get(lower_name, p.get("image", "assets/images/placeholder.png"))
                trade_type = TRADE_TYPE_MAP.get(lower_name, "Both") # Default to Mixed Trade
                exchange = EXCHANGE_MAP.get(lower_name, "Open to comparable trade or cash")

                owner = created_users[idx % len(created_users)]
                listing = ListingModel(
                    title=name,
                    description=p.get("description", ""),
                    price=float(p.get("price", 0.0)),
                    exchange_item=exchange if trade_type in ("Barter", "Both") else None,
                    trade_type=trade_type,
                    category=p.get("category", "Electronics"),
                    image_url=image,
                    user_id=owner.id,
                    sustainability_tags=["verified", "top-rated"] if (p.get("rating", 0) >= 4.5) else []
                )
                db.add(listing)
                db.commit()
                db.refresh(listing)

                # Add reviews if provided by Beeceptor
                for rev in p.get("reviews", []):
                    reviewer = created_users[(idx + 1) % len(created_users)]
                    r = ReviewModel(
                        user_id=reviewer.id,
                        listing_id=listing.id,
                        rating=rev.get("rating", 5),
                        comment=rev.get("comment", "Great trade!")
                    )
                    db.add(r)
                db.commit()

            print(f"Successfully seeded {len(beeceptor_products)} listings from {MOCK_STORE_URL}.")

        # 4. Fetch and seed products from DummyJSON
        dummy_products = fetch_dummyjson_products(limit=15)
        if dummy_products:
            print(f"Syncing {len(dummy_products)} products from https://dummyjson.com/products...")
            for idx, dp in enumerate(dummy_products):
                title = dp.get("title", f"Item #{dp.get('id', idx)}")
                if not db.query(ListingModel).filter(ListingModel.title == title).first():
                    price = float(dp.get("price", 0.0))
                    tags = [t.lower() for t in dp.get("tags", [])]
                    cat = dp.get("category", "General").capitalize()
                    img = dp.get("thumbnail") or (dp.get("images")[0] if dp.get("images") else "assets/images/placeholder.png")

                    if "beauty" in tags or price < 25:
                        trade_type = "Sale"
                        exchange = None
                    elif "headphones" in tags or "audio" in tags or price < 150:
                        trade_type = "Barter"
                        exchange = "Open to gadget or accessory swap"
                    else:
                        trade_type = "Both"
                        exchange = f"Trade for comparable {cat} + cash delta"

                    owner = created_users[idx % len(created_users)]
                    listing = ListingModel(
                        title=title,
                        description=dp.get("description", ""),
                        price=price,
                        category=cat,
                        trade_type=trade_type,
                        image_url=img,
                        user_id=owner.id,
                        exchange_item=exchange,
                        sustainability_tags=["eco-friendly"] if dp.get("rating", 0) > 4.0 else []
                    )
                    db.add(listing)
                    db.commit()
                    db.refresh(listing)

                    for rev in dp.get("reviews", []):
                        reviewer = created_users[(idx + 1) % len(created_users)]
                        r = ReviewModel(
                            user_id=reviewer.id,
                            listing_id=listing.id,
                            rating=rev.get("rating", 5),
                            comment=rev.get("comment", "Great trade!")
                        )
                        db.add(r)
                    db.commit()
            print(f"Successfully synced DummyJSON listings.")

        if not beeceptor_products and not dummy_products:
            print("Falling back to local high-quality mixed currency listings...")
            fallback_listings = [
                {
                    "title": "Smartphone",
                    "description": "High-end smartphone with advanced features, OLED screen, and 5G.",
                    "price": 599.99,
                    "exchange_item": "Tablet or DSLR Camera + KSh 5,000",
                    "trade_type": "Both",
                    "category": "Electronics",
                    "image_url": IMAGE_MAP["smartphone"]
                },
                {
                    "title": "Laptop",
                    "description": "Powerful laptop for work and gaming with 16GB RAM and RTX GPU.",
                    "price": 999.99,
                    "exchange_item": "High-end Gaming PC or Sony A7IV",
                    "trade_type": "Both",
                    "category": "Electronics",
                    "image_url": IMAGE_MAP["laptop"]
                },
                {
                    "title": "Wireless Headphones",
                    "description": "Premium wireless headphones with active noise-cancellation.",
                    "price": 149.99,
                    "exchange_item": "Smartwatch or Mechanical Keyboard",
                    "trade_type": "Barter",
                    "category": "Electronics",
                    "image_url": IMAGE_MAP["wireless headphones"]
                },
                {
                    "title": "Professional DSLR Camera",
                    "description": "High-quality DSLR camera with 50mm f/1.8 lens for photo enthusiasts.",
                    "price": 499.99,
                    "exchange_item": "Drone or iPhone 13 Pro",
                    "trade_type": "Both",
                    "category": "Cameras",
                    "image_url": IMAGE_MAP["professional dslr camera"]
                },
                {
                    "title": "Smart TV",
                    "description": "55-inch 4K HDR smart TV with built-in streaming apps.",
                    "price": 799.99,
                    "exchange_item": None,
                    "trade_type": "Sale",
                    "category": "Electronics",
                    "image_url": IMAGE_MAP["smart tv"]
                }
            ]
            for item in fallback_listings:
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
            print(f"Successfully seeded {len(fallback_listings)} fallback listings.")

        # Seed sample public comments on first listing if none exist
        first_listing = db.query(ListingModel).first()
        if first_listing and not db.query(ChatMessageModel).filter(ChatMessageModel.listing_id == first_listing.id).first():
            c1 = ChatMessageModel(
                listing_id=first_listing.id,
                sender_id=user.id,
                recipient_id=first_listing.user_id,
                message_content="Habari! Is this item available for inspection at the Barterpoint store in Nairobi?",
                is_read=True
            )
            c2 = ChatMessageModel(
                listing_id=first_listing.id,
                sender_id=shopkeeper.id,
                recipient_id=user.id,
                message_content="Karibu! 🏪 Yes, the item has been verified by the Shopkeeper desk and is ready for safe escrow trade handover.",
                is_read=True
            )
            db.add_all([c1, c2])
            db.commit()
            print("Seeded public item inquiries and official shopkeeper replies.")

        # Seed Salvage & Recyclable Auction Items
        if not db.query(AuctionModel).first():
            from datetime import timedelta, timezone
            now = datetime.now(timezone.utc)
            sample_auctions = [
                {
                    "title": "MacBook Pro 15'' (2018) - Broken Display, Logic Board Intact",
                    "description": "Retina display glass is cracked, but the logic board boots and connects to external monitor via HDMI. High-grade aluminum chassis, 16GB RAM, original battery. Perfect for repair technicians or salvage components.",
                    "image_url": "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80",
                    "condition_type": "damaged_repair",
                    "damage_details": "Display cracked; HDMI output functional; 16GB RAM; battery healthy.",
                    "recyclable_materials": ["aluminum chassis", "copper heatsink", "logic board", "lithium cells"],
                    "starting_bid": 3500.0,
                    "current_bid": 4200.0,
                    "min_increment": 100.0,
                    "ends_at": now + timedelta(hours=36),
                    "total_bids": 4
                },
                {
                    "title": "Bulk Electronic Waste & PCB Circuit Lot (12kg Salvage)",
                    "description": "Certified e-waste lot: 12kg of vintage circuit boards, server daughtercards, copper coils, and gold-plated memory modules. Ideal for metals reclamation, precious metal extraction, or electronics upcycling.",
                    "image_url": "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=800&q=80",
                    "condition_type": "recyclable",
                    "damage_details": "Mixed non-functional boards; sorted for copper, gold, and aluminum recovery.",
                    "recyclable_materials": ["e-waste", "gold-plated pins", "copper coils", "silicon chips"],
                    "starting_bid": 1800.0,
                    "current_bid": 2400.0,
                    "min_increment": 50.0,
                    "ends_at": now + timedelta(hours=48),
                    "total_bids": 6
                },
                {
                    "title": "Solid Teak Wood Coffee Table (Broken Joint, Needs Carpenter)",
                    "description": "Heavy vintage solid teak wood table. One leg detached at the joint mortise; top has minor water rings. 100% solid timber, zero particle board. Excellent for woodworking restoration or timber reuse.",
                    "image_url": "https://images.unsplash.com/photo-1538688525198-9b88f6f53126?auto=format&fit=crop&w=800&q=80",
                    "condition_type": "refurbishable",
                    "damage_details": "Loose mortise joint on rear leg; superficial finish wear.",
                    "recyclable_materials": ["solid teak timber", "brass joint bolts"],
                    "starting_bid": 1200.0,
                    "current_bid": 1600.0,
                    "min_increment": 50.0,
                    "ends_at": now + timedelta(hours=24),
                    "total_bids": 3
                },
                {
                    "title": "Sony Alpha A6000 Camera Body (Shutter Jam, Clean Sensor)",
                    "description": "Mirrorless camera body reporting Error 50 shutter malfunction. Sensor, EVF, motherboard, and dials in mint condition. Ideal for camera repairers or spare parts salvage.",
                    "image_url": "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80",
                    "condition_type": "spare_parts",
                    "damage_details": "Shutter blade stuck; optical sensor and electronic displays undamaged.",
                    "recyclable_materials": ["magnesium alloy", "optical sensor", "circuit boards"],
                    "starting_bid": 2800.0,
                    "current_bid": 3300.0,
                    "min_increment": 100.0,
                    "ends_at": now + timedelta(hours=60),
                    "total_bids": 2
                }
            ]

            for a_data in sample_auctions:
                auc = AuctionModel(
                    title=a_data["title"],
                    description=a_data["description"],
                    image_url=a_data["image_url"],
                    condition_type=a_data["condition_type"],
                    damage_details=a_data["damage_details"],
                    recyclable_materials=a_data["recyclable_materials"],
                    starting_bid=a_data["starting_bid"],
                    current_bid=a_data["current_bid"],
                    min_increment=a_data["min_increment"],
                    seller_id=user.id,
                    highest_bidder_id=shopkeeper.id,
                    status="active",
                    ends_at=a_data["ends_at"],
                    total_bids=a_data["total_bids"]
                )
                db.add(auc)
                db.commit()
                db.refresh(auc)

                # Add sample bid
                bid = BidModel(
                    auction_id=auc.id,
                    bidder_id=shopkeeper.id,
                    bid_amount=a_data["current_bid"]
                )
                db.add(bid)
            db.commit()
            print("Successfully seeded salvage & recyclable auction catalog.")

    except Exception as e:
        print(f"Error seeding database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_db()
