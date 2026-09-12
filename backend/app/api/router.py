from fastapi import APIRouter
from app.modules.auth.router import router as auth_router
from app.modules.incidents.router import router as incidents_router
from app.modules.authority.router import router as authority_router, alerts_router
from app.modules.crew.router import router as crew_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(incidents_router)
api_router.include_router(authority_router)
api_router.include_router(alerts_router)
api_router.include_router(crew_router)

