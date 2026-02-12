
import requests

API_URL = "https://api.openchargemap.io/v3/poi"
API_KEY = "10e1b363-bd6e-4f46-8141-7f98c5828d8a"

def extract_data(country_code="IN", max_results=100):
    """
    Fetches EV charging station data from the API.
    """
    params = {
        "output": "json",
        "countrycode": country_code,
        "maxresults": max_results,
        "compact": True,
        "verbose": False,
        "key": API_KEY
    }
    
    try:
        response = requests.get(API_URL, params=params)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        print(f"Error fetching data: {e}")
        return []

if __name__ == "__main__":
    data = extract_data()
    print(f"Extracted {len(data)} records.")
