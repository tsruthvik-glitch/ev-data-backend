import requests
import json

API_KEY = "10e1b363-bd6e-4f46-8141-7f98c5828d8a"

HEADERS = {
    "X-API-Key": API_KEY
}

# 1️⃣ Core Reference Data
ref_url = "https://api.openchargemap.io/v3/referencedata"

ref_response = requests.get(ref_url, headers=HEADERS)
ref_data = ref_response.json()

print("Reference Data fetched successfully")
print(ref_data.keys())
# print(ref_data)

# Save reference data to a local JSON file
with open("ref_data.json", "w", encoding="utf-8") as f:
    json.dump(ref_data, f, ensure_ascii=False, indent=2)
print("Saved reference data to ref_data.json")


# 2️⃣ POI Data (Charging stations)
poi_url = "https://api.openchargemap.io/v3/poi"

params = {
    "countrycode": "IN",   # India
    "maxresults": 10,
    "compact": True,
    "verbose": False
}

poi_response = requests.get(poi_url, headers=HEADERS, params=params)
poi_data = poi_response.json()

print("POI Data fetched successfully")
print(f"Number of stations: {len(poi_data)}")
