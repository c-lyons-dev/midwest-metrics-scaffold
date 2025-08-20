Midwest Metrics Scaffold



A robust, automated scaffold generator for building R-based data analysis pipelines. This tool quickly sets up a complete project structure for connecting to MySQL databases, analyzing poll data, generating visualizations with ggplot2, and producing exportable reports.


_________________________
Features
_________________________

    Quick Setup: Automated Bash script creates entire project structure

    Data Analysis: Pre-built R functions for poll summarization and visualization

    Database Ready: MySQL/MariaDB connection utilities with environment-based configuration

    Smart Structure: Organized directory layout with proper .gitignore rules

    Docker Support: Containerized execution with Dockerfile included

    Live Data Fetching: Optional database schema and sample data retrieval

    Production Ready: Error handling, validation, and logging throughout
    
_________________________
Project Structure:
_________________________

    midwest-metrics-scaffold/
    ├── R/
    │   ├── db_connect.R
    │   ├── summarize_polls.R
    │   ├── plot_results.R
    │   └── export_reports.R
    ├── data/
    │   ├── poll_results_sample.csv
    │   ├── regions_lookup.csv
    │   ├── live_schema.sql
    │   └── live_sample.csv
    ├── outputs/
    ├── init_midwestmetrics_v5.sh
    ├── main.R
    ├── Dockerfile
    ├── .env.example
    └── README.md

    
_________________________
Quick Start
_________________________

Prerequisites:

    R (4.0+) with packages: dplyr, ggplot2, DBI, RMariaDB

    Bash environment

    MySQL client tools (for data fetching)

    Docker (optional)

    
_________________________
Installation
_________________________

1 Clone and setup:

    git clone https://github.com/c-lyons-dev/midwest-metrics-scaffold.git
    cd midwest-metrics-scaffold
    
2 Run the scaffold:

    # Basic setup
    ./init_midwestmetrics_v5.sh

    # With main analysis script
    ./init_midwestmetrics_v5.sh --with-main
    
3 Configure environment:

    cp .env.example .env
    # Edit .env with your database credentials

4 Configuration

Edit the .env file with your database settings:

    DB_HOST=127.0.0.1
    DB_PORT=yourdbport
    DB_NAME=yourdbname
    DB_USER=yourusername
    DB_PASS=yourpassword
    POLL_TABLE=yourpolltable
    SAMPLE_LIMIT=20
    
    
    
_________________________
Usage
_________________________

Fetch Live Data

    ./init_midwestmetrics_v5.sh --fetch

Run Analysis

    Rscript main.R

Docker Execution

    docker build -t midwest-metrics .
    docker run -v $(pwd)/data:/project/data -v $(pwd)/outputs:/project/outputs midwest-metrics

    
    
_________________________
Script Options
_________________________

Option	Description

--force	Overwrite existing files
--minimal	Skip sample data creation
--with-main	Generate main.R analysis script
--fetch	Pull live schema and data from DB



_________________________
Troubleshooting
_________________________

Common Issues

1 Database Connection Failed

    Verify .env credentials

    Check database server accessibility

2 R Packages Missing

    install.packages(c("dplyr", "ggplot2", "DBI", "RMariaDB"))
    
3 Permission Denied

    chmod +x init_midwestmetrics_v5.sh main.R
    
    
    
_________________________
License
_________________________

MIT License - feel free to use this scaffold for your client projects.



