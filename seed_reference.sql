-- =====================================================
-- SEED DATA FOR EV CHARGING ETL PIPELINE
-- =====================================================
--
-- Reference data for charging levels, connector types, usage types, and status types
-- Compatible with SQLite and PostgreSQL
--
-- Note: Uses INSERT OR IGNORE (SQLite) / ON CONFLICT (PostgreSQL) for idempotent inserts

-- ===============================
-- CHARGER LEVELS
-- ===============================

INSERT INTO charger_levels (
    level_id, level_title, min_power_kw, max_power_kw, current_type, charging_speed, description
) VALUES
(0, 'Unknown', 0.0, 0.0, 'UNKNOWN', 'UNKNOWN', 'Charging level not specified'),
(1, 'Level 1 (AC)', 1.0, 3.7, 'AC', 'SLOW', 'Standard household outlet charging (120V single-phase)'),
(2, 'Level 2 (AC)', 3.7, 22.0, 'AC', 'FAST', 'Dedicated AC charging stations (230V-240V)'),
(3, 'DC Fast Charging', 22.0, 350.0, 'DC', 'RAPID', 'High-power DC fast charging'),
(4, 'Level 3 (DC)', 50.0, 150.0, 'DC', 'ULTRA_FAST', 'Ultra-fast DC charging infrastructure');

-- ===============================
-- CONNECTION TYPES
-- ===============================

INSERT INTO connection_types (
    connection_type_id, connection_title, formal_name, is_discontinued, is_obsolete, connector_category, connector_group
) VALUES
(0, 'Unknown', 'Not Specified', 0, 0, 'UNKNOWN', 'OTHER'),
(1, 'IEC 62196-2 Type 1', 'SAE J1772 / Type 1', 0, 0, 'AC', 'TYPE1'),
(2, 'IEC 62196-2 Type 2', 'Mennekes / Type 2', 0, 0, 'AC', 'TYPE2'),
(3, 'BS1363 3 Pin 13 Amp', 'BS1363 / Type G', 0, 0, 'AC', 'DOMESTIC'),
(4, 'Blue Commando (2P+E)', 'Blue Commando', 0, 0, 'AC', 'DOMESTIC'),
(5, 'IEC 62196-3 CHAdeMO', 'CHAdeMO', 0, 0, 'DC', 'CHADEMO'),
(6, 'Avcon Connector', 'Avcon SAE J1772-2001', 1, 0, 'AC', 'AVCON'),
(7, 'IEC 62196-3 CCS Combo 1', 'CCS Type 1 (Combo 1)', 0, 0, 'DC', 'CCS'),
(8, 'IEC 62196-3 CCS Combo 2', 'CCS Type 2 (Combo 2)', 0, 0, 'DC', 'CCS'),
(9, 'Tesla Connector', 'Tesla Proprietary', 0, 0, 'DC', 'TESLA'),
(10, 'IEC 60309 (Commando)', 'IEC 60309 / Commando', 0, 0, 'AC', 'COMMERCIAL');

-- ===============================
-- USAGE TYPES
-- ===============================

INSERT INTO usage_types (
    usage_type_id, usage_title, pay_at_location, membership_required, access_key_required, is_public, usage_category
) VALUES
(0, '(Unknown)', 0, 0, 0, 0, 'PRIVATE'),
(1, 'Public', 0, 0, 0, 1, 'PUBLIC_FREE'),
(2, 'Private - Restricted Access', 0, 1, 0, 0, 'PRIVATE'),
(3, 'Privately Owned - Notice Required', 0, 0, 0, 0, 'PRIVATE'),
(4, 'Public - Membership Required', 0, 1, 1, 1, 'PUBLIC_MEMBERS_ONLY'),
(5, 'Public - Pay At Location', 1, 0, 0, 1, 'PUBLIC_PAID'),
(6, 'Private - For Staff, Visitors or Customers', 0, 0, 0, 0, 'PRIVATE'),
(7, 'Public - Notice Required', 0, 0, 0, 1, 'PUBLIC_FREE');

-- ===============================
-- STATUS TYPES
-- ===============================

INSERT INTO status_types (
    status_type_id, status_title, is_operational, is_user_selectable, status_category
) VALUES
(0, 'Unknown', 0, 1, 'UNKNOWN'),
(10, 'Currently Available (Automated Status)', 1, 0, 'ACTIVE'),
(20, 'Currently In Use (Automated Status)', 1, 0, 'ACTIVE'),
(30, 'Temporarily Unavailable', 1, 1, 'TEMPORARY'),
(50, 'Operational', 1, 1, 'ACTIVE'),
(75, 'Partly Operational (Mixed)', 1, 1, 'PARTLY_OPERATIONAL'),
(100, 'Not Operational', 0, 1, 'INACTIVE'),
(150, 'Planned For Future Date', 0, 1, 'PLANNED'),
(200, 'Removed (Decommissioned)', 0, 1, 'REMOVED'),
(210, 'Removed (Duplicate Listing)', 0, 1, 'REMOVED');

