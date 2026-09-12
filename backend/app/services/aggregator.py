from typing import Dict, Any, List

def compute_aggregated_verdict(
    weather_result: Dict[str, Any],
    cluster_result: Dict[str, Any],
    ai_result: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Fuses Weather, Cluster, and Image AI signals into a final verdict,
    severity, urgency, and human-readable decision reasons.
    """
    reasons: List[str] = []

    # 1. Inspect Image AI
    ai_confidence = float(ai_result.get("confidence", 0.0))
    ai_severity = ai_result.get("severity", "LOW").upper()
    ai_hazard = ai_result.get("hazard", "hazard")

    if ai_confidence >= 0.70:
        reasons.append(f"{ai_hazard.capitalize()} detected in image ({int(ai_confidence * 100)}% confidence)")
    else:
        reasons.append(f"Low AI image confidence ({int(ai_confidence * 100)}%)")

    # 2. Inspect Weather Rules
    weather_level = weather_result.get("severity_level", "NORMAL").upper()
    rainfall = weather_result.get("rainfall_mm", 0.0)
    if weather_level in ["CRITICAL", "HIGH"]:
        reasons.append(f"Heavy rainfall and high water level ({rainfall} mm)")
    elif weather_level == "WARNING":
        reasons.append(f"Elevated rainfall ({rainfall} mm)")

    # 3. Inspect Proximity Clustering
    cluster_confirmed = cluster_result.get("cluster_confirmed", False)
    nearby_count = cluster_result.get("nearby_count", 0)
    if cluster_confirmed or nearby_count >= 2:
        reasons.append(f"Multiple nearby reports ({nearby_count} within {int(cluster_result.get('radius_meters', 200))}m)")

    # 4. Multi-signal Weighted Confidence Score
    # Weights: AI (50%), Weather (30%), Proximity (20%)
    weather_weight = 0.30 if weather_level in ["CRITICAL", "HIGH"] else (0.15 if weather_level == "WARNING" else 0.05)
    cluster_weight = 0.20 if cluster_confirmed else (0.10 if nearby_count > 0 else 0.0)
    ai_weight = ai_confidence * 0.50

    total_confidence = round(min(0.99, ai_weight + weather_weight + cluster_weight), 2)

    # 5. Determine Verdict
    if total_confidence >= 0.75 and ai_confidence >= 0.60:
        verdict = "CONFIRMED"
    elif total_confidence >= 0.50:
        verdict = "PROBABLE"
    else:
        verdict = "REJECTED"

    # 6. Determine Severity & Urgency
    if verdict == "CONFIRMED" and (weather_level in ["CRITICAL", "HIGH"] or ai_severity in ["CRITICAL", "HIGH"]):
        severity = "HIGH"
        urgency = "HIGH"
    elif verdict == "CONFIRMED" or weather_level == "WARNING":
        severity = "MEDIUM"
        urgency = "MEDIUM"
    else:
        severity = "LOW"
        urgency = "LOW"

    return {
        "verdict": verdict,
        "confidence": total_confidence,
        "severity": severity,
        "urgency": urgency,
        "reasons": reasons,
        "requires_alert": verdict == "CONFIRMED" and severity == "HIGH"
    }