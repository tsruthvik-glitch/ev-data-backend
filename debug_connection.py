
import mysql.connector
import sys
import os

# Add the project root to the path so we can import config
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

try:
    from config.db_config import DB_CONFIG
    print("Loaded DB_CONFIG:", DB_CONFIG)
except ImportError:
    print("Warning: Could not import DB_CONFIG from config.db_config")
    DB_CONFIG = {}

def test_connection():
    try:
        # Connect directly using mysql-connector, bypassing SQLAlchemy URL quirks
        conn = mysql.connector.connect(
            user=DB_CONFIG.get("user"),
            password=DB_CONFIG.get("password"),
            host=DB_CONFIG.get("host"),
            port=DB_CONFIG.get("port"),
            database=DB_CONFIG.get("database")
        )
        print("Successfully connected to MySQL with mysql-connector!")
        conn.close()
    except mysql.connector.Error as err:
        print(f"Error connecting to MySQL: {err}")

if __name__ == "__main__":
    test_connection()
