"""
Staging area management for cleaned ETL data.

Handles:
- Stations staging
- Connections staging
- Reference data staging
"""

import csv
import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from etl.transform.validators import validate_station, validate_connection, validate_reference_item
from etl.transform.utils import log_info, log_error, log_success, ProgressTracker


STAGING_DIR = Path("etl/staging")
STAGING_DIR.mkdir(parents=True, exist_ok=True)


# ===========================
# Stations Staging
# ===========================

def stage_stations(stations_data: List[Dict[str, Any]], output_file: Optional[Path] = None) -> int:
    """Stage cleaned stations to CSV.
    
    Returns number of records written.
    """
    if output_file is None:
        output_file = STAGING_DIR / "stations_stage.csv"
    
    # Validate and filter
    valid_stations = []
    errors = []
    
    for idx, station in enumerate(stations_data):
        is_ok, error_msg = validate_station(station, strict=True)
        if is_ok:
            valid_stations.append(station)
        else:
            errors.append((idx, error_msg))
    
    if errors:
        log_error(f"Found {len(errors)} invalid stations during staging")
    
    # Flatten and prepare for CSV
    records = []
    for station in valid_stations:
        addr = station.get("AddressInfo") or {}
        operator = station.get("OperatorInfo") or {}
        status = station.get("StatusType") or {}
        usage = station.get("UsageType") or {}
        
        record = {
            "station_id": station.get("ID"),
            "uuid": station.get("UUID"),
            "operator_id": operator.get("ID"),
            "operator_name": operator.get("Title"),
            "usage_type_id": usage.get("ID"),
            "usage_type": usage.get("Title"),
            "status_type_id": status.get("ID"),
            "status": status.get("Title"),
            "station_name": addr.get("Title") or station.get("Title"),
            "address_line1": addr.get("AddressLine1"),
            "town": addr.get("Town"),
            "state": addr.get("StateOrProvince"),
            "postcode": addr.get("Postcode"),
            "country_id": addr.get("CountryID"),
            "latitude": addr.get("Latitude"),
            "longitude": addr.get("Longitude"),
            "number_of_points": station.get("NumberOfPoints"),
            "date_last_verified": station.get("DateLastVerified"),
            "date_created": station.get("DateCreated"),
            "etl_staged_at": datetime.utcnow().isoformat(),
        }
        records.append(record)
    
    # Write CSV
    if records:
        fieldnames = list(records[0].keys())
        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(records)
    
    log_success(f"Staged {len(records)} stations to {output_file}")
    return len(records)


# ===========================
# Connections Staging
# ===========================

def stage_connections(connections_data: List[Dict[str, Any]], output_file: Optional[Path] = None) -> int:
    """Stage cleaned connections to CSV.
    
    Returns number of records written.
    """
    if output_file is None:
        output_file = STAGING_DIR / "connections_stage.csv"
    
    # Validate and filter
    valid_conns = []
    errors = []
    
    for idx, conn in enumerate(connections_data):
        is_ok, error_msg = validate_connection(conn, strict=False)
        if is_ok:
            valid_conns.append(conn)
        else:
            errors.append((idx, error_msg))
    
    if errors:
        log_error(f"Found {len(errors)} invalid connections during staging")
    
    # Flatten for CSV
    records = []
    for conn in valid_conns:
        record = {
            "poi_id": conn.get("POI_ID"),
            "connection_id": conn.get("ID"),
            "connection_type_id": conn.get("ConnectionTypeID"),
            "connection_type": conn.get("ConnectionType"),
            "power_kw": conn.get("PowerKW"),
            "voltage": conn.get("Voltage"),
            "amps": conn.get("Amps"),
            "current_type_id": conn.get("CurrentTypeID"),
            "current_type": conn.get("CurrentType"),
            "level_id": conn.get("LevelID"),
            "level": conn.get("Level"),
            "status_type_id": conn.get("StatusTypeID"),
            "status": conn.get("Status"),
            "quantity": conn.get("Quantity"),
            "comments": conn.get("Comments"),
            "etl_staged_at": datetime.utcnow().isoformat(),
        }
        records.append(record)
    
    # Write CSV
    if records:
        fieldnames = list(records[0].keys())
        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(records)
    
    log_success(f"Staged {len(records)} connections to {output_file}")
    return len(records)


# ===========================
# Reference Data Staging
# ===========================

def stage_reference_data(ref_data: Dict[str, List[Dict[str, Any]]], output_dir: Optional[Path] = None) -> Dict[str, int]:
    """Stage reference tables to separate CSVs.
    
    Returns dict of {table_name: record_count}
    """
    if output_dir is None:
        output_dir = STAGING_DIR
    
    results = {}
    
    for table_name, records in ref_data.items():
        if not records:
            continue
        
        # Validate
        valid = []
        errors = []
        required_fields = ["ID", "Title"] if "ID" in records[0] else []
        
        for idx, rec in enumerate(records):
            is_ok, error_msg = validate_reference_item(rec, required_fields, optional_fields=list(rec.keys()))
            if is_ok:
                valid.append(rec)
            else:
                errors.append((idx, error_msg))
        
        if errors:
            log_error(f"Found {len(errors)} invalid records in {table_name}")
        
        # Write CSV
        if valid:
            output_file = output_dir / f"reference_{table_name.lower()}_stage.csv"
            fieldnames = list(valid[0].keys())
            with open(output_file, "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(valid)
            results[table_name] = len(valid)
            log_success(f"Staged {len(valid)} records to {output_file}")
    
    return results


# ===========================
# Staging Inspection
# ===========================

def count_staged_records(staging_dir: Optional[Path] = None) -> Dict[str, int]:
    """Count records in all staging CSVs."""
    if staging_dir is None:
        staging_dir = STAGING_DIR
    
    counts = {}
    for csv_file in staging_dir.glob("*_stage.csv"):
        try:
            with open(csv_file, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                count = sum(1 for _ in reader)
                counts[csv_file.stem] = count
        except Exception as e:
            log_error(f"Failed to count {csv_file}: {e}")
    
    return counts


def clear_staging(staging_dir: Optional[Path] = None) -> int:
    """Delete all staging CSVs. Returns count deleted."""
    if staging_dir is None:
        staging_dir = STAGING_DIR
    
    deleted = 0
    for csv_file in staging_dir.glob("*_stage.csv"):
        try:
            csv_file.unlink()
            deleted += 1
        except Exception as e:
            log_error(f"Failed to delete {csv_file}: {e}")
    
    return deleted


if __name__ == "__main__":
    # Example: inspect current staging
    counts = count_staged_records()
    print("\n[*] Staging Area Summary:")
    for name, count in counts.items():
        print(f"  {name}: {count} records")
