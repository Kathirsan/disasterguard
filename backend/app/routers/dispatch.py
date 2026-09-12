from typing import List
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.all_models import Hazard, User, IncidentTicket
from app.schemas.all_schemas import (
    DispatchCreate,
    CrewAcceptRequest,
    CrewResolveRequest,
    IncidentTicketResponse
)
from app.auth import get_current_user

router = APIRouter(prefix="/api/dispatch", tags=["Officer & Crew Dispatch"])

# 1. Officer creates a dispatch ticket
@router.post("/tickets", response_model=IncidentTicketResponse, status_code=status.HTTP_201_CREATED)
def dispatch_crew_to_hazard(
    dispatch_data: DispatchCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    hazard = db.query(Hazard).filter(Hazard.id == dispatch_data.hazard_id).first()
    if not hazard:
        raise HTTPException(status_code=404, detail="Hazard not found")

    # Update hazard state to in_progress upon dispatch
    hazard.status = "in_progress"

    ticket = IncidentTicket(
        hazard_id=hazard.id,
        officer_id=current_user.id,
        crew_name=dispatch_data.crew_name,
        ticket_status="DISPATCHED",
        priority=dispatch_data.priority,
        instructions=dispatch_data.instructions
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return ticket

# 2. Get all dispatch tickets (for Officer/Crew dashboard)
@router.get("/tickets", response_model=List[IncidentTicketResponse])
def get_all_tickets(db: Session = Depends(get_db)):
    return db.query(IncidentTicket).order_by(IncidentTicket.dispatched_at.desc()).all()

# 3. Crew accepts assignment -> IN_PROGRESS
@router.post("/tickets/{ticket_id}/accept", response_model=IncidentTicketResponse)
def crew_accept_ticket(
    ticket_id: int,
    request: CrewAcceptRequest,
    db: Session = Depends(get_db)
):
    ticket = db.query(IncidentTicket).filter(IncidentTicket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Incident ticket not found")

    ticket.ticket_status = "IN_PROGRESS"
    if request.crew_notes:
        existing = ticket.instructions or ""
        ticket.instructions = f"{existing} | Crew Note: {request.crew_notes}"

    db.commit()
    db.refresh(ticket)
    return ticket

# 4. Crew submits resolution photo -> RESOLVED
@router.post("/tickets/{ticket_id}/resolve", response_model=IncidentTicketResponse)
def crew_resolve_ticket(
    ticket_id: int,
    resolve_data: CrewResolveRequest,
    db: Session = Depends(get_db)
):
    ticket = db.query(IncidentTicket).filter(IncidentTicket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Incident ticket not found")

    ticket.ticket_status = "RESOLVED"
    ticket.resolution_photo_url = resolve_data.resolution_photo_url
    ticket.resolution_notes = resolve_data.resolution_notes
    ticket.resolved_at = datetime.utcnow()

    # Update corresponding parent hazard status to resolved
    hazard = db.query(Hazard).filter(Hazard.id == ticket.hazard_id).first()
    if hazard:
        hazard.status = "resolved"

    db.commit()
    db.refresh(ticket)
    return ticket