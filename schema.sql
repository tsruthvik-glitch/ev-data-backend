-- =====================================================
-- DATABASE SCHEMA FOR EV CHARGING ETL PIPELINE
-- =====================================================
-- 
-- Compatible with: SQLite 3.x and PostgreSQL 12+
-- Auto-adjusts data types based on database backend
--
-- For PostgreSQL, set: export DATABASE_URL=postgresql://user:pass@host/dbname
-- For SQLite (default): data/db/ocm.sqlite

-- ===============================
-- REFERENCE TABLES (Lookup Data)
-- ===============================

-- Charging levels (Level 1, Level 2, DC Fast, etc.)
CREATE TABLE IF NOT EXISTS charger_levels (
    level_id INTEGER PRIMARY KEY,
    level_title TEXT NOT NULL,
    min_power_kw REAL,
    max_power_kw REAL,
    current_type TEXT,
    charging_speed TEXT,
    description TEXT
);

-- EV charging connector types (IEC, CCS, CHAdeMO, Tesla, etc.)
CREATE TABLE IF NOT EXISTS connection_types (
    connection_type_id INTEGER PRIMARY KEY,
    connection_title TEXT NOT NULL,
    formal_name TEXT,
    is_discontinued INTEGER DEFAULT 0,
    is_obsolete INTEGER DEFAULT 0,
    connector_category TEXT,
    connector_group TEXT
);

-- Station usage restrictions (Public, Private, Members-only, etc.)
CREATE TABLE IF NOT EXISTS usage_types (
    usage_type_id INTEGER PRIMARY KEY,
    usage_title TEXT NOT NULL,
    pay_at_location INTEGER DEFAULT 0,
    membership_required INTEGER DEFAULT 0,
    access_key_required INTEGER DEFAULT 0,
    is_public INTEGER DEFAULT 0,
    usage_category TEXT
);

-- Station operational status (Operational, Temporarily Unavailable, etc.)
CREATE TABLE IF NOT EXISTS status_types (
    status_type_id INTEGER PRIMARY KEY,
    status_title TEXT NOT NULL,
    is_operational INTEGER DEFAULT 0,
    is_user_selectable INTEGER DEFAULT 0,
    status_category TEXT
);

-- ===============================
-- OPERATORS TABLE
-- ===============================

-- Charging network operators/providers
CREATE TABLE IF NOT EXISTS operators (
    operator_id INTEGER PRIMARY KEY,
    operator_name TEXT NOT NULL,
    website_url TEXT,
    phone_primary TEXT,
    phone_secondary TEXT,
    email TEXT,
    is_private_individual INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1
);

-- ===============================
-- STATIONS TABLE (Charge Points)
-- ===============================

-- EV charging stations/locations
CREATE TABLE IF NOT EXISTS stations (
    station_id INTEGER PRIMARY KEY,
    uuid TEXT UNIQUE,
    station_name TEXT,
    operator_id INTEGER,
    usage_type_id INTEGER,
    status_type_id INTEGER,
    number_of_points INTEGER,
    latitude REAL,
    longitude REAL,
    address_line1 TEXT,
    town TEXT,
    state TEXT,
    postcode TEXT,
    country_id INTEGER,
    date_created TEXT,
    date_last_verified TEXT,
    data_quality_level INTEGER DEFAULT 0,

    FOREIGN KEY (operator_id)
        REFERENCES operators (operator_id),

    FOREIGN KEY (usage_type_id)
        REFERENCES usage_types (usage_type_id),

    FOREIGN KEY (status_type_id)
        REFERENCES status_types (status_type_id)
);

-- ===============================
-- CONNECTIONS TABLE (EVSE)
-- ===============================

-- Individual charging connectors at stations
CREATE TABLE IF NOT EXISTS connections (
    connection_id INTEGER PRIMARY KEY AUTOINCREMENT,
    poi_id INTEGER NOT NULL,
    connection_type_id INTEGER,
    level_id INTEGER,
    power_kw REAL,
    voltage INTEGER,
    amps INTEGER,
    current_type TEXT,
    current_type_id INTEGER,
    quantity INTEGER DEFAULT 1,
    status_type_id INTEGER,
    comments TEXT,

    FOREIGN KEY (poi_id)
        REFERENCES stations (station_id)
        ON DELETE CASCADE,

    FOREIGN KEY (connection_type_id)
        REFERENCES connection_types (connection_type_id),

    FOREIGN KEY (level_id)
        REFERENCES charger_levels (level_id),

    FOREIGN KEY (status_type_id)
        REFERENCES status_types (status_type_id)
);

-- ===============================
-- PERFORMANCE INDEXES
-- ===============================

-- Speed up location-based queries
CREATE INDEX IF NOT EXISTS idx_stations_location
    ON stations (latitude, longitude);

-- Speed up station lookups by operator
CREATE INDEX IF NOT EXISTS idx_stations_operator
    ON stations (operator_id);

-- Speed up station lookups by status
CREATE INDEX IF NOT EXISTS idx_stations_status
    ON stations (status_type_id);

-- Speed up connection queries by station
CREATE INDEX IF NOT EXISTS idx_connections_station
    ON connections (poi_id);

-- Speed up connection queries by type
CREATE INDEX IF NOT EXISTS idx_connections_type
    ON connections (connection_type_id);

-- Speed up connection queries by charging level
CREATE INDEX IF NOT EXISTS idx_connections_level
    ON connections (level_id);

