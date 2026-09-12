from fastapi import APIRouter

router = APIRouter(prefix="/api/hazards", tags=["Citizen Hazards"])

@router.get("/")
def get_hazards():
    return {"message": "Hazards endpoint active"}