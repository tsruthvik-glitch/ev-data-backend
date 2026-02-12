
import json
from pathlib import Path
from typing import Any, Dict
from sqlalchemy import text
from etl.db.db_utils import get_engine

DATA_FILE = Path("data/processed/connections_clean.json")

def _ensure_tables(engine):
    with engine.connect() as conn:
        conn.execute(text(
            """
            CREATE TABLE IF NOT EXISTS connections (
                id INT AUTO_INCREMENT PRIMARY KEY,
                station_id BIGINT,
                connection_id INT,
                connection_type VARCHAR(255),
                power_kw DOUBLE,
                voltage INT,
                current_type VARCHAR(50),
                quantity INT,
                status VARCHAR(50)
            )
            """
        ))
        conn.commit()

def _extract_connection_fields(entry: Dict[str, Any]) -> Dict[str, Any]:
    # entry expected to be a dict representing one connection; may include POI_ID
    conn_type = entry.get("ConnectionType") or {}
    current = entry.get("CurrentType") or {}
    status = entry.get("Status") or entry.get("StatusType")
    if isinstance(status, dict):
        status_val = status.get("Title")
    else:
        status_val = status

    return {
        "station_id": entry.get("POI_ID") or entry.get("StationID") or entry.get("station_id"),
        "connection_id": entry.get("ID"),
        "connection_type": conn_type.get("Title") if isinstance(conn_type, dict) else conn_type,
        "power_kw": entry.get("PowerKW"),
        "voltage": entry.get("Voltage"),
        "current_type": current.get("Title") if isinstance(current, dict) else current,
        "quantity": entry.get("Quantity"),
        "status": status_val,
    }

def load_connections_from_file(data_file: Path = DATA_FILE) -> int:
    """Load connections from cleaned JSON into the MySQL database."""
    if not data_file.exists():
        raise FileNotFoundError(f"Connections cleaned file not found: {data_file}")

    if data_file.stat().st_size == 0:
        raise ValueError(f"Connections cleaned file is empty: {data_file}")

    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError("Connections data must be a list of connection objects")

    engine = get_engine()
    _ensure_tables(engine)

    inserted = 0
    
    with engine.connect() as conn:
        # Remove existing connections to avoid duplicates on repeated loads (Full Reload Strategy)
        conn.execute(text("DELETE FROM connections"))
        
        for entry in data:
            if not isinstance(entry, dict):
                continue
            fields = _extract_connection_fields(entry)
            # require station_id and at least one identifying field
            if not fields["station_id"]:
                continue

            stmt = text(
                """
                INSERT INTO connections
                (station_id, connection_id, connection_type, power_kw, voltage, current_type, quantity, status)
                VALUES (:station_id, :connection_id, :connection_type, :power_kw, :voltage, :current_type, :quantity, :status)
                """
            )
            
            conn.execute(stmt, fields)
            inserted += 1
        
        conn.commit()

    return inserted

if __name__ == "__main__":
    try:
        n = load_connections_from_file()
        print(f"✅ Loaded {n} connections into MySQL database")
    except Exception as e:
        print(f"❌ Error loading connections: {e}")
