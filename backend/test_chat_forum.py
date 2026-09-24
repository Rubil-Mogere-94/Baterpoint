import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.database import get_db, engine, Base
from app.models import UserModel, ChatMessageModel
from app.auth_utils import get_password_hash
from datetime import datetime, timezone

# Use the same database as the app for chat/forum tests
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

def create_user_and_get_token(client, username, email, password="password123"):
    """Create a user directly in the DB and return auth header."""
    db = TestingSessionLocal()
    user = UserModel(username=username, email=email, hashed_password=get_password_hash(password))
    db.add(user)
    db.commit()
    db.refresh(user)
    db.close()
    
    response = client.post("/api/v1/token", data={"username": username, "password": password})
    assert response.status_code == 200, f"Login failed: {response.status_code} {response.text}"
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_get_user_by_email(client):
    headers = create_user_and_get_token(client, "user1", "user1@example.com")
    response = client.get("/api/v1/users/by-email/user1@example.com", headers=headers)
    assert response.status_code == 200
    assert response.json()["username"] == "user1"

def test_inbox_aggregation(client):
    headers1 = create_user_and_get_token(client, "user1", "user1@example.com")
    headers2 = create_user_and_get_token(client, "user2", "user2@example.com")
    
    db = TestingSessionLocal()
    u1 = db.query(UserModel).filter(UserModel.username == "user1").first()
    u2 = db.query(UserModel).filter(UserModel.username == "user2").first()
    
    msg1 = ChatMessageModel(sender_id=u1.id, recipient_id=u2.id, message_content="Hello u2", timestamp=datetime(2023, 1, 1))
    msg2 = ChatMessageModel(sender_id=u2.id, recipient_id=u1.id, message_content="Hi u1", timestamp=datetime(2023, 1, 2))
    db.add_all([msg1, msg2])
    db.commit()
    
    response = client.get("/api/v1/chat/inbox", headers=headers1)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["other_user_username"] == "user2"
    assert data[0]["last_message"] == "Hi u1"
    assert data[0]["unread_count"] == 1

def test_forum_messages(client):
    headers = create_user_and_get_token(client, "testuser", "test@example.com")
    db = TestingSessionLocal()
    u = db.query(UserModel).filter(UserModel.username == "testuser").first()
    
    msg1 = ChatMessageModel(sender_id=u.id, is_forum=True, forum_category="general", message_content="Forum post 1")
    msg2 = ChatMessageModel(sender_id=u.id, is_forum=True, forum_category="tips", message_content="Forum post 2")
    db.add_all([msg1, msg2])
    db.commit()
    
    response = client.get("/api/v1/forum/messages")
    assert response.status_code == 200
    assert len(response.json()) == 2
    
    response = client.get("/api/v1/forum/messages?category=tips")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["message_content"] == "Forum post 2"