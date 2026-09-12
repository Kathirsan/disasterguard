import math
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from app.models.all_models import Hazard

def evaluate_weather_severity(rainfall_mm: float, river_level_m: float) -> Dict[str, Any]:
    """
    Rule-based system check for weather & hydrological data.
    Levels: NORMAL, WARNING, HIGH, CRITICAL
    """
    # Critical threshold: extreme flood conditions
    if rainfall_mm >= 150.0 or river_level_m >= 5.0:
        level = "CRITICAL"
        message = "Severe flash flood danger. Immediate evacuation or deployment required."
    # High threshold: dangerous surge
    elif rainfall_mm >= 100.0 or river_level_m >= 4.0:
        level = "HIGH"
        message = "High flood risk. Water levels reaching dangerous limits."
    # Warning threshold: moderate rain / rising water
    elif rainfall_mm >= 50.0 or river_level_m >= 2.5:
        level = "WARNING"
        message = "Weather warning active. Monsoonal accumulation observed."
    else:
        level = "NORMAL"
        message = "Weather parameters within standard safety limits."

    return {
        "rainfall_mm": rainfall_mm,
        "river_level_m": river_level_m,
        "severity_level": level,
        "alert_message": message
    }

def calculate_haversine_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates distance between two GPS coordinates in meters."""
    R = 6371000.0  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (math.sin(delta_phi / 2.0) ** 2 +
         math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2)
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c

def evaluate_cluster_check(
    db: Session,
    current_hazard_id: int,
    lat: float,
    lon: float,
    radius_meters: float = 200.0,
    cluster_threshold: int = 3
) -> Dict[str, Any]:
    """
    Rule-based spatial cluster detection.
    Identifies if a report is part of a dense incident cluster within a set radius (default 200m).
    """
    all_hazards = db.query(Hazard).filter(Hazard.id != current_hazard_id).all()
    nearby_reports: List[Dict[str, Any]] = []

    for h in all_hazards:
        dist_m = calculate_haversine_meters(lat, lon, float(h.latitude), float(h.longitude))
        if dist_m <= radius_meters:
            nearby_reports.append({
                "hazard_id": h.id,
                "title": h.title,
                "category": h.category,
                "distance_meters": round(dist_m, 1)
            })

    report_count = len(nearby_reports)
    is_cluster = report_count >= cluster_threshold

    return {
        "radius_meters": radius_meters,
        "nearby_count": report_count,
        "threshold_required": cluster_threshold,
        "cluster_confirmed": is_cluster,
        "cluster_density": "HIGH" if report_count >= 5 else ("MODERATE" if is_cluster else "LOW"),
        "nearby_hazards": nearby_reports
    }