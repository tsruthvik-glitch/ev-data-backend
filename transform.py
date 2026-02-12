
import pandas as pd

def transform_data(raw_data):
    """
    Transforms raw JSON data into a clean Pandas DataFrame.
    """
    if not raw_data:
        return pd.DataFrame()

    # Normalize nested JSON structure
    # OpenChargeMap structure is nested, so we pick key fields
    cleaned_data = []
    for item in raw_data:
        address = item.get("AddressInfo", {})
        cleaned_data.append({
            "station_id": item.get("ID"),
            "title": address.get("Title"),
            "town": address.get("Town"),
            "latitude": address.get("Latitude"),
            "longitude": address.get("Longitude"),
            "status": item.get("StatusType", {}).get("Title"),
            "usage_cost": item.get("UsageCost"),
        })

    df = pd.DataFrame(cleaned_data)
    
    # Drop rows with missing crucial information (e.g., coordinates)
    df.dropna(subset=["latitude", "longitude"], inplace=True)
    
    return df

if __name__ == "__main__":
    # Test with dummy data or import extract
    pass
