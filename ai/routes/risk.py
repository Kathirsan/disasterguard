from fastapi import APIRouter
from pydantic import BaseModel
from typing import List
from services.risk_engine import calculate_severity

router = APIRouter()

class RiskAssessmentRequest(BaseModel):
    hazard_type: str
    confidence: float
    context: dict = None

class RiskAssessmentResponse(BaseModel):
    severity: str
    severity_calculated: bool
    risk_factors: List[str]

@router.post("/assess-risk", response_model=RiskAssessmentResponse)
async def assess_risk_endpoint(request: RiskAssessmentRequest):
    """
    Calculates the severity of a hazard based on its properties.
    """
    result = calculate_severity(request.hazard_type, request.confidence, request.context)
    return result
