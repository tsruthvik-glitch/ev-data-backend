
from sqlalchemy.orm import Session
from ..models import models

def get_stations(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Station).offset(skip).limit(limit).all()

def get_station(db: Session, station_id: int):
    return db.query(models.Station).filter(models.Station.station_id == station_id).first()

def get_stats(db: Session):
    total_stations = db.query(models.Station).count()
    total_connections = db.query(models.Connection).count()
    return {"total_stations": total_stations, "total_connections": total_connections}
