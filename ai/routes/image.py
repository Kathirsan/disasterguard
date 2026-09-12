from fastapi import APIRouter
from pydantic import BaseModel
from services.image_classifier import classify_image

router = APIRouter()

class ImageAnalysisRequest(BaseModel):
    image_url: str
    incident_id: str = None

class ImageAnalysisResponse(BaseModel):
    hazard_type: str
    confidence: float
    image_detected: bool
    hazard_classified: bool
    analysis_details: dict

@router.post("/analyze-image", response_model=ImageAnalysisResponse)
async def analyze_image_endpoint(request: ImageAnalysisRequest):
    """
    Analyzes an uploaded image (via URL) and returns the hazard classification.
    """
    result = classify_image(request.image_url)
    return result
