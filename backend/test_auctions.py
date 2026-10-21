import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from jose import jwt
from datetime import datetime, timezone, timedelta

from app.main import app
from app.database import get_db, Base
from app.models import UserModel, AuctionModel, BidModel
from app.auth_utils import get_password_hash
from app.dependencies import SECRET_KEY, ALGORITHM

SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
test_engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    yield

@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c

def create_user_and_token(username: str, email: str):
    db = TestingSessionLocal()
    user = UserModel(username=username, email=email, hashed_password=get_password_hash("password123"))
    db.add(user)
    db.commit()
    db.refresh(user)
    db.close()
    token = jwt.encode({"sub": username}, SECRET_KEY, algorithm=ALGORITHM)
    return user, {"Authorization": f"Bearer {token}"}

def test_auction_flow(client):
    seller, seller_headers = create_user_and_token("salvage_seller", "seller@example.com")
    bidder, bidder_headers = create_user_and_token("upcycle_bidder", "bidder@example.com")

    # 1. Create Auction
    create_payload = {
        "title": "Broken iPad Mini 5 (Motherboard Works)",
        "description": "Cracked screen and dented case, but motherboards and camera sensors are completely intact. Ideal for salvage parts.",
        "image_url": "https://example.com/ipad.png",
        "condition_type": "damaged_repair",
        "damage_details": "Glass shattered; display digitizer unresponsive.",
        "recyclable_materials": ["aluminum", "lithium battery", "copper"],
        "starting_bid": 1500.0,
        "min_increment": 100.0,
        "duration_hours": 48
    }
    create_resp = client.post("/api/v1/auctions/", json=create_payload, headers=seller_headers)
    assert create_resp.status_code == 201
    auction_data = create_resp.json()
    auction_id = auction_data["id"]
    assert auction_data["title"] == create_payload["title"]
    assert auction_data["current_bid"] == 1500.0
    assert auction_data["seller_username"] == "salvage_seller"

    # 2. Get list of auctions
    list_resp = client.get("/api/v1/auctions/")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1

    # 3. Seller cannot bid on own auction
    self_bid = client.post(f"/api/v1/auctions/{auction_id}/bid", json={"bid_amount": 1600.0}, headers=seller_headers)
    assert self_bid.status_code == 400
    assert "Sellers cannot bid" in self_bid.json().get("detail", self_bid.json().get("message", ""))

    # 4. Bid too low (below starting bid)
    low_bid = client.post(f"/api/v1/auctions/{auction_id}/bid", json={"bid_amount": 1400.0}, headers=bidder_headers)
    assert low_bid.status_code == 400
    assert "Bid too low" in low_bid.json().get("detail", low_bid.json().get("message", ""))

    # 5. Place valid first bid
    valid_bid = client.post(f"/api/v1/auctions/{auction_id}/bid", json={"bid_amount": 1600.0}, headers=bidder_headers)
    assert valid_bid.status_code == 200
    updated = valid_bid.json()
    assert updated["current_bid"] == 1600.0
    assert updated["highest_bidder_username"] == "upcycle_bidder"
    assert updated["total_bids"] == 1

    # 6. Second bidder tries increment that is too low (< 1600 + 100 = 1700)
    _, bidder2_headers = create_user_and_token("second_bidder", "bidder2@example.com")
    low_increment = client.post(f"/api/v1/auctions/{auction_id}/bid", json={"bid_amount": 1650.0}, headers=bidder2_headers)
    assert low_increment.status_code == 400

    # 7. Valid higher bid
    high_bid = client.post(f"/api/v1/auctions/{auction_id}/bid", json={"bid_amount": 1700.0}, headers=bidder2_headers)
    assert high_bid.status_code == 200
    assert high_bid.json()["current_bid"] == 1700.0
    assert high_bid.json()["highest_bidder_username"] == "second_bidder"
    assert high_bid.json()["total_bids"] == 2

    # 6. Check auction stats
    stats_resp = client.get("/api/v1/auctions/stats/summary")
    assert stats_resp.status_code == 200
    stats = stats_resp.json()
    assert stats["total_active_auctions"] == 1
    assert stats["total_bids_placed"] == 2
    assert stats["salvage_items_diverted"] == 1
