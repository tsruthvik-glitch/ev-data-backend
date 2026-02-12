/* =========================================================================
   File: 02_availability_analysis.sql
   Purpose:
     - Analyze operational availability of EV charging stations
     - Measure downtime, partial availability, data staleness
     - Support reliability, maintenance planning, and data quality assessment
   Definitions:
     - Operational: stations with is_operational = 1 (or TRUE in Postgres)
     - Recently verified: date_last_verified within last 180 days
     - Fast charger: power_kw >= 50
   Notes:
     - Interval syntax varies by DB (INTERVAL '180 days' for Postgres, CURRENT_DATE - 180 for SQLite)
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] OVERALL STATION AVAILABILITY BREAKDOWN
   Count of stations by operational status
+ */
SELECT
    COALESCE(st.title,'Unknown') AS status,
    COUNT(s.station_id) AS station_count
FROM stations s
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
GROUP BY COALESCE(st.title,'Unknown')
ORDER BY station_count DESC;


/* [2] PERCENTAGE AVAILABILITY ACROSS ALL STATIONS */
SELECT
    ROUND(100.0 * SUM(CASE WHEN st.is_operational IN (1,TRUE) THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS operational_pct,
    ROUND(100.0 * SUM(CASE WHEN st.is_operational IN (0,FALSE) THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS non_operational_pct,
    COUNT(*) AS total_stations
FROM stations s
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id;


/* [3] CITY-WISE AVAILABILITY DISTRIBUTION */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    COALESCE(st.title,'Unknown') AS status,
    COUNT(*) AS station_count
FROM stations s
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,''), COALESCE(st.title,'Unknown')
ORDER BY city, state, station_count DESC;


/* [4] OPERATORS WITH HIGHEST NON-OPERATIONAL STATIONS (Top 20) */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COUNT(*) AS non_operational_count,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM stations WHERE status_type_id = (SELECT status_type_id FROM status_types WHERE is_operational IN (0,FALSE) LIMIT 1)),0),2) AS pct_of_all_non_op
FROM stations s
LEFT JOIN operators o ON s.operator_id = o.operator_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
WHERE st.is_operational IN (0,FALSE)
GROUP BY COALESCE(o.title,'Independent/Unknown')
ORDER BY non_operational_count DESC
LIMIT 20;


/* [5] FAST CHARGER AVAILABILITY (Power >= 50 kW) */
SELECT
    COALESCE(st.title,'Unknown') AS status,
    COUNT(c.connection_id) AS fast_charger_count,
    ROUND(100.0 * COUNT(c.connection_id) / NULLIF((SELECT COUNT(*) FROM connections WHERE power_kw >= 50),0),2) AS pct_of_all_fast
FROM connections c
JOIN stations s ON c.station_id = s.station_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
WHERE c.power_kw >= 50
GROUP BY COALESCE(st.title,'Unknown')
ORDER BY fast_charger_count DESC;


/* [6] AVAILABILITY BY USAGE TYPE (Public vs Private) */
SELECT
    COALESCE(ut.title,'Unknown') AS usage_type,
    COALESCE(st.title,'Unknown') AS status,
    COUNT(*) AS station_count
FROM stations s
LEFT JOIN usage_types ut ON s.usage_type_id = ut.usage_type_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
GROUP BY COALESCE(ut.title,'Unknown'), COALESCE(st.title,'Unknown')
ORDER BY usage_type, status, station_count DESC;


/* [7] RECENTLY VERIFIED BUT NON-OPERATIONAL STATIONS
   These stations were checked recently but are still not operational—potential maintenance needed
+ */
SELECT
    s.station_id,
    COALESCE(s.title, 'station_'||s.station_id) AS station_title,
    COALESCE(s.city,'') AS city,
    COALESCE(s.state,'') AS state,
    s.date_last_verified,
    COALESCE(st.title,'Unknown') AS status
FROM stations s
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
WHERE st.is_operational IN (0,FALSE)
  AND s.date_last_verified IS NOT NULL
ORDER BY s.date_last_verified DESC
LIMIT 25;


/* [8] DATA STALENESS RISK: STATIONS NOT VERIFIED IN 180+ DAYS
   High risk indicators for data accuracy and operational status
+ */
SELECT
    s.station_id,
    COALESCE(s.title, 'station_'||s.station_id) AS station_title,
    COALESCE(s.city,'') AS city,
    COALESCE(s.state,'') AS state,
    s.date_last_verified,
    COALESCE(st.title,'Unknown') AS status,
    CASE
        WHEN s.date_last_verified IS NULL THEN 'Never verified'
        WHEN CAST((JULIANDAY('now') - JULIANDAY(s.date_last_verified)) AS INTEGER) > 180 THEN 'Data stale (180+ days)'
        ELSE 'Recent'
    END AS data_quality_flag
FROM stations s
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
WHERE s.date_last_verified IS NULL
   OR CAST((JULIANDAY('now') - JULIANDAY(s.date_last_verified)) AS INTEGER) > 180
ORDER BY s.date_last_verified ASC NULLS FIRST;


/* [9] AVAILABILITY TREND PROXY (by last status update date)
   Aggregate operational status by update date to identify patterns over time
+ */
SELECT
    DATE(s.date_last_status_update) AS status_update_date,
    COALESCE(st.title,'Unknown') AS status,
    COUNT(*) AS station_count
FROM stations s
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
WHERE s.date_last_status_update IS NOT NULL
GROUP BY DATE(s.date_last_status_update), COALESCE(st.title,'Unknown')
ORDER BY status_update_date DESC;


/* [10] STATIONS WITH MANY CONNECTORS BUT POOR AVAILABILITY
    High-capacity stations that are offline or underutilized—infrastructure risk
+ */
SELECT
    s.station_id,
    COALESCE(s.title, 'station_'||s.station_id) AS station_title,
    COALESCE(s.city,'') AS city,
    COALESCE(s.state,'') AS state,
    COUNT(c.connection_id) AS total_connections,
    COALESCE(st.title,'Unknown') AS status
FROM stations s
JOIN connections c ON s.station_id = c.station_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
WHERE st.is_operational IN (0,FALSE)
GROUP BY s.station_id, COALESCE(s.title, 'station_'||s.station_id), COALESCE(s.city,''), COALESCE(s.state,''), COALESCE(st.title,'Unknown')
HAVING COUNT(c.connection_id) >= 4
ORDER BY total_connections DESC;


/* [11] SUMMARY METRICS FOR AVAILABILITY ANALYSIS */
SELECT
    (SELECT COUNT(*) FROM stations) AS total_stations,
    (SELECT COUNT(*) FROM connections) AS total_connections,
    (SELECT COUNT(*) FROM stations WHERE status_type_id IN (SELECT status_type_id FROM status_types WHERE is_operational IN (1,TRUE))) AS operational_stations,
    (SELECT COUNT(*) FROM stations WHERE status_type_id IN (SELECT status_type_id FROM status_types WHERE is_operational IN (0,FALSE))) AS non_operational_stations,
    (SELECT COUNT(*) FROM stations WHERE date_last_verified IS NULL OR CAST((JULIANDAY('now') - JULIANDAY(date_last_verified)) AS INTEGER) > 180) AS stale_data_stations;
