from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# --- Auth Schemas ---
class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: Optional[str] = "citizen"
    phone: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    role: str

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

# --- Hazard Schemas ---
class HazardCreate(BaseModel):
    title: str
    description: Optional[str] = None
    category: str
    latitude: float
    longitude: float
    image_url: Optional[str] = None

class HazardResponse(BaseModel):
    id: int
    user_id: int
    title: str
    description: Optional[str]
    category: str
    status: str
    latitude: float
    longitude: float
    image_url: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

# --- Case Builder Schema ---
class UnifiedCaseResponse(BaseModel):
    case_id: str
    hazard_id: int
    status: str
    category: str
    title: str
    description: Optional[str]
    evidence: dict
    geography: dict
    environmental_context: dict
    cross_validation: dict
    created_at: Optional[str]