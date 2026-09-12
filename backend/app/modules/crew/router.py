import os
import uuid
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.dependencies import require_role
from app.modules.users.models import User, UserRole
from app.modules.incidents.models import Incident, IncidentStatus, IncidentMedia
from app.modules.incidents.schemas import IncidentResponse
from app.modules.tickets.models import CouncilTicket, CrewAssignment, CrewProgressUpdate
from app.modules.verification.verification_service import update_incident_status
from app.modules.crew.schemas import (
    CrewAssignmentDetailResponse,
    ProgressUpdateResponse,
    CrewDashboardResponse,
)

router = APIRouter(prefix="/crew", tags=["Crew Operations"])

# Strict authorization for CREW role
require_crew = require_role([UserRole.CREW])

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _build_assignment_detail_response(db: Session, assignment: CrewAssignment) -> dict:
    incident = db.query(Incident).filter(Incident.id == assignment.incident_id).first()
    ticket = db.query(CouncilTicket).filter(CouncilTicket.id == assignment.ticket_id).first()
    reporter = db.query(User).filter(User.id == incident.reporter_id).first() if incident else None

    # Get media
    primary_img = None
    res_img = None
    if incident and incident.media:
        primary_img = incident.media[0].file_path
        for m in incident.media:
            if m.evidence_type == "RESOLUTION_EVIDENCE":
                res_img = m.file_path

    # Get progress updates
    updates = (
        db.query(CrewProgressUpdate)
        .filter(CrewProgressUpdate.assignment_id == assignment.id)
        .order_by(CrewProgressUpdate.created_at.asc())
        .all()
    )

    return {
        "id": assignment.id,
        "incident_id": assignment.incident_id,
        "ticket_id": assignment.ticket_id,
        "assigned_crew_id": assignment.assigned_crew_id,
        "assigned_by_id": assignment.assigned_by_id,
        "status": assignment.status,
        "instructions": assignment.instructions,
        "assigned_at": assignment.assigned_at,
        "accepted_at": assignment.accepted_at,
        "started_at": assignment.started_at,
        "completed_at": assignment.completed_at,
        "incident": IncidentResponse.model_validate(incident) if incident else None,
        "reporter_name": reporter.full_name if reporter else "Anonymous",
        "ticket_number": ticket.ticket_number if ticket else None,
        "primary_image_url": primary_img,
        "progress_updates": [ProgressUpdateResponse.model_validate(u) for u in updates],
        "resolution_evidence_url": res_img,
    }


@router.get("/dashboard", response_model=CrewDashboardResponse)
def get_crew_dashboard(
    current_user: User = Depends(require_crew),
    db: Session = Depends(get_db),
):
    assignments = (
        db.query(CrewAssignment)
        .filter(CrewAssignment.assigned_crew_id == current_user.id)
        .all()
    )

    total_assigned = len(assignments)
    new_count = sum(1 for a in assignments if a.status == "ASSIGNED")
    active_count = sum(1 for a in assignments if a.status in ["ACCEPTED", "IN_PROGRESS"])
    completed_count = sum(1 for a in assignments if a.status == "COMPLETED")

    recent = (
        db.query(CrewAssignment)
        .filter(CrewAssignment.assigned_crew_id == current_user.id)
        .order_by(CrewAssignment.assigned_at.desc())
        .limit(10)
        .all()
    )

    recent_jobs = [_build_assignment_detail_response(db, a) for a in recent]

    return {
        "total_assigned": total_assigned,
        "new_assignments_count": new_count,
        "active_in_progress_count": active_count,
        "completed_count": completed_count,
        "recent_jobs": recent_jobs,
    }


@router.get("/assignments", response_model=List[CrewAssignmentDetailResponse])
def get_my_assignments(
    status_filter: Optional[str] = Query(None),
    current_user: User = Depends(require_crew),
    db: Session = Depends(get_db),
):
    query = db.query(CrewAssignment).filter(CrewAssignment.assigned_crew_id == current_user.id)
    if status_filter:
        query = query.filter(CrewAssignment.status == status_filter)

    assignments = query.order_by(CrewAssignment.assigned_at.desc()).all()
    return [_build_assignment_detail_response(db, a) for a in assignments]


@router.get("/assignments/{assignment_id}", response_model=CrewAssignmentDetailResponse)
def get_assignment_detail(
    assignment_id: int,
    current_user: User = Depends(require_crew),
    db: Session = Depends(get_db),
):
    assignment = (
        db.query(CrewAssignment)
        .filter(CrewAssignment.id == assignment_id, CrewAssignment.assigned_crew_id == current_user.id)
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found or not assigned to you")

    return _build_assignment_detail_response(db, assignment)


@router.post("/assignments/{assignment_id}/accept", response_model=CrewAssignmentDetailResponse)
def accept_assignment(
    assignment_id: int,
    current_user: User = Depends(require_crew),
    db: Session = Depends(get_db),
):
    assignment = (
        db.query(CrewAssignment)
        .filter(CrewAssignment.id == assignment_id, CrewAssignment.assigned_crew_id == current_user.id)
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found")

    if assignment.status != "ASSIGNED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Assignment cannot be accepted from current status '{assignment.status}'",
        )

    assignment.status = "ACCEPTED"
    assignment.accepted_at = datetime.now(timezone.utc)
    db.commit()

    return _build_assignment_detail_response(db, assignment)


@router.post("/assignments/{assignment_id}/start", response_model=CrewAssignmentDetailResponse)
def start_job(
    assignment_id: int,
    current_user: User = Depends(require_crew),
    db: Session = Depends(get_db),
):
    assignment = (
        db.query(CrewAssignment)
        .filter(CrewAssignment.id == assignment_id, CrewAssignment.assigned_crew_id == current_user.id)
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found")

    if assignment.status not in ["ASSIGNED", "ACCEPTED"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Job work cannot be started from status '{assignment.status}'",
        )

    now = datetime.now(timezone.utc)
    if not assignment.accepted_at:
        assignment.accepted_at = now
    assignment.status = "IN_PROGRESS"
    assignment.started_at = now

    # Update incident status to IN_PROGRESS
    incident = db.query(Incident).filter(Incident.id == assignment.incident_id).first()
    if incident:
        update_incident_status(
            db=db,
            incident=incident,
            new_status=IncidentStatus.IN_PROGRESS,
            actor_id=current_user.id,
            actor_role="CREW",
            reason=f"Field Crew '{current_user.full_name}' initiated on-site work.",
        )

    db.commit()
    return _build_assignment_detail_response(db, assignment)


@router.post("/assignments/{assignment_id}/progress", response_model=ProgressUpdateResponse)
async def add_progress_update(
    assignment_id: int,
    note: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    current_user: User = Depends(require_crew),
    db: Session = Depends(get_db),
):
    assignment = (
        db.query(CrewAssignment)
        .filter(CrewAssignment.id == assignment_id, CrewAssignment.assigned_crew_id == current_user.id)
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found")

    evidence_path = None
    if file:
        file_ext = os.path.splitext(file.filename)[1] or ".jpg"
        filename = f"progress_{assignment_id}_{uuid.uuid4().hex[:8]}{file_ext}"
        filepath = os.path.join(UPLOAD_DIR, filename)

        contents = await file.read()
        with open(filepath, "wb") as f:
            f.write(contents)

        evidence_path = f"/static/uploads/{filename}"

        # Add to incident_media
        media = IncidentMedia(
            incident_id=assignment.incident_id,
            file_path=evidence_path,
            media_type=file.content_type or "image/jpeg",
            evidence_type="PROGRESS_EVIDENCE",
            created_at=datetime.now(timezone.utc),
        )
        db.add(media)

    update = CrewProgressUpdate(
        assignment_id=assignment.id,
        incident_id=assignment.incident_id,
        crew_id=current_user.id,
        note=note,
        evidence_path=evidence_path,
        update_type="PROGRESS",
        created_at=datetime.now(timezone.utc),
    )
    db.add(update)
    db.commit()
    db.refresh(update)

    return ProgressUpdateResponse.model_validate(update)


@router.post("/assignments/{assignment_id}/complete", response_model=CrewAssignmentDetailResponse)
async def complete_job(
    assignment_id: int,
    note: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    current_user: User = Depends(require_crew),
    db: Session = Depends(get_db),
):
    assignment = (
        db.query(CrewAssignment)
        .filter(CrewAssignment.id == assignment_id, CrewAssignment.assigned_crew_id == current_user.id)
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found")

    if assignment.status == "COMPLETED":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Job is already completed")

    # Resolution evidence photo is required
    if not file:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Resolution photo evidence is mandatory to complete job",
        )

    file_ext = os.path.splitext(file.filename)[1] or ".jpg"
    filename = f"resolution_{assignment_id}_{uuid.uuid4().hex[:8]}{file_ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    contents = await file.read()
    with open(filepath, "wb") as f:
        f.write(contents)

    resolution_path = f"/static/uploads/{filename}"

    now = datetime.now(timezone.utc)

    # Save to incident_media
    media = IncidentMedia(
        incident_id=assignment.incident_id,
        file_path=resolution_path,
        media_type=file.content_type or "image/jpeg",
        evidence_type="RESOLUTION_EVIDENCE",
        created_at=now,
    )
    db.add(media)

    # Save to crew updates
    update = CrewProgressUpdate(
        assignment_id=assignment.id,
        incident_id=assignment.incident_id,
        crew_id=current_user.id,
        note=note or "Job completed and resolution photo uploaded.",
        evidence_path=resolution_path,
        update_type="RESOLUTION",
        created_at=now,
    )
    db.add(update)

    # Update assignment
    assignment.status = "COMPLETED"
    assignment.completed_at = now

    # Update ticket status
    ticket = db.query(CouncilTicket).filter(CouncilTicket.id == assignment.ticket_id).first()
    if ticket:
        ticket.status = "RESOLVED"

    # Update incident status to RESOLVED
    incident = db.query(Incident).filter(Incident.id == assignment.incident_id).first()
    if incident:
        incident.resolved_at = now
        update_incident_status(
            db=db,
            incident=incident,
            new_status=IncidentStatus.RESOLVED,
            actor_id=current_user.id,
            actor_role="CREW",
            reason=f"Hazard successfully resolved by Field Crew '{current_user.full_name}'. Resolution evidence verified.",
        )

    db.commit()
    return _build_assignment_detail_response(db, assignment)


@router.get("/completed-jobs", response_model=List[CrewAssignmentDetailResponse])
def get_completed_jobs(
    current_user: User = Depends(require_crew),
    db: Session = Depends(get_db),
):
    assignments = (
        db.query(CrewAssignment)
        .filter(CrewAssignment.assigned_crew_id == current_user.id, CrewAssignment.status == "COMPLETED")
        .order_by(CrewAssignment.completed_at.desc())
        .all()
    )
    return [_build_assignment_detail_response(db, a) for a in assignments]
