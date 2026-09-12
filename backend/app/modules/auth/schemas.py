from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from app.modules.users.models import UserRole

class UserRegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=100)
    role: UserRole = UserRole.CITIZEN

class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    role: UserRole
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
