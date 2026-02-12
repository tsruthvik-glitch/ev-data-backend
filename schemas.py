
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class ConnectionBase(BaseModel):
    connection_id: Optional[int] = None
    connection_type: Optional[str] = None
    power_kw: Optional[float] = None
    voltage: Optional[int] = None
    current_type: Optional[str] = None
    quantity: Optional[int] = None
    status: Optional[str] = None

class Connection(ConnectionBase):
    id: int
    station_id: int

    class Config:
        orm_mode = True

class StationBase(BaseModel):
    station_id: int
    uuid: Optional[str] = None
    name: Optional[str] = None
    city: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: Optional[str] = None
    number_of_points: Optional[int] = None
    date_created: Optional[datetime] = None

class Station(StationBase):
    connections: List[Connection] = []

    class Config:
        orm_mode = True
