from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.all_models import Hazard, User
from app.schemas.all_schemas import HazardCreate, HazardResponse
from app.auth import get_current_user

router = APIRouter(prefix="/api/hazards", tags=["Citizen Hazards"])

@router.post("/", response_model=HazardResponse, status_code=status.HTTP_201_CREATED)
def create_hazard(
    hazard_data: HazardCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    hazard = Hazard(
        user_id=current_user.id,
        title=hazard_data.title,
        description=hazard_data.description,
        category=hazard_data.category,
        latitude=hazard_data.latitude,
        longitude=hazard_data.longitude,
        image_url=hazard_data.image_url
    )
    db.add(hazard)
    db.commit()
    db.refresh(hazard)
    return hazard

@router.get("/", response_model=List[HazardResponse])
def get_all_hazards(db: Session = Depends(get_db)):
    return db.query(Hazard).all()

@router.get("/{hazard_id}", response_model=HazardResponse)
def get_hazard_by_id(hazard_id: int, db: Session = Depends(get_db)):
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    if not hazard:
        raise HTTPException(status_code=404, detail="Hazard not found")
    return hazard