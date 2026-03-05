import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app, limiter
from app.database import get_db
from app.models import Base, UserModel, ChatMessageModel
from datetime import datetime

# Disable rate limiter for tests
limiter.enabled = False

# Setup test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_chat.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield

def get_auth_header(username="testuser", email="test@example.com"):
    # Register and login to get token
    client.post("/register/", json={"username": username, "email": email, "password": "password123"})
    response = client.post("/token", data={"username": username, "password": "password123"})
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_get_user_by_email():
    client.post("/register/", json={"username": "user1", "email": "user1@example.com", "password": "password123"})
    response = client.get("/users/by-email/user1@example.com")
    assert response.status_code == 200
    assert response.json()["username"] == "user1"

def test_inbox_aggregation():
    # Create two users
    headers1 = get_auth_header("user1", "user1@example.com")
    headers2 = get_auth_header("user2", "user2@example.com")
    
    db = TestingSessionLocal()
    u1 = db.query(UserModel).filter(UserModel.username == "user1").first()
    u2 = db.query(UserModel).filter(UserModel.username == "user2").first()
    
    # Send some messages
    msg1 = ChatMessageModel(sender_id=u1.id, recipient_id=u2.id, message_content="Hello u2", timestamp=datetime(2023, 1, 1))
    msg2 = ChatMessageModel(sender_id=u2.id, recipient_id=u1.id, message_content="Hi u1", timestamp=datetime(2023, 1, 2))
    db.add_all([msg1, msg2])
    db.commit()
    
    response = client.get("/chat/inbox", headers=headers1)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["other_user_username"] == "user2"
    assert data[0]["last_message"] == "Hi u1"
    assert data[0]["unread_count"] == 1

def test_forum_messages():
    headers = get_auth_header()
    db = TestingSessionLocal()
    u = db.query(UserModel).filter(UserModel.username == "testuser").first()
    
    msg1 = ChatMessageModel(sender_id=u.id, is_forum=True, forum_category="general", message_content="Forum post 1")
    msg2 = ChatMessageModel(sender_id=u.id, is_forum=True, forum_category="tips", message_content="Forum post 2")
    db.add_all([msg1, msg2])
    db.commit()
    
    # Get all forum messages
    response = client.get("/forum/messages")
    assert response.status_code == 200
    assert len(response.json()) == 2
    
    # Get specific category
    response = client.get("/forum/messages?category=tips")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["message_content"] == "Forum post 2"
