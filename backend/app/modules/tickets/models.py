from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class CouncilTicket(Base):
    __tablename__ = "council_tickets"

    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String(50), unique=True, index=True, nullable=False)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, index=True)
    status = Column(String(50), default="OPEN", nullable=False)  # OPEN, IN_PROGRESS, RESOLVED, CLOSED
    priority = Column(String(50), default="HIGH", nullable=False)  # LOW, MEDIUM, HIGH, CRITICAL
    description = Column(Text, nullable=True)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    assigned_crew_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    created_by = relationship("User", foreign_keys=[created_by_id])
    assigned_crew = relationship("User", foreign_keys=[assigned_crew_id])
    incident = relationship("Incident")

class CrewAssignment(Base):
    __tablename__ = "crew_assignments"

    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, index=True)
    ticket_id = Column(Integer, ForeignKey("council_tickets.id"), nullable=False, index=True)
    assigned_crew_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    assigned_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String(50), default="ASSIGNED", nullable=False)  # ASSIGNED, ACCEPTED, IN_PROGRESS, COMPLETED, CANCELLED
    instructions = Column(Text, nullable=True)
    assigned_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    accepted_at = Column(DateTime, nullable=True)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)

    assigned_crew = relationship("User", foreign_keys=[assigned_crew_id])
    assigned_by = relationship("User", foreign_keys=[assigned_by_id])
    incident = relationship("Incident")
    ticket = relationship("CouncilTicket")

class CrewProgressUpdate(Base):
    __tablename__ = "crew_updates"

    id = Column(Integer, primary_key=True, index=True)
    assignment_id = Column(Integer, ForeignKey("crew_assignments.id"), nullable=False, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id"), nullable=False, index=True)
    crew_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    note = Column(Text, nullable=True)
    evidence_path = Column(String(500), nullable=True)
    update_type = Column(String(50), default="PROGRESS", nullable=False)  # PROGRESS, RESOLUTION
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    assignment = relationship("CrewAssignment")
    incident = relationship("Incident")
    crew = relationship("User")

