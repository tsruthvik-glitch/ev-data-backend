
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, BigInteger
from sqlalchemy.orm import relationship
from .database import Base

class Station(Base):
    __tablename__ = "stations"

    station_id = Column(BigInteger, primary_key=True, index=True)
    uuid = Column(String(255))
    name = Column(String(255))
    city = Column(String(255))
    latitude = Column(Float)
    longitude = Column(Float)
    status = Column(String(50))
    number_of_points = Column(Integer)
    date_created = Column(DateTime)

    connections = relationship("Connection", back_populates="station")

class Connection(Base):
    __tablename__ = "connections"

    id = Column(Integer, primary_key=True, index=True)
    station_id = Column(BigInteger, ForeignKey("stations.station_id"))
    connection_id = Column(Integer)
    connection_type = Column(String(255))
    power_kw = Column(Float)
    voltage = Column(Integer)
    current_type = Column(String(50))
    quantity = Column(Integer)
    status = Column(String(50))

    station = relationship("Station", back_populates="connections")
