import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.database import get_db
from app.models import Base, UserModel, ListingModel
import os

# Use SQLite for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            pass
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()

def test_register_user(client):
    response = client.post("/api/v1/register/", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123"
    })
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"

def test_login_for_access_token(client):
    # First register
    client.post("/api/v1/register/", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123"
    })
    
    # Then login
    response = client.post("/api/v1/token", data={
        "username": "testuser",
        "password": "password123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_get_all_users_as_admin(client, db):
    # Create an admin user
    admin = UserModel(username="admin", email="admin@example.com", hashed_password="hashed", role="admin")
    db.add(admin)
    db.commit()

    # Login and get token (we'll manually override for simplicity in this specific test if needed, 
    # but let's try the proper way)
    
    # Actually, let's use dependency override for current_user to simplify admin testing
    from app.main import get_current_user
    app.dependency_overrides[get_current_user] = lambda: admin
    
    response = client.get("/api/v1/admin/users")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["username"] == "admin"

def test_get_listings_empty(client):
    response = client.get("/api/v1/listings/")
    assert response.status_code == 200
    assert response.json() == []

def test_create_listing_unauthenticated(client):
    # Should fail without token/override
    response = client.post("/api/v1/listings/", data={
        "title": "Test Listing",
        "category": "Electronics",
        "tradeType": "Trade"
    })
    assert response.status_code == 401

def test_pagination(client, db):
    # Create 25 listings
    user = UserModel(username="testuser2", email="test2@example.com", hashed_password="hashed")
    db.add(user)
    db.commit()
    for i in range(25):
        listing = ListingModel(title=f"Listing {i}", category="Test", trade_type="Sale", user_id=user.id)
        db.add(listing)
    db.commit()

    # Test limit=20 (default or explicit)
    response = client.get("/api/v1/listings/")
    assert response.status_code == 200
    assert len(response.json()) == 20

    # Test limit=10
    response = client.get("/api/v1/listings/?limit=10")
    assert response.status_code == 200
    assert len(response.json()) == 10

    # Test skip=20, expecting 5
    response = client.get("/api/v1/listings/?skip=20&limit=10")
    assert response.status_code == 200
    assert len(response.json()) == 5

def test_favorites(client, db):
    # Create user and listing
    user = UserModel(username="favuser", email="fav@example.com", hashed_password="hashed")
    db.add(user)
    db.commit()
    listing = ListingModel(title="Fav Listing", category="Test", trade_type="Sale", user_id=user.id)
    db.add(listing)
    db.commit()

    from app.main import get_current_user
    app.dependency_overrides[get_current_user] = lambda: user

    # Get empty favorites
    response = client.get("/api/v1/users/me/favorites")
    assert response.status_code == 200
    assert response.json() == []

    # Add favorite
    response = client.post(f"/api/v1/listings/{listing.id}/favorite")
    assert response.status_code == 200
    assert response.json()["status"] == "favorited"

    # Get favorites again
    response = client.get("/api/v1/users/me/favorites")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == listing.id

    # Remove favorite
    response = client.post(f"/api/v1/listings/{listing.id}/favorite")
    assert response.status_code == 200
    assert response.json()["status"] == "unfavorited"

    # Get favorites again
    response = client.get("/api/v1/users/me/favorites")
    assert response.status_code == 200
    assert response.json() == []
    
    app.dependency_overrides.pop(get_current_user, None)

def test_offers(client, db):
    # Setup users and listing
    seller = UserModel(username="seller", email="seller@example.com", hashed_password="hashed")
    buyer = UserModel(username="buyer", email="buyer@example.com", hashed_password="hashed")
    db.add_all([seller, buyer])
    db.commit()
    listing = ListingModel(title="Selling Object", category="Test", trade_type="Both", user_id=seller.id, view_count=0)
    db.add(listing)
    db.commit()

    from app.main import get_current_user

    # Test buyer making an offer
    app.dependency_overrides[get_current_user] = lambda: buyer
    response = client.post(f"/api/v1/listings/{listing.id}/offers", json={
        "offered_price": 50.0,
        "offered_item": "Trade Item"
    })
    assert response.status_code == 200
    offer_id = response.json()["id"]
    assert response.json()["status"] == "pending"

    # Test making offer on own listing fails
    app.dependency_overrides[get_current_user] = lambda: seller
    response = client.post(f"/api/v1/listings/{listing.id}/offers", json={
        "offered_price": 50.0
    })
    assert response.status_code == 400

    # Test buyer viewing their offers
    app.dependency_overrides[get_current_user] = lambda: buyer
    response = client.get("/api/v1/users/me/offers")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["id"] == offer_id

    # Test seller viewing received offers
    app.dependency_overrides[get_current_user] = lambda: seller
    response = client.get("/api/v1/users/me/received_offers")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["id"] == offer_id

    # Test buyer trying to accept their own offer (should fail)
    app.dependency_overrides[get_current_user] = lambda: buyer
    response = client.put(f"/api/v1/offers/{offer_id}", json={
        "status": "accepted"
    })
    assert response.status_code == 403

    # Test seller accepting the offer
    app.dependency_overrides[get_current_user] = lambda: seller
    response = client.put(f"/api/v1/offers/{offer_id}", json={
        "status": "accepted"
    })
    assert response.status_code == 200
    assert response.json()["status"] == "accepted"

    app.dependency_overrides.pop(get_current_user, None)

def test_recommendations(client, db):
    user = UserModel(username="recuser", email="rec@example.com", hashed_password="hashed")
    other_user = UserModel(username="other", email="other@example.com", hashed_password="hashed")
    db.add_all([user, other_user])
    db.commit()
    
    listing = ListingModel(title="Rec Listing", category="Tech", trade_type="Sale", user_id=other_user.id, view_count=100)
    db.add(listing)
    db.commit()

    from app.main import get_current_user
    app.dependency_overrides[get_current_user] = lambda: user
    
    response = client.get("/api/v1/listings/recommendations")
    assert response.status_code == 200
    assert len(response.json()) > 0
    assert response.json()[0]["id"] == listing.id

def test_loyalty_shop(client, db):
    user = UserModel(username="shopuser", email="shop@example.com", hashed_password="hashed", loyalty_points=1000)
    db.add(user)
    db.commit()

    from app.main import get_current_user
    app.dependency_overrides[get_current_user] = lambda: user

    # Get rewards
    response = client.get("/api/v1/rewards/")
    assert response.status_code == 200
    rewards = response.json()
    assert len(rewards) > 0
    premium_reward = next(r for r in rewards if "Premium" in r["title"])

    # Redeem
    response = client.post(f"/api/v1/rewards/{premium_reward['id']}/redeem")
    assert response.status_code == 200
    assert response.json()["reward"]["title"] == premium_reward["title"]

    # Verify points deducted
    db.refresh(user)
    assert user.loyalty_points == 1000 - premium_reward["points_cost"]
    assert user.subscription_status == "premium"

def test_deal_of_the_hour(client, db):
    user = UserModel(username="seller2", email="seller2@example.com", hashed_password="hashed")
    db.add(user)
    db.commit()
    listing = ListingModel(title="Deal Item", category="Tech", price=100.0, user_id=user.id, trade_type="Sale")
    db.add(listing)
    db.commit()

    response = client.get("/api/v1/listings/deal-of-the-hour")
    assert response.status_code == 200
    assert "discount_percentage" in response.json()
    assert response.json()["listing"]["id"] == listing.id

