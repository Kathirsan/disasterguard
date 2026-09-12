from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import image, risk

app = FastAPI(
    title="DisasterGuard AI Services",
    description="Microservice for handling AI analysis and risk assessment.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(image.router, prefix="/api/v1/image", tags=["Image Analysis"])
app.include_router(risk.router, prefix="/api/v1/risk", tags=["Risk Assessment"])

@app.get("/")
def read_root():
    return {"status": "AI Microservice is up and running"}
