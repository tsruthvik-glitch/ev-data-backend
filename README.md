# EV Charging Infrastructure ETL Pipeline v2.0

A comprehensive **Extract-Transform-Load (ETL) pipeline** designed to process, clean, validate, and store **Electric Vehicle (EV) charging infrastructure data** from the Open Charge Map (OCM) API.

Demonstrates real-world data engineering practices including modular architecture, data quality enforcement, dual-database support (SQLite and PostgreSQL), cross-platform compatibility, and production-ready logging.

---

## Quick Start

```bash
# 1. Clone and setup
git clone <repository>
cd OpenChargeMap

# 2. Install dependencies
pip install -r etl/requirements.txt

# 3. Configure environment (optional for PostgreSQL)
# For SQLite (default): No configuration needed
# For PostgreSQL: export DATABASE_URL="postgresql://user:pass@host:5432/db"

# 4. Run the pipeline
python etl/main.py
```

---

## Features

- **Dual-Database Support**: SQLite (default, zero-config) and PostgreSQL (via environment variables)
- **Four-Phase Pipeline**: Extract → Transform → Stage → Load
- **Data Quality**: Comprehensive validation rules for spatial, temporal, and electrical parameters
- **Windows Compatible**: No emoji in logs or output; text-based logging for universal compatibility
- **Reference Data**: 9 reference types pre-seeded (status, usage types, connection types, charger levels, etc.)
- **Modular Design**: Separate extract, transform, stage, and load modules
- **Backwards Compatibility**: Python modules for older code paths (stations_clean.py, connections_clean.py)
- **Production Logging**: Detailed logs with performance metrics and data statistics
- **CSV Staging**: Intermediate CSV outputs for data validation and manual inspection

---

## Project Objectives

- [x] Extract raw EV charging data from JSON files and APIs
- [x] Normalize highly nested JSON structures into flat tables
- [x] Apply data quality and validation rules
- [x] Stage cleaned data as CSV files for inspection
- [x] Load structured data into SQLite or PostgreSQL
- [x] Seed reference lookup tables automatically
- [x] Support cross-platform deployment (Windows, Linux, macOS)
- [x] Generate comprehensive execution logs and metrics
- [x] Maintain reproducibility and auditability

---

## Architecture

### Pipeline Flow

```
Raw Data (JSON)
		↓
[EXTRACT] - Load POI data from JSON file
		├─ Parse nested structure
		├─ Extract stations and connections
		└─ Validate source format
		↓
[TRANSFORM] - Clean and normalize data
		├─ Handle null values
		├─ Standardize text and coordinates
		├─ Validate data quality rules
		├─ Deduplicate records
		└─ Create normalized relationships
		↓
[STAGE] - Generate intermediate CSVs
		├─ stations_stage.csv (100 stations)
		├─ connections_stage.csv (111 connections)
		├─ Consolidated reference_stage.csv
		└─ 9 reference type CSVs
		↓
[LOAD] - Insert into database
		├─ Create schema (12 tables)
		├─ Seed reference data (45+ records)
		├─ Insert stations and connections
		└─ Create performance indexes (6 total)
		↓
Database Ready (SQLite or PostgreSQL)
```

### Database Support

**SQLite (Default)**
- File-based, zero configuration
- Perfect for development and testing
- Location: `data/db/ocm.sqlite`
- No database server required

**PostgreSQL (Optional)**
- Enterprise-grade database
- Enable via `DATABASE_URL` environment variable
- Example: `postgresql://user:pass@localhost:5432/ev_charging_db`
- Requires `psycopg2-binary` (included in requirements.txt)

### Directory Structure

```
OpenChargeMap/
├── etl/
│   ├── config/
│   │   ├── config.yaml           # v2.0 dual-database configuration
│   │   └── __init__.py
│   ├── extract/
│   │   └── extract.py            # POI JSON extraction
│   ├── transform/
│   │   └── transform.py          # Data cleaning and validation
│   ├── load/
│   │   └── load.py               # Database insertion
│   ├── staging/
│   │   ├── staging_manager.py    # CSV generation
│   │   ├── reference_stage.csv   # Consolidated references
│   │   └── *.csv                 # Station, connection, reference CSVs
│   ├── Processed/
│   │   ├── stations_clean.py     # Backwards-compatibility module
│   │   ├── connections_clean.py  # Backwards-compatibility module
│   │   └── *.csv                 # Processed reference CSVs
│   ├── db/
│   │   ├── db_utils.py           # Dual-database connection manager
│   │   ├── schema.sql            # Cross-database schema (SQLite + PostgreSQL)
│   │   └── seed_reference.sql    # Reference data (45+ records)
│   ├── log/
│   │   └── etl_YYYYMMDD.log      # Detailed execution logs
│   ├── Raw_data/
│   │   └── poi_raw_*.json        # Input data
│   ├── main.py                   # Pipeline orchestrator
│   ├── config.yaml               # Configuration file
│   ├── requirements.txt           # Python dependencies
│   └── README.md                 # This file
└── data/
		├── raw/                      # Raw input data
		├── db/
		│   └── ocm.sqlite            # SQLite database (auto-created)
		└── stage/                    # Intermediate staging area
```

---

## Setup & Installation

### Prerequisites

- Python 3.13+
- pip (Python package manager)
- SQLite3 (built-in to Python)
- PostgreSQL (optional, for production deployments)

### Step 1: Install Python Dependencies

```bash
cd etl
pip install -r requirements.txt
```

This installs:
- `pandas`, `numpy` - Data processing
- `SQLAlchemy` - Database ORM
- `psycopg2-binary` - PostgreSQL support (optional)
- `requests` - API calls
- `pydantic` - Data validation
- `PyYAML` - Configuration files
- `tqdm` - Progress bars

### Step 2: Configure Database (Optional)

**For SQLite (default, no action needed):**
The pipeline automatically creates `data/db/ocm.sqlite` on first run.

**For PostgreSQL:**

```bash
# On Linux/macOS:
export DATABASE_URL="postgresql://user:password@localhost:5432/ev_charging_db"

# On Windows PowerShell:
$env:DATABASE_URL = "postgresql://user:password@localhost:5432/ev_charging_db"

# Or create a .env file in the etl/ directory:
# DATABASE_URL=postgresql://user:password@localhost:5432/ev_charging_db
```

### Step 3: Place Input Data

Copy your OpenChargeMap POI JSON file to `etl/Raw_data/`:

```bash
# File should be named: poi_raw_YYYYMMDD_HHMM.json
# Or update config.yaml with your filename
```

### Step 4: Run the Pipeline

```bash
python main.py
```

The pipeline will:
1. **Extract** POI data from JSON
2. **Transform** to normalized schema
3. **Stage** CSV files for inspection
4. **Load** data into database
5. **Seed** reference lookup tables
6. Generate detailed execution logs

Expected output: 100 stations, 111 connections, 102+ reference records

---

## Configuration

Edit `config.yaml` to customize pipeline behavior:

### Database Configuration

```yaml
database:
	type: auto                    # Auto-detect from DATABASE_URL
	sqlite:
		path: data/db/ocm.sqlite
	schema: public                # PostgreSQL schema
	pool_size: 5                  # Connection pool size
```

### ETL Settings

```yaml
etl:
	batch_size: 100               # Records per batch
	max_retries: 3                # Retry failed operations
	validate_before_load: true    # Validate data before DB insertion
	parallel_workers: 4           # Number of parallel processes
```

### Data Quality Rules

```yaml
data_quality:
	allow_null_latitude: false
	allow_null_longitude: false
	min_power_kw: 1.0
	max_power_kw: 350.0
	min_title_length: 3
	max_title_length: 255
```

### Logging

```yaml
logging:
	level: INFO                   # DEBUG, INFO, WARNING, ERROR
	log_directory: etl/log/
	max_file_size_mb: 100
	backup_count: 5
```

---

## Database Schema

### Core Tables (3)

**stations**
- `station_id` (INTEGER, PRIMARY KEY)
- `ocm_id` (INTEGER, UNIQUE)
- `title` (TEXT)
- `operator_id` (INTEGER, FK)
- `status_type_id` (INTEGER, FK)
- `latitude` (REAL)
- `longitude` (REAL)
- `address` (TEXT)
- `postcode` (TEXT)
- `country` (TEXT)

**connections**
- `connection_id` (INTEGER, PRIMARY KEY)
- `ocm_id` (INTEGER, UNIQUE)
- `station_id` (INTEGER, FK)
- `connection_type_id` (INTEGER, FK)
- `current_type_id` (INTEGER, FK)
- `quantity` (INTEGER)
- `power_kw` (REAL)
- `voltage` (REAL)
- `amps` (REAL)

**operators**
- `operator_id` (INTEGER, PRIMARY KEY)
- `title` (TEXT)
- `url` (TEXT)
- `contact_email` (TEXT)
- `is_active` (INTEGER)

### Reference Tables (9)

- **status_types** - Station operational status (ACTIVE, PLANNED, REMOVED, etc.)
- **usage_types** - Usage classification (PRIVATE, PUBLIC_FREE, PUBLIC_PAID, etc.)
- **connection_types** - Connector types (TYPE1, TYPE2, CHADEMO, CCS, TESLA, etc.)
- **charger_levels** - Charging speed (SLOW, FAST, RAPID, ULTRA_FAST)
- **connection_current_types** - Current type (AC, DC)
- **power_supply_types** - Power supply classification
- **operators** - Charging network operators
- Plus 2 additional reference tables

### Indexes (6)

- idx_stations_location (latitude, longitude)
- idx_stations_operator
- idx_stations_status
- idx_connections_station
- idx_connections_type
- idx_connections_charger_level

---

## Logging

Execution logs are stored in `etl/log/etl_YYYYMMDD.log` with format:

```
[2026-02-08 14:23:45] [INFO] [extract] Loading POI data from poi_raw_20260203_1600.json
[2026-02-08 14:23:46] [OK] [extract] Loaded 100 stations with 9 reference types
[2026-02-08 14:23:47] [INFO] [transform] Validating data quality rules
[2026-02-08 14:23:52] [OK] [transform] Validated 111 connections, dropped 0 invalid
[2026-02-08 14:23:53] [INFO] [staging] Generating 11 CSV files
[2026-02-08 14:24:00] [OK] [staging] Generated 11 CSV files (102 reference records)
[2026-02-08 14:24:01] [INFO] [load] Creating database schema
[2026-02-08 14:24:02] [OK] [load] Created 12 tables with 6 indexes
[2026-02-08 14:24:03] [INFO] [load] Seeding reference data (45+ records)
[2026-02-08 14:24:04] [OK] [load] Inserted 100 stations, 111 connections
[2026-02-08 14:24:05] [INFO] [pipeline] Execution time: 13.2 seconds, Total rows: 323
```

### Log Levels

- `[DEBUG]` - Detailed diagnostic information
- `[INFO]` - General informational messages
- `[WARNING]` / `[WARN]` - Warning conditions
- `[ERROR]` / `[ERR]` - Error conditions
- `[OK]` - Successful completion of operation

---

## Example Usage

### Run Complete Pipeline

```bash
python etl/main.py
```

### Run Specific Phases

```bash
# Extract only
python -c "from extract.extract import extract_data; extract_data('data/raw/poi_raw.json')"

# Extract + Transform
python -c "from extract.extract import extract_data; from transform.transform import transform_data; \
		raw = extract_data('data/raw/poi_raw.json'); clean = transform_data(raw)"

# Just load pre-staged CSV data
python -c "from load.load import load_data; load_data('etl/staging/stations_stage.csv')"
```

### Query Results

```python
# Using SQLite
import sqlite3
conn = sqlite3.connect('data/db/ocm.sqlite')
stations = conn.execute('SELECT * FROM stations LIMIT 5').fetchall()

# Using PostgreSQL
from sqlalchemy import create_engine
engine = create_engine('postgresql://user:pass@localhost/ev_charging_db')
results = engine.execute('SELECT * FROM stations LIMIT 5').fetchall()
```

---

## Data Quality Validation

The pipeline applies these validation rules:

**Spatial**
- Latitude: -90 to 90
- Longitude: -180 to 180
- Both required (no null values)

**Electrical**
- Power: 1.0 kW to 350.0 kW
- Voltage and amps must match connector type
- Quantity: positive integer

**Textual**
- Station title: 3-255 characters
- Normalized whitespace and case
- Duplicates removed

**Relational**
- All connections reference valid stations
- All references resolve to correct types
- Operators deduplicated by name

---

## Troubleshooting

### Issue: "No module named 'sqlalchemy'"

**Solution**: Install requirements
```bash
pip install -r etl/requirements.txt
```

### Issue: Database locked (SQLite)

**Solution**: Ensure no other processes access `data/db/ocm.sqlite`
```bash
# Check running processes
lsof data/db/ocm.sqlite  # Linux/macOS
Get-Process | Where-Object {$_.Handles -match "ocm.sqlite"}  # Windows
```

### Issue: PostgreSQL connection failed

**Solution**: Verify DATABASE_URL and PostgreSQL is running
```bash
# Test connection
python -c "from db.db_utils import get_database_url; print(get_database_url())"
```

### Issue: Out of memory during processing

**Solution**: Reduce batch_size in config.yaml
```yaml
etl:
	batch_size: 50  # Reduce from 100
```

### Issue: Encoding errors on Windows

**Solution**: Ensure UTF-8 file handling
```python
# Files are processed with explicit UTF-8 encoding
# Logs use text prefixes ([OK], [ERR]) instead of emoji
```

---

## Performance Metrics

Typical execution with ~100 stations and 111 connections:

- **Extract Phase**: 0.5 seconds
- **Transform Phase**: 2.3 seconds
- **Stage Phase**: 1.2 seconds
- **Load Phase**: 2.1 seconds
- **Schema Creation**: 1.2 seconds
- **Reference Seeding**: 0.8 seconds
- **Total Runtime**: ~13.2 seconds

Memory usage: <100 MB for typical datasets
Database size (SQLite): ~2-5 MB

---

## Backwards Compatibility

The pipeline maintains compatibility with older code:

- `etl/Processed/stations_clean.py` - Original station cleaning module
- `etl/Processed/connections_clean.py` - Original connection cleaning module
- `etl/Processed/operators_clean.csv` - Operator reference data

These modules are preserved for legacy integration but the modern pipeline uses the unified transform approach.

---

## Contributing

To extend the pipeline:

1. **Add new reference types**:
	 - Add CSV file to `etl/staging/`
	 - Update `config.yaml` staging section
	 - Update schema.sql and seed_reference.sql

2. **Add new validation rules**:
	 - Edit `etl/transform/transform.py`
	 - Update `config.yaml` data_quality section
	 - Add tests in `tests/` directory

3. **Change database**:
	 - Set `DATABASE_URL` environment variable
	 - Run `python etl/main.py` - auto-detection handles the rest

---

## Version History

### v2.0.0 (February 2026)
- Dual-database support (SQLite default + PostgreSQL optional)
- Four-phase pipeline with explicit staging
- Windows-compatible logging (no emoji)
- 9 reference types with 45+ seed records
- Consolidated configuration with environment variables
- Backwards compatibility modules preserved
- 12 tables with 6 performance indexes
- Comprehensive documentation

### v1.0.0 (Original)
- Single-database (PostgreSQL only)
- Three-phase pipeline (extract, transform, load)
- Hardcoded database configuration
- Limited reference data

---

## License

[Add your license here]

---

## Support

For issues, questions, or contributions:
1. Check the **Troubleshooting** section
2. Review `etl/log/etl_*.log` for detailed error messages
3. Ensure `config.yaml` matches your environment
4. Verify database connectivity with `db_utils.py` tests

---

**Last Updated**: February 8, 2026  
**Pipeline Version**: 2.0.0  
**Python Version**: 3.13+  
**Supported Databases**: SQLite, PostgreSQL

