import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.models import all_models  # Loads User, Hazard, HazardCheck
from app.routers import auth, hazards

# Auto-create tables in MySQL
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="DisasterGuard API",
    description="AI-Powered Disaster Response & Hazard Verification Platform",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(hazards.router)

@app.get("/", tags=["Health Check"])
def root():
    return {"status": "ok", "message": "DisasterGuard API is running"}