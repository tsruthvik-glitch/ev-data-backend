import subprocess
import sys
import os
import json
from pathlib import Path

# transform module
from etl.transform.transform import main as transform_main

# loaders
from etl.load.load_stations import load_stations_from_file
from etl.load.load_connections import load_connections_from_file

# staging
from etl.staging.staging_manager import stage_stations, stage_connections, stage_reference_data


def run_etl():
    print("[*] ETL Pipeline Started")

    # --------------------
    # EXTRACT (run script) - skip if no API key and use existing raw files
    # --------------------
    api_key = os.getenv("OCM_API_KEY")
    if api_key:
        print("[->] Extracting data from API (etl/extract/extract_api.py)...")
        res = subprocess.run([sys.executable, "etl/extract/extract_api.py"], capture_output=True, text=True)
        if res.returncode != 0:
            print("[ERR] Extract step failed:")
            print(res.stdout)
            print(res.stderr)
            return False
        print(res.stdout)
    else:
        # ensure raw files exist
        raw_dir = Path("etl/Raw_data")
        if not raw_dir.exists():
            print("[ERR] No API key set and etl/Raw_data does not exist. Cannot proceed.")
            return False
        poi_files = sorted(raw_dir.glob("poi_raw_*.json"))
        ref_file = raw_dir / "reference_data.json"
        if not poi_files or not ref_file.exists():
            print("[ERR] No API key set and required raw files are missing in etl/Raw_data.")
            return False
        latest_poi = poi_files[-1]
        print(f"[INFO] OCM_API_KEY not set -- using existing raw files: {latest_poi.name}, {ref_file.name}")

    # --------------------
    # TRANSFORM (module)
    # --------------------
    print("[*] Transforming data (etl/transform/transform.py)...")
    transform_ok = transform_main()
    if not transform_ok:
        print("[ERR] Transform step failed")
        return False

    # --------------------
    # LOAD (loaders operate on processed files)
    # --------------------
    print("[*] Loading stations into database...")
    try:
        n_stations = load_stations_from_file()
        print(f"[OK] Loaded {n_stations} stations")
    except Exception as e:
        print(f"[ERR] Stations load failed: {e}")
        return False

    print("[*] Loading connections into database...")
    try:
        n_conns = load_connections_from_file()
        print(f"[OK] Loaded {n_conns} connections")
    except Exception as e:
        print(f"[ERR] Connections load failed: {e}")
        return False

    # --------------------
    # STAGING (from processed files)
    # --------------------
    print("[*] Generating staging files...")
    try:
        # Load processed data
        poi_clean_file = Path("data/processed/poi_clean.json")
        ref_clean_file = Path("data/processed/reference_clean.json")
        conn_clean_file = Path("data/processed/connections_clean.json")
        
        if poi_clean_file.exists():
            with open(poi_clean_file, "r", encoding="utf-8") as f:
                stations = json.load(f)
            n_staged = stage_stations(stations)
            print(f"  [OK] Staged {n_staged} stations")
        
        if conn_clean_file.exists():
            with open(conn_clean_file, "r", encoding="utf-8") as f:
                connections = json.load(f)
            n_staged = stage_connections(connections)
            print(f"  [OK] Staged {n_staged} connections")
        
        if ref_clean_file.exists():
            with open(ref_clean_file, "r", encoding="utf-8") as f:
                ref_data = json.load(f)
            ref_counts = stage_reference_data(ref_data)
            for table_name, count in ref_counts.items():
                print(f"  [OK] Staged {count} {table_name}")
    except Exception as e:
        print(f"[ERR] Staging failed: {e}")
        return False

    print("[OK] ETL Pipeline Completed Successfully")
    return True


if __name__ == "__main__":
    success = run_etl()
    sys.exit(0 if success else 1)
