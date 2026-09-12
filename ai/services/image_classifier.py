import random
import time

def classify_image(image_url: str) -> dict:
    """
    Simulates classifying an image and extracting hazard properties.
    For demonstration, it hardcodes 'Flood' with 94% confidence.
    """
    # Simulate processing time
    time.sleep(1)
    
    return {
        "hazard_type": "Flood",
        "confidence": 0.94,
        "image_detected": True,
        "hazard_classified": True,
        "analysis_details": {
            "resolution": "4032x3024",
            "water_surface_segment": "68.4%",
            "severity_preliminary": "HIGH"
        }
    }
