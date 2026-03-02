-- SQL/analysis_queries.sql
-- E-Commerce Analytics Pipeline - KPI Queries (PostgreSQL)

-- =========================================================
-- 0) Quick sanity: optional search_path
-- =========================================================
-- SET search_path TO public;

-- =========================================================
-- 1) Basic row counts
-- =========================================================
SELECT 'dim_customers' AS table_name, COUNT(*) AS rows FROM dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*) FROM dim_products
UNION ALL
SELECT 'fact_orders', COUNT(*) FROM fact_orders
UNION ALL
SELECT 'fact_order_items', COUNT(*) FROM fact_order_items;

-- =========================================================
-- 2) Revenue over time (monthly) + order count
-- =========================================================
SELECT
  DATE_TRUNC('month', order_purchase_timestamp) AS month,
  ROUND(SUM(payment_value)::numeric, 2) AS revenue,
  COUNT(*) AS orders
FROM fact_orders
WHERE payment_value IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- =========================================================
-- 3) Average order value (AOV) by month
-- =========================================================
SELECT
  DATE_TRUNC('month', order_purchase_timestamp) AS month,
  ROUND(AVG(payment_value)::numeric, 2) AS avg_order_value
FROM fact_orders
WHERE payment_value IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- =========================================================
-- 4) Top states by revenue
-- =========================================================
SELECT
  dc.customer_state,
  ROUND(SUM(fo.payment_value)::numeric, 2) AS revenue,
  COUNT(*) AS orders
FROM fact_orders fo
JOIN dim_customers dc ON dc.customer_id = fo.customer_id
WHERE fo.payment_value IS NOT NULL
GROUP BY 1
ORDER BY revenue DESC;

-- =========================================================
-- 5) Repeat purchase rate (customers with 2+ orders)
-- =========================================================
WITH orders_per_customer AS (
  SELECT customer_id, COUNT(*) AS order_count
  FROM fact_orders
  GROUP BY customer_id
)
SELECT
  ROUND(
    (100.0 * SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) / COUNT(*))::numeric,
    2
  ) AS repeat_customer_rate_pct,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) AS repeat_customers
FROM orders_per_customer;

-- =========================================================
-- 6) Customer Lifetime Value (CLV) - top 20 customers
-- =========================================================
SELECT
  customer_id,
  ROUND(SUM(payment_value)::numeric, 2) AS lifetime_value,
  COUNT(*) AS total_orders,
  ROUND(AVG(payment_value)::numeric, 2) AS avg_order_value
FROM fact_orders
WHERE payment_value IS NOT NULL
GROUP BY customer_id
ORDER BY lifetime_value DESC
LIMIT 20;

-- 6b) CLV distribution buckets (dashboard-friendly)

WITH customer_clv AS (
  SELECT
    customer_id,
    SUM(payment_value) AS lifetime_value
  FROM fact_orders
  WHERE payment_value IS NOT NULL
  GROUP BY customer_id
),
bucketed AS (
  SELECT
    CASE
      WHEN lifetime_value < 50 THEN '< 50'
      WHEN lifetime_value < 100 THEN '50-99'
      WHEN lifetime_value < 200 THEN '100-199'
      WHEN lifetime_value < 500 THEN '200-499'
      ELSE '500+'
    END AS clv_bucket,
    lifetime_value
  FROM customer_clv
)
SELECT
  clv_bucket,
  COUNT(*) AS customers,
  ROUND(AVG(lifetime_value)::numeric, 2) AS avg_clv_in_bucket
FROM bucketed
GROUP BY clv_bucket
ORDER BY
  CASE clv_bucket
    WHEN '< 50' THEN 1
    WHEN '50-99' THEN 2
    WHEN '100-199' THEN 3
    WHEN '200-499' THEN 4
    ELSE 5
  END;

-- =========================================================
-- 7) Revenue by product category (items + freight)
-- =========================================================
SELECT
  dp.product_category_name_english AS category,
  ROUND(SUM(foi.price)::numeric, 2) AS item_revenue,
  ROUND(SUM(foi.freight_value)::numeric, 2) AS total_freight,
  COUNT(*) AS items_sold
FROM fact_order_items foi
JOIN dim_products dp ON dp.product_id = foi.product_id
GROUP BY 1
ORDER BY item_revenue DESC;

-- =========================================================
-- 7b) Top 10 categories by item revenue (clean quick view)
-- =========================================================
SELECT
  dp.product_category_name_english AS category,
  ROUND(SUM(foi.price)::numeric, 2) AS item_revenue
FROM fact_order_items foi
JOIN dim_products dp ON dp.product_id = foi.product_id
GROUP BY 1
ORDER BY item_revenue DESC
LIMIT 10;

-- =========================================================
-- 8) Category share of revenue (Top 15 + "Other")
-- =========================================================
WITH category_revenue AS (
  SELECT
    COALESCE(dp.product_category_name_english, 'unknown') AS category,
    SUM(foi.price) AS revenue
  FROM fact_order_items foi
  JOIN dim_products dp ON dp.product_id = foi.product_id
  GROUP BY 1
),
ranked AS (
  SELECT
    category,
    revenue,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS rnk
  FROM category_revenue
),
tot AS (
  SELECT SUM(revenue) AS total_revenue FROM category_revenue
)
SELECT
  CASE WHEN rnk <= 15 THEN category ELSE 'Other' END AS category_group,
  ROUND(SUM(revenue)::numeric, 2) AS revenue,
  ROUND(
    (100.0 * SUM(revenue) / (SELECT total_revenue FROM tot))::numeric,
    2
  ) AS revenue_share_pct
FROM ranked
GROUP BY 1
ORDER BY revenue DESC;

-- =========================================================
-- 9) Delivery performance summary
-- =========================================================
SELECT
  ROUND(AVG(delivery_time_days)::numeric, 2) AS avg_delivery_days,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_time_days) AS median_delivery_days,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY delivery_time_days) AS p90_delivery_days
FROM fact_orders
WHERE delivery_time_days IS NOT NULL;

-- =========================================================
-- 10) Delivery performance by state (top 15 by order count)
-- =========================================================
SELECT
  dc.customer_state,
  COUNT(*) AS orders,
  ROUND(AVG(fo.delivery_time_days)::numeric, 2) AS avg_delivery_days
FROM fact_orders fo
JOIN dim_customers dc ON dc.customer_id = fo.customer_id
WHERE fo.delivery_time_days IS NOT NULL
GROUP BY 1
ORDER BY orders DESC
LIMIT 15;

-- =========================================================
-- 11) Order status breakdown
-- =========================================================
SELECT
  order_status,
  COUNT(*) AS orders,
  ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ())::numeric, 2) AS pct
FROM fact_orders
GROUP BY 1
ORDER BY orders DESC;

-- =========================================================
-- 12) New vs Repeat customers by month
-- (New customer = first-ever order month)
-- =========================================================
WITH first_order AS (
  SELECT
    customer_id,
    MIN(DATE_TRUNC('month', order_purchase_timestamp)) AS first_month
  FROM fact_orders
  GROUP BY customer_id
),
orders_monthly AS (
  SELECT
    fo.customer_id,
    DATE_TRUNC('month', fo.order_purchase_timestamp) AS month,
    fo.payment_value
  FROM fact_orders fo
  WHERE fo.payment_value IS NOT NULL
)
SELECT
  om.month,
  COUNT(*) AS orders,
  ROUND(SUM(om.payment_value)::numeric, 2) AS revenue,
  COUNT(DISTINCT CASE WHEN fo.first_month = om.month THEN om.customer_id END) AS new_customers,
  COUNT(DISTINCT CASE WHEN fo.first_month < om.month THEN om.customer_id END) AS repeat_customers
FROM orders_monthly om
JOIN first_order fo ON fo.customer_id = om.customer_id
GROUP BY 1
ORDER BY 1;

-- =========================================================
-- 13) Revenue & freight over time (monthly)
-- =========================================================
WITH order_months AS (
  SELECT
    order_id,
    DATE_TRUNC('month', order_purchase_timestamp) AS month
  FROM fact_orders
)
SELECT
  om.month,
  ROUND(SUM(foi.price)::numeric, 2) AS item_revenue,
  ROUND(SUM(foi.freight_value)::numeric, 2) AS freight_total,
  ROUND((SUM(foi.freight_value) / NULLIF(SUM(foi.price), 0))::numeric, 4) AS freight_to_revenue_ratio
FROM order_months om
JOIN fact_order_items foi ON foi.order_id = om.order_id
GROUP BY 1
ORDER BY 1;

-- =========================================================
-- 14) RFM base table (no LIMIT; useful for exports)
-- =========================================================
WITH max_date AS (
  SELECT MAX(order_purchase_timestamp) AS max_purchase_date
  FROM fact_orders
),
customer_metrics AS (
  SELECT
    customer_id,
    MAX(order_purchase_timestamp) AS last_purchase,
    COUNT(*) AS frequency,
    SUM(payment_value) AS monetary
  FROM fact_orders
  WHERE payment_value IS NOT NULL
  GROUP BY customer_id
)
SELECT
  cm.customer_id,
  EXTRACT(DAY FROM ((SELECT max_purchase_date FROM max_date) - cm.last_purchase))::int AS recency_days,
  cm.frequency,
  ROUND(cm.monetary::numeric, 2) AS monetary_total
FROM customer_metrics cm
ORDER BY monetary_total DESC;

-- =========================================================
-- 15) RFM segmentation summary (dashboard-friendly)
-- Produces segment counts + spending
-- =========================================================
WITH max_date AS (
  SELECT MAX(order_purchase_timestamp) AS max_purchase_date
  FROM fact_orders
),
customer_metrics AS (
  SELECT
    customer_id,
    MAX(order_purchase_timestamp) AS last_purchase,
    COUNT(*) AS frequency,
    SUM(payment_value) AS monetary
  FROM fact_orders
  WHERE payment_value IS NOT NULL
  GROUP BY customer_id
),
rfm_base AS (
  SELECT
    cm.customer_id,
    EXTRACT(DAY FROM ((SELECT max_purchase_date FROM max_date) - cm.last_purchase))::int AS recency_days,
    cm.frequency,
    cm.monetary
  FROM customer_metrics cm
),
scored AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    NTILE(4) OVER (ORDER BY recency_days ASC) AS r_tile,   -- 1=most recent, 4=least recent
    NTILE(4) OVER (ORDER BY frequency DESC)  AS f_tile,   -- 1=highest frequency
    NTILE(4) OVER (ORDER BY monetary DESC)   AS m_tile    -- 1=highest monetary
  FROM rfm_base
),
scored_fixed AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    (5 - r_tile) AS r_score,  -- 4=best (recent), 1=worst
    (5 - f_tile) AS f_score,  -- 4=best (frequent)
    (5 - m_tile) AS m_score   -- 4=best (high monetary)
  FROM scored
),
segmented AS (
  SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE
      WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
      WHEN r_score >= 3 AND f_score >= 2 THEN 'Loyal / Active'
      WHEN r_score >= 3 AND f_score = 1 THEN 'New Customers'
      WHEN r_score = 2 AND f_score >= 2 THEN 'Potential Loyalists'
      WHEN r_score = 1 AND f_score >= 2 THEN 'At Risk'
      ELSE 'Others'
    END AS segment
  FROM scored_fixed
)
SELECT
  segment,
  COUNT(*) AS customers,
  ROUND(AVG(recency_days)::numeric, 2) AS avg_recency_days,
  ROUND(AVG(frequency)::numeric, 2) AS avg_orders,
  ROUND(AVG(monetary)::numeric, 2) AS avg_spend,
  ROUND(SUM(monetary)::numeric, 2) AS total_spend
FROM segmented
GROUP BY segment
ORDER BY total_spend DESC;