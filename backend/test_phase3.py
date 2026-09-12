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

def run_phase3_tests():
    print("==================================================")
    print("         PHASE 3 END-TO-END VALIDATION            ")
    print("==================================================")

    # 1. Authenticate Citizen User
    citizen_email = "citizen_phase3@disasterguard.org"
    pwd = "Password123!"
    
    status, res = make_json_request(f"{BASE_URL}/auth/login", method="POST", data={"email": citizen_email, "password": pwd})
    if status != 200:
        status, res = make_json_request(
            f"{BASE_URL}/auth/register",
            method="POST",
            data={"full_name": "Phase3 Citizen", "email": citizen_email, "password": pwd, "role": "CITIZEN"}
        )
    assert status in (200, 201), f"Citizen auth failed: {res}"
    citizen_token = res["access_token"]
    print(f"[1] Citizen Authenticated. Token acquired.")

    # 2. Authenticate Authority User
    auth_email = "authority_officer@disasterguard.org"
    status, res = make_json_request(f"{BASE_URL}/auth/login", method="POST", data={"email": auth_email, "password": pwd})
    if status != 200:
        status, res = make_json_request(
            f"{BASE_URL}/auth/register",
            method="POST",
            data={"full_name": "Officer Sarah Connor", "email": auth_email, "password": pwd, "role": "AUTHORITY"}
        )
    assert status in (200, 201), f"Authority auth failed: {res}"
    authority_token = res["access_token"]
    print(f"[2] Authority Officer Authenticated. Token acquired.")

    # 3. Authenticate Crew User
    crew_email = "crew_lead@disasterguard.org"
    status, res = make_json_request(f"{BASE_URL}/auth/login", method="POST", data={"email": crew_email, "password": pwd})
    if status != 200:
        status, res = make_json_request(
            f"{BASE_URL}/auth/register",
            method="POST",
            data={"full_name": "Crew Lead Mark Miller", "email": crew_email, "password": pwd, "role": "CREW"}
        )
    assert status in (200, 201)
    crew_id = res["user"]["id"]
    print(f"[3] Crew Lead Authenticated. ID: {crew_id}")

    # 4. Citizen Submits Flood Incident with Photo
    fields = {
        "hazard_type": "FLOOD",
        "description": "Severe flash flood submerging Sector 4 avenue. People trapped near high water.",
        "latitude": "6.9271",
        "longitude": "79.8612",
        "address_text": "Sector 4 Main Avenue"
    }
    dummy_img = b"\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00\x60\x00\x60\x00\x00\xFF\xD9"
    status, inc_res = post_multipart(f"{BASE_URL}/incidents", fields, "file", "flood_photo.jpg", dummy_img, citizen_token)
    print(f"[4] Incident Submitted. Status Code: {status} => ID: {inc_res.get('id')}, Status: {inc_res.get('status')}")
    assert status == 201
    inc_id = inc_res["id"]
    assert inc_res["status"] == "VERIFICATION_REQUIRED", f"Status should be VERIFICATION_REQUIRED, got: {inc_res.get('status')}"

    # 5. Verify RBAC Security: Citizen CANNOT access Authority Endpoints
    status, res = make_json_request(f"{BASE_URL}/authority/dashboard", method="GET", token=citizen_token)
    print(f"[5] RBAC Security Check (Citizen calling Authority API): Status: {status}")
    assert status == 403, "Citizen must be forbidden from calling Authority APIs"

    # 6. Authority Views Dashboard
    status, dash = make_json_request(f"{BASE_URL}/authority/dashboard", method="GET", token=authority_token)
    print(f"[6] Authority Dashboard Metrics: Status {status} => {dash['metrics']}")
    assert status == 200
    assert dash["metrics"]["total_incidents"] >= 1

    # 7. Authority Inspects Detailed Incident Review (Verification + AI + Risk Assessment)
    status, detail = make_json_request(f"{BASE_URL}/authority/incidents/{inc_id}", method="GET", token=authority_token)
    print(f"[7] Detailed Incident Review Status: {status}")
    assert status == 200
    ver = detail["verification"]
    assert ver is not None, "Verification data must exist"
    print(f"    - Risk Level: {ver['risk_level']}, Score: {ver['risk_score']}/100")
    print(f"    - Weather Support: {ver['weather_support']}, Summary: {ver['weather_summary']}")
    print(f"    - AI Detected Hazard: {ver['ai_detected_hazard']}, Confidence: {ver['ai_confidence']}")
    print(f"    - Evidence Summary:\n{ver['evidence_summary']}")

    # 8. Authority Confirms Incident
    status, conf_res = make_json_request(f"{BASE_URL}/authority/incidents/{inc_id}/confirm", method="POST", token=authority_token)
    print(f"[8] Authority Confirm Incident Status: {status} => {conf_res}")
    assert status == 200 and conf_res["status"] == "VERIFIED"

    # 9. Authority Broadcasts Affected-Area Alert
    alert_payload = {
        "incident_id": inc_id,
        "title": "EMERGENCY FLASH FLOOD WARNING",
        "message": "High water levels detected in Sector 4 Main Avenue. Evacuate low ground immediately.",
        "radius_km": 10.0
    }
    status, alert_res = make_json_request(f"{BASE_URL}/authority/alerts", method="POST", data=alert_payload, token=authority_token)
    print(f"[9] Created Affected-Area Alert Status: {status} => Alert ID: {alert_res.get('id')}")
    assert status == 201

    # 10. Citizen Receives Area Alert
    status, citizen_alerts = make_json_request(f"{BASE_URL}/alerts/relevant?latitude=6.9271&longitude=79.8612", method="GET", token=citizen_token)
    print(f"[10] Citizen Relevant Alerts Status: {status} => Count: {len(citizen_alerts)}")
    assert status == 200 and len(citizen_alerts) >= 1
    assert citizen_alerts[0]["title"] == "EMERGENCY FLASH FLOOD WARNING"

    # 11. Authority Generates Council Ticket
    ticket_payload = {
        "incident_id": inc_id,
        "priority": "CRITICAL",
        "description": "Urgent drainage pumping and road blockade deployment."
    }
    status, ticket_res = make_json_request(f"{BASE_URL}/authority/tickets", method="POST", data=ticket_payload, token=authority_token)
    print(f"[11] Created Council Ticket Status: {status} => Ticket Number: {ticket_res.get('ticket_number')}")
    assert status == 201
    ticket_id = ticket_res["id"]

    # 12. Authority Fetches Available Crews
    status, crews = make_json_request(f"{BASE_URL}/authority/crews", method="GET", token=authority_token)
    print(f"[12] Fetch Available Crews Status: {status} => Crews Count: {len(crews)}")
    assert status == 200 and len(crews) >= 1

    # 13. Authority Dispatches Emergency Crew
    dispatch_payload = {
        "incident_id": inc_id,
        "ticket_id": ticket_id,
        "assigned_crew_id": crew_id,
        "instructions": "Proceed with heavy drainage vehicles to Sector 4 Main Avenue."
    }
    status, dispatch_res = make_json_request(f"{BASE_URL}/authority/dispatch", method="POST", data=dispatch_payload, token=authority_token)
    print(f"[13] Dispatch Crew Status: {status} => Assignment ID: {dispatch_res.get('id')}")
    assert status == 201

    # 14. Verify Final Incident Status is DISPATCHED
    status, final_inc = make_json_request(f"{BASE_URL}/incidents/{inc_id}", method="GET", token=citizen_token)
    print(f"[14] Final Incident Status Check: {final_inc['status']}")
    assert final_inc["status"] == "DISPATCHED"

    print("\n==================================================")
    print("[SUCCESS] ALL PHASE 3 BACKEND TESTS PASSED 100%!   ")
    print("==================================================")

if __name__ == "__main__":
    run_phase3_tests()
