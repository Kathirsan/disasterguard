import enum
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, Enum, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.modules.incidents.models import HazardType

class WeatherSupportLevel(str, enum.Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"
    UNKNOWN = "UNKNOWN"

class HazardAgreement(str, enum.Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    MISMATCH = "MISMATCH"

class RiskLevel(str, enum.Enum):
    LOW = "LOW"
    MODERATE = "MODERATE"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

class IncidentVerification(Base):
    __tablename__ = "incident_verifications"

    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, unique=True, index=True)
    gps_valid = Column(Boolean, default=True, nullable=False)
    
    # Weather evidence
    weather_support = Column(Enum(WeatherSupportLevel), default=WeatherSupportLevel.UNKNOWN, nullable=False)
    weather_summary = Column(Text, nullable=True)
    
    # Report analysis & duplicates
    nearby_report_count = Column(Integer, default=0, nullable=False)
    is_possible_duplicate = Column(Boolean, default=False, nullable=False)
    duplicate_of_id = Column(Integer, ForeignKey("incidents.id"), nullable=True)
    cluster_id = Column(String(100), nullable=True, index=True)
    
    # AI Vision analysis
    ai_detected_hazard = Column(Enum(HazardType), nullable=True)
    ai_confidence = Column(Float, nullable=True)
    ai_severity = Column(String(50), nullable=True)  # LOW, MODERATE, HIGH, CRITICAL
    hazard_agreement = Column(Enum(HazardAgreement), nullable=True)
    ai_visible_evidence = Column(Text, nullable=True)
    ai_reasoning = Column(Text, nullable=True)
    
    # Combined Risk Assessment
    risk_score = Column(Integer, default=0, nullable=False)  # 0-100
    risk_level = Column(Enum(RiskLevel), default=RiskLevel.LOW, nullable=False, index=True)
    evidence_summary = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    incident = relationship("Incident", foreign_keys=[incident_id])
    duplicate_of = relationship("Incident", foreign_keys=[duplicate_of_id])

class WeatherObservation(Base):
    __tablename__ = "weather_observations"

    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    condition = Column(String(100), nullable=False)
    rainfall_mm = Column(Float, default=0.0, nullable=False)
    wind_speed_kmh = Column(Float, default=0.0, nullable=False)
    temperature_c = Column(Float, default=0.0, nullable=False)
    provider = Column(String(50), default="OpenMeteoFallback", nullable=False)
    weather_support = Column(Enum(WeatherSupportLevel), default=WeatherSupportLevel.UNKNOWN, nullable=False)
    observed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

class AIAssessment(Base):
    __tablename__ = "ai_assessments"

    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, index=True)
    detected_hazard = Column(Enum(HazardType), nullable=False)
    confidence = Column(Float, nullable=False)
    severity_estimate = Column(String(50), nullable=False)
    visible_evidence = Column(Text, nullable=False)
    reasoning_summary = Column(Text, nullable=False)
    hazard_agreement = Column(Enum(HazardAgreement), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

class IncidentCluster(Base):
    __tablename__ = "incident_clusters"

    id = Column(Integer, primary_key=True, index=True)
    cluster_id = Column(String(100), unique=True, index=True, nullable=False)
    hazard_type = Column(Enum(HazardType), nullable=False)
    report_count = Column(Integer, default=1, nullable=False)
    center_latitude = Column(Float, nullable=False)
    center_longitude = Column(Float, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

class IncidentStatusHistory(Base):
    __tablename__ = "incident_status_history"

    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, index=True)
    prev_status = Column(String(50), nullable=False)
    new_status = Column(String(50), nullable=False)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    actor_role = Column(String(50), default="SYSTEM", nullable=False)
    reason = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    actor = relationship("User")
