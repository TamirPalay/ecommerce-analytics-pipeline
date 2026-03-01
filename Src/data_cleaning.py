import pandas as pd
import os

# Paths
RAW_PATH = "Data/Raw"
PROCESSED_PATH = "Data/Processed"

os.makedirs(PROCESSED_PATH, exist_ok=True)


# Load datasets
orders = pd.read_csv(f"{RAW_PATH}/olist_orders_dataset.csv")
order_items = pd.read_csv(f"{RAW_PATH}/olist_order_items_dataset.csv")
payments = pd.read_csv(f"{RAW_PATH}/olist_order_payments_dataset.csv")
customers = pd.read_csv(f"{RAW_PATH}/olist_customers_dataset.csv")
products = pd.read_csv(f"{RAW_PATH}/olist_products_dataset.csv")
category_translation = pd.read_csv(f"{RAW_PATH}/product_category_name_translation.csv")

print("Datasets loaded successfully.")

# Basic Cleaning

# Convert date columns
date_columns = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

for col in date_columns:
    orders[col] = pd.to_datetime(orders[col], errors="coerce")

# Remove duplicate rows
orders = orders.drop_duplicates()
order_items = order_items.drop_duplicates()
payments = payments.drop_duplicates()
customers = customers.drop_duplicates()
products = products.drop_duplicates()

print("Duplicates removed.")


# Merge payment value into orders
payment_summary = payments.groupby("order_id")["payment_value"].sum().reset_index()
orders = orders.merge(payment_summary, on="order_id", how="left")


# Add derived columns
orders["order_month"] = orders["order_purchase_timestamp"].dt.to_period("M")
orders["delivery_time_days"] = (
    orders["order_delivered_customer_date"] - orders["order_purchase_timestamp"]
).dt.days

print("Derived columns created.")


# Translate product category names
products = products.merge(
    category_translation,
    on="product_category_name",
    how="left"
)

products["product_category_name_english"] = products[
    "product_category_name_english"
].fillna("unknown")


# Create fact and dimension tables

# Fact Orders
fact_orders = orders[[
    "order_id",
    "customer_id",
    "order_status",
    "order_purchase_timestamp",
    "order_month",
    "payment_value",
    "delivery_time_days"
]]

# Fact Order Items
fact_order_items = order_items[[
    "order_id",
    "product_id",
    "seller_id",
    "price",
    "freight_value"
]]

# Dimension Customers
dim_customers = customers[[
    "customer_id",
    "customer_city",
    "customer_state"
]]

# Dimension Products
dim_products = products[[
    "product_id",
    "product_category_name_english",
    "product_weight_g",
    "product_length_cm",
    "product_height_cm",
    "product_width_cm"
]]

print("Fact and dimension tables created.")


# Save processed outputs
fact_orders.to_csv(f"{PROCESSED_PATH}/fact_orders.csv", index=False)
fact_order_items.to_csv(f"{PROCESSED_PATH}/fact_order_items.csv", index=False)
dim_customers.to_csv(f"{PROCESSED_PATH}/dim_customers.csv", index=False)
dim_products.to_csv(f"{PROCESSED_PATH}/dim_products.csv", index=False)

print("Processed files saved to Data/Processed.")