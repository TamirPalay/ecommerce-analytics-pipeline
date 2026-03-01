# E-Commerce Analytics Pipeline

## Overview
This project simulates a real-world analytics workflow for an e-commerce company. It transforms raw transactional data into actionable business insights using a full pipeline: data cleaning, relational modeling, SQL analysis, and dashboard reporting.

What this project demonstrates:
- Data cleaning and transformation in Python (Pandas)
- Relational schema design in PostgreSQL
- Advanced SQL analysis (joins, aggregations, window functions)
- KPI development and business insights
- Dashboard reporting (Power BI)
- Clear documentation and reproducibility

---

## Dataset
This project uses the **Olist Brazilian E-Commerce Public Dataset** from Kaggle.

Dataset link:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Note: The raw dataset may be large. You can choose whether to commit raw data to GitHub.
- Recommended (professional standard): keep raw data out of Git and provide download instructions (cleaner repo).
- If you prefer to show everything you worked with: you can commit the raw CSVs, but it makes the repo heavier.

Expected local dataset location after download/unzip:
Data/Raw

---

## Business Questions
The analytics in this project is built to answer questions such as:
- How does revenue change over time (monthly trends)?
- Who are the most valuable customers (Customer Lifetime Value)?
- What percentage of customers make repeat purchases?
- Which product categories contribute the most revenue?
- How efficient is delivery (delivery time and delays)?

---

## Project Architecture
Pipeline flow:
Raw CSV Data -> Python Cleaning & Transformation -> PostgreSQL Database -> SQL Analytics -> Power BI Dashboard -> Business Insights

---

## Tech Stack
- Python: Pandas, NumPy, SQLAlchemy
- PostgreSQL: relational storage, indexing, query performance
- SQL: joins, aggregations, window functions
- Power BI: interactive dashboarding
- Git/GitHub: version control and portfolio presentation

---

## Repository Structure
- Data/Raw
  - Place downloaded Kaggle CSV files here
- Data/Processed
  - Generated cleaned outputs written by the pipeline scripts
- Src
  - Python scripts for cleaning and loading data
- SQL
  - Database schema and analysis queries
- Notebooks
  - Optional EDA notebook(s)
- Dashboard
  - Power BI file and/or dashboard screenshots

---

## Database Design
This project uses a simplified star-schema approach.

Dimension tables:
- dim_customers: customer attributes and location
- dim_products: product attributes and translated category name

Fact tables:
- fact_orders: order-level attributes, timestamps, status, and order value fields
- fact_order_items: item-level details, product references, price, freight

Indexes are added on common join keys (for example: order_id, customer_id, product_id) to improve query performance.

---

## Metrics Implemented
The SQL analysis focuses on business KPIs such as:
- Monthly revenue
- Customer Lifetime Value (CLV)
- Repeat purchase rate
- Revenue by product category
- Average delivery time
- Order volume trends

---

## Example Insights (Typical Outcomes)
These are representative insights that this project enables:
- A small percentage of customers contribute a large share of total revenue.
- Revenue spikes during specific months (often tied to promotions/seasonality).
- Repeat customers have significantly higher lifetime value than one-time customers.
- Some product categories contribute disproportionally to revenue.
- Delivery times vary by region and can impact customer satisfaction.

---

## How to Run (Local Reproduction)

### Step 1: Clone the repository
- git clone https://github.com/TamirPalay/ecommerce-analytics-pipeline.git
- cd ecommerce-analytics-pipeline

### Step 2: Create and activate a Python virtual environment
Windows:
- python -m venv venv
- venv\Scripts\activate

### Step 3: Install dependencies
- pip install -r requirements.txt

### Step 4: Download and place the dataset
1) Download from Kaggle:
   https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2) Unzip the files
3) Place the CSVs into:
   Data/Raw

### Step 5: Run data cleaning
- python Src/data_cleaning.py

Outputs will be written to:
- Data/Processed

### Step 6: Create PostgreSQL database
Create a local PostgreSQL database named:
- ecommerce_db

### Step 7: Create tables
Run the schema script in your SQL client (pgAdmin or psql):
- SQL/schema.sql

### Step 8: Load cleaned data into PostgreSQL
- python Src/load_to_db.py

### Step 9: Run analytics SQL
Execute the analysis queries in your SQL client:
- SQL/analysis_queries.sql

### Step 10: Build and view the dashboard
Open the Power BI dashboard (if included) from:
- Dashboard

If your dashboard is not included, you can connect Power BI to PostgreSQL (ecommerce_db) and build visuals for the KPIs listed above.

---

## Power BI Dashboard (Suggested Pages)
Recommended dashboard pages:
- Overview: revenue, orders, AOV, repeat rate
- Revenue Trends: monthly revenue line, seasonal spikes
- Customers: CLV distribution, top customers, repeat vs one-time
- Products: revenue by category, top products
- Delivery: average delivery time, delays by region

---

## Future Improvements
Possible extensions:
- Cohort retention analysis
- Customer segmentation (clustering)
- Profitability / margin analysis (if cost data is available)
- Automated scheduled ETL (Airflow / cron)
- Streamlit dashboard deployment

---

## Author
Tamir Palay
GitHub: https://github.com/TamirPalay