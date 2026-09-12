from sqlalchemy import Column, Integer, String, Text, DECIMAL, Enum, ForeignKey, TIMESTAMP, func
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(Enum("citizen", "officer", "responder", "admin"), default="citizen", nullable=False)
    phone = Column(String(20), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

    hazards = relationship("Hazard", back_populates="reporter", cascade="all, delete-orphan")


class Hazard(Base):
    __tablename__ = "hazards"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    category = Column(Enum("flood", "landslide", "fire", "storm", "other"), nullable=False)
    status = Column(Enum("reported", "verified", "in_progress", "resolved", "rejected"), default="reported", nullable=False)
    latitude = Column(DECIMAL(10, 8), nullable=False)
    longitude = Column(DECIMAL(11, 8), nullable=False)
    image_url = Column(String(255), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    reporter = relationship("User", back_populates="hazards")
    checks = relationship("HazardCheck", back_populates="hazard", cascade="all, delete-orphan")


class HazardCheck(Base):
    __tablename__ = "hazard_checks"

    id = Column(Integer, primary_key=True, index=True)
    hazard_id = Column(Integer, ForeignKey("hazards.id", ondelete="CASCADE"), nullable=False)
    confidence_score = Column(DECIMAL(4, 2), nullable=False)
    weather_match = Column(Enum("pass", "warn", "fail"), default="pass")
    duplicate_risk = Column(Enum("low", "medium", "high"), default="low")
    notes = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

    hazard = relationship("Hazard", back_populates="checks")


class IncidentTicket(Base):
    __tablename__ = "incident_tickets"

    id = Column(Integer, primary_key=True, index=True)
    hazard_id = Column(Integer, ForeignKey("hazards.id", ondelete="CASCADE"), nullable=False)
    officer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    crew_name = Column(String(100), nullable=False)
    ticket_status = Column(
        Enum("DISPATCHED", "IN_PROGRESS", "RESOLVED"),
        default="DISPATCHED",
        nullable=False
    )
    priority = Column(Enum("LOW", "MEDIUM", "HIGH", "CRITICAL"), default="HIGH", nullable=False)
    instructions = Column(Text, nullable=True)
    resolution_photo_url = Column(String(255), nullable=True)
    resolution_notes = Column(Text, nullable=True)
    dispatched_at = Column(TIMESTAMP, server_default=func.now())
    resolved_at = Column(TIMESTAMP, nullable=True)

    hazard = relationship("Hazard")
    officer = relationship("User")