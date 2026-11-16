-- --------------------------------------------
-- STEP 9: RFM raw values per customer (top 10 by monetary)
-- Note: recency_days = days from the last date in the data
-- (2011-12-09 12:50:00), not from today. CAST AS INTEGER truncates
-- to whole days, so 0 means less than 1 full day, not necessarily
-- the same calendar day. monetary is gross revenue.
-- Requires the clean_sales view (see 02_create_clean_sales.sql).
-- --------------------------------------------
SELECT CustomerID,
       CAST(julianday((SELECT MAX(InvoiceDate) FROM clean_sales))
            - julianday(MAX(InvoiceDate)) AS INTEGER) AS recency_days,
       COUNT(DISTINCT InvoiceNo) AS frequency,
       ROUND(SUM(Revenue), 2) AS monetary
FROM clean_sales
GROUP BY CustomerID
ORDER BY monetary DESC
LIMIT 10;