

import urllib.parse
from sqlalchemy import create_engine
import sys
import os

# Add the project root to the path so we can import config
# This assumes this file is in etl/db/ and we want to reach config/
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, '..', '..'))
if project_root not in sys.path:
    sys.path.append(project_root)

try:
    from config.db_config import DB_CONFIG
except ImportError:
    print("Warning: Could not import DB_CONFIG from config.db_config")
    DB_CONFIG = {}

def get_engine():
    """Create and return a SQLAlchemy engine for MySQL."""

    user = DB_CONFIG.get("user")
    password = DB_CONFIG.get("password")
    host = DB_CONFIG.get("host", "127.0.0.1")
    port = DB_CONFIG.get("port", 3306)
    database = DB_CONFIG.get("database", "ev_poi_db")
    

    # URL encode the user and password to handle special characters (e.g. spaces, @)
    encoded_user = urllib.parse.quote(user)
    encoded_password = urllib.parse.quote_plus(password)
    
    # Construct the connection string
    # mysql+mysqlconnector://user:password@host:port/database
    db_url = f"mysql+mysqlconnector://{encoded_user}:{encoded_password}@{host}:{port}/{database}"
    
    engine = create_engine(db_url, echo=False)
    return engine

def test_connection():
    """Test the database connection."""
    try:
        engine = get_engine()
        with engine.connect() as conn:
            print("Successfully connected to the database!")
        return True
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return False

if __name__ == "__main__":
    test_connection()
