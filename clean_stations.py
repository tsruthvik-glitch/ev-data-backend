# transform/clean_stations.py

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    import pandas as pd  # optional, used for CSV output if available
except Exception:
    pd = None


PROCESSED_DIR = Path("data/processed")
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)


def clean_stations(raw_data: Any, output_path: Optional[str] = None, to_csv: bool = False) -> List[Dict[str, Any]]:
    """Clean and flatten station-level data from raw POI JSON.

    raw_data may be:
      - a list of POI entries (the API POI response)
      - a dict containing a 'ChargePoint' key with entries

    Writes JSON to `data/processed/poi_stations_clean.json` by default.
    If `to_csv=True` and pandas is available, a CSV is also written.

    Returns the list of cleaned station dicts.
    """
    # Normalize incoming structure to a list of entries
    if isinstance(raw_data, dict):
        # support different shapes
        if "ChargePoint" in raw_data:
            entries = raw_data.get("ChargePoint") or []
        elif "POI" in raw_data:
            entries = raw_data.get("POI") or []
        else:
            # assume it's a single entry dict
            entries = [raw_data]
    elif isinstance(raw_data, list):
        entries = raw_data
    else:
        entries = []

    # ensure entries is a list
    if isinstance(entries, dict):
        entries = [entries]

    stations: List[Dict[str, Any]] = []
    for cp in entries:
        if not isinstance(cp, dict):
            continue

        address = cp.get("AddressInfo") or {}
        operator = cp.get("OperatorInfo") or {}
        status = cp.get("StatusType") or {}
        usage = cp.get("UsageType") or {}

        station_record: Dict[str, Any] = {
            # Keep original POI structure keys to remain compatible with other steps
            "ID": cp.get("ID"),
            "UUID": cp.get("UUID"),
            "Title": address.get("Title") or cp.get("AddressInfo", {}).get("Title"),
            "OperatorInfo": operator,
            "AddressInfo": address,
            "UsageType": usage,
            "StatusType": status,
            "NumberOfPoints": cp.get("NumberOfPoints"),
            "DateCreated": cp.get("DateCreated"),
            "DateLastVerified": cp.get("DateLastVerified"),
            "ETLLoadedAt": datetime.utcnow().isoformat(),
        }

        # Add latitude/longitude directly for easy filtering
        station_record["Latitude"] = address.get("Latitude")
        station_record["Longitude"] = address.get("Longitude")

        stations.append(station_record)

    # Filter out entries without coordinates or without ID
    cleaned = [s for s in stations if s.get("ID") is not None and s.get("Latitude") is not None and s.get("Longitude") is not None]

    # Default output path
    output_json = Path(output_path) if output_path else PROCESSED_DIR / "poi_stations_clean.json"
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    # Optionally write CSV if pandas is available
    if to_csv and pd is not None:
        try:
            df = pd.DataFrame(cleaned)
            csv_path = output_json.with_suffix(".csv")
            df.to_csv(csv_path, index=False)
        except Exception:
            pass

    print(f"✅ Cleaned stations saved to: {output_json}")
    print(f"📊 Total stations processed: {len(cleaned)}")

    return cleaned
