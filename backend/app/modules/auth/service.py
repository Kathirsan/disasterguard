from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.modules.users.models import User
from app.modules.auth.schemas import UserRegisterRequest, UserLoginRequest
from app.core.security import get_password_hash, verify_password, create_access_token

def register_user(db: Session, req: UserRegisterRequest) -> User:
    # Check duplicate email
    existing_user = db.query(User).filter(User.email == req.email.lower()).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email address already exists"
        )
    
    hashed_pwd = get_password_hash(req.password)
    new_user = User(
        full_name=req.full_name,
        email=req.email.lower(),
        hashed_password=hashed_pwd,
        role=req.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

def authenticate_user(db: Session, req: UserLoginRequest) -> tuple[User, str]:
    user = db.query(User).filter(User.email == req.email.lower()).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    if not verify_password(req.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
        
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled"
        )
        
    token = create_access_token(subject=user.id)
    return user, token
