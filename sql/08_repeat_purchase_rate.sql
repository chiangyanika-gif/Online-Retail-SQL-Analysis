-- Query: Repeat purchase rate
-- Purpose: Share of customers who placed more than one order
-- Output: results/08_repeat_purchase_rate.csv
-- Note: Based on about 13 months of data and customers with a CustomerID only,
-- so interpret cautiously. Currency assumed GBP.

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