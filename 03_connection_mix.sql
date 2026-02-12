/* =========================================================================
   File: 03_connection_mix.sql
   Purpose:
     - Analyze connector / plug type distribution and power mix
     - Understand AC vs DC split, charger levels, and fast-charging penetration
     - Produce cross-database compatible results suitable for reporting (SQLite/Postgres)
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] OVERALL DISTRIBUTION OF CONNECTION (PLUG) TYPES */
SELECT
    COALESCE(ct.title,'Unknown') AS connection_type,
    COUNT(c.connection_id) AS total_connections,
    COUNT(DISTINCT c.station_id) AS stations_with_this_connector,
    ROUND(100.0 * COUNT(c.connection_id) / NULLIF((SELECT COUNT(*) FROM connections),0),2) AS pct_of_connections
FROM connections c
LEFT JOIN connection_types ct ON c.connection_type_id = ct.connection_type_id
GROUP BY COALESCE(ct.title,'Unknown')
ORDER BY total_connections DESC
LIMIT 50;


/* [2] CONNECTION MIX BY CHARGER LEVEL */
SELECT
    COALESCE(cl.title,'Unknown') AS charger_level,
    COUNT(c.connection_id) AS total_connections,
    ROUND(AVG(c.power_kw),2) AS avg_power_kw
FROM connections c
LEFT JOIN charger_levels cl ON c.level_id = cl.charger_level_id
GROUP BY COALESCE(cl.title,'Unknown')
ORDER BY total_connections DESC;


/* [3] AC vs DC CHARGING MIX (based on current_type reference table)
   Uses `connection_current_types` or `current_type_id` where available
 */
SELECT
    COALESCE(ct.title,'Unknown') AS current_category,
    COUNT(c.connection_id) AS total_connections,
    ROUND(100.0 * COUNT(c.connection_id) / NULLIF((SELECT COUNT(*) FROM connections),0),2) AS pct_of_connections
FROM connections c
LEFT JOIN connection_current_types ct ON c.current_type_id = ct.current_type_id
GROUP BY COALESCE(ct.title,'Unknown')
ORDER BY total_connections DESC;


/* [4] FAST vs SLOW/MEDIUM CHARGING (POWER BUCKETS) */
SELECT
    CASE
        WHEN c.power_kw >= 150 THEN 'Very High (>=150 kW)'
        WHEN c.power_kw >= 50 THEN 'High (50-149 kW)'
        WHEN c.power_kw >= 7 THEN 'Medium (7-49 kW)'
        WHEN c.power_kw IS NOT NULL THEN 'Low (<7 kW)'
        ELSE 'Unknown'
    END AS power_bucket,
    COUNT(*) AS total_connections,
    ROUND(AVG(COALESCE(c.power_kw,0)),2) AS avg_power_kw
FROM connections c
GROUP BY power_bucket
ORDER BY total_connections DESC;


/* [5] CONNECTOR DIVERSITY PER STATION (TOP 20) */
SELECT
    s.station_id,
    COALESCE(s.title, 'station_' || s.station_id) AS station_title,
    COUNT(DISTINCT c.connection_type_id) AS distinct_connector_types,
    COUNT(c.connection_id) AS total_connections
FROM stations s
LEFT JOIN connections c ON s.station_id = c.station_id
GROUP BY s.station_id, COALESCE(s.title, 'station_' || s.station_id)
ORDER BY distinct_connector_types DESC, total_connections DESC
LIMIT 20;


/* [6] MOST COMMON CONNECTOR TYPES FOR FAST CHARGING (>=50 kW) */
SELECT
    COALESCE(ct.title,'Unknown') AS connection_type,
    COUNT(*) AS fast_charge_connections,
    COUNT(DISTINCT c.station_id) AS stations_with_fast_connector
FROM connections c
LEFT JOIN connection_types ct ON c.connection_type_id = ct.connection_type_id
WHERE c.power_kw >= 50
GROUP BY COALESCE(ct.title,'Unknown')
ORDER BY fast_charge_connections DESC
LIMIT 20;


/* [7] OPERATOR-WISE CONNECTION MIX (sample)
   Shows connector counts per operator; limit results for readability
 */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COALESCE(ct.title,'Unknown') AS connection_type,
    COUNT(c.connection_id) AS total_connections
FROM connections c
LEFT JOIN stations s ON c.station_id = s.station_id
LEFT JOIN operators o ON s.operator_id = o.operator_id
LEFT JOIN connection_types ct ON c.connection_type_id = ct.connection_type_id
GROUP BY COALESCE(o.title,'Independent/Unknown'), COALESCE(ct.title,'Unknown')
ORDER BY operator, total_connections DESC
LIMIT 200;


/* [8] CONNECTION AVAILABILITY BY STATION STATUS */
SELECT
    COALESCE(st.title,'Unknown') AS station_status,
    COUNT(c.connection_id) AS total_connections,
    COUNT(DISTINCT c.station_id) AS stations_with_connections
FROM connections c
LEFT JOIN stations s ON c.station_id = s.station_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
GROUP BY COALESCE(st.title,'Unknown')
ORDER BY total_connections DESC;


/* [9] TOP CONNECTOR TYPES PER COUNTRY (SAMPLE)
   Useful to identify regional connector preferences
 */
WITH country_conn AS (
    SELECT
        COALESCE(s.country,'Unknown') AS country,
        COALESCE(ct.title,'Unknown') AS connector_type,
        COUNT(*) AS cnt
    FROM connections c
    JOIN stations s ON c.station_id = s.station_id
    LEFT JOIN connection_types ct ON c.connection_type_id = ct.connection_type_id
    GROUP BY COALESCE(s.country,'Unknown'), COALESCE(ct.title,'Unknown')
)
SELECT country, connector_type, cnt
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY country ORDER BY cnt DESC) AS rn
    FROM country_conn
) t
WHERE rn = 1
ORDER BY cnt DESC
LIMIT 50;


/* [10] SUMMARY METRICS FOR CONNECTION MIX */
SELECT
    (SELECT COUNT(*) FROM connections) AS total_connections,
    (SELECT COUNT(DISTINCT station_id) FROM connections) AS stations_with_connections,
    (SELECT COUNT(*) FROM connection_types) AS known_connection_types,
    (SELECT COUNT(*) FROM connection_current_types) AS current_type_count,
    (SELECT COUNT(*) FROM charger_levels) AS charger_level_count;

