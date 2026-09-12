from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.modules.incidents.models import HazardType

class Alert(Base):
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    hazard_type = Column(Enum(HazardType), nullable=False)
    risk_level = Column(String(50), nullable=False)  # LOW, MODERATE, HIGH, CRITICAL
    message = Column(Text, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    radius_km = Column(Float, default=10.0, nullable=False)
    issuing_authority_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    issuing_authority = relationship("User")
    incident = relationship("Incident")
