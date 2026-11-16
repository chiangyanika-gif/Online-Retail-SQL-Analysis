-- --------------------------------------------
-- STEP 8: Repeat purchase rate
-- Note: repeat rate = customers with more than 1 order in the data
-- window (2010-12 to 2011-12-09) / all customers with a CustomerID.
-- It is NOT the share of Champions in the RFM segmentation.
-- Orders cancelled later are still counted as orders.
-- Requires the clean_sales view (see 02_create_clean_sales.sql).
-- --------------------------------------------
WITH customer_orders AS (
    SELECT CustomerID,
           COUNT(DISTINCT InvoiceNo) AS orders
    FROM clean_sales
    GROUP BY CustomerID
)
SELECT COUNT(*) AS total_customers,
       SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS repeat_rate_pct
FROM customer_orders;