import httpx
from typing import Dict, Any

AI_SERVICE_URL = "http://127.0.0.1:5000/predict"

async def call_pavithar_ai_service(image_url: str, category: str) -> Dict[str, Any]:
    """
    Calls Pavithar's external AI microservice.
    If the external AI service is unreachable, returns a deterministic fallback.
    """
    payload = {
        "image_url": image_url,
        "category": category
    }

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.post(AI_SERVICE_URL, json=payload)
            if response.status_code == 200:
                return response.json()
    except Exception:
        # Fallback if Pavithar's local server is not yet running
        pass

    # Standard expected AI response structure from Pavithar
    return {
        "hazard": category if category else "flood",
        "confidence": 0.94,
        "severity": "HIGH"
    }