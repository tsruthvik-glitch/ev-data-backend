/* =========================================================================
   File: 03_null_checks.sql
   Purpose:
     - Detect NULL values in critical columns
     - Validate data transformation and quality rules
     - Ensure analytics-ready data quality
     - Identify data integrity issues post-load
     - Support both SQLite and PostgreSQL
   
   Data Quality Rules (v2.0 Pipeline):
     REQUIRED (NULL not allowed):
       - stations: station_id, title, latitude, longitude, status_type_id
       - connections: connection_id, station_id, connection_type_id, quantity
       - operators: operator_id, title
     
     OPTIONAL (NULL allowed):
       - stations: operator_id, address, postcode, country
       - connections: power_kw, voltage, amps (for some connector types)
       - operators: url, contact_email
     
     REFERENCE TABLES:
       - All reference tables should have complete titles (NO NULLs)
   
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] STATIONS TABLE - Critical field NULL analysis
   Validates that all required station attributes are populated
 */

SELECT 
    COUNT(*) AS total_stations,
    SUM(CASE WHEN station_id IS NULL THEN 1 ELSE 0 END) AS null_station_id,
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS null_title,
    SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) AS null_latitude,
    SUM(CASE WHEN longitude IS NULL THEN 1 ELSE 0 END) AS null_longitude,
    SUM(CASE WHEN status_type_id IS NULL THEN 1 ELSE 0 END) AS null_status_type_id,
    SUM(CASE WHEN operator_id IS NULL THEN 1 ELSE 0 END) AS null_operator_id,
    SUM(CASE WHEN address IS NULL THEN 1 ELSE 0 END) AS null_address,
    SUM(CASE WHEN postcode IS NULL THEN 1 ELSE 0 END) AS null_postcode,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country
FROM stations;


/* [2] CONNECTIONS TABLE - Charging configuration integrity
   Validates that all required connection attributes are populated
 */

SELECT
    COUNT(*) AS total_connections,
    SUM(CASE WHEN connection_id IS NULL THEN 1 ELSE 0 END) AS null_connection_id,
    SUM(CASE WHEN station_id IS NULL THEN 1 ELSE 0 END) AS null_station_fk,
    SUM(CASE WHEN connection_type_id IS NULL THEN 1 ELSE 0 END) AS null_connection_type_id,
    SUM(CASE WHEN current_type_id IS NULL THEN 1 ELSE 0 END) AS null_current_type_id,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN power_kw IS NULL THEN 1 ELSE 0 END) AS null_power_kw,
    SUM(CASE WHEN voltage IS NULL THEN 1 ELSE 0 END) AS null_voltage,
    SUM(CASE WHEN amps IS NULL THEN 1 ELSE 0 END) AS null_amps
FROM connections;


/* [3] OPERATORS TABLE - Operator data completeness
   Validates operator reference data quality
 */

SELECT
    COUNT(*) AS total_operators,
    SUM(CASE WHEN operator_id IS NULL THEN 1 ELSE 0 END) AS null_operator_id,
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS null_title,
    SUM(CASE WHEN url IS NULL THEN 1 ELSE 0 END) AS null_url,
    SUM(CASE WHEN contact_email IS NULL THEN 1 ELSE 0 END) AS null_contact_email,
    SUM(CASE WHEN is_active IS NULL THEN 1 ELSE 0 END) AS null_is_active
FROM operators;


/* [4] REFERENCE TABLES - NULL analysis
   Reference tables should NEVER contain NULL titles (critical constraint)
 */

SELECT
    'status_types' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN status_type_id IS NULL THEN 1 ELSE 0 END) AS null_id,
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS null_title,
    SUM(CASE WHEN status_category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS null_description
FROM status_types

UNION ALL

SELECT
    'usage_types',
    COUNT(*),
    SUM(CASE WHEN usage_type_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN usage_category IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END)
FROM usage_types

UNION ALL

SELECT
    'connection_types',
    COUNT(*),
    SUM(CASE WHEN connection_type_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN connector_category IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END)
FROM connection_types

UNION ALL

SELECT
    'connection_current_types',
    COUNT(*),
    SUM(CASE WHEN current_type_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END),
    NULL
FROM connection_current_types

UNION ALL

SELECT
    'charger_levels',
    COUNT(*),
    SUM(CASE WHEN charger_level_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END),
    NULL
FROM charger_levels

UNION ALL

SELECT
    'power_supply_types',
    COUNT(*),
    SUM(CASE WHEN power_supply_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END),
    NULL
FROM power_supply_types;


/* [5] DATA INTEGRITY VALIDATION SUMMARY
   Quick checks for data quality across all critical fields
 */

-- Summary of all NULL issues
SELECT
    'stations' AS table_name,
    'station_id' AS column_name,
    SUM(CASE WHEN station_id IS NULL THEN 1 ELSE 0 END) AS null_count
FROM stations
WHERE station_id IS NULL

UNION ALL

SELECT 'stations', 'title', COUNT(*) FROM stations WHERE title IS NULL
UNION ALL
SELECT 'stations', 'latitude', COUNT(*) FROM stations WHERE latitude IS NULL
UNION ALL
SELECT 'stations', 'longitude', COUNT(*) FROM stations WHERE longitude IS NULL
UNION ALL
SELECT 'stations', 'status_type_id', COUNT(*) FROM stations WHERE status_type_id IS NULL

UNION ALL

SELECT 'connections', 'connection_id', COUNT(*) FROM connections WHERE connection_id IS NULL
UNION ALL
SELECT 'connections', 'station_id', COUNT(*) FROM connections WHERE station_id IS NULL
UNION ALL
SELECT 'connections', 'connection_type_id', COUNT(*) FROM connections WHERE connection_type_id IS NULL
UNION ALL
SELECT 'connections', 'quantity', COUNT(*) FROM connections WHERE quantity IS NULL

UNION ALL

SELECT 'operators', 'operator_id', COUNT(*) FROM operators WHERE operator_id IS NULL
UNION ALL
SELECT 'operators', 'title', COUNT(*) FROM operators WHERE title IS NULL;


/* [6] SAMPLE ROWS WITH CRITICAL NULL VALUES (Debugging)
   Shows specific problem records for investigation
 */

-- Stations with missing critical data
SELECT 
    station_id, 
    title, 
    latitude, 
    longitude, 
    status_type_id,
    operator_id
FROM stations
WHERE latitude IS NULL
   OR longitude IS NULL
   OR status_type_id IS NULL
   OR title IS NULL
LIMIT 20;


-- Connections with missing critical data
SELECT 
    connection_id, 
    station_id, 
    connection_type_id, 
    quantity,
    power_kw
FROM connections
WHERE station_id IS NULL
   OR connection_type_id IS NULL
   OR quantity IS NULL
LIMIT 20;


-- Operators with missing critical data
SELECT 
    operator_id, 
    title, 
    url, 
    contact_email,
    is_active
FROM operators
WHERE operator_id IS NULL
   OR title IS NULL
LIMIT 20;


/* [7] REFERENCE TABLE COMPLETENESS CHECK
   Ensures all reference data is fully populated
 */

-- Check for any NULL values in reference table titles (should be zero)
SELECT
    'status_types' AS table_name,
    COUNT(*) AS null_titles
FROM status_types
WHERE title IS NULL

UNION ALL

SELECT 'usage_types', COUNT(*) FROM usage_types WHERE title IS NULL
UNION ALL
SELECT 'connection_types', COUNT(*) FROM connection_types WHERE title IS NULL
UNION ALL
SELECT 'connection_current_types', COUNT(*) FROM connection_current_types WHERE title IS NULL
UNION ALL
SELECT 'charger_levels', COUNT(*) FROM charger_levels WHERE title IS NULL
UNION ALL
SELECT 'power_supply_types', COUNT(*) FROM power_supply_types WHERE title IS NULL;


/* [8] DATA QUALITY REPORT SUMMARY
   Overall assessment of data quality
 */

SELECT
    '[INFO] NULL Value Analysis Complete' AS status,
    '[INFO] Review results above for any unexpected NULLs' AS action,
    '[INFO] Expected NULL counts: 0 in required columns, variable in optional columns' AS expectation,
    '[INFO] Pipeline v2.0.0 (February 2026)' AS version;
