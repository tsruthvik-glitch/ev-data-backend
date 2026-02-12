import requests
import json

API_KEY = '9d44df51-320b-410c-baea-eb0cd79c0872'
HEADERS = {'X-API-Key': API_KEY}

poi_url = 'https://api.openchargemap.io/v3/poi'

params = {
    'countrycode': 'IN',
    'maxresults': 100,
    'compact': False,
    'verbose': False
}

poi_response = requests.get(poi_url, headers=HEADERS, params=params)
poi_data = poi_response.json()

# Define fields to keep
fields_to_keep = [
    'ID',
    'UUID',
    'DataProvider',
    'OperatorInfo',
    'UsageType',
    'StatusType',
    'AddressInfo',
    'Connections',
    'NumberOfPoints',
    'GeneralComments',
    'DateLastVerified',
    'DateCreated',
    'MetadataValues'
]

# Filter each entry
filtered_data = []
for entry in poi_data:
    filtered_entry = {k: entry.get(k) for k in fields_to_keep}
    filtered_data.append(filtered_entry)

# Write to file
with open('etl/Raw_data/poi_raw_20260203_1600.json', 'w', encoding='utf-8') as f:
    json.dump(filtered_data, f, ensure_ascii=False, indent=2)

print(f'POI data saved: {len(filtered_data)} entries')
print(f'Fields: {fields_to_keep}')
