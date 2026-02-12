
import json
from pathlib import Path
from typing import Any, Dict
from sqlalchemy import text
from etl.db.db_utils import get_engine

DATA_FILE = Path("data/processed/poi_clean.json")

def _ensure_tables(engine):
    with engine.connect() as conn:
        conn.execute(text(
            """
            CREATE TABLE IF NOT EXISTS stations (
                station_id BIGINT PRIMARY KEY,
                uuid VARCHAR(255),
                name VARCHAR(255),
                city VARCHAR(255),
                latitude DOUBLE,
                longitude DOUBLE,
                status VARCHAR(50),
                number_of_points INT,
                date_created DATETIME
            )
            """
        ))
        conn.commit()


from dateutil import parser as date_parser

def _extract_station_fields(entry: Dict[str, Any]) -> Dict[str, Any]:
    addr = entry.get("AddressInfo") or {}
    status = entry.get("StatusType") or {}
    
    date_created_str = entry.get("DateCreated")
    date_created_val = None
    if date_created_str:
        try:
            # Parse ISO string and standardise to YYYY-MM-DD HH:MM:SS
            dt = date_parser.parse(date_created_str)
            date_created_val = dt.strftime('%Y-%m-%d %H:%M:%S')
        except Exception:
            date_created_val = None

    return {
        "station_id": entry.get("ID"),
        "uuid": entry.get("UUID"),
        "name": addr.get("Title") or (entry.get("OperatorInfo") or {}).get("Title") or (entry.get("DataProvider") or {}).get("Title"),
        "city": addr.get("Town"),
        "latitude": addr.get("Latitude"),
        "longitude": addr.get("Longitude"),
        "status": status.get("Title"),
        "number_of_points": entry.get("NumberOfPoints"),
        "date_created": date_created_val
    }

def load_stations_from_file(data_file: Path = DATA_FILE) -> int:
    """Load stations from cleaned JSON file into MySQL database."""
    if not data_file.exists():
        raise FileNotFoundError(f"POI cleaned file not found: {data_file}")

    if data_file.stat().st_size == 0:
        raise ValueError(f"POI cleaned file is empty: {data_file}")

    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError("POI data must be a list of station objects")

    engine = get_engine()
    _ensure_tables(engine)

    inserted = 0
    
    # We will use a list of dicts to insert in bulk if possible, but for 'REPLACE INTO' across dialects it's tricky.
    # MySQL supports REPLACE INTO.
    
    with engine.connect() as conn:
        for entry in data:
            if not isinstance(entry, dict):
                continue
            fields = _extract_station_fields(entry)
            if not fields["station_id"]:
                continue

            # MySQL syntax: REPLACE INTO
            stmt = text(
                """
                REPLACE INTO stations
                (station_id, uuid, name, city, latitude, longitude, status, number_of_points, date_created)
                VALUES (:station_id, :uuid, :name, :city, :latitude, :longitude, :status, :number_of_points, :date_created)
                """
            )
            
            conn.execute(stmt, fields)
            inserted += 1
        
        conn.commit()

    return inserted

if __name__ == "__main__":
    try:
        n = load_stations_from_file()
        print(f"✅ Loaded {n} stations into MySQL database")
    except Exception as e:
        print(f"❌ Error loading stations: {e}")
