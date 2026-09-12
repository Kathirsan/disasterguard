import os
import math
import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import UploadFile, HTTPException, status
from app.modules.incidents.models import Incident, IncidentMedia, HazardType, IncidentStatus
from app.modules.incidents.schemas import NearbyIncidentResponse

UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "uploads"))
os.makedirs(UPLOAD_DIR, exist_ok=True)

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    # Earth radius in kilometers
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

async def save_upload_file(file: UploadFile) -> str:
    ext = os.path.splitext(file.filename or "")[1] or ".jpg"
    filename = f"{uuid.uuid4().hex}{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    content = await file.read()
    if len(content) > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size exceeds maximum 10MB limit"
        )

    with open(filepath, "wb") as f:
        f.write(content)

    return f"/uploads/{filename}"

async def create_incident(
    db: Session,
    reporter_id: int,
    hazard_type: HazardType,
    description: str,
    latitude: float,
    longitude: float,
    address_text: Optional[str] = None,
    file: Optional[UploadFile] = None,
) -> Incident:
    new_incident = Incident(
        reporter_id=reporter_id,
        hazard_type=hazard_type,
        description=description,
        latitude=latitude,
        longitude=longitude,
        address_text=address_text,
        status=IncidentStatus.SUBMITTED,
    )
    db.add(new_incident)
    db.commit()
    db.refresh(new_incident)

    if file:
        file_url = await save_upload_file(file)
        media = IncidentMedia(
            incident_id=new_incident.id,
            file_path=file_url,
            media_type=file.content_type or "image/jpeg",
        )
        db.add(media)
        db.commit()
        db.refresh(new_incident)

    return new_incident

def get_user_incidents(db: Session, user_id: int) -> List[Incident]:
    return (
        db.query(Incident)
        .filter(Incident.reporter_id == user_id)
        .order_by(Incident.created_at.desc())
        .all()
    )

def get_incident_by_id(db: Session, incident_id: int) -> Optional[Incident]:
    return db.query(Incident).filter(Incident.id == incident_id).first()

def get_nearby_incidents(
    db: Session, latitude: float, longitude: float, radius_km: float = 25.0
) -> List[dict]:
    all_incidents = db.query(Incident).order_by(Incident.created_at.desc()).all()
    nearby = []

    for inc in all_incidents:
        dist = haversine_distance(latitude, longitude, inc.latitude, inc.longitude)
        if dist <= radius_km:
            primary_img = inc.media[0].file_path if inc.media else None
            nearby.append({
                "id": inc.id,
                "hazard_type": inc.hazard_type,
                "description": inc.description,
                "latitude": inc.latitude,
                "longitude": inc.longitude,
                "address_text": inc.address_text,
                "status": inc.status,
                "created_at": inc.created_at,
                "distance_km": round(dist, 2),
                "primary_image_url": primary_img,
            })

    return sorted(nearby, key=lambda x: x["distance_km"])
