import streamlit as st
import pandas as pd
from pathlib import Path

from etl.db.db_utils import (
    get_connection,
    get_database_url,
    bulk_insert_csv,
    truncate_table,
)

# --------------------------------------------------
# Streamlit Page Config
# --------------------------------------------------
st.set_page_config(page_title="EV Charging Infrastructure Analytics", layout="wide")

st.title("EV Charging Infrastructure Analytics Platform")
st.markdown(
    """
    This application provides:
    - Access to cleaned EV charging datasets
    - Database load (Load step of the ETL)
    - Interactive SQL analytics
    """
)

# --------------------------------------------------
# Sidebar Navigation
# --------------------------------------------------
menu = st.sidebar.radio(
    "Select Module",
    [
        "View Cleaned Dataset",
        "Load Data into Database",
        "Run SQL Analytics",
    ],
)

DATA_DIR = Path("data/clean")

# --------------------------------------------------
# SECTION 1 — View Cleaned Dataset
# --------------------------------------------------
if menu == "View Cleaned Dataset":
    st.header("Cleaned Dataset Viewer")

    dataset = st.selectbox(
        "Choose dataset",
        [
            "stations_clean.csv",
            "connections_clean.csv",
            "operators_clean.csv",
            "status_types.csv",
            "usage_types.csv"
        ]
    )

    file_path = DATA_DIR / dataset

    if file_path.exists():
        df = pd.read_csv(file_path)

        st.success(f"Loaded {len(df)} records")
        st.dataframe(df, use_container_width=True)

        st.download_button(label="Download CSV", data=df.to_csv(index=False), file_name=dataset, mime="text/csv")
    else:
        st.error("Selected file does not exist.")

# --------------------------------------------------
# SECTION 2 — Load Data into Database
# --------------------------------------------------
elif menu == "Load Data into Database":
    st.header("Load Cleaned Data into Database")

    st.info("This step loads cleaned CSV files into the configured database (SQLite default or Postgres).")

    if st.button("Start Data Load"):
        tables = {
            "stations_clean.csv": "stations",
            "connections_clean.csv": "connections",
            "operators_clean.csv": "operators",
            "status_types.csv": "status_types",
            "usage_types.csv": "usage_types",
        }

        try:
            db_url = get_database_url()

            for csv_file, table in tables.items():
                csv_path = DATA_DIR / csv_file
                if not csv_path.exists():
                    st.warning(f"Skipping missing file: {csv_file}")
                    continue

                # Truncate target table to ensure idempotent load
                try:
                    truncate_table(table)
                except Exception:
                    # If truncate fails for permissions/engine specifics, continue to load
                    st.info(f"Could not truncate {table}; attempting to load into existing table")

                inserted = bulk_insert_csv(table, csv_path)
                st.write(f"Loaded {inserted} rows into {table} from {csv_file}")

            st.success("Data successfully loaded into database")

        except Exception as e:
            st.error(f"Load failed: {e}")

# --------------------------------------------------
# SECTION 3 — Run SQL Analytics
# --------------------------------------------------
elif menu == "Run SQL Analytics":
    st.header("SQL Analytics Console")

    st.markdown(
        """
        Run ad-hoc SQL queries or query database views created during the project.
        """
    )

    sql_query = st.text_area(
        "Enter SQL query",
        height=180,
        value="""
        SELECT *
        FROM vw_operator_performance
        ORDER BY total_stations DESC
        LIMIT 10;
        """
    )

    if st.button("Execute Query"):
        try:
            conn = get_connection()
            df = pd.read_sql_query(sql_query, conn)
            close = getattr(conn, "close", None)
            if callable(close):
                conn.close()

            st.success(f"Query executed successfully ({len(df)} rows)")
            st.dataframe(df, use_container_width=True)

        except Exception as e:
            st.error(f"Query execution failed: {e}")
