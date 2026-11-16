-- --------------------------------------------
-- STEP 7: Top 10 customers by revenue (gross)
-- Note: gross revenue; purchases cancelled later are NOT deducted.
-- Customers 16446 (2 orders) and 12346 (1 order) rank high on gross
-- revenue, but their net revenue may be much lower if their orders
-- were cancelled later (preliminary observation, not verified
-- in this query).
-- Requires the clean_sales view (see 02_create_clean_sales.sql).
-- --------------------------------------------
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