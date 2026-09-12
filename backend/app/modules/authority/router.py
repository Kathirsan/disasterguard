import uuid
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.dependencies import get_current_user, require_role
from app.modules.users.models import User, UserRole
from app.modules.incidents.models import Incident, IncidentStatus, HazardType
from app.modules.incidents.schemas import IncidentResponse
from app.modules.verification.models import (
    IncidentVerification,
    WeatherObservation,
    AIAssessment,
    IncidentStatusHistory,
    RiskLevel,
)
from app.modules.verification.schemas import (
    IncidentVerificationResponse,
    WeatherObservationResponse,
    AIAssessmentResponse,
    IncidentStatusHistoryResponse,
)
from app.modules.verification.verification_service import update_incident_status, run_full_verification_pipeline
from app.modules.alerts.models import Alert
from app.modules.alerts.schemas import AlertCreate, AlertResponse
from app.modules.tickets.models import CouncilTicket, CrewAssignment, CrewProgressUpdate
from app.modules.tickets.schemas import (
    CouncilTicketCreate,
    CouncilTicketResponse,
    DispatchCreate,
    CrewAssignmentResponse,
    CrewUserResponse,
)

router = APIRouter(prefix="/authority", tags=["Authority Operations"])
alerts_router = APIRouter(prefix="/alerts", tags=["Alerts"])

# Dependency for strict Authority role access
require_authority = require_role([UserRole.AUTHORITY])

@router.get("/dashboard")
def get_authority_dashboard(
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    all_incidents = db.query(Incident).all()
    
    pending_count = 0
    high_risk_count = 0
    critical_count = 0
    verified_count = 0
    dispatched_count = 0

    for inc in all_incidents:
        if inc.status in [IncidentStatus.SUBMITTED, IncidentStatus.SYSTEM_CHECKING, IncidentStatus.AI_ANALYSIS, IncidentStatus.VERIFICATION_REQUIRED]:
            pending_count += 1
        elif inc.status == IncidentStatus.VERIFIED:
            verified_count += 1
        elif inc.status == IncidentStatus.DISPATCHED:
            dispatched_count += 1

        ver = db.query(IncidentVerification).filter(IncidentVerification.incident_id == inc.id).first()
        if ver:
            if ver.risk_level == RiskLevel.CRITICAL:
                critical_count += 1
            elif ver.risk_level == RiskLevel.HIGH:
                high_risk_count += 1

    recent = (
        db.query(Incident)
        .order_by(Incident.created_at.desc())
        .limit(6)
        .all()
    )

    recent_data = []
    for inc in recent:
        ver = db.query(IncidentVerification).filter(IncidentVerification.incident_id == inc.id).first()
        recent_data.append({
            "id": inc.id,
            "hazard_type": inc.hazard_type,
            "description": inc.description,
            "status": inc.status,
            "latitude": inc.latitude,
            "longitude": inc.longitude,
            "address_text": inc.address_text,
            "created_at": inc.created_at,
            "risk_score": ver.risk_score if ver else 0,
            "risk_level": ver.risk_level if ver else "LOW",
        })

    return {
        "metrics": {
            "pending_verification": pending_count,
            "high_risk_incidents": high_risk_count,
            "critical_incidents": critical_count,
            "verified_incidents": verified_count,
            "dispatched_incidents": dispatched_count,
            "total_incidents": len(all_incidents),
        },
        "recent_incidents": recent_data,
    }

@router.get("/incidents")
def list_authority_incidents(
    risk_level: Optional[str] = Query(None),
    status_filter: Optional[str] = Query(None),
    hazard_type: Optional[str] = Query(None),
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    query = db.query(Incident)
    
    if status_filter:
        query = query.filter(Incident.status == status_filter)
    if hazard_type:
        query = query.filter(Incident.hazard_type == hazard_type)
        
    incidents = query.order_by(Incident.created_at.desc()).offset(offset).limit(limit).all()

    items = []
    for inc in incidents:
        ver = db.query(IncidentVerification).filter(IncidentVerification.incident_id == inc.id).first()
        if risk_level and ver and ver.risk_level.value != risk_level:
            continue

        primary_img = inc.media[0].file_path if inc.media else None
        items.append({
            "id": inc.id,
            "hazard_type": inc.hazard_type,
            "description": inc.description,
            "latitude": inc.latitude,
            "longitude": inc.longitude,
            "address_text": inc.address_text,
            "status": inc.status,
            "created_at": inc.created_at,
            "primary_image_url": primary_img,
            "verification": IncidentVerificationResponse.model_validate(ver) if ver else None,
        })

    return items

@router.get("/incidents/{incident_id}")
def get_authority_incident_detail(
    incident_id: int,
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    reporter = db.query(User).filter(User.id == incident.reporter_id).first()
    verification = db.query(IncidentVerification).filter(IncidentVerification.incident_id == incident_id).first()
    weather = db.query(WeatherObservation).filter(WeatherObservation.incident_id == incident_id).first()
    ai_eval = db.query(AIAssessment).filter(AIAssessment.incident_id == incident_id).first()
    history = db.query(IncidentStatusHistory).filter(IncidentStatusHistory.incident_id == incident_id).order_by(IncidentStatusHistory.created_at.asc()).all()
    ticket = db.query(CouncilTicket).filter(CouncilTicket.incident_id == incident_id).first()
    assignment = db.query(CrewAssignment).filter(CrewAssignment.incident_id == incident_id).first()
    active_alert = db.query(Alert).filter(Alert.incident_id == incident_id).first()

    primary_img = incident.media[0].file_path if incident.media else None
    res_img = None
    if incident.media:
        for m in incident.media:
            if m.evidence_type == "RESOLUTION_EVIDENCE":
                res_img = m.file_path

    progress_updates = (
        db.query(CrewProgressUpdate)
        .filter(CrewProgressUpdate.incident_id == incident_id)
        .order_by(CrewProgressUpdate.created_at.asc())
        .all()
    )

    return {
        "incident": IncidentResponse.model_validate(incident),
        "reporter": {
            "id": reporter.id if reporter else 0,
            "full_name": reporter.full_name if reporter else "Anonymous Citizen",
            "email": reporter.email if reporter else "",
        },
        "primary_image_url": primary_img,
        "resolution_image_url": res_img,
        "verification": IncidentVerificationResponse.model_validate(verification) if verification else None,
        "weather": WeatherObservationResponse.model_validate(weather) if weather else None,
        "ai_assessment": AIAssessmentResponse.model_validate(ai_eval) if ai_eval else None,
        "status_history": [IncidentStatusHistoryResponse.model_validate(h) for h in history],
        "council_ticket": CouncilTicketResponse.model_validate(ticket) if ticket else None,
        "crew_assignment": CrewAssignmentResponse.model_validate(assignment) if assignment else None,
        "alert": AlertResponse.model_validate(active_alert) if active_alert else None,
        "progress_updates": [
            {
                "id": u.id,
                "crew_id": u.crew_id,
                "note": u.note,
                "evidence_path": u.evidence_path,
                "update_type": u.update_type,
                "created_at": u.created_at,
            }
            for u in progress_updates
        ],
    }

@router.post("/incidents/{incident_id}/close")
def close_incident(
    incident_id: int,
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    if incident.status not in [IncidentStatus.RESOLVED, IncidentStatus.IN_PROGRESS]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incident can only be closed once resolved or in progress")

    incident.closed_at = datetime.now(timezone.utc)
    updated = update_incident_status(
        db=db,
        incident=incident,
        new_status=IncidentStatus.CLOSED,
        actor_id=current_user.id,
        actor_role="AUTHORITY",
        reason=f"Incident officially closed by Authority Officer {current_user.full_name}.",
    )
    return {"message": "Incident closed successfully", "incident_id": incident_id, "status": updated.status}


@router.post("/incidents/{incident_id}/confirm")
def confirm_incident(
    incident_id: int,
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    if incident.status in [IncidentStatus.RESOLVED, IncidentStatus.CLOSED]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Resolved or closed incidents cannot be re-confirmed")

    updated = update_incident_status(
        db=db,
        incident=incident,
        new_status=IncidentStatus.VERIFIED,
        actor_id=current_user.id,
        actor_role="AUTHORITY",
        reason=f"Incident confirmed by Authority Officer {current_user.full_name}.",
    )
    return {"message": "Incident confirmed successfully", "incident_id": incident_id, "status": updated.status}

@router.post("/incidents/{incident_id}/reject")
def reject_incident(
    incident_id: int,
    payload: dict,
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    reason = payload.get("reason", "Incident rejected by authority evaluation.")

    updated = update_incident_status(
        db=db,
        incident=incident,
        new_status=IncidentStatus.REJECTED,
        actor_id=current_user.id,
        actor_role="AUTHORITY",
        reason=reason,
    )
    return {"message": "Incident rejected successfully", "incident_id": incident_id, "status": updated.status}

@router.post("/alerts", response_model=AlertResponse, status_code=status.HTTP_201_CREATED)
def create_affected_area_alert(
    payload: AlertCreate,
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    incident = db.query(Incident).filter(Incident.id == payload.incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    ver = db.query(IncidentVerification).filter(IncidentVerification.incident_id == payload.incident_id).first()
    risk_level_str = ver.risk_level.value if ver else "HIGH"

    alert = Alert(
        incident_id=incident.id,
        title=payload.title,
        hazard_type=incident.hazard_type,
        risk_level=risk_level_str,
        message=payload.message,
        latitude=incident.latitude,
        longitude=incident.longitude,
        radius_km=payload.radius_km,
        issuing_authority_id=current_user.id,
        created_at=datetime.now(timezone.utc),
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)
    return AlertResponse.model_validate(alert)

@alerts_router.get("/relevant", response_model=List[AlertResponse])
def get_relevant_citizen_alerts(
    latitude: float,
    longitude: float,
    db: Session = Depends(get_db),
):
    # Fetch all recent alerts and filter by geographical radius
    alerts = db.query(Alert).order_by(Alert.created_at.desc()).all()
    results = []
    for alt in alerts:
        # Distance calculation
        from app.modules.incidents.service import haversine_distance
        dist = haversine_distance(latitude, longitude, alt.latitude, alt.longitude)
        if dist <= alt.radius_km:
            results.append(AlertResponse.model_validate(alt))
    return results

@router.post("/tickets", response_model=CouncilTicketResponse, status_code=status.HTTP_201_CREATED)
def create_council_ticket(
    payload: CouncilTicketCreate,
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    incident = db.query(Incident).filter(Incident.id == payload.incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    existing = db.query(CouncilTicket).filter(CouncilTicket.incident_id == payload.incident_id).first()
    if existing:
        return CouncilTicketResponse.model_validate(existing)

    ticket_no = f"TICK-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:4].upper()}"
    ticket = CouncilTicket(
        ticket_number=ticket_no,
        incident_id=payload.incident_id,
        status="OPEN",
        priority=payload.priority,
        description=payload.description or f"Operational ticket generated for {incident.hazard_type.value} incident #{incident.id}",
        created_by_id=current_user.id,
        created_at=datetime.now(timezone.utc),
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return CouncilTicketResponse.model_validate(ticket)

@router.get("/crews", response_model=List[CrewUserResponse])
def get_available_crews(
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    crews = db.query(User).filter(User.role == UserRole.CREW, User.is_active == True).all()
    return [CrewUserResponse.model_validate(c) for c in crews]

@router.post("/dispatch", response_model=CrewAssignmentResponse, status_code=status.HTTP_201_CREATED)
def dispatch_crew_assignment(
    payload: DispatchCreate,
    current_user: User = Depends(require_authority),
    db: Session = Depends(get_db),
):
    incident = db.query(Incident).filter(Incident.id == payload.incident_id).first()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    ticket = db.query(CouncilTicket).filter(CouncilTicket.id == payload.ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found")

    crew = db.query(User).filter(User.id == payload.assigned_crew_id, User.role == UserRole.CREW).first()
    if not crew:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid CREW user ID")

    assignment = CrewAssignment(
        incident_id=payload.incident_id,
        ticket_id=payload.ticket_id,
        assigned_crew_id=payload.assigned_crew_id,
        assigned_by_id=current_user.id,
        status="ASSIGNED",
        instructions=payload.instructions or f"Immediate dispatch for {incident.hazard_type.value} incident at {incident.address_text or 'coordinates'}.",
        assigned_at=datetime.now(timezone.utc),
    )
    db.add(assignment)
    
    # Update ticket assigned crew and status
    ticket.assigned_crew_id = payload.assigned_crew_id
    ticket.status = "IN_PROGRESS"
    
    db.commit()

    # Update incident status to DISPATCHED
    update_incident_status(
        db=db,
        incident=incident,
        new_status=IncidentStatus.DISPATCHED,
        actor_id=current_user.id,
        actor_role="AUTHORITY",
        reason=f"Emergency field crew '{crew.full_name}' dispatched by Officer {current_user.full_name}.",
    )

    db.refresh(assignment)
    return CrewAssignmentResponse.model_validate(assignment)
