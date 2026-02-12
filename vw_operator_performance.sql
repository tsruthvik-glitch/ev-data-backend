/* =========================================================================
   View: vw_operator_performance
   Purpose:
     - Operator-level performance, coverage, and reliability analytics
     - Evaluate scale, operational health, fast-charging strength
     - Enable operator benchmarking and performance comparisons
   Definitions:
     - Operational: stations with is_operational = 1 (or TRUE in Postgres)
     - Fast charger: connector with power_kw >= 50
     - DC fast: connector with level_id = 3
   Notes:
     - View uses LEFT JOINs for cross-database compatibility
     - Handles NULL values with COALESCE for robustness
   Version: v2.0.0 (February 2026)
   ========================================================================= */

CREATE OR REPLACE VIEW vw_operator_performance AS
SELECT
    /* Operator identifiers */
    o.operator_id,
    COALESCE(o.title, 'Independent/Unknown') AS operator_title,

    /* Coverage metrics */
    COUNT(DISTINCT s.station_id) AS total_stations,
    COUNT(DISTINCT s.city) AS cities_covered,
    COUNT(DISTINCT s.country) AS countries_covered,

    /* Operational health */
    COUNT(DISTINCT CASE WHEN st.is_operational IN (1,TRUE) THEN s.station_id END) AS operational_stations,

    ROUND(100.0 * COUNT(DISTINCT CASE WHEN st.is_operational IN (1,TRUE) THEN s.station_id END) / NULLIF(COUNT(DISTINCT s.station_id),0),2) AS operational_pct,

    /* Charging infrastructure - connectivity */
    COUNT(c.connection_id) AS total_connectors,

    COUNT(CASE WHEN c.level_id = 3 THEN 1 ELSE 0 END) AS dc_fast_connectors,

    COUNT(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) AS fast_charger_count,

    ROUND(100.0 * COUNT(CASE WHEN c.power_kw >= 50 THEN 1 ELSE 0 END) / NULLIF(COUNT(c.connection_id),0),2) AS fast_charger_pct,

    /* Power capacity */
    ROUND(COALESCE(MAX(c.power_kw), 0), 2) AS max_power_kw,
    ROUND(COALESCE(AVG(c.power_kw), 0), 2) AS avg_power_kw,

    /* Growth timeline and data freshness */
    MIN(s.date_created) AS first_station_added,
    MAX(s.date_created) AS latest_station_added,

    COUNT(CASE WHEN s.date_last_verified IS NOT NULL AND CAST((JULIANDAY('now') - JULIANDAY(s.date_last_verified)) AS INTEGER) <= 180 THEN 1 ELSE 0 END) AS recently_verified_stations

FROM operators o
LEFT JOIN stations s ON o.operator_id = s.operator_id
LEFT JOIN status_types st ON s.status_type_id = st.status_type_id
LEFT JOIN connections c ON s.station_id = c.station_id

GROUP BY
    o.operator_id,
    COALESCE(o.title, 'Independent/Unknown');
