import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.core.database import engine, Base
from app.api.router import api_router

# Import models so SQLAlchemy creates tables
from app.modules.users.models import User  # noqa
from app.modules.incidents.models import Incident, IncidentMedia  # noqa
from app.modules.verification.models import (  # noqa
    IncidentVerification,
    WeatherObservation,
    AIAssessment,
    IncidentCluster,
    IncidentStatusHistory,
)
from app.modules.alerts.models import Alert  # noqa
from app.modules.tickets.models import CouncilTicket, CrewAssignment, CrewProgressUpdate  # noqa

# Create database tables automatically on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Ensure uploads directory exists and mount static files
uploads_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "uploads"))
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

# Allow all origins during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {
        "status": "online",
        "app": "DisasterGuard API",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
