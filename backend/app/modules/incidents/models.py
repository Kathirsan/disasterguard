import enum
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, Enum, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class HazardType(str, enum.Enum):
    FLOOD = "FLOOD"
    BLOCKED_ROAD = "BLOCKED_ROAD"
    FALLEN_TREE = "FALLEN_TREE"
    OTHER = "OTHER"

class IncidentStatus(str, enum.Enum):
    SUBMITTED = "SUBMITTED"
    SYSTEM_CHECKING = "SYSTEM_CHECKING"
    AI_ANALYSIS = "AI_ANALYSIS"
    VERIFICATION_REQUIRED = "VERIFICATION_REQUIRED"
    VERIFIED = "VERIFIED"
    REJECTED = "REJECTED"
    DISPATCHED = "DISPATCHED"
    IN_PROGRESS = "IN_PROGRESS"
    RESOLVED = "RESOLVED"
    CLOSED = "CLOSED"

class Incident(Base):
    __tablename__ = "incidents"

    id = Column(Integer, primary_key=True, index=True)
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    hazard_type = Column(Enum(HazardType), nullable=False)
    description = Column(Text, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address_text = Column(String(255), nullable=True)
    status = Column(Enum(IncidentStatus), default=IncidentStatus.SUBMITTED, nullable=False, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    resolved_at = Column(DateTime, nullable=True)
    closed_at = Column(DateTime, nullable=True)

    media = relationship("IncidentMedia", back_populates="incident", cascade="all, delete-orphan")

class IncidentMedia(Base):
    __tablename__ = "incident_media"

    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, index=True)
    file_path = Column(String(500), nullable=False)
    media_type = Column(String(50), default="image/jpeg", nullable=False)
    evidence_type = Column(String(50), default="REPORT_EVIDENCE", nullable=False)  # REPORT_EVIDENCE, PROGRESS_EVIDENCE, RESOLUTION_EVIDENCE
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    incident = relationship("Incident", back_populates="media")
