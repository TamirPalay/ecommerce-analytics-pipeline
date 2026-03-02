import os
import pandas as pd
from sqlalchemy import create_engine, text

PROCESSED_PATH = "Data/Processed"
DB_USER = "postgres"
DB_PASSWORD = "4544"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "ecommerce_db"


TABLE_FILES = [
    ("dim_customers", "dim_customers.csv"),
    ("dim_products", "dim_products.csv"),
    ("fact_orders", "fact_orders.csv"),
    ("fact_order_items", "fact_order_items.csv"),
]

def make_engine():
    conn_str = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    return create_engine(conn_str)

def assert_file_exists(path: str):
    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing file: {path}")

def truncate_tables(engine):
    # CASCADE clears dependent rows in FK-related tables safely
    with engine.begin() as conn:
        conn.execute(text("""
            TRUNCATE TABLE
                fact_order_items,
                fact_orders,
                dim_products,
                dim_customers
            RESTART IDENTITY CASCADE;
        """))
def load_table(engine, table_name: str, filename: str):
    path = os.path.join(PROCESSED_PATH, filename)
    assert_file_exists(path)

    df = pd.read_csv(path)

    print(f"\nLoading {filename} -> {table_name}")
    print(f"Rows: {len(df):,} | Columns: {len(df.columns)}")

    # Append into existing schema tables
    df.to_sql(
        table_name,
        engine,
        if_exists="append",
        index=False,
        method="multi",
        chunksize=5000
    )

    print(f"Loaded: {table_name}")

def main():
    # Safety checks
    if not os.path.isdir(PROCESSED_PATH):
        raise FileNotFoundError(f"Processed folder not found: {PROCESSED_PATH}")

    engine = make_engine()

    # Optional: clear tables before loading (recommended while developing)
    print("Truncating existing tables...")
    truncate_tables(engine)
    print("Tables truncated.")

    # Load in dimension -> facts order (dims first for FK integrity)
    for table_name, filename in TABLE_FILES:
        load_table(engine, table_name, filename)

    print("\n✅ All tables loaded successfully.")

if __name__ == "__main__":
    main()