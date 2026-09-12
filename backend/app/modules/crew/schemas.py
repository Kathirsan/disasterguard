from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict
from app.modules.incidents.schemas import IncidentResponse

class ProgressUpdateCreate(BaseModel):
    note: Optional[str] = None

class ProgressUpdateResponse(BaseModel):
    id: int
    assignment_id: int
    incident_id: int
    crew_id: int
    note: Optional[str] = None
    evidence_path: Optional[str] = None
    update_type: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class CrewAssignmentDetailResponse(BaseModel):
    id: int
    incident_id: int
    ticket_id: int
    assigned_crew_id: int
    assigned_by_id: int
    status: str
    instructions: Optional[str] = None
    assigned_at: datetime
    accepted_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    # Nested information for operational view
    incident: IncidentResponse
    reporter_name: Optional[str] = None
    ticket_number: Optional[str] = None
    primary_image_url: Optional[str] = None
    progress_updates: List[ProgressUpdateResponse] = []
    resolution_evidence_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class CrewDashboardResponse(BaseModel):
    total_assigned: int
    new_assignments_count: int
    active_in_progress_count: int
    completed_count: int
    recent_jobs: List[CrewAssignmentDetailResponse]
