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
