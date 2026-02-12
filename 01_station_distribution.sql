/* =========================================================================
   File: 01_station_distribution.sql
   Purpose:
     - Analyze distribution of EV charging stations for reporting and exploration
     - Provide cross-database (SQLite/PostgreSQL) compatible queries
     - Summarize distribution by status, usage, operator, country, connector types
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] TOTAL STATIONS BY OPERATIONAL STATUS */
-- Count of stations grouped by status (ACTIVE, PLANNED, REMOVED, etc.)
SELECT
    st.title AS status,
    COUNT(s.station_id) AS station_count,
    ROUND(100.0 * COUNT(s.station_id) / NULLIF((SELECT COUNT(*) FROM stations),0),2) AS pct_total
FROM stations s
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
GROUP BY st.title
ORDER BY station_count DESC;


/* [2] STATIONS BY USAGE TYPE */
-- Public vs Private vs Members-only
SELECT
    COALESCE(ut.title,'Unknown') AS usage_type,
    COUNT(s.station_id) AS station_count,
    ROUND(100.0 * COUNT(s.station_id) / NULLIF((SELECT COUNT(*) FROM stations),0),2) AS pct_total
FROM stations s
LEFT JOIN usage_types ut ON s.usage_type_id = ut.usage_type_id
GROUP BY COALESCE(ut.title,'Unknown')
ORDER BY station_count DESC;


/* [3] STATIONS BY OPERATOR (TOP 15) */
-- Shows which networks host the most stations
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COUNT(s.station_id) AS station_count,
    ROUND(100.0 * COUNT(s.station_id) / NULLIF((SELECT COUNT(*) FROM stations),0),2) AS pct_total
FROM stations s
LEFT JOIN operators o ON s.operator_id = o.operator_id
GROUP BY COALESCE(o.title,'Independent/Unknown')
ORDER BY station_count DESC
LIMIT 15;


/* [4] STATIONS BY COUNTRY */
-- Top countries by number of stations
SELECT
    COALESCE(country,'Unknown') AS country,
    COUNT(station_id) AS station_count,
    ROUND(100.0 * COUNT(station_id) / NULLIF((SELECT COUNT(*) FROM stations),0),2) AS pct_total
FROM stations
GROUP BY COALESCE(country,'Unknown')
ORDER BY station_count DESC
LIMIT 20;


/* [5] CONNECTOR TYPE DISTRIBUTION
   Counts per connector type based on connections table
 */
SELECT
    COALESCE(ct.title,'Unknown') AS connector_type,
    COUNT(c.connection_id) AS connection_count,
    COUNT(DISTINCT c.station_id) AS stations_with_connector,
    ROUND(100.0 * COUNT(c.connection_id) / NULLIF((SELECT COUNT(*) FROM connections),0),2) AS pct_of_connections
FROM connections c
LEFT JOIN connection_types ct ON c.connection_type_id = ct.connection_type_id
GROUP BY COALESCE(ct.title,'Unknown')
ORDER BY connection_count DESC
LIMIT 20;


/* [6] HIGH-POWER CONNECTORS (>= 50 kW) - per station */
-- Number of stations that have at least one connector >= 50 kW
SELECT
    COUNT(DISTINCT c.station_id) AS stations_with_high_power_connectors
FROM connections c
WHERE c.power_kw >= 50;


/* [7] STATIONS WITH MULTIPLE CONNECTIONS (BUCKETED)
   Uses connections table to compute counts per station
 */
WITH station_conn_counts AS (
    SELECT station_id, COUNT(*) AS conn_count
    FROM connections
    GROUP BY station_id
)
SELECT
    CASE
        WHEN conn_count = 1 THEN '1'
        WHEN conn_count BETWEEN 2 AND 4 THEN '2-4'
        WHEN conn_count BETWEEN 5 AND 10 THEN '5-10'
        ELSE '11+'
    END AS connection_bucket,
    COUNT(*) AS station_count
FROM station_conn_counts
GROUP BY connection_bucket
ORDER BY station_count DESC;


/* [8] SPATIAL DISTRIBUTION (GRID) - rounded lat/lon bins
   Useful for heatmaps; rounds coordinates to 2 decimal places (~1km resolution)
 */
SELECT
    ROUND(latitude,2) AS lat_round,
    ROUND(longitude,2) AS lon_round,
    COUNT(*) AS stations_in_cell
FROM stations
WHERE latitude IS NOT NULL AND longitude IS NOT NULL
GROUP BY ROUND(latitude,2), ROUND(longitude,2)
ORDER BY stations_in_cell DESC
LIMIT 50;


/* [9] TOP CONNECTOR TYPES PER COUNTRY (sample)
   Shows most common connector in each top country
 */
WITH country_connector AS (
    SELECT
        s.country,
        ct.title AS connector_type,
        COUNT(*) AS cnt
    FROM connections c
    JOIN stations s ON c.station_id = s.station_id
    LEFT JOIN connection_types ct ON c.connection_type_id = ct.connection_type_id
    WHERE s.country IS NOT NULL
    GROUP BY s.country, ct.title
)
SELECT country, connector_type, cnt
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY country ORDER BY cnt DESC) AS rn
    FROM country_connector
) t
WHERE rn = 1
ORDER BY cnt DESC
LIMIT 30;


/* [10] DISTRIBUTION SUMMARY
   Compact overview of core distribution metrics
 */
SELECT
    (SELECT COUNT(*) FROM stations) AS total_stations,
    (SELECT COUNT(*) FROM connections) AS total_connections,
    (SELECT COUNT(DISTINCT operator_id) FROM stations) AS operators_referenced,
    (SELECT COUNT(*) FROM connection_types) AS known_connector_types,
    (SELECT COUNT(*) FROM charger_levels) AS charger_level_count;

