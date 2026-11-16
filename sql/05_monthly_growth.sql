-- --------------------------------------------
-- STEP 5: Month-over-month growth (gross revenue)
-- Note: 2011-12 is a partial month (data ends 2011-12-09),
-- so its -55.4% is NOT a real decline; do not interpret it as one.
-- Requires the clean_sales view (see 02_create_clean_sales.sql).
-- --------------------------------------------
WITH monthly AS (
  SELECT SUBSTR(InvoiceDate, 1, 7) AS month,
         SUM(Revenue) AS revenue
  FROM clean_sales
  GROUP BY month
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS prev_revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
             * 100.0 / LAG(revenue) OVER (ORDER BY month), 1) AS growth_pct
FROM monthly
ORDER BY month;