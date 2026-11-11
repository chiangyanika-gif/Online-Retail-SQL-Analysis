-- Query: Top 10 customers by revenue
-- Purpose: Identify the highest-spending customers and their share of total revenue
-- Output: results/07_top_customers.csv
-- Note: Top 10 customers account for about 17.3% of revenue. Some top buyers
-- place very few orders (possibly wholesale). Currency assumed GBP.

SELECT CustomerID,
       Country,
       COUNT(DISTINCT InvoiceNo) AS orders,
       ROUND(SUM(Revenue), 2) AS revenue,
       ROUND(SUM(Revenue) * 100.0 /
             (SELECT SUM(Revenue) FROM clean_sales), 2) AS revenue_share_pct
FROM clean_sales
GROUP BY CustomerID, Country
ORDER BY revenue DESC
LIMIT 10;