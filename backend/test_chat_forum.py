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

from jose import jwt
from app.dependencies import SECRET_KEY, ALGORITHM

def create_user_and_get_token(client, username, email, password="password123"):
    """Create a user directly in the DB and return auth header."""
    db = TestingSessionLocal()
    user = UserModel(username=username, email=email, hashed_password=get_password_hash(password))
    db.add(user)
    db.commit()
    db.refresh(user)
    db.close()
    
    token = jwt.encode({"sub": username}, SECRET_KEY, algorithm=ALGORITHM)
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

def test_shopkeeper_desk_and_private_dm_restriction(client):
    headers_buyer = create_user_and_get_token(client, "buyer1", "buyer1@example.com")
    headers_supplier = create_user_and_get_token(client, "supplier1", "supplier1@example.com")

    db = TestingSessionLocal()
    buyer = db.query(UserModel).filter(UserModel.username == "buyer1").first()
    supplier = db.query(UserModel).filter(UserModel.username == "supplier1").first()

    # 1. Direct private DM between buyer and supplier should be blocked (403)
    resp = client.post("/api/v1/chat/send", json={
        "recipient_id": supplier.id,
        "message_content": "Can I pay you cash offline?"
    }, headers=headers_buyer)
    assert resp.status_code == 403
    assert "Direct private messaging" in (resp.json().get("detail") or resp.json().get("message", ""))

    # 2. Get Shopkeeper desk info
    sk_resp = client.get("/api/v1/chat/shopkeeper", headers=headers_buyer)
    assert sk_resp.status_code == 200
    sk_data = sk_resp.json()
    assert sk_data["username"] == "Shopkeeper"
    assert sk_data["role"] == "official"

    # 3. Messaging the Shopkeeper is permitted
    send_resp = client.post("/api/v1/chat/send", json={
        "recipient_id": sk_data["id"],
        "message_content": "Habari Shopkeeper, how do I verify a trade?"
    }, headers=headers_buyer)
    assert send_resp.status_code == 200

    # 4. Check conversation with Shopkeeper
    conv_resp = client.get(f"/api/v1/chat/conversation/{sk_data['id']}", headers=headers_buyer)
    assert conv_resp.status_code == 200
    conv_data = conv_resp.json()
    assert len(conv_data) >= 1

def test_listing_public_comments(client):
    headers = create_user_and_get_token(client, "buyer_commenter", "commenter@example.com")
    db = TestingSessionLocal()
    u = db.query(UserModel).filter(UserModel.username == "buyer_commenter").first()
    
    from app.models import ListingModel
    listing = ListingModel(
        title="Sample Item for Q&A",
        description="Public discussion test",
        price=50.0,
        trade_type="Sale",
        category="General",
        image_url="http://example.com/img.png",
        user_id=u.id
    )
    db.add(listing)
    db.commit()
    db.refresh(listing)

    # 1. Post a public comment
    post_res = client.post(f"/api/v1/listings/{listing.id}/comments", json={
        "message_content": "Is this product in new condition?"
    }, headers=headers)
    assert post_res.status_code == 200
    assert post_res.json()["message_content"] == "Is this product in new condition?"
    assert post_res.json()["sender_username"] == "buyer_commenter"

    # 2. Read public comments
    get_res = client.get(f"/api/v1/listings/{listing.id}/comments")
    assert get_res.status_code == 200
    comments = get_res.json()
    assert len(comments) == 1
    assert comments[0]["message_content"] == "Is this product in new condition?"