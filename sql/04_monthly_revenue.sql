-- --------------------------------------------
-- STEP 4: Monthly revenue (gross)
-- Note: 2011-12 is a partial month (data ends 2011-12-09)
-- Requires the clean_sales view (see 02_create_clean_sales.sql).
-- --------------------------------------------

SELECT SUBSTR(InvoiceDate, 1, 7) AS month,
       ROUND(SUM(Revenue), 2) AS revenue
FROM clean_sales
GROUP BY month
ORDER BY month;