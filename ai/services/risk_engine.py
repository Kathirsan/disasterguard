import random
import time

def calculate_severity(hazard_type: str, confidence: float, context: dict = None) -> dict:
    """
    Simulates the Risk Engine calculating severity based on hazard type and confidence.
    For demonstration, returns HIGH severity.
    """
    # Simulate processing time
    time.sleep(1)
    
    severity = "HIGH"
    if hazard_type.lower() == "flood" and confidence > 0.90:
        severity = "HIGH"
    elif confidence < 0.50:
        severity = "LOW"
    
    return {
        "severity": severity,
        "severity_calculated": True,
        "risk_factors": [
            "High confidence in computer vision model",
            "Water level threshold exceeded",
            "Proximity to populated area"
        ]
    }
