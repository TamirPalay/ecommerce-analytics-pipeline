-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS fact_order_items;
DROP TABLE IF EXISTS fact_orders;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS dim_customers;


-- Dimension Tables
CREATE TABLE dim_customers (
    customer_id TEXT PRIMARY KEY,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE dim_products (
    product_id TEXT PRIMARY KEY,
    product_category_name_english TEXT,
    product_weight_g DOUBLE PRECISION,
    product_length_cm DOUBLE PRECISION,
    product_height_cm DOUBLE PRECISION,
    product_width_cm DOUBLE PRECISION
);



-- Fact Tables
CREATE TABLE fact_orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT REFERENCES dim_customers(customer_id),
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_month TEXT,
    payment_value DOUBLE PRECISION,
    delivery_time_days INTEGER
);

CREATE TABLE fact_order_items (
    order_id TEXT REFERENCES fact_orders(order_id),
    product_id TEXT REFERENCES dim_products(product_id),
    seller_id TEXT,
    price DOUBLE PRECISION,
    freight_value DOUBLE PRECISION
);



-- Indexes for Performance
CREATE INDEX idx_fact_orders_customer_id
ON fact_orders(customer_id);

CREATE INDEX idx_fact_orders_purchase_ts
ON fact_orders(order_purchase_timestamp);

CREATE INDEX idx_fact_order_items_order_id
ON fact_order_items(order_id);

CREATE INDEX idx_fact_order_items_product_id
ON fact_order_items(product_id);

CREATE INDEX idx_fact_order_items_seller_id
ON fact_order_items(seller_id);