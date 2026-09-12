import math
import logging
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Tuple
from sqlalchemy.orm import Session

from app.modules.incidents.models import Incident, IncidentStatus, HazardType
from app.modules.incidents.service import haversine_distance
from app.modules.verification.models import (
    IncidentVerification,
    WeatherObservation,
    AIAssessment,
    IncidentCluster,
    IncidentStatusHistory,
    WeatherSupportLevel,
    HazardAgreement,
    RiskLevel,
)
from app.modules.verification.weather_service import fetch_weather_verification
from app.modules.verification.ai_service import analyze_incident_ai

logger = logging.getLogger("verification_service")

def record_status_change(
    db: Session,
    incident_id: int,
    prev_status: str,
    new_status: str,
    actor_id: Optional[int] = None,
    actor_role: str = "SYSTEM",
    reason: Optional[str] = None,
) -> IncidentStatusHistory:
    history = IncidentStatusHistory(
        incident_id=incident_id,
        prev_status=prev_status,
        new_status=new_status,
        actor_id=actor_id,
        actor_role=actor_role,
        reason=reason,
        created_at=datetime.now(timezone.utc),
    )
    db.add(history)
    db.commit()
    db.refresh(history)
    return history

def update_incident_status(
    db: Session,
    incident: Incident,
    new_status: IncidentStatus,
    actor_id: Optional[int] = None,
    actor_role: str = "SYSTEM",
    reason: Optional[str] = None,
) -> Incident:
    old_status = incident.status.value if isinstance(incident.status, IncidentStatus) else str(incident.status)
    incident.status = new_status
    db.commit()
    db.refresh(incident)
    
    record_status_change(
        db=db,
        incident_id=incident.id,
        prev_status=old_status,
        new_status=new_status.value,
        actor_id=actor_id,
        actor_role=actor_role,
        reason=reason,
    )
    return incident

def analyze_nearby_and_duplicates(
    db: Session, incident: Incident
) -> Tuple[int, bool, Optional[int], Optional[str]]:
    # Search incidents in last 24 hours excluding current incident
    all_incidents = (
        db.query(Incident)
        .filter(Incident.id != incident.id)
        .order_by(Incident.created_at.desc())
        .all()
    )

    nearby_count = 0
    is_duplicate = False
    duplicate_of_id = None

    for other in all_incidents:
        dist = haversine_distance(incident.latitude, incident.longitude, other.latitude, other.longitude)
        if dist <= 5.0:  # Within 5km
            nearby_count += 1
            if dist <= 0.5 and other.hazard_type == incident.hazard_type:
                is_duplicate = True
                if not duplicate_of_id:
                    duplicate_of_id = other.id

    # Cluster key based on hazard and rounded lat/lon (~1-2km grid)
    cluster_key = f"CLUSTER_{incident.hazard_type.value}_{round(incident.latitude, 2)}_{round(incident.longitude, 2)}"
    
    # Get or create cluster record
    cluster = db.query(IncidentCluster).filter(IncidentCluster.cluster_id == cluster_key).first()
    if not cluster:
        cluster = IncidentCluster(
            cluster_id=cluster_key,
            hazard_type=incident.hazard_type,
            report_count=1 + nearby_count,
            center_latitude=incident.latitude,
            center_longitude=incident.longitude,
        )
        db.add(cluster)
    else:
        cluster.report_count += 1
        cluster.updated_at = datetime.now(timezone.utc)
    
    db.commit()

    return nearby_count, is_duplicate, duplicate_of_id, cluster_key

def compute_combined_risk(
    gps_valid: bool,
    weather_obs: WeatherObservation,
    nearby_count: int,
    is_duplicate: bool,
    cluster_id: Optional[str],
    ai_assessment: AIAssessment,
) -> Tuple[int, RiskLevel, str]:
    score = 0
    bullets = []

    # 1. Location / GPS score
    if gps_valid:
        score += 10
        bullets.append("Valid GPS coordinates verified")
    else:
        bullets.append("WARNING: Invalid or suspicious GPS coordinates")

    # 2. AI Confidence & Severity
    ai_conf_score = int(ai_assessment.confidence * 30)  # Max 30 pts
    score += ai_conf_score
    bullets.append(f"AI vision confidence: {int(ai_assessment.confidence * 100)}% (+{ai_conf_score} pts)")

    sev = ai_assessment.severity_estimate.upper()
    if sev == "CRITICAL":
        score += 25
        bullets.append("AI vision assessed hazard as CRITICAL (+25 pts)")
    elif sev == "HIGH":
        score += 20
        bullets.append("AI vision assessed hazard as HIGH (+20 pts)")
    elif sev == "MODERATE":
        score += 10
        bullets.append("AI vision assessed hazard as MODERATE (+10 pts)")
    else:
        score += 5
        bullets.append("AI vision assessed hazard as LOW (+5 pts)")

    # 3. Weather Evidence
    ws = weather_obs.weather_support
    if ws == WeatherSupportLevel.HIGH:
        score += 20
        bullets.append(f"Severe weather correlation HIGH ({weather_obs.condition}, Rain: {weather_obs.rainfall_mm}mm, Wind: {weather_obs.wind_speed_kmh}km/h) (+20 pts)")
    elif ws == WeatherSupportLevel.MEDIUM:
        score += 10
        bullets.append(f"Weather evidence MODERATE ({weather_obs.condition}) (+10 pts)")
    else:
        bullets.append("Environmental weather support: Low/Normal")

    # 4. Nearby & Cluster evidence
    if nearby_count > 0:
        added = min(nearby_count * 5, 15)
        score += added
        bullets.append(f"{nearby_count} nearby incident reports within 5km (+{added} pts)")
    
    if is_duplicate:
        score += 5
        bullets.append("Multiple reports for same incident location detected (+5 pts)")

    if cluster_id:
        bullets.append(f"Assigned to regional hazard cluster '{cluster_id}'")

    # Cap score 0-100
    final_score = min(max(score, 0), 100)

    if final_score >= 80:
        level = RiskLevel.CRITICAL
    elif final_score >= 60:
        level = RiskLevel.HIGH
    elif final_score >= 40:
        level = RiskLevel.MODERATE
    else:
        level = RiskLevel.LOW

    evidence_str = "\n".join(f"• {b}" for b in bullets)
    return final_score, level, evidence_str

async def run_full_verification_pipeline(db: Session, incident_id: int) -> IncidentVerification:
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise ValueError(f"Incident {incident_id} not found")

    # 1. System Checking status
    update_incident_status(db, incident, IncidentStatus.SYSTEM_CHECKING)

    # 2. GPS Validation
    gps_valid = (-90.0 <= incident.latitude <= 90.0) and (-180.0 <= incident.longitude <= 180.0)

    # 3. Weather Verification
    weather_obs = await fetch_weather_verification(db, incident)

    # 4. Nearby Report & Duplicate Analysis & Clustering
    nearby_count, is_dup, dup_id, cluster_key = analyze_nearby_and_duplicates(db, incident)

    # 5. AI Analysis status
    update_incident_status(db, incident, IncidentStatus.AI_ANALYSIS)

    # 6. AI Vision Analysis
    ai_assessment = await analyze_incident_ai(db, incident)

    # 7. Combined Risk Assessment
    risk_score, risk_level, evidence_summary = compute_combined_risk(
        gps_valid=gps_valid,
        weather_obs=weather_obs,
        nearby_count=nearby_count,
        is_duplicate=is_dup,
        cluster_id=cluster_key,
        ai_assessment=ai_assessment,
    )

    # Check existing verification or create new (idempotent)
    verification = db.query(IncidentVerification).filter(IncidentVerification.incident_id == incident_id).first()
    if not verification:
        verification = IncidentVerification(incident_id=incident_id)
        db.add(verification)

    verification.gps_valid = gps_valid
    verification.weather_support = weather_obs.weather_support
    verification.weather_summary = f"{weather_obs.condition} ({weather_obs.rainfall_mm}mm rain, {weather_obs.wind_speed_kmh}km/h wind)"
    verification.nearby_report_count = nearby_count
    verification.is_possible_duplicate = is_dup
    verification.duplicate_of_id = dup_id
    verification.cluster_id = cluster_key
    verification.ai_detected_hazard = ai_assessment.detected_hazard
    verification.ai_confidence = ai_assessment.confidence
    verification.ai_severity = ai_assessment.severity_estimate
    verification.hazard_agreement = ai_assessment.hazard_agreement
    verification.ai_visible_evidence = ai_assessment.visible_evidence
    verification.ai_reasoning = ai_assessment.reasoning_summary
    verification.risk_score = risk_score
    verification.risk_level = risk_level
    verification.evidence_summary = evidence_summary

    db.commit()
    db.refresh(verification)

    # 8. Transition status to VERIFICATION_REQUIRED for Authority review
    update_incident_status(
        db, incident, IncidentStatus.VERIFICATION_REQUIRED, reason="Verification pipeline complete. Awaiting authority confirmation."
    )

    return verification
