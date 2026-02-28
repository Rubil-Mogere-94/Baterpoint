import httpx

def test_root():
    try:
        response = httpx.get("http://localhost:8000/")
        print(f"Root Status: {response.status_code}")
        print(f"Root Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

def test_register():
    try:
        response = httpx.post("http://localhost:8000/register/", json={
            "username": "diagnose_user",
            "email": "diagnose@example.com",
            "password": "password123"
        })
        print(f"Register Status: {response.status_code}")
        print(f"Register Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_root()
    test_register()
