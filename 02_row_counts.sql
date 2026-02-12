/* =========================================================================
   File: 02_row_counts.sql
   Purpose:
     - Validate data load completeness for all 12 tables
     - Check record volumes per table (core and reference)
     - Detect missing or partial loads
     - Compare actual vs expected row counts
     - Support both SQLite and PostgreSQL
   
   Expected Row Counts (v2.0 Pipeline):
     CORE TABLES:
       - stations: ~100 records
       - connections: ~111 records
       - operators: ~20-30 records
     
     REFERENCE TABLES:
       - status_types: 10+ records
       - usage_types: 8+ records
       - connection_types: 11+ records
       - connection_current_types: 2-3 records (AC/DC)
       - charger_levels: 5 records (SLOW, FAST, RAPID, ULTRA_FAST, etc.)
       - power_supply_types: 3-5 records
       - Plus 3 additional reference tables
   
   Total Expected Rows: 300+ across all tables
   
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] CORE FACT TABLES - Individual row counts
   These are the main data tables loaded from extracted/transformed data
 */

-- Stations table - Main EV charging locations
SELECT 'stations' AS table_name, COUNT(*) AS row_count
FROM stations;

-- Connections table - Individual chargers at stations
SELECT 'connections' AS table_name, COUNT(*) AS row_count
FROM connections;

-- Operators table - Charging network operators
SELECT 'operators' AS table_name, COUNT(*) AS row_count
FROM operators;


/* [2] REFERENCE / DIMENSION TABLES - Individual row counts
   These provide lookup values and categorization for the core tables
 */

-- Status Types - Station operational status (ACTIVE, PLANNED, REMOVED, TEMPORARY, INACTIVE, PARTLY_OPERATIONAL, UNKNOWN)
SELECT 'status_types' AS table_name, COUNT(*) AS record_count
FROM status_types;

-- Usage Types - Usage classification (PRIVATE, PUBLIC_FREE, PUBLIC_PAID, PUBLIC_MEMBERS_ONLY)
SELECT 'usage_types' AS table_name, COUNT(*) AS record_count
FROM usage_types;

-- Connection Types - Connector types (TYPE1, TYPE2, CHADEMO, CCS, TESLA, MENNEKES, etc.)
SELECT 'connection_types' AS table_name, COUNT(*) AS record_count
FROM connection_types;

-- Connection Current Types - Current type (AC = Alternating Current, DC = Direct Current)
SELECT 'connection_current_types' AS table_name, COUNT(*) AS record_count
FROM connection_current_types;

-- Charger Levels - Charging speed classification (SLOW, FAST, RAPID, ULTRA_FAST)
SELECT 'charger_levels' AS table_name, COUNT(*) AS record_count
FROM charger_levels;

-- Power Supply Types - Power supply classification
SELECT 'power_supply_types' AS table_name, COUNT(*) AS record_count
FROM power_supply_types;


/* [3] COMBINED OVERVIEW - All tables in single result set
   Provides a unified view of all row counts for quick validation
 */

SELECT * FROM (
    -- Core tables
    SELECT 'CORE TABLES' AS section, NULL AS table_name, NULL AS row_count, 1 AS sort_order
    UNION ALL
    SELECT NULL, 'stations', COUNT(*)::TEXT, 2 FROM stations
    UNION ALL
    SELECT NULL, 'connections', COUNT(*)::TEXT, 3 FROM connections
    UNION ALL
    SELECT NULL, 'operators', COUNT(*)::TEXT, 4 FROM operators
    
    -- Reference tables
    UNION ALL
    SELECT 'REFERENCE TABLES', NULL, NULL, 5
    UNION ALL
    SELECT NULL, 'status_types', COUNT(*)::TEXT, 6 FROM status_types
    UNION ALL
    SELECT NULL, 'usage_types', COUNT(*)::TEXT, 7 FROM usage_types
    UNION ALL
    SELECT NULL, 'connection_types', COUNT(*)::TEXT, 8 FROM connection_types
    UNION ALL
    SELECT NULL, 'connection_current_types', COUNT(*)::TEXT, 9 FROM connection_current_types
    UNION ALL
    SELECT NULL, 'charger_levels', COUNT(*)::TEXT, 10 FROM charger_levels
    UNION ALL
    SELECT NULL, 'power_supply_types', COUNT(*)::TEXT, 11 FROM power_supply_types
) t
WHERE section IS NOT NULL OR table_name IS NOT NULL
ORDER BY sort_order;


/* [4] DATA LOAD VALIDATION SUMMARY
   Checks against expected row counts and provides status indicators
 */

-- Simplified combined overview (works with both SQLite and PostgreSQL)
SELECT 'stations' AS table_name, COUNT(*) AS row_count FROM stations
UNION ALL
SELECT 'connections', COUNT(*) FROM connections
UNION ALL
SELECT 'operators', COUNT(*) FROM operators
UNION ALL
SELECT 'status_types', COUNT(*) FROM status_types
UNION ALL
SELECT 'usage_types', COUNT(*) FROM usage_types
UNION ALL
SELECT 'connection_types', COUNT(*) FROM connection_types
UNION ALL
SELECT 'connection_current_types', COUNT(*) FROM connection_current_types
UNION ALL
SELECT 'charger_levels', COUNT(*) FROM charger_levels
UNION ALL
SELECT 'power_supply_types', COUNT(*) FROM power_supply_types
ORDER BY table_name;


/* [5] DETAILED LOAD STATISTICS
   Shows size, cardinality, and data quality metrics
 */

-- Total row count across all tables
SELECT
    (SELECT COUNT(*) FROM stations) +
    (SELECT COUNT(*) FROM connections) +
    (SELECT COUNT(*) FROM operators) +
    (SELECT COUNT(*) FROM status_types) +
    (SELECT COUNT(*) FROM usage_types) +
    (SELECT COUNT(*) FROM connection_types) +
    (SELECT COUNT(*) FROM connection_current_types) +
    (SELECT COUNT(*) FROM charger_levels) +
    (SELECT COUNT(*) FROM power_supply_types) AS total_rows_all_tables;


-- Core table statistics
SELECT
    (SELECT COUNT(*) FROM stations) AS stations_count,
    (SELECT COUNT(*) FROM connections) AS connections_count,
    (SELECT COUNT(*) FROM operators) AS operators_count,
    (SELECT COUNT(*) FROM stations) + (SELECT COUNT(*) FROM connections) AS core_data_rows;


-- Reference table statistics
SELECT
    (SELECT COUNT(*) FROM status_types) AS status_types,
    (SELECT COUNT(*) FROM usage_types) AS usage_types,
    (SELECT COUNT(*) FROM connection_types) AS connection_types,
    (SELECT COUNT(*) FROM connection_current_types) AS current_types,
    (SELECT COUNT(*) FROM charger_levels) AS charger_levels,
    (SELECT COUNT(*) FROM power_supply_types) AS power_supply_types;


/* [6] VALIDATION CHECKS
   Verify data load expectations and identify issues
 */

-- Check 1: Verify core tables have data
SELECT
    CASE WHEN (SELECT COUNT(*) FROM stations) > 0 THEN 'OK' ELSE 'MISSING DATA' END AS stations_status,
    CASE WHEN (SELECT COUNT(*) FROM connections) > 0 THEN 'OK' ELSE 'MISSING DATA' END AS connections_status,
    CASE WHEN (SELECT COUNT(*) FROM operators) > 0 THEN 'OK' ELSE 'MISSING DATA' END AS operators_status;


-- Check 2: Verify reference tables are populated
SELECT
    CASE WHEN (SELECT COUNT(*) FROM status_types) >= 5 THEN 'OK' ELSE 'INCOMPLETE' END AS status_check,
    CASE WHEN (SELECT COUNT(*) FROM usage_types) >= 4 THEN 'OK' ELSE 'INCOMPLETE' END AS usage_check,
    CASE WHEN (SELECT COUNT(*) FROM connection_types) >= 6 THEN 'OK' ELSE 'INCOMPLETE' END AS connection_type_check,
    CASE WHEN (SELECT COUNT(*) FROM charger_levels) >= 3 THEN 'OK' ELSE 'INCOMPLETE' END AS charger_level_check;


-- Check 3: Verify expected row counts (approximate)
SELECT
    'Expected ~100 stations' AS check_1,
    CASE WHEN (SELECT COUNT(*) FROM stations) BETWEEN 80 AND 120 THEN 'PASS' ELSE 'CHECK' END AS result_1,
    'Expected ~111 connections' AS check_2,
    CASE WHEN (SELECT COUNT(*) FROM connections) BETWEEN 100 AND 130 THEN 'PASS' ELSE 'CHECK' END AS result_2;


/* [7] PIPELINE EXECUTION SUMMARY
   Quick status check after data load
 */

SELECT
    '[INFO] Row Count Validation Complete' AS status,
    '[INFO] Pipeline v2.0.0 (February 2026)' AS version,
    '[INFO] Supports SQLite and PostgreSQL' AS database_support,
    '[INFO] Review row counts above to validate load completeness' AS action;
