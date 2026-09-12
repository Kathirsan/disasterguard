
import sqlite3
import os
from app.core.database import engine, Base

# Import all models
from app.modules.users.models import User
from app.modules.incidents.models import Incident, IncidentMedia
from app.modules.tickets.models import CouncilTicket, CrewAssignment, CrewProgressUpdate

db_path = os.path.join(os.path.dirname(__file__), "disasterguard_dev.db")

def run_migration():
    print(f"Migrating database at: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    columns_to_add = [
        ("incidents", "resolved_at", "DATETIME"),
        ("incidents", "closed_at", "DATETIME"),
        ("incident_media", "evidence_type", "VARCHAR(50) DEFAULT 'REPORT_EVIDENCE'"),
        ("crew_assignments", "accepted_at", "DATETIME"),
        ("crew_assignments", "started_at", "DATETIME"),
        ("crew_assignments", "completed_at", "DATETIME"),
    ]

    
    for table, col, col_type in columns_to_add:
        try:
            cursor.execute(f"ALTER TABLE {table} ADD COLUMN {col} {col_type};")
            print(f"Added column '{col}' to table '{table}'.")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e).lower():
                print(f"Column '{col}' already exists in table '{table}'.")
            else:
                print(f"Error adding {col} to {table}: {e}")

    conn.commit()
    conn.close()

    # Create new tables such as crew_updates
    Base.metadata.create_all(bind=engine)
    print("Database schema migration complete!")

if __name__ == "__main__":
    run_migration()
