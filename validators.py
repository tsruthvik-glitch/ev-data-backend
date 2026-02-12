# transform/validators.py

from typing import Any, Dict, List, Optional, Tuple


# -----------------------------
# Generic Validators
# -----------------------------

def is_valid_id(value: Any) -> bool:
    """Check if value is a valid positive integer ID."""
    return isinstance(value, int) and value > 0


def is_valid_string(value: Any, allow_empty: bool = False) -> bool:
    """Check if value is a valid non-empty string."""
    if not isinstance(value, str):
        return False
    return allow_empty or value.strip() != ""


def is_valid_latitude(lat: Any) -> bool:
    """Check if value is a valid latitude (-90 to 90)."""
    return isinstance(lat, (int, float)) and -90 <= lat <= 90


def is_valid_longitude(lon: Any) -> bool:
    """Check if value is a valid longitude (-180 to 180)."""
    return isinstance(lon, (int, float)) and -180 <= lon <= 180


def is_valid_boolean(value: Any) -> bool:
    """Check if value is a boolean."""
    return isinstance(value, bool)


def is_valid_numeric(value: Any, positive: bool = False) -> bool:
    """Check if value is numeric (int or float)."""
    if not isinstance(value, (int, float)):
        return False
    if positive:
        return value > 0
    return True


def is_valid_url(value: Any) -> bool:
    """Simple URL validation."""
    if not isinstance(value, str):
        return False
    return value.startswith(("http://", "https://"))


# -----------------------------
# Station Validators
# -----------------------------

def validate_station(station: Dict, strict: bool = False) -> Tuple[bool, Optional[str]]:
    """Validate a charging station record.

    Returns (is_valid, error_message_or_none)
    """
    if not isinstance(station, dict):
        return False, "Station must be a dict"

    station_id = station.get("ID")
    if not is_valid_id(station_id):
        return False, f"Invalid or missing station ID: {station_id}"

    address = station.get("AddressInfo") or {}
    title = address.get("Title") or station.get("Title")
    if strict and not is_valid_string(title):
        return False, "Station name/title is required"

    lat = address.get("Latitude")
    lon = address.get("Longitude")
    if lat is None or not is_valid_latitude(lat):
        return False, f"Invalid latitude: {lat}"
    if lon is None or not is_valid_longitude(lon):
        return False, f"Invalid longitude: {lon}"

    return True, None


# -----------------------------
# Connection Validators
# -----------------------------

def validate_connection(connection: Dict, strict: bool = False) -> Tuple[bool, Optional[str]]:
    """Validate a connection record.

    Returns (is_valid, error_message_or_none)
    """
    if not isinstance(connection, dict):
        return False, "Connection must be a dict"

    poi_id = connection.get("POI_ID")
    if not is_valid_id(poi_id):
        return False, f"Invalid or missing POI_ID: {poi_id}"

    power_kw = connection.get("PowerKW")
    if power_kw is not None and not is_valid_numeric(power_kw, positive=True):
        return False, f"Invalid PowerKW: {power_kw}"

    quantity = connection.get("Quantity")
    if quantity is not None and not is_valid_numeric(quantity, positive=True):
        return False, f"Invalid Quantity: {quantity}"

    return True, None


# -----------------------------
# Reference Data Validators
# -----------------------------

def validate_reference_item(item: Dict, required_fields: List[str], optional_fields: Optional[List[str]] = None) -> Tuple[bool, Optional[str]]:
    """Generic validator for reference table items.

    Returns (is_valid, error_message_or_none)
    """
    if not isinstance(item, dict):
        return False, "Item must be a dict"

    optional_fields = optional_fields or []

    # Check required fields
    for field in required_fields:
        if field not in item or item[field] is None:
            return False, f"Missing required field: {field}"

    # Special validation for ID and Title
    if "ID" in required_fields and not is_valid_id(item.get("ID")):
        return False, f"Invalid ID: {item.get('ID')}"

    if "Title" in required_fields and not is_valid_string(item.get("Title")):
        return False, f"Invalid Title: {item.get('Title')}"

    return True, None


# -----------------------------
# Bulk Validation Helpers
# -----------------------------

def filter_valid_stations(stations: List[Dict], strict: bool = False) -> List[Dict]:
    """Filter list of stations, keeping only valid ones."""
    valid = []
    for s in stations:
        is_ok, _ = validate_station(s, strict=strict)
        if is_ok:
            valid.append(s)
    return valid


def filter_valid_connections(connections: List[Dict], strict: bool = False) -> List[Dict]:
    """Filter list of connections, keeping only valid ones."""
    valid = []
    for c in connections:
        is_ok, _ = validate_connection(c, strict=strict)
        if is_ok:
            valid.append(c)
    return valid


def filter_valid_reference_items(
    items: List[Dict],
    required_fields: List[str],
    optional_fields: Optional[List[str]] = None
) -> List[Dict]:
    """Filter list of reference items, keeping only valid ones."""
    valid = []
    for item in items:
        is_ok, _ = validate_reference_item(item, required_fields, optional_fields)
        if is_ok:
            valid.append(item)
    return valid


def validate_list_and_report(
    items: List[Dict],
    validator_func,
    item_name: str = "item"
) -> Tuple[List[Dict], List[Tuple[int, str]]]:
    """Validate a list of items and return valid items + errors.

    Returns (valid_items, [(index, error_msg), ...])
    """
    valid = []
    errors = []
    for idx, item in enumerate(items):
        is_ok, error_msg = validator_func(item)
        if is_ok:
            valid.append(item)
        else:
            errors.append((idx, error_msg or "Unknown validation error"))
    return valid, errors
