# DisasterGuard API Contract

Base URL: `/api`

---

## 1. Authentication
* **POST `/api/auth/register`** — Register new citizen/user
* **POST `/api/auth/login`** — User login (returns JWT token)
* **GET `/api/auth/me`** — Get current logged-in user profile

---

## 2. Citizen Hazards
* **POST `/api/hazards`** — Report a new hazard (photo, location, description)
* **GET `/api/hazards`** — Get all reported hazards
* **GET `/api/hazards/:id`** — Get details of a single hazard

---

## 3. AI / Verification
* **POST `/api/hazards/:id/analyze`** — Run AI analysis on hazard image & data
* **GET `/api/hazards/:id/checks`** — View AI & manual verification results

---

## 4. Weather
* **GET `/api/weather/current`** — Get current weather by coordinates
* **GET `/api/weather/feed`** — Get weather alerts and live feed

---

## 5. Alerts
* **GET `/api/alerts`** — Get list of active disaster alerts
* **POST `/api/alerts`** — Broadcast a new emergency alert (Officer only)

---

## 6. Officer
* **GET `/api/officer/incidents`** — List incidents waiting for officer action
* **POST `/api/officer/incidents/:id/dispatch`** — Dispatch response team to incident

---

## 7. Crew
* **GET `/api/crew/jobs`** — List tasks assigned to the crew
* **POST `/api/crew/jobs/:id/accept`** — Crew accepts the job
* **POST `/api/crew/jobs/:id/resolve`** — Mark job complete with proof