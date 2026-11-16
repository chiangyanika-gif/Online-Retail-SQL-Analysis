-- --------------------------------------------
-- STEP 6: Top countries by revenue (gross)
-- Note: gross revenue; purchases cancelled later are NOT deducted.
-- Netherlands (9 customers) and EIRE (3 customers) are highly
-- concentrated in a few customers, so read their share with care.
-- UK includes customers 12346 and 16446 (gross 245,656.10 combined),
-- which may be overstated if their orders were cancelled later
-- (preliminary observation, not verified in this query).
-- Requires the clean_sales view (see 02_create_clean_sales.sql).
-- UK accounts for 82.0% of gross revenue.
-- --------------------------------------------
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