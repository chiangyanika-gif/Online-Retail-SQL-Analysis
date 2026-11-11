-- Query: Monthly revenue growth
-- Purpose: Month-over-month revenue change using LAG()
-- Output: results/05_monthly_growth.csv
-- Note: First month has no previous value (NULL). December 2011 is partial (data ends Dec 9), so exclude its growth from conclusions. Currency assumed GBP.

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