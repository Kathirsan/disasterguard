from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import hazards

app = FastAPI(
    title="DisasterGuard API",
    description="AI-Powered Disaster Response & Hazard Verification Platform",
    version="1.0.0"
)

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(hazards.router)

@app.get("/", tags=["Health Check"])
def root():
    return {"status": "ok", "message": "DisasterGuard API is running"}