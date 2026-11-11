-- Query: Monthly revenue
-- Purpose: Total revenue per month from the clean_sales view
-- Output: results/04_monthly_revenue.csv
-- Note: December 2011 is partial (data ends Dec 9). Currency assumed GBP.

SELECT SUBSTR(InvoiceDate, 1, 7) AS month,
       ROUND(SUM(Revenue), 2) AS revenue
FROM clean_sales
GROUP BY month
ORDER BY month;