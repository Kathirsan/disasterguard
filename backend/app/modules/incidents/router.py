from typing import List, Optional
from fastapi import APIRouter, Depends, Form, File, UploadFile, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from app.core.database import get_db, SessionLocal
from app.api.dependencies import get_current_user
from app.modules.users.models import User
from app.modules.incidents.models import HazardType
from app.modules.incidents.schemas import IncidentResponse, NearbyIncidentResponse
from app.modules.incidents.service import (
    create_incident,
    get_user_incidents,
    get_incident_by_id,
    get_nearby_incidents,
)
from app.modules.verification.verification_service import run_full_verification_pipeline

router = APIRouter(prefix="/incidents", tags=["Incidents"])

async def _bg_run_pipeline(incident_id: int):
    db = SessionLocal()
    try:
        await run_full_verification_pipeline(db, incident_id)
    finally:
        db.close()

@router.post("", response_model=IncidentResponse, status_code=status.HTTP_201_CREATED)
async def report_incident(
    background_tasks: BackgroundTasks,
    hazard_type: HazardType = Form(...),
    description: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    address_text: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not description.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Description cannot be empty"
        )

    incident = await create_incident(
        db=db,
        reporter_id=current_user.id,
        hazard_type=hazard_type,
        description=description,
        latitude=latitude,
        longitude=longitude,
        address_text=address_text,
        file=file,
    )
    
    # Run verification pipeline synchronously or background
    await run_full_verification_pipeline(db, incident.id)

    # Refresh incident object
    db.refresh(incident)
    return IncidentResponse.model_validate(incident)

@router.post("/{incident_id}/verify")
async def trigger_incident_verification(
    incident_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    incident = get_incident_by_id(db, incident_id)
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    verification = await run_full_verification_pipeline(db, incident_id)
    return {"message": "Verification pipeline completed", "incident_id": incident_id, "risk_level": verification.risk_level}

@router.get("/my", response_model=List[IncidentResponse])
def list_my_incidents(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    incidents = get_user_incidents(db, current_user.id)
    return [IncidentResponse.model_validate(inc) for inc in incidents]

@router.get("/nearby", response_model=List[NearbyIncidentResponse])
def list_nearby_incidents(
    latitude: float,
    longitude: float,
    radius_km: float = 50.0,
    db: Session = Depends(get_db),
):
    return get_nearby_incidents(db, latitude, longitude, radius_km)

@router.get("/{incident_id}", response_model=IncidentResponse)
def get_incident_details(
    incident_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    incident = get_incident_by_id(db, incident_id)
    if not incident:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Incident not found"
        )
    return IncidentResponse.model_validate(incident)
