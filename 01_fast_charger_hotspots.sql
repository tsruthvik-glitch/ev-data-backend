/* =========================================================================
   File: 01_fast_charger_hotspots.sql
   Purpose:
     - Identify geographic hotspots of fast chargers
     - Analyze fast charging concentration by city/state/country
     - Provide density metrics for planning and gap analysis
   Definitions:
     - Fast charger: connector with `power_kw >= 50`
     - High-power: connector with `power_kw >= 150`
   Notes:
     - Includes both Postgres-optimized and generic (grid) approaches
     - Use Postgres haversine queries if precise radius-based density is required
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] CITY-WISE FAST CHARGER COUNT (Top 20)
   Fast chargers defined as connections with power >= 50 kW
 */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    COUNT(c.connection_id) AS fast_charger_count
FROM stations s
JOIN connections c ON s.station_id = c.station_id
WHERE c.power_kw >= 50
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,'')
ORDER BY fast_charger_count DESC
LIMIT 20;


/* [2] CITY-WISE TOTAL FAST CHARGING CAPACITY (kW) */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    ROUND(SUM(COALESCE(c.power_kw,0)),2) AS total_fast_charging_kw
FROM stations s
JOIN connections c ON s.station_id = c.station_id
WHERE c.power_kw >= 50
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,'')
ORDER BY total_fast_charging_kw DESC
LIMIT 20;


/* [3] FAST CHARGER DENSITY BY COUNTRY */
SELECT
    COALESCE(s.country,'Unknown') AS country,
    COUNT(DISTINCT s.station_id) AS fast_charger_stations,
    COUNT(c.connection_id) AS fast_charger_connections
FROM stations s
JOIN connections c ON s.station_id = c.station_id
WHERE c.power_kw >= 50
GROUP BY COALESCE(s.country,'Unknown')
ORDER BY fast_charger_connections DESC;


/* [4] TOP STATIONS BY NUMBER OF FAST CHARGERS */
SELECT
    s.station_id,
    COALESCE(s.title, 'station_'||s.station_id) AS station_title,
    COALESCE(s.city,'') AS city,
    COALESCE(s.state,'') AS state,
    COUNT(c.connection_id) AS fast_charger_count,
    ROUND(SUM(COALESCE(c.power_kw,0)),2) AS total_power_kw
FROM stations s
JOIN connections c ON s.station_id = c.station_id
WHERE c.power_kw >= 50
GROUP BY s.station_id, COALESCE(s.title, 'station_'||s.station_id), COALESCE(s.city,''), COALESCE(s.state,'')
ORDER BY fast_charger_count DESC, total_power_kw DESC
LIMIT 20;


/* [5] OPERATOR-WISE FAST CHARGER HOTSPOTS (Top 20)
   Operator and city combination with most fast chargers
 */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COALESCE(s.city,'Unknown') AS city,
    COUNT(c.connection_id) AS fast_charger_count
FROM stations s
JOIN connections c ON s.station_id = c.station_id
LEFT JOIN operators o ON s.operator_id = o.operator_id
WHERE c.power_kw >= 50
GROUP BY COALESCE(o.title,'Independent/Unknown'), COALESCE(s.city,'Unknown')
ORDER BY fast_charger_count DESC
LIMIT 20;


/* [6] PERCENTAGE OF FAST CHARGERS PER CITY (cities with >=10 connections)
   Useful to highlight cities where fast charging is proportionally high
 */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    ROUND(100.0 * SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) / NULLIF(COUNT(c.connection_id),0),2) AS fast_charger_percentage,
    COUNT(c.connection_id) AS total_connections
FROM stations s
JOIN connections c ON s.station_id = c.station_id
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,'')
HAVING COUNT(c.connection_id) >= 10
ORDER BY fast_charger_percentage DESC
LIMIT 50;


/* [7] GRID-BASED HOTSPOTS (rounded lat/lon bins)
   Generic approach compatible with SQLite and Postgres; rounds coords to create grid cells
 */
SELECT
    ROUND(latitude,2) AS lat_round,
    ROUND(longitude,2) AS lon_round,
    COUNT(DISTINCT s.station_id) FILTER (WHERE c.power_kw >= 50) AS fast_stations_in_cell,
    COUNT(DISTINCT s.station_id) AS stations_in_cell
FROM stations s
LEFT JOIN connections c ON s.station_id = c.station_id
WHERE s.latitude IS NOT NULL AND s.longitude IS NOT NULL
GROUP BY ROUND(latitude,2), ROUND(longitude,2)
ORDER BY fast_stations_in_cell DESC NULLS LAST, stations_in_cell DESC
LIMIT 100;


/* [8] RADIUS-BASED DENSITY (Postgres - haversine)
   Use this query in Postgres to compute accurate counts of nearby stations within a radius (e.g., 5 km)
   Note: SQLite typically lacks trig functions; skip this on SQLite.
 */
-- SELECT s1.station_id, s1.title, s1.latitude, s1.longitude, COUNT(s2.station_id) AS neighbors_within_5km
-- FROM stations s1
-- JOIN stations s2 ON s2.latitude IS NOT NULL AND s2.longitude IS NOT NULL
-- WHERE (6371 * acos( cos(radians(s1.latitude)) * cos(radians(s2.latitude)) * cos(radians(s2.longitude) - radians(s1.longitude)) + sin(radians(s1.latitude)) * sin(radians(s2.latitude)) )) < 5
-- GROUP BY s1.station_id, s1.title, s1.latitude, s1.longitude
-- ORDER BY neighbors_within_5km DESC
-- LIMIT 50;


/* [9] HIGH-POWER CONNECTORS SUMMARY (>=150 kW) */
SELECT
    COUNT(DISTINCT c.station_id) AS stations_with_150kw_plus,
    COUNT(c.connection_id) AS connections_150kw_plus,
    ROUND(SUM(CASE WHEN c.power_kw >= 150 THEN c.power_kw ELSE 0 END),2) AS total_150kw_capacity
FROM connections c
WHERE c.power_kw >= 150;


/* [10] SUMMARY METRICS FOR FAST CHARGER HOTSPOTS */
SELECT
    (SELECT COUNT(*) FROM stations) AS total_stations,
    (SELECT COUNT(*) FROM connections) AS total_connections,
    (SELECT COUNT(*) FROM connections WHERE power_kw >= 50) AS total_fast_connections,
    ROUND(100.0 * (SELECT COUNT(*) FROM connections WHERE power_kw >= 50) / NULLIF((SELECT COUNT(*) FROM connections),0),2) AS pct_fast_connections,
    (SELECT COUNT(DISTINCT station_id) FROM connections WHERE power_kw >= 50) AS stations_with_fast_connectors;
