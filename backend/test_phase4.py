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
        if v is not None:
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

def run_phase4_tests():
    print("==================================================")
    print("         PHASE 4 END-TO-END VALIDATION            ")
    print("==================================================")

    pwd = "Password123!"
    dummy_img = b"\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00\x60\x00\x60\x00\x00\xFF\xD9"

    # 1. Citizen Authentication
    citizen_email = "citizen_p4@disasterguard.org"
    status, res = make_json_request(f"{BASE_URL}/auth/login", method="POST", data={"email": citizen_email, "password": pwd})
    if status != 200:
        status, res = make_json_request(
            f"{BASE_URL}/auth/register",
            method="POST",
            data={"full_name": "Phase4 Citizen", "email": citizen_email, "password": pwd, "role": "CITIZEN"}
        )
    assert status in (200, 201), f"Citizen auth failed: {res}"
    citizen_token = res["access_token"]
    print("[1] Citizen Authenticated.")

    # 2. Authority Authentication
    auth_email = "authority_p4@disasterguard.org"
    status, res = make_json_request(f"{BASE_URL}/auth/login", method="POST", data={"email": auth_email, "password": pwd})
    if status != 200:
        status, res = make_json_request(
            f"{BASE_URL}/auth/register",
            method="POST",
            data={"full_name": "Officer Alex Mercer", "email": auth_email, "password": pwd, "role": "AUTHORITY"}
        )
    assert status in (200, 201), f"Authority auth failed: {res}"
    authority_token = res["access_token"]
    print("[2] Authority Officer Authenticated.")

    # 3. Crew Authentication
    crew_email = "crew_p4@disasterguard.org"
    status, res = make_json_request(f"{BASE_URL}/auth/login", method="POST", data={"email": crew_email, "password": pwd})
    if status != 200:
        status, res = make_json_request(
            f"{BASE_URL}/auth/register",
            method="POST",
            data={"full_name": "Crew Lead David Vance", "email": crew_email, "password": pwd, "role": "CREW"}
        )
    assert status in (200, 201), f"Crew auth failed: {res}"
    crew_token = res["access_token"]
    crew_id = res["user"]["id"]
    print(f"[3] Crew Lead Authenticated (ID: {crew_id}).")

    # 4. Citizen Submits Fallen Tree Incident
    fields = {
        "hazard_type": "FALLEN_TREE",
        "description": "Large oak tree collapsed blocking dual carriageway. Power lines down.",
        "latitude": "6.9150",
        "longitude": "79.8580",
        "address_text": "High Street Junction"
    }
    status, inc_res = post_multipart(f"{BASE_URL}/incidents", fields, "file", "fallen_tree.jpg", dummy_img, citizen_token)
    assert status == 201, f"Status failed: {status}, response: {inc_res}"
    inc_id = inc_res["id"]
    print(f"[4] Incident Submitted => ID: {inc_id}, Status: {inc_res['status']}")

    # 5. Authority Confirms Incident
    status, conf = make_json_request(f"{BASE_URL}/authority/incidents/{inc_id}/confirm", method="POST", token=authority_token)
    assert status == 200 and conf["status"] == "VERIFIED"
    print(f"[5] Authority Confirmed Incident => Status: VERIFIED")

    # 6. Authority Creates Council Ticket
    ticket_payload = {"incident_id": inc_id, "priority": "CRITICAL", "description": "Clear dual carriageway fallen tree."}
    status, ticket_res = make_json_request(f"{BASE_URL}/authority/tickets", method="POST", data=ticket_payload, token=authority_token)
    assert status == 201
    ticket_id = ticket_res["id"]
    print(f"[6] Council Ticket Created => Ticket #{ticket_res['ticket_number']}")

    # 7. Authority Dispatches Crew
    dispatch_payload = {
        "incident_id": inc_id,
        "ticket_id": ticket_id,
        "assigned_crew_id": crew_id,
        "instructions": "Bring heavy chain-saws and cranes to clear tree debris safely."
    }
    status, dispatch_res = make_json_request(f"{BASE_URL}/authority/dispatch", method="POST", data=dispatch_payload, token=authority_token)
    assert status == 201
    assignment_id = dispatch_res["id"]
    print(f"[7] Crew Dispatched => Assignment ID: {assignment_id}")

    # 8. Crew Dashboard & Assignments Fetch
    status, dash = make_json_request(f"{BASE_URL}/crew/dashboard", method="GET", token=crew_token)
    assert status == 200 and dash["new_assignments_count"] >= 1
    print(f"[8] Crew Dashboard Loaded => New Assignments: {dash['new_assignments_count']}")

    status, my_jobs = make_json_request(f"{BASE_URL}/crew/assignments", method="GET", token=crew_token)
    assert status == 200 and len(my_jobs) >= 1
    target_job = [j for j in my_jobs if j["id"] == assignment_id][0]
    assert target_job["status"] == "ASSIGNED"
    print(f"[9] Crew fetched assignments => Found assignment #{assignment_id} (Status: ASSIGNED)")

    # 9. Crew Accepts Job
    status, accept_res = make_json_request(f"{BASE_URL}/crew/assignments/{assignment_id}/accept", method="POST", token=crew_token)
    assert status == 200 and accept_res["status"] == "ACCEPTED"
    print(f"[10] Crew Accepted Job => Status: ACCEPTED")

    # 10. Crew Starts Work
    status, start_res = make_json_request(f"{BASE_URL}/crew/assignments/{assignment_id}/start", method="POST", token=crew_token)
    assert status == 200 and start_res["status"] == "IN_PROGRESS"
    assert start_res["incident"]["status"] == "IN_PROGRESS"
    print(f"[11] Crew Started Work => Assignment: IN_PROGRESS, Incident: IN_PROGRESS")

    # 11. Crew Uploads Progress Update with Photo
    prog_fields = {"note": "Heavy crane setup completed. Sawing primary tree trunk."}
    status, prog_res = post_multipart(f"{BASE_URL}/crew/assignments/{assignment_id}/progress", prog_fields, "file", "progress_photo.jpg", dummy_img, crew_token)
    assert status == 200 and prog_res["update_type"] == "PROGRESS"
    print(f"[12] Crew Uploaded Progress Evidence => Update ID: {prog_res['id']}")

    # 12. Authority Inspects Field Progress
    status, auth_inc_detail = make_json_request(f"{BASE_URL}/authority/incidents/{inc_id}", method="GET", token=authority_token)
    assert status == 200
    assert len(auth_inc_detail["progress_updates"]) >= 1
    print(f"[13] Authority Verified Field Progress => Updates Count: {len(auth_inc_detail['progress_updates'])}")

    # 13. Crew Completes Job with Mandatory Resolution Photo
    comp_fields = {"note": "Road cleared completely. Debris removed. Carriageway reopened."}
    status, comp_res = post_multipart(f"{BASE_URL}/crew/assignments/{assignment_id}/complete", comp_fields, "file", "resolution_photo.jpg", dummy_img, crew_token)
    assert status == 200 and comp_res["status"] == "COMPLETED"
    assert comp_res["incident"]["status"] == "RESOLVED"
    print(f"[14] Crew Completed Job with Resolution Photo => Incident Status: RESOLVED")

    # 14. Citizen Views Resolved Incident Status & Evidence
    status, cit_inc_detail = make_json_request(f"{BASE_URL}/incidents/{inc_id}", method="GET", token=citizen_token)
    assert status == 200 and cit_inc_detail["status"] == "RESOLVED"
    print(f"[15] Citizen Verified Incident Status => RESOLVED, Resolved At: {cit_inc_detail.get('resolved_at')}")

    # 15. Public / Nearby Map Verification
    status, nearby = make_json_request(f"{BASE_URL}/incidents/nearby?latitude=6.9150&longitude=79.8580", method="GET", token=citizen_token)
    assert status == 200
    inc_on_map = [n for n in nearby if n["id"] == inc_id][0]
    assert inc_on_map["status"] == "RESOLVED"
    print(f"[16] Public Nearby Map Verified => Incident #{inc_id} reflects RESOLVED state")

    # 16. Authority Officially Closes Incident
    status, close_res = make_json_request(f"{BASE_URL}/authority/incidents/{inc_id}/close", method="POST", token=authority_token)
    assert status == 200 and close_res["status"] == "CLOSED"
    print(f"[17] Authority Officially Closed Incident => Status: CLOSED")

    # 17. Crew Completed Jobs History
    status, completed_jobs = make_json_request(f"{BASE_URL}/crew/completed-jobs", method="GET", token=crew_token)
    assert status == 200 and len(completed_jobs) >= 1
    print(f"[18] Crew Completed Jobs History Verified => Count: {len(completed_jobs)}")

    print("\n==================================================")
    print(" [SUCCESS] ALL PHASE 4 END-TO-END TESTS PASSED!   ")
    print("==================================================")

if __name__ == "__main__":
    run_phase4_tests()
