import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "DisasterGuard API"
    API_V1_STR: str = "/api/v1"
    
    # Database Configuration (MySQL default with SQLite fallback for seamless local execution)
    MYSQL_USER: str = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD: str = os.getenv("MYSQL_PASSWORD", "password")
    MYSQL_HOST: str = os.getenv("MYSQL_HOST", "localhost")
    MYSQL_PORT: str = os.getenv("MYSQL_PORT", "3306")
    MYSQL_DB: str = os.getenv("MYSQL_DB", "disasterguard")
    
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"
    )
    # Fallback to local SQLite if MySQL connection fails in dev environment
    SQLITE_URL: str = "sqlite:///./disasterguard_dev.db"

    # JWT Configuration
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "disasterguard_super_secret_key_2026_change_in_production")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    class Config:
        case_sensitive = True

settings = Settings()
