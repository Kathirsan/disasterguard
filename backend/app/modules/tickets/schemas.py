from typing import Optional
from datetime import datetime
from pydantic import BaseModel

class CouncilTicketCreate(BaseModel):
    incident_id: int
    priority: str = "HIGH"  # LOW, MEDIUM, HIGH, CRITICAL
    description: Optional[str] = None

class CouncilTicketResponse(BaseModel):
    id: int
    ticket_number: str
    incident_id: int
    status: str
    priority: str
    description: Optional[str] = None
    created_by_id: int
    assigned_crew_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True

class DispatchCreate(BaseModel):
    incident_id: int
    ticket_id: int
    assigned_crew_id: int
    instructions: Optional[str] = None

class CrewAssignmentResponse(BaseModel):
    id: int
    incident_id: int
    ticket_id: int
    assigned_crew_id: int
    assigned_by_id: int
    status: str
    instructions: Optional[str] = None
    assigned_at: datetime

    class Config:
        from_attributes = True

class CrewUserResponse(BaseModel):
    id: int
    full_name: str
    email: str

    class Config:
        from_attributes = True
