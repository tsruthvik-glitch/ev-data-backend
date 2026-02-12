
# OpenChargeMap Project - SQL Queries

This document contains all the SQL queries used in the ETL pipeline and Web Application.

## DDL (Data Definition Language)

### Create Stations Table
Used in `etl/load/load_stations.py`
```sql
CREATE TABLE IF NOT EXISTS stations (
    station_id BIGINT PRIMARY KEY,
    uuid VARCHAR(255),
    name VARCHAR(255),
    city VARCHAR(255),
    latitude DOUBLE,
    longitude DOUBLE,
    status VARCHAR(50),
    number_of_points INT,
    date_created DATETIME
)
```

### Create Connections Table
Used in `etl/load/load_connections.py`
```sql
CREATE TABLE IF NOT EXISTS connections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    station_id BIGINT,
    connection_id INT,
    connection_type VARCHAR(255),
    power_kw DOUBLE,
    voltage INT,
    current_type VARCHAR(50),
    quantity INT,
    status VARCHAR(50)
)
```

## DML (Data Manipulation Language)

### Insert/Update Stations
Used in `etl/load/load_stations.py`
```sql
REPLACE INTO stations
(station_id, uuid, name, city, latitude, longitude, status, number_of_points, date_created)
VALUES (:station_id, :uuid, :name, :city, :latitude, :longitude, :status, :number_of_points, :date_created)
```

### Clear Connections (Full Reload)
Used in `etl/load/load_connections.py`
```sql
DELETE FROM connections
```

### Insert Connections
Used in `etl/load/load_connections.py`
```sql
INSERT INTO connections
(station_id, connection_id, connection_type, power_kw, voltage, current_type, quantity, status)
VALUES (:station_id, :connection_id, :connection_type, :power_kw, :voltage, :current_type, :quantity, :status)
```

## Data Retrieval

### Select All Stations
Used in `app.py`
```sql
SELECT * FROM stations
```

### Select All Connections
Used in `app.py`
```sql
SELECT * FROM connections
```
