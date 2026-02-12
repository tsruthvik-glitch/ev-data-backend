#!/usr/bin/env python
"""Run ETL pipeline from current directory."""

import os
import sys

# Change to workspace directory
os.chdir(r'c:\Users\RUTHVIK SRINATH\OneDrive\Desktop\OpenChargeMap')

# Import and run ETL
from etl.main import run_etl

if __name__ == "__main__":
    success = run_etl()
    sys.exit(0 if success else 1)
