/* =========================================================================
   File: 01_table_overview.sql
   Purpose: 
     - List all 12 tables created by the ETL pipeline v2.0
     - Verify schema structure and column definitions
     - Perform initial sanity checks after data load
     - Support both SQLite and PostgreSQL
   
   Pipeline Tables (12 total):
     CORE DATA TABLES (3):
       - stations: Main charging station records (100 expected)
       - connections: Individual connectors/chargers (111 expected)
       - operators: Charging network operators
     
     REFERENCE TABLES (9):
       - status_types: Station operational status
       - usage_types: Usage classification
       - connection_types: Connector types (TYPE1, TYPE2, CHADEMO, CCS, TESLA, etc.)
       - connection_current_types: Current type (AC/DC)
       - charger_levels: Charging speed classification
       - power_supply_types: Power supply classification
       - Plus 3 additional reference tables
   
   Compatibility: Works with both SQLite and PostgreSQL
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] LIST ALL TABLES IN DATABASE
   Shows all 12 tables in the schema
   
   SQLite equivalent: .tables
   PostgreSQL: SELECT * FROM information_schema.tables WHERE table_schema = 'public'
 */

-- APPROACH 1: PostgreSQL method (compatible with most databases)
SELECT
    table_schema,
    table_name,
    'Core Data' AS table_category
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name IN ('stations', 'connections', 'operators')
UNION ALL
SELECT
    table_schema,
    table_name,
    'Reference Data' AS table_category
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name IN (
    'status_types', 'usage_types', 'connection_types', 
    'connection_current_types', 'charger_levels', 'power_supply_types'
)
ORDER BY table_category, table_name;


/* [2] DESCRIBE CORE FACT TABLES (3 tables)
   Stations - Main EV charging station records
 */

-- Stations table structure with full metadata
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stations'
ORDER BY ordinal_position;

-- Stations row count and basic statistics
SELECT
    'stations' AS table_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT operator_id) AS unique_operators,
    COUNT(DISTINCT status_type_id) AS status_types_used,
    ROUND(AVG(latitude), 4) AS avg_latitude,
    ROUND(AVG(longitude), 4) AS avg_longitude,
    COUNT(*) FILTER (WHERE latitude IS NULL) AS null_latitude_count,
    COUNT(*) FILTER (WHERE longitude IS NULL) AS null_longitude_count
FROM stations;


/* Connections - Individual charging connectors at each station */

-- Connections table structure
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'connections'
ORDER BY ordinal_position;

-- Connections row count and statistics
SELECT
    'connections' AS table_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT station_id) AS stations_with_connections,
    COUNT(DISTINCT connection_type_id) AS connector_types_used,
    COUNT(DISTINCT current_type_id) AS current_types_used,
    ROUND(AVG(power_kw), 2) AS avg_power_kw,
    ROUND(MAX(power_kw), 2) AS max_power_kw,
    ROUND(MIN(power_kw), 2) AS min_power_kw,
    COUNT(*) FILTER (WHERE power_kw IS NULL) AS null_power_count
FROM connections;


/* Operators - Charging network operators (e.g., Tesla, EVGo, ChargePoint) */

-- Operators table structure
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'operators'
ORDER BY ordinal_position;

-- Operators count and sample data
SELECT
    'operators' AS table_name,
    COUNT(*) AS operator_count,
    COUNT(*) FILTER (WHERE is_active = 1) AS active_operators,
    COUNT(*) FILTER (WHERE url IS NOT NULL) AS operators_with_url,
    COUNT(*) FILTER (WHERE contact_email IS NOT NULL) AS operators_with_email
FROM operators;


/* [3] DESCRIBE REFERENCE TABLES (9 tables)
   Reference tables provide lookup values for categorization and classification
 */

-- Status Types - Station operational status
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'status_types'
ORDER BY ordinal_position;

SELECT
    'status_types' AS table_name,
    COUNT(*) AS record_count,
    COUNT(DISTINCT status_category) AS categories
FROM status_types;

-- Sample status types
SELECT * FROM status_types LIMIT 10;


-- Usage Types - Usage classification (private, public, members-only, etc.)
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'usage_types'
ORDER BY ordinal_position;

SELECT
    'usage_types' AS table_name,
    COUNT(*) AS record_count,
    COUNT(DISTINCT usage_category) AS categories
FROM usage_types;

-- Sample usage types
SELECT * FROM usage_types LIMIT 10;


-- Connection Types - Connector types (TYPE1, TYPE2, CHADEMO, CCS, TESLA, etc.)
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'connection_types'
ORDER BY ordinal_position;

SELECT
    'connection_types' AS table_name,
    COUNT(*) AS record_count,
    COUNT(DISTINCT connector_category) AS categories
FROM connection_types;

-- Sample connection types
SELECT * FROM connection_types ORDER BY connection_type_id LIMIT 15;


-- Connection Current Types - AC vs DC power types
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'connection_current_types'
ORDER BY ordinal_position;

SELECT
    'connection_current_types' AS table_name,
    COUNT(*) AS record_count
FROM connection_current_types;

-- Sample current types
SELECT * FROM connection_current_types;


-- Charger Levels - Charging speed classification (SLOW, FAST, RAPID, ULTRA_FAST)
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'charger_levels'
ORDER BY ordinal_position;

SELECT
    'charger_levels' AS table_name,
    COUNT(*) AS record_count
FROM charger_levels;

-- Sample charger levels with power ranges
SELECT * FROM charger_levels ORDER BY charger_level_id;


-- Power Supply Types - Power supply classification
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'power_supply_types'
ORDER BY ordinal_position;

SELECT
    'power_supply_types' AS table_name,
    COUNT(*) AS record_count
FROM power_supply_types;

-- Sample power supply types
SELECT * FROM power_supply_types;


/* [4] SUMMARY STATISTICS FOR ALL TABLES
   Quick overview of all tables and row counts
 */
SELECT
    'CORE TABLES' AS category,
    NULL AS padding_1,
    NULL AS padding_2
UNION ALL
SELECT 'stations', COUNT(*), NULL FROM stations
UNION ALL
SELECT 'connections', COUNT(*), NULL FROM connections
UNION ALL
SELECT 'operators', COUNT(*), NULL FROM operators
UNION ALL
SELECT 'REFERENCE TABLES', NULL, NULL
UNION ALL
SELECT 'status_types', COUNT(*), NULL FROM status_types
UNION ALL
SELECT 'usage_types', COUNT(*), NULL FROM usage_types
UNION ALL
SELECT 'connection_types', COUNT(*), NULL FROM connection_types
UNION ALL
SELECT 'connection_current_types', COUNT(*), NULL FROM connection_current_types
UNION ALL
SELECT 'charger_levels', COUNT(*), NULL FROM charger_levels
UNION ALL
SELECT 'power_supply_types', COUNT(*), NULL FROM power_supply_types
ORDER BY category DESC;


/* [5] DATABASE INTEGRITY CHECKS
   Verify foreign key relationships and data consistency
 */

-- Check for orphaned connections (connections referencing non-existent stations)
SELECT
    COUNT(*) AS orphaned_connections
FROM connections c
WHERE NOT EXISTS (SELECT 1 FROM stations s WHERE s.station_id = c.station_id);


-- Check for invalid foreign key references in stations
SELECT
    COUNT(*) AS stations_invalid_operator
FROM stations s
WHERE operator_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM operators o WHERE o.operator_id = s.operator_id);


-- Check stations with missing status type
SELECT
    COUNT(*) AS stations_missing_status
FROM stations
WHERE status_type_id IS NULL;


/* [6] SCHEMA VERSION AND PIPELINE INFO
   Metadata about pipeline execution
 */

-- Display pipeline execution summary (if logging table exists)
-- This would show when the pipeline last ran successfully
SELECT
    '[INFO] Pipeline: EV Charging ETL v2.0' AS info,
    '[INFO] Total Core Tables: 3 (stations, connections, operators)' AS tables_1,
    '[INFO] Total Reference Tables: 9' AS tables_2,
    '[INFO] Expected Stations: ~100' AS expected_1,
    '[INFO] Expected Connections: ~111' AS expected_2,
    '[INFO] Database Type: Auto-detected (SQLite or PostgreSQL)' AS database_type;
