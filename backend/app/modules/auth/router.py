from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.modules.auth.schemas import UserRegisterRequest, UserLoginRequest, TokenResponse, UserResponse
from app.modules.auth.service import register_user, authenticate_user
from app.api.dependencies import get_current_user
from app.modules.users.models import User
from app.core.security import create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(req: UserRegisterRequest, db: Session = Depends(get_db)):
    user = register_user(db, req)
    token = create_access_token(subject=user.id)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )

@router.post("/login", response_model=TokenResponse)
def login(req: UserLoginRequest, db: Session = Depends(get_db)):
    user, token = authenticate_user(db, req)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)
