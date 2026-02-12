
import sqlite3
import pandas as pd
import os

DB_NAME = "ev.db"

def load_data(df):
    """
    Loads the transformed DataFrame into a SQLite database.
    """
    if df.empty:
        print("No data to load.")
        return

    try:
        # Create database connection
        # Ensure the path is relative to where script is run or absolute
        db_path = os.path.join(os.path.dirname(__file__), "..", "data", DB_NAME)
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        
        conn = sqlite3.connect(db_path)
        
        # Write to SQL
        df.to_sql("ev_data", conn, if_exists="replace", index=False)
        print(f"Successfully loaded {len(df)} records into {DB_NAME}.")
        
    except sqlite3.Error as e:
        print(f"Database error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    # Test with dummy data
    pass
