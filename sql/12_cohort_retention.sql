-- Query: Cohort retention by first purchase month
-- Purpose: Count customers active 0, 1, 3 and 6 months after their first purchase
-- Output: results/12_cohort_retention.csv
-- Note: Counts exact-month activity, not cumulative retention.
-- Late cohorts show zeros because they have not been observed long enough.
-- Dec 2011 is partial (data ends Dec 9). Dec 2010 may include existing customers.

WITH first_purchase AS (
    SELECT CustomerID,
           SUBSTR(MIN(InvoiceDate), 1, 7) AS cohort_month
    FROM clean_sales
    GROUP BY CustomerID
),
activity AS (
    SELECT DISTINCT CustomerID,
           SUBSTR(InvoiceDate, 1, 7) AS active_month
    FROM clean_sales
),
joined AS (
    SELECT f.CustomerID,
           f.cohort_month,
           (CAST(SUBSTR(a.active_month, 1, 4) AS INTEGER) * 12 + CAST(SUBSTR(a.active_month, 6, 2) AS INTEGER))
         - (CAST(SUBSTR(f.cohort_month, 1, 4) AS INTEGER) * 12 + CAST(SUBSTR(f.cohort_month, 6, 2) AS INTEGER)) AS month_number
    FROM first_purchase f
    JOIN activity a ON f.CustomerID = a.CustomerID
)
SELECT cohort_month,
       COUNT(DISTINCT CASE WHEN month_number = 0 THEN CustomerID END) AS cohort_size,
       COUNT(DISTINCT CASE WHEN month_number = 1 THEN CustomerID END) AS month_1,
       COUNT(DISTINCT CASE WHEN month_number = 3 THEN CustomerID END) AS month_3,
       COUNT(DISTINCT CASE WHEN month_number = 6 THEN CustomerID END) AS month_6
FROM joined
GROUP BY cohort_month
ORDER BY cohort_month;