# transform/clean_reference.py

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


def clean_reference_data(raw_json: Dict[str, Any], output_path: Optional[str] = None, to_csv: bool = False) -> Dict[str, List[Dict[str, Any]]]:
    """Clean and normalize all reference datasets from raw JSON.

    Handles: ConnectionTypes, StatusTypes, UsageTypes, SubmissionStatusTypes,
    UserCommentTypes, CheckinStatusTypes, DataTypes, MetadataGroups.

    Writes JSON to `data/processed/reference_clean.json` by default.
    Optionally writes per-table CSVs if `to_csv=True` and pandas is available.

    Returns dict of {table_name: [records]}
    """
    cleaned: Dict[str, List[Dict[str, Any]]] = {}

    # Simple reference tables with ID and Title
    simple_tables = {
        "ConnectionTypes": ["ID", "Title", "FormalName", "IsDiscontinued", "IsObsolete"],
        "StatusTypes": ["ID", "Title", "IsOperational", "IsUserSelectable"],
        "UsageTypes": ["ID", "Title", "IsPayAtLocation", "IsMembershipRequired", "IsAccessKeyRequired"],
        "SubmissionStatusTypes": ["ID", "Title", "IsLive"],
        "UserCommentTypes": ["ID", "Title"],
        "CheckinStatusTypes": ["ID", "Title", "IsPositive", "IsAutomatedCheckin"],
        "DataTypes": ["ID", "Title"],
    }

    for table_name, columns in simple_tables.items():
        if table_name in raw_json and isinstance(raw_json[table_name], list):
            records = []
            seen_ids = set()
            for entry in raw_json[table_name]:
                if not isinstance(entry, dict):
                    continue
                entry_id = entry.get("ID")
                # skip duplicates and missing IDs
                if entry_id is None or entry_id in seen_ids:
                    continue
                seen_ids.add(entry_id)
                rec = {col: entry.get(col) for col in columns if col in entry or col == "ID"}
                rec["ETLLoadedAt"] = datetime.utcnow().isoformat()
                records.append(rec)
            cleaned[table_name] = records

    # Metadata Groups with nested fields
    if "MetadataGroups" in raw_json and isinstance(raw_json["MetadataGroups"], list):
        metadata_records = []
        for group in raw_json["MetadataGroups"]:
            if not isinstance(group, dict):
                continue
            group_id = group.get("ID")
            group_title = group.get("Title")
            for field in group.get("MetadataFields") or []:
                if isinstance(field, dict):
                    metadata_records.append({
                        "MetadataGroupID": group_id,
                        "MetadataGroupTitle": group_title,
                        "MetadataFieldID": field.get("ID"),
                        "MetadataFieldTitle": field.get("Title"),
                        "DataTypeID": field.get("DataTypeID"),
                        "ETLLoadedAt": datetime.utcnow().isoformat(),
                    })
        if metadata_records:
            cleaned["MetadataGroups"] = metadata_records

    # Default output path
    output_json = Path(output_path) if output_path else PROCESSED_DIR / "reference_clean.json"
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    # Optionally write per-table CSVs if pandas available
    if to_csv and pd is not None:
        try:
            for table_name, records in cleaned.items():
                if records:
                    df = pd.DataFrame(records)
                    csv_path = PROCESSED_DIR / f"reference_{table_name.lower()}.csv"
                    df.to_csv(csv_path, index=False)
        except Exception:
            pass

    # Print summary
    total_records = sum(len(records) for records in cleaned.values())
    print(f"✅ Reference data cleaned: {len(cleaned)} tables, {total_records} total records")
    print(f"   Saved to {output_json}")
    print("🎯 All reference data cleaned successfully.")

    return cleaned
