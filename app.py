
import streamlit as st
import pandas as pd
import plotly.express as px
from sqlalchemy import text
import sys
import os

# Ensure we can import from the etl module
sys.path.append(os.path.abspath(os.path.dirname(__file__)))
from etl.db.db_utils import get_engine

# ---------------------------
# Page Configuration
# ---------------------------
st.set_page_config(
    page_title="OpenChargeMap Dashboard",
    page_icon="⚡",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ---------------------------
# CSS Styling
# ---------------------------
st.markdown("""
    <style>
    .main {
        background-color: #f5f5f5;
    }
    .stMetric {
        background-color: #ffffff;
        padding: 15px;
        border-radius: 10px;
        box-shadow: 2px 2px 5px rgba(0,0,0,0.1);
    }
    h1, h2, h3 {
        color: #2c3e50;
    }
    </style>
    """, unsafe_allow_html=True)

# ---------------------------
# Data Loading
# ---------------------------
@st.cache_data
def load_data():
    try:
        engine = get_engine()
        # Test connection first
        with engine.connect() as conn:
            pass
            
        # Query Stations
        query_stations = "SELECT * FROM stations"
        stations_df = pd.read_sql(query_stations, engine)
        
        # Query Connections
        query_connections = "SELECT * FROM connections"
        connections_df = pd.read_sql(query_connections, engine)
        

        return stations_df, connections_df, None
    except Exception as e:
        return None, None, str(e)

# ---------------------------
# Sidebar Navigation
# ---------------------------
st.sidebar.title("⚡ EV Dashboard")
page = st.sidebar.radio("Navigate", ["Home", "Map View", "Data Explorer", "Analysis"])

st.sidebar.markdown("---")
st.sidebar.info("Data Source: OpenChargeMap API")

# ---------------------------
# Main Logic
# ---------------------------
stations, connections, error = load_data()

if error:
    st.error("⚠️ Database Connection Failed")
    st.code(error)
    st.stop()

if stations is None or stations.empty:
    st.warning("No data found in the database. Please run the ETL pipeline first.")
    st.stop()

# Merge for analysis if needed (though keeping separate is often cleaner for specific stats)
full_data = pd.merge(connections, stations, on="station_id", how="left")

if page == "Home":
    st.title("🔋 EV Charging Infrastructure Overview")
    
    # KPIs
    col1, col2, col3, col4 = st.columns(4)
    
    total_stations = stations['station_id'].nunique()
    total_connections = len(connections)
    avg_power = connections['power_kw'].mean()
    active_stations = stations[stations['status'].str.lower().str.contains('operational', na=False)].shape[0]
    
    col1.metric("Total Stations", f"{total_stations}")
    col2.metric("Total Connections", f"{total_connections}")
    col3.metric("Avg Power (kW)", f"{avg_power:.1f} kW")
    col4.metric("Operational Stations", f"{active_stations}")
    
    st.markdown("### Recent Activity")
    st.dataframe(stations.sort_values(by="date_created", ascending=False).head(5)[['name', 'city', 'status', 'date_created']], use_container_width=True)

elif page == "Map View":
    st.title("🗺️ Station Map")
    
    # Filter by Status
    status_options = stations['status'].dropna().unique().tolist()
    selected_status = st.multiselect("Filter by Status", status_options, default=status_options)
    
    map_data = stations[stations['status'].isin(selected_status)]
    
    if not map_data.empty:
        fig = px.scatter_mapbox(
            map_data,
            lat="latitude",
            lon="longitude",
            hover_name="name",
            hover_data=["city", "status", "number_of_points"],
            color="status",
            zoom=4,
            height=600,
            title="Charging Station Locations"
        )
        fig.update_layout(mapbox_style="open-street-map")
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No stations match the selected criteria.")

elif page == "Data Explorer":
    st.title("💾 Data Explorer")
    
    tab1, tab2 = st.tabs(["Stations", "Connections"])
    
    with tab1:
        st.subheader("Stations Data")
        st.dataframe(stations, use_container_width=True)
        
    with tab2:
        st.subheader("Connections Data")
        st.dataframe(connections, use_container_width=True)

elif page == "Analysis":
    st.title("📊 Data Analysis")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Charger Types Distribution")
        type_counts = connections['connection_type'].value_counts().reset_index()
        type_counts.columns = ['Type', 'Count']
        fig_pie = px.pie(type_counts, names='Type', values='Count', title="Connection Types")
        st.plotly_chart(fig_pie, use_container_width=True)
        
    with col2:
        st.subheader("Power Output Distribution")
        fig_hist = px.histogram(connections, x="power_kw", nbins=20, title="Power (kW) Distribution", color_discrete_sequence=['#2ecc71'])
        st.plotly_chart(fig_hist, use_container_width=True)
    
    st.subheader("Stations by City (Top 10)")
    city_counts = stations['city'].value_counts().head(10).reset_index()
    city_counts.columns = ['City', 'Count']
    fig_bar = px.bar(city_counts, x='City', y='Count', title="Top Cities", color='Count', color_continuous_scale='Blues')
    st.plotly_chart(fig_bar, use_container_width=True)

