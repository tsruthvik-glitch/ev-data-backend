/* =========================================================================
   File: 03_growth_readiness.sql
   Purpose:
     - Evaluate EV infrastructure readiness for future growth
     - Identify cities and operators prepared for demand scaling
     - Assess fast-charger density, capacity, reliability, and data freshness
   Definitions:
     - Fast charger: power_kw >= 50
     - Expansion-ready: >=4 connectors AND max power >= 50 kW
     - Operational: is_operational = 1 (or TRUE in Postgres)
   Notes:
     - Growth readiness score: weighted composite (40% fast chargers, 40% operational, 20% station count)
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] CITIES WITH HIGHEST STATION DENSITY (Growth Potential Hubs) */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    COUNT(DISTINCT s.station_id) AS total_stations
FROM stations s
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,'')
ORDER BY total_stations DESC
LIMIT 20;


/* [2] CITIES WITH STRONG FAST-CHARGER PRESENCE (>= 50 kW) */
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


/* [3] FAST-CHARGER READINESS RATIO BY CITY
   Percentage of fast chargers in cities with >= 10 total connections
+ */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) AS fast_chargers,
    COUNT(c.connection_id) AS total_chargers,
    ROUND(100.0 * SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) / NULLIF(COUNT(c.connection_id),0),2) AS fast_charger_pct
FROM stations s
JOIN connections c ON s.station_id = c.station_id
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,'')
HAVING COUNT(c.connection_id) >= 10
ORDER BY fast_charger_pct DESC;


/* [4] OPERATORS BEST POSITIONED FOR FUTURE GROWTH (Top 20) */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COUNT(DISTINCT s.station_id) AS total_stations,
    SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) AS fast_chargers,
    COUNT(c.connection_id) AS total_connections
FROM operators o
LEFT JOIN stations s ON o.operator_id = s.operator_id
LEFT JOIN connections c ON s.station_id = c.station_id
GROUP BY COALESCE(o.title,'Independent/Unknown')
ORDER BY fast_chargers DESC, total_stations DESC
LIMIT 20;


/* [5] STATIONS WITH EXPANSION-READY INFRASTRUCTURE
    Stations with >=4 connections and at least one high-power (>=50kW) charger
+ */
SELECT
    s.station_id,
    COALESCE(s.title, 'station_'||s.station_id) AS station_title,
    COALESCE(s.city,'') AS city,
    COALESCE(s.state,'') AS state,
    COUNT(c.connection_id) AS total_connections,
    ROUND(MAX(COALESCE(c.power_kw,0)),2) AS max_power_kw,
    SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) AS fast_charger_count
FROM stations s
LEFT JOIN connections c ON s.station_id = c.station_id
GROUP BY s.station_id, COALESCE(s.title, 'station_'||s.station_id), COALESCE(s.city,''), COALESCE(s.state,'')
HAVING COUNT(c.connection_id) >= 4 AND MAX(COALESCE(c.power_kw,0)) >= 50
ORDER BY max_power_kw DESC, total_connections DESC;


/* [6] STATION DISTRIBUTION BY USAGE TYPE (Public vs Private) */
SELECT
    COALESCE(ut.title,'Unknown') AS usage_type,
    COUNT(DISTINCT s.station_id) AS station_count,
    COUNT(c.connection_id) AS total_connections,
    SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) AS fast_chargers
FROM stations s
LEFT JOIN usage_types ut ON s.usage_type_id = ut.usage_type_id
LEFT JOIN connections c ON s.station_id = c.station_id
GROUP BY COALESCE(ut.title,'Unknown')
ORDER BY station_count DESC;


/* [7] GROWTH-READY CITIES WITH OPERATIONAL RELIABILITY
    Cities with >=10 stations and their operational status
+ */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    COUNT(DISTINCT s.station_id) AS total_stations,
    SUM(CASE WHEN st.is_operational IN (1,TRUE) THEN 1 ELSE 0 END) AS operational_stations,
    ROUND(100.0 * SUM(CASE WHEN st.is_operational IN (1,TRUE) THEN 1 ELSE 0 END) / NULLIF(COUNT(DISTINCT s.station_id),0),2) AS operational_pct
FROM stations s
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,'')
HAVING COUNT(DISTINCT s.station_id) >= 10
ORDER BY operational_pct DESC;


/* [8] RECENTLY VERIFIED HIGH-CAPACITY STATIONS
    Stations with recent verification and high power capability (expansion-ready)
+ */
SELECT
    s.station_id,
    COALESCE(s.title, 'station_'||s.station_id) AS station_title,
    COALESCE(s.city,'') AS city,
    COALESCE(s.state,'') AS state,
    s.date_last_verified,
    ROUND(MAX(COALESCE(c.power_kw,0)),2) AS max_power_kw
FROM stations s
LEFT JOIN connections c ON s.station_id = c.station_id
WHERE s.date_last_verified IS NOT NULL
GROUP BY s.station_id, COALESCE(s.title, 'station_'||s.station_id), COALESCE(s.city,''), COALESCE(s.state,''), s.date_last_verified
HAVING MAX(COALESCE(c.power_kw,0)) >= 50
ORDER BY max_power_kw DESC
LIMIT 25;


/* [9] UNDERSERVED CITIES (Low fast-charger density despite many stations)
    Growth opportunity indicator: cities with >= 10 stations but < 3 fast chargers
+ */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    COUNT(DISTINCT s.station_id) AS stations,
    SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) AS fast_chargers,
    COUNT(c.connection_id) AS total_connections
FROM stations s
LEFT JOIN connections c ON s.station_id = c.station_id
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,'')
HAVING COUNT(DISTINCT s.station_id) >= 10
   AND SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) < 3
ORDER BY stations DESC;


/* [10] GROWTH READINESS COMPOSITE SCORE (Top 20)
    Weighted scoring: 40% fast chargers + 40% operational + 20% station count
+ */
SELECT
    COALESCE(s.city,'Unknown') AS city,
    COALESCE(s.state,'') AS state,
    COUNT(DISTINCT s.station_id) AS stations,
    SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) AS fast_chargers,
    SUM(CASE WHEN st.is_operational IN (1,TRUE) THEN 1 ELSE 0 END) AS operational_stations,
    ROUND(
        (
            SUM(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) * 0.4 +
            SUM(CASE WHEN st.is_operational IN (1,TRUE) THEN 1 ELSE 0 END) * 0.4 +
            COUNT(DISTINCT s.station_id) * 0.2
        ),
        2
    ) AS growth_readiness_score
FROM stations s
LEFT JOIN connections c ON s.station_id = c.station_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
GROUP BY COALESCE(s.city,'Unknown'), COALESCE(s.state,'')
ORDER BY growth_readiness_score DESC
LIMIT 20;


/* [11] SUMMARY METRICS FOR GROWTH READINESS ASSESSMENT */
SELECT
    (SELECT COUNT(DISTINCT city) FROM stations WHERE city IS NOT NULL) AS total_cities,
    (SELECT COUNT(DISTINCT s.city) FROM stations s JOIN connections c ON s.station_id = c.station_id WHERE c.power_kw >= 50) AS cities_with_fast_chargers,
    (SELECT COUNT(DISTINCT operator_id) FROM stations WHERE operator_id IS NOT NULL) AS total_operators,
    (SELECT COUNT(*) FROM stations WHERE date_last_verified IS NOT NULL) AS stations_recently_verified;
