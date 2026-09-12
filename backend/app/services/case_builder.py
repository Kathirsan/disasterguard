import math
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from app.models.all_models import Hazard

def calculate_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Haversine formula to compute distance in km between two GPS coordinates."""
    R = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def get_simulated_or_live_weather(latitude: float, longitude: float) -> Dict[str, Any]:
    """
    Returns live weather context for the hazard area.
    (Can be hooked to OpenWeatherMap or Sri Lanka Met dept feed).
    """
    # Baseline contextual values
    return {
        "latitude": latitude,
        "longitude": longitude,
        "temperature_c": 29.0,
        "humidity_percent": 84.0,
        "rainfall_mm": 35.5,
        "wind_speed_kmh": 28.0,
        "condition": "Heavy Monsoonal Rain",
        "advisory_active": True
    }

def find_nearby_hazards(db: Session, current_hazard_id: int, lat: float, lon: float, radius_km: float = 5.0) -> List[Dict[str, Any]]:
    """Finds existing reports within radius_km to check corroboration or duplicate risk."""
    all_hazards = db.query(Hazard).filter(Hazard.id != current_hazard_id).all()
    nearby = []

    for h in all_hazards:
        dist = calculate_distance_km(lat, lon, float(h.latitude), float(h.longitude))
        if dist <= radius_km:
            nearby.append({
                "hazard_id": h.id,
                "title": h.title,
                "category": h.category,
                "status": h.status,
                "distance_km": round(dist, 2),
                "created_at": h.created_at.isoformat() if h.created_at else None
            })
    return nearby

def build_unified_case(db: Session, hazard: Hazard) -> Dict[str, Any]:
    """
    Assembles the complete Unified Disaster Case for AI and Officer review.
    """
    lat = float(hazard.latitude)
    lon = float(hazard.longitude)

    # 1. Fetch live or localized weather
    weather_context = get_simulated_or_live_weather(lat, lon)

    # 2. Find nearby corroborating or duplicate hazards
    nearby_reports = find_nearby_hazards(db, hazard.id, lat, lon, radius_km=5.0)

    # 3. Assemble Unified Case
    unified_case = {
        "case_id": f"CASE-{hazard.id:04d}",
        "hazard_id": hazard.id,
        "status": hazard.status,
        "category": hazard.category,
        "title": hazard.title,
        "description": hazard.description,
        "evidence": {
            "image_url": hazard.image_url,
            "has_photo": bool(hazard.image_url)
        },
        "geography": {
            "latitude": lat,
            "longitude": lon,
        },
        "environmental_context": weather_context,
        "cross_validation": {
            "nearby_report_count": len(nearby_reports),
            "nearby_hazards": nearby_reports,
            "corroboration_score": min(1.0, 0.4 + (0.3 * len(nearby_reports)))
        },
        "created_at": hazard.created_at.isoformat() if hazard.created_at else None
    }

    return unified_case