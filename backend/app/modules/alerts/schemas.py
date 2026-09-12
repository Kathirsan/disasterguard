from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from app.modules.incidents.models import HazardType

class AlertCreate(BaseModel):
    incident_id: int
    title: str
    message: str
    radius_km: float = 10.0

class AlertResponse(BaseModel):
    id: int
    incident_id: int
    title: str
    hazard_type: HazardType
    risk_level: str
    message: str
    latitude: float
    longitude: float
    radius_km: float
    issuing_authority_id: int
    created_at: datetime

    class Config:
        from_attributes = True
