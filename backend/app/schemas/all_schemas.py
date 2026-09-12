from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# --- Auth Schemas ---
class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: Optional[str] = "citizen"
    phone: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    role: str

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

# --- Hazard Schemas ---
class HazardCreate(BaseModel):
    title: str
    description: Optional[str] = None
    category: str
    latitude: float
    longitude: float
    image_url: Optional[str] = None

class HazardResponse(BaseModel):
    id: int
    user_id: int
    title: str
    description: Optional[str]
    category: str
    status: str
    latitude: float
    longitude: float
    image_url: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

# --- Case Builder Schema ---
class UnifiedCaseResponse(BaseModel):
    case_id: str
    hazard_id: int
    status: str
    category: str
    title: str
    description: Optional[str]
    evidence: dict
    geography: dict
    environmental_context: dict
    cross_validation: dict
    created_at: Optional[str]

# --- Priority 6: System Checks Schemas ---
class WeatherCheckResponse(BaseModel):
    rainfall_mm: float
    river_level_m: float
    severity_level: str
    alert_message: str

class ClusterCheckResponse(BaseModel):
    hazard_id: int
    radius_meters: float
    nearby_count: int
    threshold_required: int
    cluster_confirmed: bool
    cluster_density: str
    nearby_hazards: List[dict]

class FullSystemCheckResponse(BaseModel):
    hazard_id: int
    weather_check: WeatherCheckResponse
    cluster_check: ClusterCheckResponse
    system_verdict: str

# --- Priority 7: AI Detection Schemas ---
class AIDetectionResult(BaseModel):
    hazard: str
    confidence: float
    severity: str

class AIAnalysisCompleteResponse(BaseModel):
    hazard_id: int
    new_status: str
    ai_verdict: AIDetectionResult
    weather_match: str
    duplicate_risk: str
    notes: str

# --- Priority 8: Aggregator Schemas ---
class AggregatorResponse(BaseModel):
    hazard_id: int
    verdict: str
    confidence: float
    severity: str
    urgency: str
    reasons: List[str]
    requires_alert: bool
    status_updated: str

    # --- Priority 9: Officer / Crew Dispatch Schemas ---
class DispatchCreate(BaseModel):
    hazard_id: int
    crew_name: str
    priority: Optional[str] = "HIGH"
    instructions: Optional[str] = None

class CrewAcceptRequest(BaseModel):
    crew_notes: Optional[str] = None

class CrewResolveRequest(BaseModel):
    resolution_photo_url: str
    resolution_notes: str

class IncidentTicketResponse(BaseModel):
    id: int
    hazard_id: int
    officer_id: int
    crew_name: str
    ticket_status: str
    priority: str
    instructions: Optional[str]
    resolution_photo_url: Optional[str]
    resolution_notes: Optional[str]
    dispatched_at: datetime
    resolved_at: Optional[datetime]

    class Config:
        from_attributes = True