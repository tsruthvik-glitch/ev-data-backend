# utils.py

import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


# Configure logging
logger = logging.getLogger(__name__)


# -----------------------------
# Safe Access Helpers
# -----------------------------

def safe_get(obj: Dict, key: str, default: Any = None) -> Any:
    """Safely get value from dictionary."""
    if not isinstance(obj, dict):
        return default
    return obj.get(key, default)


def safe_nested_get(obj: Dict, keys: List[str], default: Any = None) -> Any:
    """Safely get nested value from dict.
    
    Example: safe_nested_get(d, ["AddressInfo", "Latitude"])
    """
    current = obj
    for key in keys:
        if not isinstance(current, dict):
            return default
        current = current.get(key)
        if current is None:
            return default
    return current


# -----------------------------
# Normalization Helpers
# -----------------------------

def normalize_string(value: Any, allow_empty: bool = False) -> Optional[str]:
    """Normalize strings (strip whitespace, convert empty to None)."""
    if not isinstance(value, str):
        return None
    value = value.strip()
    return value if (allow_empty or value) else None


def normalize_int(value: Any) -> Optional[int]:
    """Convert value to int if possible."""
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def normalize_float(value: Any) -> Optional[float]:
    """Convert value to float if possible."""
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def normalize_boolean(value: Any) -> Optional[bool]:
    """Normalize boolean values."""
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        if value.lower() in ("true", "yes", "1"):
            return True
        if value.lower() in ("false", "no", "0"):
            return False
    if isinstance(value, int):
        return bool(value)
    return None


def normalize_nested_object(value: Any) -> Optional[str]:
    """Convert nested dict/list objects to JSON string."""
    if value is None:
        return None
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False)
    return None


# -----------------------------
# Date & Time Helpers
# -----------------------------

def parse_iso_datetime(value: Any) -> Optional[datetime]:
    """Parse ISO-8601 datetime string."""
    if not isinstance(value, str):
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def current_utc_timestamp() -> str:
    """Return current UTC timestamp as ISO string."""
    return datetime.utcnow().isoformat()


def format_datetime(dt: datetime) -> str:
    """Format datetime as ISO string."""
    if isinstance(dt, datetime):
        return dt.isoformat()
    return str(dt)


# -----------------------------
# List Helpers
# -----------------------------

def flatten_list(nested_list: List[List[Any]]) -> List[Any]:
    """Flatten list of lists."""
    return [item for sublist in nested_list for item in sublist]


def ensure_list(value: Any) -> List:
    """Ensure value is always a list."""
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def chunk_list(items: List[Any], chunk_size: int) -> List[List[Any]]:
    """Split list into chunks."""
    return [items[i:i + chunk_size] for i in range(0, len(items), chunk_size)]


# -----------------------------
# Default Value Helpers
# -----------------------------

def default_if_none(value: Any, default: Any) -> Any:
    """Return default if value is None."""
    return value if value is not None else default


def coalesce(*values) -> Any:
    """Return first non-None value."""
    for v in values:
        if v is not None:
            return v
    return None


# -----------------------------
# JSON/File Helpers
# -----------------------------

def load_json_file(path: Path) -> Dict[str, Any]:
    """Load and parse JSON file."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Failed to load JSON file {path}: {e}")
        raise


def save_json_file(data: Any, path: Path, indent: int = 2) -> None:
    """Save data as JSON file."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=indent)
    except Exception as e:
        logger.error(f"Failed to save JSON file {path}: {e}")
        raise


# -----------------------------
# Logging Helpers
# -----------------------------

def log_info(message: str) -> None:
    """Log info level message."""
    print(f"[INFO] {message}")
    logger.info(message)


def log_warning(message: str) -> None:
    """Log warning level message."""
    print(f"[WARN] {message}")
    logger.warning(message)


def log_error(message: str) -> None:
    """Log error level message."""
    print(f"[ERR] {message}")
    logger.error(message)


def log_success(message: str) -> None:
    """Log success message."""
    print(f"[OK] {message}")
    logger.info(message)


# -----------------------------
# Progress Tracking
# -----------------------------

class ProgressTracker:
    """Simple progress tracker for ETL operations."""
    
    def __init__(self, name: str, total: Optional[int] = None):
        self.name = name
        self.total = total
        self.current = 0
        self.errors = []
    
    def update(self, count: int = 1) -> None:
        self.current += count
        if self.total:
            pct = (self.current / self.total) * 100
            print(f"  {self.name}: {self.current}/{self.total} ({pct:.1f}%)", end="\r")
    
    def add_error(self, idx: int, error: str) -> None:
        self.errors.append((idx, error))
    
    def finish(self) -> None:
        if self.total:
            print(f"  {self.name}: {self.current}/{self.total} (100.0%) ✓")
        else:
            print(f"  {self.name}: {self.current} processed ✓")
        if self.errors:
            print(f"    {len(self.errors)} errors encountered")
