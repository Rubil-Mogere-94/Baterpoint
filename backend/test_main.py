import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from main import app, get_db, Base, UserModel, ListingModel
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
    response = client.post("/register/", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123"
    })
    assert response.status_code == 200
    assert response.json()["username"] == "testuser"

def test_login_for_access_token(client):
    # First register
    client.post("/register/", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123"
    })
    
    # Then login
    response = client.post("/token", data={
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
    from main import get_current_user
    app.dependency_overrides[get_current_user] = lambda: admin
    
    response = client.get("/admin/users")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["username"] == "admin"

def test_get_listings_empty(client):
    response = client.get("/listings/")
    assert response.status_code == 200
    assert response.json() == []

def test_create_listing_unauthenticated(client):
    # Should fail without token/override
    response = client.post("/listings/", data={
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
    response = client.get("/listings/")
    assert response.status_code == 200
    assert len(response.json()) == 20

    # Test limit=10
    response = client.get("/listings/?limit=10")
    assert response.status_code == 200
    assert len(response.json()) == 10

    # Test skip=20, expecting 5
    response = client.get("/listings/?skip=20&limit=10")
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

    from main import get_current_user
    app.dependency_overrides[get_current_user] = lambda: user

    # Get empty favorites
    response = client.get("/users/me/favorites")
    assert response.status_code == 200
    assert response.json() == []

    # Add favorite
    response = client.post(f"/listings/{listing.id}/favorite")
    assert response.status_code == 200
    assert response.json()["status"] == "favorited"

    # Get favorites again
    response = client.get("/users/me/favorites")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == listing.id

    # Remove favorite
    response = client.post(f"/listings/{listing.id}/favorite")
    assert response.status_code == 200
    assert response.json()["status"] == "unfavorited"

    # Get favorites again
    response = client.get("/users/me/favorites")
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

    from main import get_current_user

    # Test buyer making an offer
    app.dependency_overrides[get_current_user] = lambda: buyer
    response = client.post(f"/listings/{listing.id}/offers", json={
        "offered_price": 50.0,
        "offered_item": "Trade Item"
    })
    assert response.status_code == 200
    offer_id = response.json()["id"]
    assert response.json()["status"] == "pending"

    # Test making offer on own listing fails
    app.dependency_overrides[get_current_user] = lambda: seller
    response = client.post(f"/listings/{listing.id}/offers", json={
        "offered_price": 50.0
    })
    assert response.status_code == 400

    # Test buyer viewing their offers
    app.dependency_overrides[get_current_user] = lambda: buyer
    response = client.get("/users/me/offers")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["id"] == offer_id

    # Test seller viewing received offers
    app.dependency_overrides[get_current_user] = lambda: seller
    response = client.get("/users/me/received_offers")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["id"] == offer_id

    # Test buyer trying to accept their own offer (should fail)
    app.dependency_overrides[get_current_user] = lambda: buyer
    response = client.put(f"/offers/{offer_id}", json={
        "status": "accepted"
    })
    assert response.status_code == 403

    # Test seller accepting the offer
    app.dependency_overrides[get_current_user] = lambda: seller
    response = client.put(f"/offers/{offer_id}", json={
        "status": "accepted"
    })
    assert response.status_code == 200
    assert response.json()["status"] == "accepted"

    app.dependency_overrides.pop(get_current_user, None)

