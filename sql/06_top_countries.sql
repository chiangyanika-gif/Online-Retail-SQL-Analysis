-- Query: Top 10 countries by revenue
-- Purpose: Compare customers, orders, revenue and revenue share by country
-- Output: results/06_top_countries.csv
-- Note: UK is about 82% of revenue. Netherlands and EIRE have very few buyers,
-- so they may be wholesale accounts. Currency assumed GBP.

SELECT Country,
       COUNT(DISTINCT CustomerID) AS customers,
       COUNT(DISTINCT InvoiceNo) AS orders,
       ROUND(SUM(Revenue), 2) AS revenue,
       ROUND(SUM(Revenue) * 100.0 /
             (SELECT SUM(Revenue) FROM clean_sales), 1) AS revenue_share_pct
FROM clean_sales
GROUP BY Country
ORDER BY revenue DESC
LIMIT 10;