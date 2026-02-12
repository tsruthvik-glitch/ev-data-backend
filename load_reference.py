import json
import sqlite3
from pathlib import Path
from typing import Any, Dict, List


DATA_FILE = Path("data/processed/reference_clean.json")
DB_FILE = Path("data/db/ocm.sqlite")


def _sql_type_for_values(values: List[Any]) -> str:
    """Determine a SQLite column type for a list of sample values."""
    has_float = False
    has_int = False
    for v in values:
        if v is None:
            continue
        if isinstance(v, bool):
            has_int = True
        elif isinstance(v, int):
            has_int = True
        elif isinstance(v, float):
            has_float = True
        else:
            return "TEXT"
    if has_float:
        return "REAL"
    if has_int:
        return "INTEGER"
    return "TEXT"


def _normalize_value(v: Any) -> Any:
    if v is None:
        return None
    if isinstance(v, (dict, list)):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, bool):
        return int(v)
    return v


def load_reference_from_file(data_file: Path = DATA_FILE, db_file: Path = DB_FILE) -> Dict[str, int]:
    """Load reference data JSON into SQLite. Returns dict of table -> rows inserted."""
    if not data_file.exists():
        raise FileNotFoundError(f"Reference cleaned file not found: {data_file}")
    if data_file.stat().st_size == 0:
        raise ValueError(f"Reference cleaned file is empty: {data_file}")

    with open(data_file, "r", encoding="utf-8") as f:
        ref_data = json.load(f)

    if not isinstance(ref_data, dict):
        raise ValueError("Reference data must be a JSON object/dictionary")

    db_file.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_file))
    cursor = conn.cursor()

    results: Dict[str, int] = {}

    for key, items in ref_data.items():
        table_name = key.lower()
        if not isinstance(items, list):
            continue

        # collect all column names
        columns = set()
        for it in items:
            if isinstance(it, dict):
                columns.update(it.keys())

        if not columns:
            continue

        # determine types per column
        col_types: Dict[str, str] = {}
        for col in columns:
            samples = [it.get(col) for it in items if isinstance(it, dict) and col in it]
            col_types[col] = _sql_type_for_values(samples)

        # build CREATE TABLE
        cols_sql = []
        pk = None
        for col, typ in col_types.items():
            col_name = col.replace(" ", "_")
            if col == "ID":
                pk = col_name
                cols_sql.append(f'"{col_name}" {typ} PRIMARY KEY')
            else:
                cols_sql.append(f'"{col_name}" {typ}')

        if pk is None:
            cols_sql.insert(0, '"rowid" INTEGER PRIMARY KEY AUTOINCREMENT')

        create_sql = f"CREATE TABLE IF NOT EXISTS \"{table_name}\" ({', '.join(cols_sql)})"
        cursor.execute(create_sql)

        # replace existing data
        cursor.execute(f"DELETE FROM \"{table_name}\"")

        # Insert rows
        col_list = [c.replace(" ", "_") for c in columns]
        placeholders = ",".join(["?" for _ in col_list])
        insert_sql = f'INSERT INTO "{table_name}" ({",".join(["\""+c+"\"" for c in col_list])}) VALUES ({placeholders})'

        inserted = 0
        for it in items:
            if not isinstance(it, dict):
                continue
            row = [_normalize_value(it.get(orig_col)) for orig_col in col_list]
            cursor.execute(insert_sql, row)
            inserted += 1

        conn.commit()
        results[table_name] = inserted
        print(f"✅ Loaded reference table '{table_name}' with {inserted} rows")

    conn.close()
    return results


if __name__ == "__main__":
    try:
        res = load_reference_from_file()
        print("All reference tables loaded:", res)
    except Exception as e:
        print(f"❌ Error loading reference data: {e}")
