import urllib.request
import urllib.error
import json
import uuid

BASE_URL = "http://127.0.0.1:8000/api/v1"

def make_json_request(url, method="GET", data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
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

def post_multipart(url, fields, file_field=None, filename=None, file_bytes=None, token=None):
    boundary = f"----WebKitFormBoundary{uuid.uuid4().hex}"
    headers = {"Content-Type": f"multipart/form-data; boundary={boundary}"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    body = []
    for k, v in fields.items():
        body.append(f"--{boundary}".encode("utf-8"))
        body.append(f'Content-Disposition: form-data; name="{k}"'.encode("utf-8"))
        body.append(b"")
        body.append(str(v).encode("utf-8"))

    if file_field and filename and file_bytes:
        body.append(f"--{boundary}".encode("utf-8"))
        body.append(f'Content-Disposition: form-data; name="{file_field}"; filename="{filename}"'.encode("utf-8"))
        body.append(b"Content-Type: image/jpeg")
        body.append(b"")
        body.append(file_bytes)

    body.append(f"--{boundary}--".encode("utf-8"))
    body.append(b"")
    payload = b"\r\n".join(body)

    req = urllib.request.Request(url, data=payload, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            resp_body = resp.read().decode("utf-8")
            return resp.status, json.loads(resp_body)
    except urllib.error.HTTPError as e:
        resp_body = e.read().decode("utf-8")
        try:
            json_body = json.loads(resp_body)
        except:
            json_body = resp_body
        return e.code, json_body

def run_tests():
    print("--- Phase 2 Backend API Validation ---")

    # 1. Login or Register Citizen
    email = "citizen_phase2@disasterguard.org"
    pwd = "Password123!"
    
    status, res = make_json_request(f"{BASE_URL}/auth/login", method="POST", data={"email": email, "password": pwd})
    if status != 200:
        status, res = make_json_request(
            f"{BASE_URL}/auth/register",
            method="POST",
            data={"full_name": "Phase2 Citizen", "email": email, "password": pwd, "role": "CITIZEN"}
        )
    
    assert status in (200, 201), f"Auth failed with status {status}"
    token = res["access_token"]
    print(f"[1] Citizen Authenticated. Token acquired.")

    # 2. Post Incident via Multipart Request (Flood)
    fields = {
        "hazard_type": "FLOOD",
        "description": "Severe flash flood covering main avenue near Sector 4.",
        "latitude": "6.9271",
        "longitude": "79.8612",
        "address_text": "Sector 4 Main Avenue"
    }
    dummy_img = b"\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00\x60\x00\x60\x00\x00\xFF\xD9"
    status, res = post_multipart(f"{BASE_URL}/incidents", fields, "file", "flood_photo.jpg", dummy_img, token)
    print(f"[2] Post Incident Status: {status} => Incident ID: {res.get('id')}, Status: {res.get('status')}")
    assert status == 201, f"Failed to report incident: {res}"
    inc_id = res["id"]
    assert res["status"] == "SUBMITTED", "Initial status must be SUBMITTED"
    assert len(res["media"]) > 0, "Media record must be created"

    # 3. Post Second Incident (Blocked Road)
    fields2 = {
        "hazard_type": "BLOCKED_ROAD",
        "description": "Landslide blocking dual carriageway.",
        "latitude": "6.9310",
        "longitude": "79.8650",
        "address_text": "Highway Junction 12"
    }
    status2, res2 = post_multipart(f"{BASE_URL}/incidents", fields2, token=token)
    print(f"[3] Post 2nd Incident Status: {status2} => Incident ID: {res2.get('id')}")
    assert status2 == 201

    # 4. Fetch My Incidents
    status, my_list = make_json_request(f"{BASE_URL}/incidents/my", method="GET", token=token)
    print(f"[4] Fetch My Incidents Status: {status} => Count: {len(my_list)}")
    assert status == 200 and len(my_list) >= 2

    # 5. Fetch Nearby Incidents
    status, nearby_list = make_json_request(
        f"{BASE_URL}/incidents/nearby?latitude=6.9271&longitude=79.8612&radius_km=10",
        method="GET",
        token=token
    )
    print(f"[5] Fetch Nearby Incidents Status: {status} => Count nearby: {len(nearby_list)}")
    assert status == 200 and len(nearby_list) >= 2

    # 6. Fetch Incident Details by ID
    status, detail = make_json_request(f"{BASE_URL}/incidents/{inc_id}", method="GET", token=token)
    print(f"[6] Incident Detail Status: {status} => Hazard: {detail.get('hazard_type')}, Status: {detail.get('status')}")
    assert status == 200 and detail["id"] == inc_id

    # 7. Unauthenticated request rejection
    status, res = make_json_request(f"{BASE_URL}/incidents/my", method="GET")
    print(f"[7] Unauthenticated request Status: {status} => {res}")
    assert status == 401

    print("\n[SUCCESS] ALL PHASE 2 BACKEND & DATABASE TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    run_tests()
