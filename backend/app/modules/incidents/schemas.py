from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from app.modules.incidents.models import HazardType, IncidentStatus

class IncidentMediaResponse(BaseModel):
    id: int
    file_path: str
    media_type: str
    evidence_type: Optional[str] = "REPORT_EVIDENCE"
    created_at: datetime

    class Config:
        from_attributes = True

class IncidentResponse(BaseModel):
    id: int
    reporter_id: int
    hazard_type: HazardType
    description: str
    latitude: float
    longitude: float
    address_text: Optional[str] = None
    status: IncidentStatus
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    media: List[IncidentMediaResponse] = []

    class Config:
        from_attributes = True

class NearbyIncidentResponse(BaseModel):
    id: int
    hazard_type: HazardType
    description: str
    latitude: float
    longitude: float
    address_text: Optional[str] = None
    status: IncidentStatus
    created_at: datetime
    distance_km: float
    primary_image_url: Optional[str] = None

    class Config:
        from_attributes = True
