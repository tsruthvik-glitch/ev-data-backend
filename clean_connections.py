# transform/clean_connections.py

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    import pandas as pd
except Exception:
    pd = None


PROCESSED_DIR = Path("data/processed")
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)


def clean_connections(raw_data: Any, output_path: Optional[str] = None, to_csv: bool = False) -> List[Dict[str, Any]]:
    """Clean and flatten connection records from raw POI JSON.

    raw_data may be a dict with 'ChargePoint' or a list of POI entries.
    Writes JSON to `data/processed/connections_clean.json` by default.
    Returns list of cleaned connection dicts.
    """
    # normalize input
    if isinstance(raw_data, dict):
        entries = raw_data.get("ChargePoint") or raw_data.get("POI") or [raw_data]
    elif isinstance(raw_data, list):
        entries = raw_data
    else:
        entries = []

    if isinstance(entries, dict):
        entries = [entries]

    records: List[Dict[str, Any]] = []
    for cp in entries:
        if not isinstance(cp, dict):
            continue
        station_id = cp.get("ID")
        connections = cp.get("Connections") or []
        for conn in connections:
            if not isinstance(conn, dict):
                continue
            connection_record: Dict[str, Any] = {
                "POI_ID": station_id,
                "ID": conn.get("ID"),
                "ConnectionTypeID": conn.get("ConnectionTypeID"),
                "ConnectionType": (conn.get("ConnectionType") or {}).get("Title") if isinstance(conn.get("ConnectionType"), dict) else conn.get("ConnectionType"),
                "PowerKW": conn.get("PowerKW"),
                "Voltage": conn.get("Voltage"),
                "Amps": conn.get("Amps"),
                "CurrentTypeID": conn.get("CurrentTypeID"),
                "CurrentType": (conn.get("CurrentType") or {}).get("Title") if isinstance(conn.get("CurrentType"), dict) else conn.get("CurrentType"),
                "LevelID": conn.get("LevelID"),
                "Level": (conn.get("Level") or {}).get("Title") if isinstance(conn.get("Level"), dict) else conn.get("Level"),
                "StatusTypeID": conn.get("StatusTypeID"),
                "Status": (conn.get("StatusType") or {}).get("Title") if isinstance(conn.get("StatusType"), dict) else conn.get("StatusType"),
                "Quantity": conn.get("Quantity") if conn.get("Quantity") is not None else 1,
                "Comments": conn.get("Comments"),
                "ETLLoadedAt": datetime.utcnow().isoformat(),
            }
            records.append(connection_record)

    # Filter invalid
    cleaned = [r for r in records if r.get("POI_ID") is not None]

    # Default output path
    output_json = Path(output_path) if output_path else PROCESSED_DIR / "connections_clean.json"
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    # Optionally write CSV if pandas available
    if to_csv and pd is not None:
        try:
            df = pd.DataFrame(cleaned)
            csv_path = output_json.with_suffix(".csv")
            df.to_csv(csv_path, index=False)
        except Exception:
            pass

    print(f"✅ Cleaned connections saved to: {output_json}")
    print(f"🔌 Total connections processed: {len(cleaned)}")
    return cleaned
