import urllib.request
import urllib.error
import json

BASE_URL = "http://127.0.0.1:8000/api/v1"

def make_request(url, method="GET", data=None, headers=None):
    if headers is None:
        headers = {}
    headers["Content-Type"] = "application/json"
    
    encoded_data = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            json_body = json.loads(body)
        except:
            json_body = body
        return e.code, json_body

def run_tests():
    print("--- Phase 1 Backend API Validation ---")
    
    # 1. Health check / Root
    status, res = make_request("http://127.0.0.1:8000/")
    print(f"[1] Root Status: {status} => {res}")
    assert status == 200, "Root failed"
    
    # 2. Register Citizen User
    citizen_email = "test_citizen@disasterguard.org"
    register_payload = {
        "full_name": "John Citizen",
        "email": citizen_email,
        "password": "Password123!",
        "role": "CITIZEN"
    }
    status, res = make_request(f"{BASE_URL}/auth/register", method="POST", data=register_payload)
    print(f"[2] Register Citizen Status: {status} => Token length: {len(res.get('access_token', '')) if status==201 else res}")
    assert status in (201, 400), f"Unexpected register status: {status}"
    
    # 3. Duplicate Registration check
    status, res = make_request(f"{BASE_URL}/auth/register", method="POST", data=register_payload)
    print(f"[3] Duplicate Register Check: {status} => {res}")
    assert status == 400, "Duplicate registration should return 400"
    
    # 4. Login User
    login_payload = {
        "email": citizen_email,
        "password": "Password123!"
    }
    status, res = make_request(f"{BASE_URL}/auth/login", method="POST", data=login_payload)
    print(f"[4] Login Status: {status}")
    assert status == 200, "Login failed"
    token = res["access_token"]
    user_data = res["user"]
    print(f"    Logged in user: {user_data['full_name']} ({user_data['role']})")
    
    # 5. Incorrect Password Check
    bad_login = {
        "email": citizen_email,
        "password": "WrongPassword!"
    }
    status, res = make_request(f"{BASE_URL}/auth/login", method="POST", data=bad_login)
    print(f"[5] Bad Password Status: {status} => {res}")
    assert status == 401, "Bad password should return 401"
    
    # 6. Protected /auth/me with JWT Token
    headers = {"Authorization": f"Bearer {token}"}
    status, res = make_request(f"{BASE_URL}/auth/me", method="GET", headers=headers)
    print(f"[6] Protected /auth/me Status: {status} => User: {res.get('email')} ({res.get('role')})")
    assert status == 200 and res.get("email") == citizen_email, "Protected endpoint failed"
    
    # 7. Unauthenticated request without JWT
    status, res = make_request(f"{BASE_URL}/auth/me", method="GET")
    print(f"[7] Unauthenticated /auth/me Status: {status} => {res}")
    assert status == 401, "Unauthenticated request should return 401"
    
    # 8. Register Authority & Crew Users
    for role_name, email_prefix in [("AUTHORITY", "officer"), ("CREW", "crewlead")]:
        email = f"{email_prefix}@disasterguard.org"
        payload = {
            "full_name": f"{role_name.title()} User",
            "email": email,
            "password": "Password123!",
            "role": role_name
        }
        status, res = make_request(f"{BASE_URL}/auth/register", method="POST", data=payload)
        print(f"[8] Register {role_name} Status: {status}")

    print("\n[SUCCESS] ALL PHASE 1 BACKEND API TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    run_tests()
