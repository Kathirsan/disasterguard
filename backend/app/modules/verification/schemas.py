from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel
from app.modules.incidents.models import HazardType
from app.modules.verification.models import WeatherSupportLevel, HazardAgreement, RiskLevel

class WeatherObservationResponse(BaseModel):
    id: int
    incident_id: int
    condition: str
    rainfall_mm: float
    wind_speed_kmh: float
    temperature_c: float
    provider: str
    weather_support: WeatherSupportLevel
    observed_at: datetime

    class Config:
        from_attributes = True

class AIAssessmentResponse(BaseModel):
    id: int
    incident_id: int
    detected_hazard: HazardType
    confidence: float
    severity_estimate: str
    visible_evidence: str
    reasoning_summary: str
    hazard_agreement: HazardAgreement
    created_at: datetime

    class Config:
        from_attributes = True

class IncidentVerificationResponse(BaseModel):
    id: int
    incident_id: int
    gps_valid: bool
    weather_support: WeatherSupportLevel
    weather_summary: Optional[str] = None
    nearby_report_count: int
    is_possible_duplicate: bool
    duplicate_of_id: Optional[int] = None
    cluster_id: Optional[str] = None
    ai_detected_hazard: Optional[HazardType] = None
    ai_confidence: Optional[float] = None
    ai_severity: Optional[str] = None
    hazard_agreement: Optional[HazardAgreement] = None
    ai_visible_evidence: Optional[str] = None
    ai_reasoning: Optional[str] = None
    risk_score: int
    risk_level: RiskLevel
    evidence_summary: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class IncidentStatusHistoryResponse(BaseModel):
    id: int
    incident_id: int
    prev_status: str
    new_status: str
    actor_id: Optional[int] = None
    actor_role: str
    reason: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True