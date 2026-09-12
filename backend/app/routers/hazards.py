from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.schemas.all_schemas import AggregatorResponse
from app.services.aggregator import compute_aggregated_verdict

from app.database import get_db
from app.models.all_models import Hazard, User, HazardCheck
from app.schemas.all_schemas import (
    HazardCreate,
    HazardResponse,
    UnifiedCaseResponse,
    WeatherCheckResponse,
    ClusterCheckResponse,
    FullSystemCheckResponse,
    AIAnalysisCompleteResponse,
)
from app.auth import get_current_user
from app.services.case_builder import build_unified_case
from app.services.system_checks import evaluate_weather_severity, evaluate_cluster_check
from app.services.verification import call_pavithar_ai_service

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

@router.get("/checks/weather", response_model=WeatherCheckResponse)
def check_weather_rule(rainfall_mm: float = 145.0, river_level_m: float = 4.8):
    """
    Evaluates weather rule-based severity: NORMAL, WARNING, HIGH, or CRITICAL.
    """
    return evaluate_weather_severity(rainfall_mm, river_level_m)

@router.get("/{hazard_id}", response_model=HazardResponse)
def get_hazard_by_id(hazard_id: int, db: Session = Depends(get_db)):
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    if not hazard:
        raise HTTPException(status_code=404, detail="Hazard not found")
    return hazard

@router.get("/{hazard_id}/case", response_model=UnifiedCaseResponse)
def get_hazard_unified_case(hazard_id: int, db: Session = Depends(get_db)):
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    if not hazard:
        raise HTTPException(status_code=404, detail="Hazard not found")
    return build_unified_case(db=db, hazard=hazard)

@router.get("/{hazard_id}/checks/cluster", response_model=ClusterCheckResponse)
def check_hazard_cluster(
    hazard_id: int,
    radius_meters: float = 200.0,
    threshold: int = 3,
    db: Session = Depends(get_db)
):
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    if not hazard:
        raise HTTPException(status_code=404, detail="Hazard not found")

    result = evaluate_cluster_check(
        db=db,
        current_hazard_id=hazard.id,
        lat=float(hazard.latitude),
        lon=float(hazard.longitude),
        radius_meters=radius_meters,
        cluster_threshold=threshold
    )
    result["hazard_id"] = hazard.id
    return result

@router.get("/{hazard_id}/checks/system", response_model=FullSystemCheckResponse)
def run_all_system_checks(
    hazard_id: int,
    rainfall_mm: float = 145.0,
    river_level_m: float = 4.8,
    db: Session = Depends(get_db)
):
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    if not hazard:
        raise HTTPException(status_code=404, detail="Hazard not found")

    weather_res = evaluate_weather_severity(rainfall_mm, river_level_m)
    cluster_res = evaluate_cluster_check(
        db=db,
        current_hazard_id=hazard.id,
        lat=float(hazard.latitude),
        lon=float(hazard.longitude),
        radius_meters=200.0,
        cluster_threshold=3
    )
    cluster_res["hazard_id"] = hazard.id

    if weather_res["severity_level"] in ["CRITICAL", "HIGH"] or cluster_res["cluster_confirmed"]:
        verdict = "PRIORITY_DISPATCH"
    elif weather_res["severity_level"] == "WARNING":
        verdict = "MONITOR_CLOSELY"
    else:
        verdict = "STANDARD_REVIEW"

    return {
        "hazard_id": hazard.id,
        "weather_check": weather_res,
        "cluster_check": cluster_res,
        "system_verdict": verdict
    }

@router.post("/{hazard_id}/analyze-ai", response_model=AIAnalysisCompleteResponse)
async def analyze_hazard_with_ai(hazard_id: int, db: Session = Depends(get_db)):
    """
    Connects to Pavithar's AI service, analyzes the hazard photo,
    updates hazard status, and logs the result into hazard_checks.
    """
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    if not hazard:
        raise HTTPException(status_code=404, detail="Hazard not found")

    ai_result = await call_pavithar_ai_service(
        image_url=hazard.image_url or "",
        category=hazard.category
    )

    confidence = float(ai_result.get("confidence", 0.0))
    severity = ai_result.get("severity", "LOW")
    detected_hazard = ai_result.get("hazard", "")

    if confidence >= 0.75:
        hazard.status = "verified"
    else:
        hazard.status = "reported"

    check_entry = HazardCheck(
        hazard_id=hazard.id,
        confidence_score=confidence,
        weather_match="pass",
        duplicate_risk="low",
        notes=f"AI confirmed: {detected_hazard} with severity {severity}"
    )
    db.add(check_entry)
    db.commit()
    db.refresh(hazard)

    return {
        "hazard_id": hazard.id,
        "new_status": hazard.status,
        "ai_verdict": {
            "hazard": detected_hazard,
            "confidence": confidence,
            "severity": severity
        },
        "weather_match": "pass",
        "duplicate_risk": "low",
        "notes": check_entry.notes
    }

@router.post("/{hazard_id}/aggregate", response_model=AggregatorResponse)
async def run_hazard_aggregator(
    hazard_id: int,
    rainfall_mm: float = 145.0,
    river_level_m: float = 4.8,
    db: Session = Depends(get_db)
):
    """
    Executes Weather Check + Cluster Check + Image AI,
    aggregates the signals, updates hazard status, and logs the decision.
    """
    hazard = db.query(Hazard).filter(Hazard.id == hazard_id).first()
    if not hazard:
        raise HTTPException(status_code=404, detail="Hazard not found")

    # 1. Run Weather Check
    weather_res = evaluate_weather_severity(rainfall_mm, river_level_m)

    # 2. Run Spatial Cluster Check (200m)
    cluster_res = evaluate_cluster_check(
        db=db,
        current_hazard_id=hazard.id,
        lat=float(hazard.latitude),
        lon=float(hazard.longitude),
        radius_meters=200.0,
        cluster_threshold=2
    )

    # 3. Fetch Image AI Verification
    ai_res = await call_pavithar_ai_service(
        image_url=hazard.image_url or "",
        category=hazard.category
    )

    # 4. Synthesize via Aggregator Engine
    aggregated = compute_aggregated_verdict(weather_res, cluster_res, ai_res)

    # 5. Persist Status Transition
    if aggregated["verdict"] == "CONFIRMED":
        hazard.status = "verified"
    elif aggregated["verdict"] == "REJECTED":
        hazard.status = "rejected"
    else:
        hazard.status = "reported"

    # 6. Audit to hazard_checks
    check_entry = HazardCheck(
        hazard_id=hazard.id,
        confidence_score=aggregated["confidence"],
        weather_match="pass" if weather_res["severity_level"] != "CRITICAL" else "warn",
        duplicate_risk="high" if cluster_res["cluster_confirmed"] else "low",
        notes="; ".join(aggregated["reasons"])
    )
    db.add(check_entry)
    db.commit()
    db.refresh(hazard)

    return {
        "hazard_id": hazard.id,
        "verdict": aggregated["verdict"],
        "confidence": aggregated["confidence"],
        "severity": aggregated["severity"],
        "urgency": aggregated["urgency"],
        "reasons": aggregated["reasons"],
        "requires_alert": aggregated["requires_alert"],
        "status_updated": hazard.status
    }