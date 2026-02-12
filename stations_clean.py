"""
Stations data cleaning and validation module.

This module provides utilities for cleaning and validating station data
from the staging CSV files and preparing it for database loading.

DEPRECATED: Use etl/transform/clean_stations.py instead.
This file is kept for backwards compatibility and reference only.
"""

import json
from pathlib import Path
from typing import List, Dict, Any, Optional

# Modern clean stations import (recommended)
try:
    from etl.transform.clean_stations import clean_stations_from_list
except ImportError:
    # Fallback if import fails
    def clean_stations_from_list(stations_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Fallback function - use etl/transform/clean_stations.py instead."""
        print("[WARN] Using fallback clean_stations function")
        return stations_data


def load_and_clean_stations_csv(csv_file: Optional[Path] = None) -> List[Dict[str, Any]]:
    """
    Load stations from staging CSV and return cleaned list of dicts.
    
    DEPRECATED: Use etl/transform/clean_stations.py::clean_stations_from_file instead.
    
    Args:
        csv_file: Path to staging CSV (defaults to etl/staging/stations_stage.csv)
    
    Returns:
        List of cleaned station dictionaries
    """
    if csv_file is None:
        csv_file = Path("etl/staging/stations_stage.csv")
    
    if not csv_file.exists():
        raise FileNotFoundError(f"Staging file not found: {csv_file}")
    
    # Import pandas only if available
    try:
        import pandas as pd
        df = pd.read_csv(csv_file)
        stations = df.to_dict(orient="records")
    except ImportError:
        # Fallback: manual CSV parsing
        import csv
        stations = []
        with open(csv_file, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            stations = list(reader)
    
    # Basic cleaning
    cleaned = []
    for station in stations:
        # Skip invalid records
        if not station.get("station_id"):
            continue
        
        # Normalize numeric fields
        try:
            lat = float(station.get("latitude") or 0)
            lon = float(station.get("longitude") or 0)
            if lat == 0 or lon == 0:
                continue  # Skip invalid coordinates
        except (ValueError, TypeError):
            continue
        
        cleaned.append(station)
    
    return cleaned


def validate_stations(stations: List[Dict[str, Any]]) -> tuple:
    """
    Validate list of stations.
    
    Returns:
        (valid_count, invalid_count, error_list)
    """
    valid = 0
    invalid = 0
    errors = []
    
    for idx, station in enumerate(stations):
        if not station.get("station_id"):
            invalid += 1
            errors.append(f"Row {idx}: Missing station_id")
            continue
        
        try:
            lat = float(station.get("latitude", 0))
            lon = float(station.get("longitude", 0))
            if lat < -90 or lat > 90 or lon < -180 or lon > 180:
                invalid += 1
                errors.append(f"Row {idx}: Invalid coordinates")
                continue
        except (ValueError, TypeError):
            invalid += 1
            errors.append(f"Row {idx}: Coordinate conversion failed")
            continue
        
        valid += 1
    
    return valid, invalid, errors


def export_clean_stations_json(stations: List[Dict[str, Any]], output_file: Optional[Path] = None) -> int:
    """
    Export cleaned stations to JSON file.
    
    DEPRECATED: Use etl/staging/staging_manager.py::stage_stations instead.
    
    Args:
        stations: List of station dictionaries
        output_file: Output path (defaults to data/processed/poi_clean.json)
    
    Returns:
        Number of records written
    """
    if output_file is None:
        output_file = Path("data/processed/poi_clean.json")
    
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(stations, f, ensure_ascii=False, indent=2)
    
    print(f"[OK] Exported {len(stations)} stations to {output_file}")
    return len(stations)


if __name__ == "__main__":
    # Example usage (for backwards compatibility)
    print("[*] Loading and cleaning stations from staging CSV...")
    
    try:
        stations = load_and_clean_stations_csv()
        print(f"[OK] Loaded {len(stations)} stations")
        
        valid, invalid, errors = validate_stations(stations)
        print(f"[OK] Validation: {valid} valid, {invalid} invalid")
        
        if errors:
            for error in errors[:5]:  # Show first 5 errors
                print(f"  [ERR] {error}")
        
        # Export to JSON
        n = export_clean_stations_json(stations)
        print(f"[OK] Pipeline complete: {n} stations processed")
    
    except Exception as e:
        print(f"[ERR] Error: {e}")

