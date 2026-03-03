-- SQL/data_quality_checks.sql

-- Duplicate checks (should be 0)
SELECT order_id, COUNT(*) FROM fact_orders GROUP BY order_id HAVING COUNT(*) > 1;
SELECT customer_id, COUNT(*) FROM dim_customers GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT product_id, COUNT(*) FROM dim_products GROUP BY product_id HAVING COUNT(*) > 1;

-- FK integrity checks (should be 0)
SELECT COUNT(*) AS missing_customers
FROM fact_orders fo
LEFT JOIN dim_customers dc ON dc.customer_id = fo.customer_id
WHERE dc.customer_id IS NULL;

SELECT COUNT(*) AS missing_products
FROM fact_order_items foi
LEFT JOIN dim_products dp ON dp.product_id = foi.product_id
WHERE dp.product_id IS NULL;

SELECT COUNT(*) AS missing_orders
FROM fact_order_items foi
LEFT JOIN fact_orders fo ON fo.order_id = foi.order_id
WHERE fo.order_id IS NULL;

-- Null / range sanity checks
SELECT COUNT(*) AS null_payment_value FROM fact_orders WHERE payment_value IS NULL;
SELECT COUNT(*) AS negative_delivery_days FROM fact_orders WHERE delivery_time_days < 0;