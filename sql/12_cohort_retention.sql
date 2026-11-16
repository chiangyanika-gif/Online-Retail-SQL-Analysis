-- --------------------------------------------
-- STEP 12: Cohort retention
-- cohort = month of a customer's first purchase in the data.
-- month_N = customers active in EXACTLY month N after the cohort month
--           (not cumulative retention).
-- NULL = target month is after the last month in the data (2011-12).
-- Cells whose target month is 2011-12 cover only 9 days (partial month).
-- The 2010-12 cohort is not purely new customers: the data starts that month.
-- Requires the clean_sales view (see 02_create_clean_sales.sql).
-- --------------------------------------------
WITH activity AS (
    SELECT DISTINCT CustomerID,
           CAST(SUBSTR(InvoiceDate, 1, 4) AS INTEGER) * 12
         + CAST(SUBSTR(InvoiceDate, 6, 2) AS INTEGER) AS month_idx
    FROM clean_sales
),
first_purchase AS (
    SELECT CustomerID, MIN(month_idx) AS cohort_idx
    FROM activity
    GROUP BY CustomerID
),
data_end AS (
    SELECT MAX(month_idx) AS end_idx FROM activity
),
joined AS (
    SELECT f.CustomerID,
           f.cohort_idx,
           a.month_idx - f.cohort_idx AS month_number
    FROM first_purchase f
    JOIN activity a ON f.CustomerID = a.CustomerID
),
counts AS (
    SELECT cohort_idx,
           COUNT(DISTINCT CASE WHEN month_number = 0 THEN CustomerID END) AS cohort_size,
           COUNT(DISTINCT CASE WHEN month_number = 1 THEN CustomerID END) AS c1,
           COUNT(DISTINCT CASE WHEN month_number = 3 THEN CustomerID END) AS c3,
           COUNT(DISTINCT CASE WHEN month_number = 6 THEN CustomerID END) AS c6
    FROM joined
    GROUP BY cohort_idx
)
SELECT printf('%04d-%02d', (c.cohort_idx - 1) / 12, (c.cohort_idx - 1) % 12 + 1) AS cohort_month,
       c.cohort_size,
       CASE WHEN d.end_idx - c.cohort_idx >= 1 THEN c.c1 END AS month_1,
       CASE WHEN d.end_idx - c.cohort_idx >= 3 THEN c.c3 END AS month_3,
       CASE WHEN d.end_idx - c.cohort_idx >= 6 THEN c.c6 END AS month_6,
       CASE WHEN d.end_idx - c.cohort_idx >= 1
            THEN ROUND(100.0 * c.c1 / c.cohort_size, 1) END AS month_1_pct,
       CASE WHEN d.end_idx - c.cohort_idx >= 3
            THEN ROUND(100.0 * c.c3 / c.cohort_size, 1) END AS month_3_pct,
       CASE WHEN d.end_idx - c.cohort_idx >= 6
            THEN ROUND(100.0 * c.c6 / c.cohort_size, 1) END AS month_6_pct
FROM counts c
CROSS JOIN data_end d
ORDER BY c.cohort_idx;