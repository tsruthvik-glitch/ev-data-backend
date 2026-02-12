
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import urllib.parse
import sys
import os

# Add project root to sys.path to access config
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

try:
    from config.db_config import DB_CONFIG
except ImportError:
    # Fallback or error if config not found
    print("Warning: Could not import DB_CONFIG. Please ensure config/db_config.py exists.")
    DB_CONFIG = {}

def get_db_url():
    user = DB_CONFIG.get("user", "root")
    password = DB_CONFIG.get("password", "")
    host = DB_CONFIG.get("host", "127.0.0.1")
    port = DB_CONFIG.get("port", 3306)
    database = DB_CONFIG.get("database", "ev_poi_db")
    
    encoded_user = urllib.parse.quote(user)
    encoded_password = urllib.parse.quote_plus(password)
    
    return f"mysql+mysqlconnector://{encoded_user}:{encoded_password}@{host}:{port}/{database}"

SQLALCHEMY_DATABASE_URL = get_db_url()

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
