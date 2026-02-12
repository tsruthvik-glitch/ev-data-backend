/* =========================================================================
   File: 02_operator_coverage.sql
   Purpose:
     - Analyze EV charging operator coverage and market presence
     - Measure geographic spread, infrastructure strength, and service mix per operator
     - Produce cross-database compatible queries (SQLite/PostgreSQL)
   Version: v2.0.0 (February 2026)
   ========================================================================= */


/* [1] TOTAL STATIONS PER OPERATOR (MARKET SHARE)
   Shows station count and percent of total stations for each operator
 */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COUNT(s.station_id) AS total_stations,
    ROUND(100.0 * COUNT(s.station_id) / NULLIF((SELECT COUNT(*) FROM stations),0),2) AS pct_of_network
FROM stations s
LEFT JOIN operators o ON s.operator_id = o.operator_id
GROUP BY COALESCE(o.title,'Independent/Unknown')
ORDER BY total_stations DESC;


/* [2] OPERATOR COVERAGE BY COUNTRY
   Station counts per operator per country; useful for regional market analysis
 */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COALESCE(s.country,'Unknown') AS country,
    COUNT(s.station_id) AS station_count
FROM stations s
LEFT JOIN operators o ON s.operator_id = o.operator_id
GROUP BY COALESCE(o.title,'Independent/Unknown'), COALESCE(s.country,'Unknown')
ORDER BY operator, station_count DESC;


/* [3] COUNTRIES COVERED PER OPERATOR
   Number of distinct countries where each operator has stations
 */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COUNT(DISTINCT COALESCE(s.country,'Unknown')) AS countries_covered
FROM stations s
LEFT JOIN operators o ON s.operator_id = o.operator_id
GROUP BY COALESCE(o.title,'Independent/Unknown')
ORDER BY countries_covered DESC;


/* [4] TOP OPERATORS BY GEOGRAPHIC SPREAD (TOP 10)
 */
SELECT
    operator, countries_covered
FROM (
    SELECT
        COALESCE(o.title,'Independent/Unknown') AS operator,
        COUNT(DISTINCT COALESCE(s.country,'Unknown')) AS countries_covered
    FROM stations s
    LEFT JOIN operators o ON s.operator_id = o.operator_id
    GROUP BY COALESCE(o.title,'Independent/Unknown')
    ORDER BY countries_covered DESC
    LIMIT 10
) t;


/* [5] AVERAGE CONNECTIONS PER STATION (INFRASTRUCTURE SIZE)
   Uses connections table to compute average number of connectors per station for each operator
 */
WITH ops_station_connections AS (
    SELECT s.operator_id, s.station_id, COUNT(c.connection_id) AS connections_per_station
    FROM stations s
    LEFT JOIN connections c ON s.station_id = c.station_id
    GROUP BY s.operator_id, s.station_id
)
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    ROUND(AVG(osc.connections_per_station),2) AS avg_connectors_per_station,
    ROUND(AVG(COALESCE(s.number_of_points,0)),2) AS avg_reported_points
FROM ops_station_connections osc
LEFT JOIN operators o ON osc.operator_id = o.operator_id
LEFT JOIN stations s ON osc.station_id = s.station_id
GROUP BY COALESCE(o.title,'Independent/Unknown')
ORDER BY avg_connectors_per_station DESC
LIMIT 20;


/* [6] OPERATORS WITH FAST-CHARGING COVERAGE (>= 50 kW)
   Number of stations per operator that have at least one connector >= 50 kW
 */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COUNT(DISTINCT s.station_id) AS stations_with_high_power
FROM stations s
LEFT JOIN operators o ON s.operator_id = o.operator_id
LEFT JOIN connections c ON s.station_id = c.station_id AND c.power_kw >= 50
WHERE c.connection_id IS NOT NULL
GROUP BY COALESCE(o.title,'Independent/Unknown')
ORDER BY stations_with_high_power DESC
LIMIT 20;


/* [7] OPERATOR STATION STATUS DISTRIBUTION
   Breakdown of station statuses (ACTIVE, PLANNED, REMOVED, etc.) per operator
 */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COALESCE(st.title,'Unknown') AS status,
    COUNT(s.station_id) AS station_count
FROM stations s
LEFT JOIN operators o ON s.operator_id = o.operator_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
GROUP BY COALESCE(o.title,'Independent/Unknown'), COALESCE(st.title,'Unknown')
ORDER BY operator, station_count DESC;


/* [8] OPERATOR MARKET SHARE PER COUNTRY (TOP 5 PER COUNTRY)
   For each country show top 5 operators by station count
 */
WITH country_ops AS (
    SELECT
        COALESCE(s.country,'Unknown') AS country,
        COALESCE(o.title,'Independent/Unknown') AS operator,
        COUNT(s.station_id) AS station_count
    FROM stations s
    LEFT JOIN operators o ON s.operator_id = o.operator_id
    GROUP BY COALESCE(s.country,'Unknown'), COALESCE(o.title,'Independent/Unknown')
)
SELECT country, operator, station_count
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY country ORDER BY station_count DESC) AS rn
    FROM country_ops
) t
WHERE rn <= 5
ORDER BY country, station_count DESC;


/* [9] OPERATOR CONNECTOR MIX
   Distribution of connector types deployed by each operator (sample top operators)
 */
SELECT
    COALESCE(o.title,'Independent/Unknown') AS operator,
    COALESCE(ct.title,'Unknown') AS connector_type,
    COUNT(c.connection_id) AS connector_count,
    ROUND(100.0 * COUNT(c.connection_id) / NULLIF((SELECT COUNT(*) FROM connections),0),2) AS pct_of_all_connections
FROM connections c
LEFT JOIN stations s ON c.station_id = s.station_id
LEFT JOIN operators o ON s.operator_id = o.operator_id
LEFT JOIN connection_types ct ON c.connection_type_id = ct.connection_type_id
GROUP BY COALESCE(o.title,'Independent/Unknown'), COALESCE(ct.title,'Unknown')
ORDER BY operator, connector_count DESC
LIMIT 200;


/* [10] SUMMARY METRICS
   Compact operator-level summary useful for dashboards
 */
SELECT
    (SELECT COUNT(*) FROM stations) AS total_stations,
    (SELECT COUNT(*) FROM connections) AS total_connections,
    (SELECT COUNT(DISTINCT operator_id) FROM stations) AS operators_referenced,
    (SELECT COUNT(*) FROM connection_types) AS known_connector_types;

