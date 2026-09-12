from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings

def get_db_engine():
    try:
        # Try primary MySQL database URL
        engine = create_engine(
            settings.DATABASE_URL,
            pool_pre_ping=True,
            pool_recycle=3600
        )
        # Test connection
        with engine.connect() as conn:
            pass
        return engine
    except Exception as e:
        print(f"[Database Config] MySQL connection failed ({e}). Falling back to SQLite dev database.")
        engine = create_engine(
            settings.SQLITE_URL,
            connect_args={"check_same_thread": False}
        )
        return engine

engine = get_db_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
