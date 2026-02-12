/* =========================================================================
   View: vw_station_summary
   Purpose:
     - Provide a denormalized, analytics-friendly summary of all stations
     - Combine stations, operators, connections, status, and usage types
     - Enable fast analytics, BI dashboards, and reporting without joins
   Definitions:
     - Fast charger: connector with power_kw >= 50
     - Operational: status with is_operational = 1 (or TRUE in Postgres)
     - Recently verified: date_last_verified within last 180 days (proxy, computed separately)
   Notes:
     - View is idempotent (CREATE OR REPLACE); works on SQLite and Postgres
     - Includes aggregated connection metrics and charger level counts
   Version: v2.0.0 (February 2026)
   ========================================================================= */

CREATE OR REPLACE VIEW vw_station_summary AS
SELECT
    /* Station core identifiers & location */
    s.station_id,
    COALESCE(s.title, 'station_'||s.station_id) AS station_title,
    COALESCE(s.city, 'Unknown') AS city,
    COALESCE(s.state, '') AS state,
    COALESCE(s.country, 'Unknown') AS country,
    s.latitude,
    s.longitude,

    /* Operator information */
    o.operator_id,
    COALESCE(o.title, 'Independent/Unknown') AS operator_title,

    /* Usage and status categories */
    ut.usage_type_id,
    COALESCE(ut.title, 'Unknown') AS usage_type,
    st.status_type_id,
    COALESCE(st.title, 'Unknown') AS status_title,
    COALESCE(st.is_operational, 0) AS is_operational,

    /* Station lifecycle and verification */
    s.date_created,
    s.date_last_verified,
    CASE
        WHEN s.date_last_verified IS NULL THEN 'Never verified'
        WHEN CAST((JULIANDAY('now') - JULIANDAY(s.date_last_verified)) AS INTEGER) > 180 THEN 'Stale (180+ days)'
        ELSE 'Recently verified'
    END AS verification_status,

    /* Aggregated connection metrics */
    COUNT(c.connection_id) AS total_connections,
    COUNT(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) AS fast_charger_count,
    ROUND(COALESCE(MAX(c.power_kw), 0), 2) AS max_power_kw,
    ROUND(COALESCE(AVG(c.power_kw), 0), 2) AS avg_power_kw,
    ROUND(100.0 * COUNT(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) / NULLIF(COUNT(c.connection_id), 0), 2) AS fast_charger_pct,

    /* Charger level breakdown */
    COUNT(CASE WHEN c.level_id = 1 THEN 1 ELSE 0 END) AS level1_count,
    COUNT(CASE WHEN c.level_id = 2 THEN 1 ELSE 0 END) AS level2_count,
    COUNT(CASE WHEN c.level_id = 3 THEN 1 ELSE 0 END) AS dc_fast_count

FROM stations s
LEFT JOIN operators o ON s.operator_id = o.operator_id
LEFT JOIN usage_types ut ON s.usage_type_id = ut.usage_type_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
LEFT JOIN connections c ON s.station_id = c.station_id

GROUP BY
    s.station_id,
    COALESCE(s.title, 'station_'||s.station_id),
    COALESCE(s.city, 'Unknown'),
    COALESCE(s.state, ''),
    COALESCE(s.country, 'Unknown'),
    s.latitude,
    s.longitude,
    o.operator_id,
    COALESCE(o.title, 'Independent/Unknown'),
    ut.usage_type_id,
    COALESCE(ut.title, 'Unknown'),
    st.status_type_id,
    COALESCE(st.title, 'Unknown'),
    COALESCE(st.is_operational, 0),
    s.date_created,
    s.date_last_verified;
