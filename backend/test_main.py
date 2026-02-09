import pytest
from fastapi.testclient import TestClient
from fastapi import HTTPException
from unittest.mock import MagicMock, patch
from main import app, get_db_connection, get_current_user, User # Assuming User model is also in main

# Mock database connection
@pytest.fixture(name="db_connection")
def mock_db_connection():
    with patch("main.psycopg2.connect") as mock_connect:
        mock_conn = MagicMock()
        mock_cur = MagicMock()
        mock_conn.cursor.return_value = mock_cur
        mock_connect.return_value = mock_conn
        yield mock_conn

# Mock get_current_user dependency for testing
def override_get_current_user_admin():
    return User(id=1, email="admin@example.com", username="adminuser", role="admin")

def override_get_current_user_normal():
    return User(id=2, email="user@example.com", username="normaluser", role="user")

def override_get_current_user_unauthenticated():
    raise HTTPException(status_code=401, detail="Not authenticated")

client = TestClient(app)

# Test GET /admin/users
def test_get_all_users_as_admin(db_connection):
    app.dependency_overrides[get_current_user] = override_get_current_user_admin
    mock_cur = db_connection.cursor.return_value
    mock_cur.fetchall.return_value = [
        (1, "adminuser", "admin@example.com", "admin"),
        (2, "normaluser", "user@example.com", "user")
    ]
    response = client.get("/admin/users")
    assert response.status_code == 200
    assert response.json() == [
        {"id": 1, "username": "adminuser", "email": "admin@example.com", "role": "admin", "subscription_status": "basic"},
        {"id": 2, "username": "normaluser", "email": "user@example.com", "role": "user", "subscription_status": "basic"}
    ]

def test_get_all_users_as_normal_user(db_connection):
    app.dependency_overrides[get_current_user] = override_get_current_user_normal
    response = client.get("/admin/users")
    assert response.status_code == 403
    assert response.json() == {"detail": "Not an admin user"}

def test_get_all_users_unauthenticated(db_connection):
    app.dependency_overrides[get_current_user] = override_get_current_user_unauthenticated
    response = client.get("/admin/users")
    assert response.status_code == 401
    assert response.json() == {"detail": "Not authenticated"}

# Test PUT /admin/users/{user_id}/role
def test_update_user_role_as_admin(db_connection):
    app.dependency_overrides[get_current_user] = override_get_current_user_admin
    mock_cur = db_connection.cursor.return_value
    mock_cur.fetchone.return_value = (2, "normaluser", "user@example.com", "admin") # User after update
    response = client.put("/admin/users/2/role", json={"role": "admin"})
    assert response.status_code == 200
    assert response.json() == {"id": 2, "username": "normaluser", "email": "user@example.com", "role": "admin", "subscription_status": "basic"} # Assuming default subscription

def test_update_user_role_as_normal_user(db_connection):
    app.dependency_overrides[get_current_user] = override_get_current_user_normal
    response = client.put("/admin/users/2/role", json={"role": "admin"})
    assert response.status_code == 403
    assert response.json() == {"detail": "Not an admin user"}

# Test PUT /admin/users/{user_id}/subscription
def test_update_user_subscription_as_admin(db_connection):
    app.dependency_overrides[get_current_user] = override_get_current_user_admin
    mock_cur = db_connection.cursor.return_value
    # Mock behavior for checking column existence
    mock_cur.fetchone.side_effect = [None, (2, "normaluser", "user@example.com", "user", "premium")] # Column doesn't exist, then user found and updated
    response = client.put("/admin/users/2/subscription", json={"subscription_status": "premium"})
    assert response.status_code == 200
    assert response.json() == {"id": 2, "username": "normaluser", "email": "user@example.com", "role": "user", "subscription_status": "premium"}

def test_update_user_subscription_as_normal_user(db_connection):
    app.dependency_overrides[get_current_user] = override_get_current_user_normal
    response = client.put("/admin/users/2/subscription", json={"subscription_status": "premium"})
    assert response.status_code == 403
    assert response.json() == {"detail": "Not an admin user"}

# Clean up overrides after tests
@pytest.fixture(autouse=True)
def run_around_tests():
    yield
    app.dependency_overrides = {}
